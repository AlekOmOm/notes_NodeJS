# 7b. Simple Authentication Server with Docker Compose 🔐

[<- Back to Main Topic](./07-auth-system.md) | [Next Sub-Topic: Role-Based Access Control ->](./07c-rbac.md)

## Overview

This guide focuses on building a straightforward, session-based authentication service using PostgreSQL and Express.js in Docker. This simplified approach eliminates the complexity of JWT tokens, Redis caching, Nginx configuration, and multi-factor authentication while still providing secure user authentication for your applications.

## Simplified Architecture

### Directory Structure

```
auth-simple/
├── docker-compose.yml        # Container configuration
├── .env                      # Environment variables
├── auth-service/             # Authentication API code
│   ├── Dockerfile            # Build instructions for Node.js app
│   ├── package.json          # Dependencies
│   ├── src/                  # Source code
│   │   ├── index.js          # Entry point
│   │   ├── config.js         # Configuration
│   │   ├── routes/           # API routes
│   │   │   └── auth.js       # Authentication endpoints
│   │   ├── controllers/      # Request handlers
│   │   │   └── auth.js       # Authentication logic
│   │   ├── middleware/       # Express middleware
│   │   │   └── session.js    # Session validation
│   │   └── db/               # Database access
│   │       └── users.js      # User-related queries
│   └── .dockerignore         # Files to exclude from Docker build
└── database/                 # Database setup
    ├── init/                 # Initialization scripts
    │   ├── 01-schema.sql     # User and session tables
    │   └── 02-seed-users.sql # Test users (dev only)
    └── scripts/              # Utility scripts
        └── reset-db.sh       # Reset database
```

### Components

#### 1. Auth Service (Express.js)

A simple Express.js application that provides:
- User registration and login
- Session-based authentication
- Password reset functionality
- Basic user profile management

#### 2. PostgreSQL Database

Stores all persistent data:
- User accounts and profile information
- Encrypted passwords
- Session information
- Simple role assignments

## Docker Compose Configuration

```yaml
# docker-compose.yml
version: '3.8'
services:
  auth_api:
    build: ./auth-service
    container_name: auth-api
    restart: unless-stopped
    ports:
      - "${AUTH_PORT:-3000}:3000"
    environment:
      NODE_ENV: ${NODE_ENV:-development}
      PORT: 3000
      SESSION_SECRET: ${SESSION_SECRET:-dev_session_secret}
      COOKIE_MAX_AGE: ${COOKIE_MAX_AGE:-86400000}
      PGHOST: postgres
      PGUSER: ${POSTGRES_USER:-auth_user}
      PGPASSWORD: ${POSTGRES_PASSWORD:-auth_password}
      PGDATABASE: ${POSTGRES_DB:-auth_db}
      PGPORT: 5432
      CORS_ORIGIN: ${CORS_ORIGIN:-http://localhost:8080}
    depends_on:
      - postgres
    networks:
      - auth_network
    volumes:
      - ./auth-service/src:/app/src  # For development hot-reload

  postgres:
    image: postgres:15
    container_name: auth-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-auth_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-auth_password}
      POSTGRES_DB: ${POSTGRES_DB:-auth_db}
    ports:
      - "${POSTGRES_PORT:-5432}:5432"  # Expose for development tools
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
    networks:
      - auth_network

networks:
  auth_network:
    driver: bridge

volumes:
  postgres_data:
```

### Environment Variables (.env)

```
# .env
NODE_ENV=development
AUTH_PORT=3000
SESSION_SECRET=something_very_secret_for_development
COOKIE_MAX_AGE=86400000  # 24 hours in milliseconds

# PostgreSQL
POSTGRES_USER=auth_user
POSTGRES_PASSWORD=auth_password
POSTGRES_DB=auth_db
POSTGRES_PORT=5432

# CORS
CORS_ORIGIN=http://localhost:8080
```

## Database Setup

### Schema (01-schema.sql)

```sql
-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_modtime
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- Sessions table (for server-side sessions)
CREATE TABLE sessions (
    sid VARCHAR(255) PRIMARY KEY,
    sess JSON NOT NULL,
    expire TIMESTAMP(6) NOT NULL
);
CREATE INDEX IDX_sessions_expire ON sessions (expire);
```

## Express.js Authentication Implementation

### Key Components

#### 1. Session Configuration

```javascript
// src/middleware/session.js
import session from 'express-session';
import pgSession from 'connect-pg-simple';
import pool from '../db/pool.js';

const PgSession = pgSession(session);

export default function configureSession(app) {
  app.use(session({
    store: new PgSession({
      pool,
      tableName: 'sessions'
    }),
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: process.env.NODE_ENV === 'production',
      httpOnly: true,
      maxAge: parseInt(process.env.COOKIE_MAX_AGE) || 86400000 // 24 hours
    }
  }));
}
```

#### 2. Authentication Routes

```javascript
// src/routes/auth.js
import express from 'express';
import * as authController from '../controllers/auth.js';
import { isAuthenticated } from '../middleware/auth.js';

const router = express.Router();

// Public routes
router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);

// Protected routes
router.get('/me', isAuthenticated, authController.getCurrentUser);
router.put('/me', isAuthenticated, authController.updateProfile);
router.post('/logout', isAuthenticated, authController.logout);

export default router;
```

#### 3. Authentication Controller

```javascript
// src/controllers/auth.js (simplified)
import * as userService from '../services/user.js';
import bcrypt from 'bcrypt';

export async function login(req, res) {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    // Find user
    const user = await userService.findByEmail(email);
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Check if user is active
    if (!user.is_active) {
      return res.status(401).json({ message: 'Account is inactive' });
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Create session
    req.session.userId = user.id;
    req.session.role = user.role;

    // Return user info (without password)
    const { password_hash, ...userWithoutPassword } = user;
    res.json({
      message: 'Login successful',
      user: userWithoutPassword
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'An error occurred during login' });
  }
}

export async function logout(req, res) {
  req.session.destroy(err => {
    if (err) {
      console.error('Session destruction error:', err);
      return res.status(500).json({ message: 'Could not log out' });
    }
    res.clearCookie('connect.sid');
    res.json({ message: 'Logged out successfully' });
  });
}

// Other controller methods...
```

#### 4. Authentication Middleware

```javascript
// src/middleware/auth.js
export function isAuthenticated(req, res, next) {
  if (!req.session || !req.session.userId) {
    return res.status(401).json({ message: 'Authentication required' });
  }
  next();
}

export function hasRole(role) {
  return (req, res, next) => {
    if (!req.session || !req.session.userId) {
      return res.status(401).json({ message: 'Authentication required' });
    }
    
    if (req.session.role !== role && req.session.role !== 'admin') {
      return res.status(403).json({ message: 'Insufficient permissions' });
    }
    
    next();
  };
}
```

## Integration with Client Applications

### Client Authentication with Session Cookies

```javascript
// Example client-side code (with fetch API)
const API_URL = 'http://localhost:3000/api/auth';

// Login function
async function login(email, password) {
  const response = await fetch(`${API_URL}/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ email, password }),
    credentials: 'include' // Important for cookies!
  });
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message);
  }
  
  return response.json();
}

// Get current user profile
async function getCurrentUser() {
  const response = await fetch(`${API_URL}/me`, {
    credentials: 'include' // Important for cookies!
  });
  
  if (!response.ok) {
    if (response.status === 401) {
      // Not authenticated
      return null;
    }
    const error = await response.json();
    throw new Error(error.message);
  }
  
  return response.json();
}

// Logout
async function logout() {
  const response = await fetch(`${API_URL}/logout`, {
    method: 'POST',
    credentials: 'include'
  });
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message);
  }
  
  return response.json();
}
```

## Running the Authentication Service

### Starting the Service

```bash
# Start containers
docker-compose up -d

# View logs
docker-compose logs -f

# Access the API
curl http://localhost:3000/api/auth/status
```

### Resetting the Database

```bash
# Run reset script
./database/scripts/reset-db.sh
```

## Security Considerations

Even with this simplified approach, several security aspects remain important:

1. **Session Security**:
   - Use a strong, unique SESSION_SECRET
   - Set secure and httpOnly flags for cookies in production
   - Implement proper session expiration

2. **Password Security**:
   - Use bcrypt for password hashing
   - Implement password strength validation
   - Provide secure password reset workflows

3. **Input Validation**:
   - Validate and sanitize all user inputs
   - Prevent SQL injection via parameterized queries
   - Avoid exposing sensitive information in responses

4. **CORS Configuration**:
   - Configure specific allowed origins
   - Use credentials mode for cross-origin requests

5. **Rate Limiting**:
   - Consider adding express-rate-limit for basic protection
   - Limit login attempts to prevent brute force attacks

## Common Customizations

This simple authentication system can be customized in several ways:

1. **Email Verification**:
   - Add email_verified field to users table
   - Create verification token system
   - Add email sending functionality

2. **Password Reset**:
   - Create reset tokens table
   - Add expiring token generation and validation
   - Include email notifications

3. **Profile Enhancement**:
   - Add additional user profile fields
   - Support profile images (with file storage)
   - Add user preferences

4. **Role Expansion**:
   - Create dedicated roles and permissions tables
   - Implement more granular access control
   - Add role management endpoints

## Summary

This simplified authentication service:

1. **Uses sessions** instead of JWTs for simplicity and security
2. **Leverages PostgreSQL** for both user data and session storage
3. **Provides basic endpoints** for registration, login, and profile management
4. **Runs entirely in Docker** for consistency and portability
5. **Excludes complexity** like Redis, Nginx, and MFA

This approach is ideal for small to medium applications where a dedicated, simple authentication service is needed without the overhead of more complex solutions.

---

[<- Back to Main Topic](./07-auth-system.md) | [Next Sub-Topic: Role-Based Access Control ->](./07c-rbac.md)
