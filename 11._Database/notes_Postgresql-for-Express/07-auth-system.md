# 7. Authentication System Setup 🔐

[<- Back: PostgreSQL Features](./06-postgresql-features.md) | [Next: Docker Deployment ->](./08-docker-deployment.md)

## Table of Contents

- [Database Schema](#database-schema)
- [Password Storage](#password-storage)
- [User Management](#user-management)
- [Session Management](#session-management)
- [Token-based Authentication](#token-based-authentication)
- [Role-based Access Control](#role-based-access-control)
- [Security Considerations](#security-considerations)

## Database Schema

A robust authentication system requires several interconnected tables:

```sql
-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    verification_token VARCHAR(255),
    reset_token VARCHAR(255),
    reset_token_expires TIMESTAMPTZ
);

-- Roles table
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

-- User roles (many-to-many)
CREATE TABLE user_roles (
    user_id INTEGER NOT NULL,
    role_id INTEGER NOT NULL,
    granted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE
);

-- Sessions table
CREATE TABLE sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id INTEGER NOT NULL,
    token VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,
    is_valid BOOLEAN DEFAULT true,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- Audit log for authentication events
CREATE TABLE auth_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    event_type VARCHAR(50) NOT NULL, -- 'login', 'logout', 'failed_login', etc.
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    details JSONB,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
);
```

### Optional Tables

For more advanced authentication systems:

```sql
-- Two-factor authentication
CREATE TABLE two_factor_auth (
    user_id INTEGER PRIMARY KEY,
    secret_key VARCHAR(255) NOT NULL,
    is_enabled BOOLEAN DEFAULT false,
    backup_codes JSONB,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- Social logins
CREATE TABLE social_connections (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    provider VARCHAR(50) NOT NULL, -- 'google', 'facebook', 'github', etc.
    provider_user_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMPTZ,
    profile_data JSONB,
    UNIQUE (provider, provider_user_id),
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);
```

## Password Storage

Never store plaintext passwords. PostgreSQL enables secure password management:

```javascript
import bcrypt from 'bcrypt';
import pool from '../database/connection.js';

// Register a new user
async function registerUser(username, email, password) {
  // Generate salt and hash
  const saltRounds = 12;
  const passwordHash = await bcrypt.hash(password, saltRounds);
  
  // Store user with hashed password
  const result = await pool.query(
    `INSERT INTO users (username, email, password_hash)
     VALUES ($1, $2, $3)
     RETURNING id`,
    [username, email, passwordHash]
  );
  
  return result.rows[0].id;
}

// Verify password during login
async function verifyUser(email, password) {
  // Get user by email
  const result = await pool.query(
    'SELECT id, username, password_hash FROM users WHERE email = $1',
    [email]
  );
  
  const user = result.rows[0];
  if (!user) return null;
  
  // Check password
  const passwordValid = await bcrypt.compare(password, user.password_hash);
  if (!passwordValid) return null;
  
  // Return user without password hash
  return {
    id: user.id,
    username: user.username
  };
}
```

### Handling Password Resets

```javascript
import crypto from 'crypto';

// Generate reset token
async function createPasswordReset(email) {
  // Generate random token
  const resetToken = crypto.randomBytes(32).toString('hex');
  const resetTokenExpires = new Date(Date.now() + 3600000); // 1 hour
  
  // Store token in database
  await pool.query(
    `UPDATE users 
     SET reset_token = $1, reset_token_expires = $2
     WHERE email = $3`,
    [resetToken, resetTokenExpires, email]
  );
  
  return resetToken;
}

// Verify reset token and update password
async function resetPassword(token, newPassword) {
  // Find user with valid token
  const result = await pool.query(
    `SELECT id FROM users 
     WHERE reset_token = $1 AND reset_token_expires > NOW()`,
    [token]
  );
  
  if (result.rows.length === 0) {
    return { success: false, message: 'Invalid or expired token' };
  }
  
  const userId = result.rows[0].id;
  
  // Hash new password
  const saltRounds = 12;
  const passwordHash = await bcrypt.hash(newPassword, saltRounds);
  
  // Update password and clear token
  await pool.query(
    `UPDATE users 
     SET password_hash = $1, reset_token = NULL, reset_token_expires = NULL
     WHERE id = $2`,
    [passwordHash, userId]
  );
  
  return { success: true };
}
```

## User Management

Functions for common user management operations:

```javascript
// Create role
async function createRole(name, description) {
  const result = await pool.query(
    'INSERT INTO roles (name, description) VALUES ($1, $2) RETURNING id',
    [name, description]
  );
  return result.rows[0].id;
}

// Assign role to user
async function assignRole(userId, roleName) {
  // Get role ID
  const roleResult = await pool.query(
    'SELECT id FROM roles WHERE name = $1',
    [roleName]
  );
  
  if (roleResult.rows.length === 0) {
    throw new Error(`Role ${roleName} not found`);
  }
  
  const roleId = roleResult.rows[0].id;
  
  // Assign role
  await pool.query(
    'INSERT INTO user_roles (user_id, role_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
    [userId, roleId]
  );
}

// Get user with roles
async function getUserWithRoles(userId) {
  const result = await pool.query(
    `SELECT 
       u.id, u.username, u.email, u.created_at, u.last_login, u.is_active,
       COALESCE(json_agg(r.name) FILTER (WHERE r.name IS NOT NULL), '[]') as roles
     FROM users u
     LEFT JOIN user_roles ur ON u.id = ur.user_id
     LEFT JOIN roles r ON ur.role_id = r.id
     WHERE u.id = $1
     GROUP BY u.id`,
    [userId]
  );
  
  return result.rows[0];
}

// Deactivate user
async function deactivateUser(userId) {
  await pool.query(
    'UPDATE users SET is_active = false WHERE id = $1',
    [userId]
  );
}
```

## Session Management

Managing user sessions with PostgreSQL:

```javascript
import { v4 as uuidv4 } from 'uuid';

// Create new session
async function createSession(userId, ipAddress, userAgent) {
  const sessionToken = uuidv4();
  const expiresAt = new Date(Date.now() + 86400000); // 24 hours
  
  await pool.query(
    `INSERT INTO sessions 
     (user_id, token, ip_address, user_agent, expires_at)
     VALUES ($1, $2, $3, $4, $5)`,
    [userId, sessionToken, ipAddress, userAgent, expiresAt]
  );
  
  return {
    token: sessionToken,
    expiresAt
  };
}

// Validate session
async function validateSession(sessionToken) {
  const result = await pool.query(
    `SELECT s.id, s.user_id, s.expires_at, u.username, u.is_active
     FROM sessions s
     JOIN users u ON s.user_id = u.id
     WHERE s.token = $1 AND s.is_valid = true AND s.expires_at > NOW()`,
    [sessionToken]
  );
  
  if (result.rows.length === 0) {
    return null;
  }
  
  const session = result.rows[0];
  
  // Check if user is active
  if (!session.is_active) {
    await invalidateSession(sessionToken);
    return null;
  }
  
  return {
    id: session.id,
    userId: session.user_id,
    username: session.username,
    expiresAt: session.expires_at
  };
}

// Invalidate session (logout)
async function invalidateSession(sessionToken) {
  await pool.query(
    'UPDATE sessions SET is_valid = false WHERE token = $1',
    [sessionToken]
  );
}

// Clean up expired sessions (scheduled job)
async function cleanupSessions() {
  const result = await pool.query(
    'DELETE FROM sessions WHERE expires_at < NOW() OR is_valid = false',
    []
  );
  
  return result.rowCount;
}
```

## Token-based Authentication

JWT (JSON Web Token) implementation with PostgreSQL:

```javascript
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// Generate JWT token
function generateToken(user) {
  return jwt.sign(
    { 
      id: user.id,
      username: user.username,
      roles: user.roles || []
    },
    JWT_SECRET,
    { expiresIn: '1h' }
  );
}

// Verify JWT token
function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return null;
  }
}

// Log authentication event
async function logAuthEvent(userId, eventType, ipAddress, userAgent, details = {}) {
  await pool.query(
    `INSERT INTO auth_logs
     (user_id, event_type, ip_address, user_agent, details)
     VALUES ($1, $2, $3, $4, $5)`,
    [userId, eventType, ipAddress, userAgent, JSON.stringify(details)]
  );
}

// Complete login flow
async function login(email, password, ipAddress, userAgent) {
  // Verify credentials
  const user = await verifyUser(email, password);
  
  if (!user) {
    await logAuthEvent(null, 'failed_login', ipAddress, userAgent, { email });
    return { success: false, message: 'Invalid credentials' };
  }
  
  // Get user roles
  const userWithRoles = await getUserWithRoles(user.id);
  
  // Generate token
  const token = generateToken(userWithRoles);
  
  // Create session
  const session = await createSession(user.id, ipAddress, userAgent);
  
  // Update last login timestamp
  await pool.query(
    'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1',
    [user.id]
  );
  
  // Log successful login
  await logAuthEvent(user.id, 'login', ipAddress, userAgent);
  
  return {
    success: true,
    user: userWithRoles,
    token,
    session
  };
}
```

## Role-based Access Control

Middleware for Express.js that implements RBAC:

```javascript
// Authentication middleware
function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Authentication required' });
  }
  
  const token = authHeader.split(' ')[1];
  const payload = verifyToken(token);
  
  if (!payload) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
  
  req.user = payload;
  next();
}

// Role-based authorization
function authorize(requiredRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Authentication required' });
    }
    
    // Check if user has any of the required roles
    const hasRole = requiredRoles.some(role => 
      req.user.roles && req.user.roles.includes(role)
    );
    
    if (!hasRole) {
      return res.status(403).json({ message: 'Insufficient permissions' });
    }
    
    next();
  };
}

// Usage in routes
app.get('/api/users', authenticate, authorize(['admin']), async (req, res) => {
  // Only admins can list users
  const users = await listUsers();
  res.json(users);
});

app.get('/api/profile', authenticate, async (req, res) => {
  // Any authenticated user can access their profile
  const userId = req.user.id;
  const profile = await getUserProfile(userId);
  res.json(profile);
});
```

## Security Considerations

Protect your PostgreSQL authentication system with these best practices:

1. **Rate Limiting**:
   ```javascript
   import rateLimit from 'express-rate-limit';
   
   // Limit login attempts
   const loginLimiter = rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minutes
     max: 5, // 5 attempts per window
     message: 'Too many login attempts, please try again later'
   });
   
   app.post('/api/login', loginLimiter, loginHandler);
   ```

2. **Password Policies**:
   ```javascript
   function validatePassword(password) {
     // Minimum 8 characters, at least one uppercase, one lowercase, one number
     const regex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
     return regex.test(password);
   }
   ```

3. **Secure Headers**:
   ```javascript
   import helmet from 'helmet';
   
   // Set security headers
   app.use(helmet());
   ```

4. **CSRF Protection**:
   ```javascript
   import csurf from 'csurf';
   
   // Enable CSRF protection
   const csrfProtection = csurf({ cookie: true });
   app.use(csrfProtection);
   ```

5. **SQL Injection Prevention**:
   ```javascript
   // Always use parameterized queries
   pool.query('SELECT * FROM users WHERE id = $1', [userId]);
   
   // Never use template literals or string concatenation
   // BAD: `SELECT * FROM users WHERE id = ${userId}`
   ```

6. **Audit Logging**:
   - Log all authentication events in `auth_logs` table
   - Include IP address, user agent, and timestamp
   - Regularly review logs for suspicious activity

7. **Database Permissions**:
   ```sql
   -- Create application-specific role with limited permissions
   CREATE ROLE auth_app WITH LOGIN PASSWORD 'secure_password';
   
   -- Grant only necessary permissions
   GRANT SELECT, INSERT, UPDATE ON users, sessions, auth_logs TO auth_app;
   GRANT SELECT ON roles, user_roles TO auth_app;
   
   -- Revoke direct table deletion
   REVOKE DELETE ON users, roles FROM auth_app;
   ```

8. **Connection Encryption**:
   - Enable SSL/TLS for database connections
   - Set `ssl: true` in PostgreSQL connection options

---

[<- Back: PostgreSQL Features](./06-postgresql-features.md) | [Next: Docker Deployment ->](./08-docker-deployment.md)
