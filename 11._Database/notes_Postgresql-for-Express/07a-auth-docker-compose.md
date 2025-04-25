# 7a. Authentication Server with Docker Compose 🔐

[<- Back to Main Topic](./07-auth-system.md) | [Next Sub-Topic: Role-Based Access Control ->](./07b-rbac.md)

## Overview

Creating a dedicated authentication service with Docker Compose provides a centralized solution for managing user identity across multiple applications. This architecture separates authentication concerns from your business logic, improving security, maintainability, and scalability.

## Authentication Service Architecture

### Directory Structure

```
auth-service/
├── docker-compose.yml      # Defines services, networks, volumes
├── .env                    # Environment variables
├── auth/                   # Authentication service code
│   ├── Dockerfile          # Instructions to build Auth API image
│   ├── package.json        # Node.js dependencies
│   ├── src/                # Source code
│   │   ├── index.js        # Entry point
│   │   ├── config/         # Configuration files
│   │   ├── routes/         # API routes
│   │   ├── controllers/    # Request handlers
│   │   ├── middleware/     # Custom middleware
│   │   ├── services/       # Business logic
│   │   ├── utils/          # Helper functions
│   │   └── models/         # Data models
│   └── tests/              # Unit and integration tests
├── database/               # Database configuration
│   ├── init/               # Initialization scripts
│   │   ├── 01-schema.sql   # Tables and relationships
│   │   ├── 02-functions.sql # Stored procedures, triggers
│   │   ├── 03-seed-data.sql # Reference data
│   │   └── 04-dev-users.sh # Development test users
│   └── scripts/            # Database maintenance scripts
│       ├── backup-db.sh    # Database backup
│       └── reseed-db.sh    # Reset and reseed database
└── nginx/                  # Optional reverse proxy
    ├── Dockerfile          # Instructions to build Nginx image
    └── nginx.conf          # Nginx configuration
```

### Components and Services

The authentication service consists of several containerized components working together:

#### 1. Auth API Service

A Node.js/Express application that handles:
- User registration and login
- Password reset workflows
- Token generation and validation
- Session management
- User profile management
- Multi-factor authentication

#### 2. PostgreSQL Database

Stores:
- User credentials (securely hashed)
- Roles and permissions
- Sessions
- Authentication logs
- Security configuration

#### 3. Redis Cache (Optional)

Provides:
- Token blacklisting
- Rate limiting data
- Session storage
- Temporary codes (verification, 2FA)

#### 4. Nginx Reverse Proxy (Optional)

Manages:
- TLS termination
- Request routing
- Basic request filtering
- Static assets (if any)

## Docker Compose Configuration

### Basic Configuration

```yaml
# docker-compose.yml
version: '3.8'
services:
  auth_api:
    build: ./auth
    restart: unless-stopped
    ports:
      - "${AUTH_PORT:-3000}:3000"
    environment:
      NODE_ENV: ${NODE_ENV:-development}
      DATABASE_URL: postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      REDIS_URL: ${REDIS_URL:-redis://redis:6379}
      JWT_SECRET: ${JWT_SECRET}
      JWT_EXPIRES_IN: ${JWT_EXPIRES_IN:-1h}
      REFRESH_TOKEN_EXPIRES_IN: ${REFRESH_TOKEN_EXPIRES_IN:-7d}
      CORS_ORIGINS: ${CORS_ORIGINS:-*}
    depends_on:
      - postgres
      - redis
    networks:
      - auth_network
    volumes:
      - ./auth/logs:/app/logs

  postgres:
    image: postgres:15
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-auth_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-auth_password}
      POSTGRES_DB: ${POSTGRES_DB:-auth_db}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
    networks:
      - auth_network

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD:-redis_password}
    volumes:
      - redis_data:/data
    networks:
      - auth_network

networks:
  auth_network:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
```

### Environment Variables (.env)

```
# .env
# Node environment
NODE_ENV=development

# API configuration
AUTH_PORT=3000
CORS_ORIGINS=http://localhost:8080,https://yourapplication.com

# JWT configuration
JWT_SECRET=your_very_secure_secret_key_here
JWT_EXPIRES_IN=1h
REFRESH_TOKEN_EXPIRES_IN=7d

# PostgreSQL configuration
POSTGRES_USER=auth_user
POSTGRES_PASSWORD=strong_database_password
POSTGRES_DB=auth_db

# Redis configuration
REDIS_PASSWORD=strong_redis_password
REDIS_URL=redis://:strong_redis_password@redis:6379
```

## Authentication Service Design

### API Endpoints

A typical authentication service exposes these endpoints:

```
POST   /api/auth/register       # Create new user account
POST   /api/auth/login          # Authenticate and get tokens
POST   /api/auth/logout         # Invalidate tokens
POST   /api/auth/refresh        # Get new access token using refresh token
POST   /api/auth/forgot-password # Initiate password reset
POST   /api/auth/reset-password # Complete password reset
GET    /api/auth/me             # Get current user profile
PUT    /api/auth/me             # Update current user profile
POST   /api/auth/verify-email   # Verify email address
POST   /api/auth/enable-2fa     # Enable two-factor authentication
POST   /api/auth/verify-2fa     # Verify 2FA code
```

### Authentication Flow

1. **Registration Flow**:
   - User submits registration data
   - Server validates data
   - Password is hashed
   - Email verification token is generated
   - User record is created
   - Verification email is sent

2. **Login Flow**:
   - User submits credentials
   - Server validates credentials
   - If 2FA is enabled, prompt for code
   - Access token and refresh token are generated
   - Tokens are returned to client

3. **Authorization Flow**:
   - Client includes access token in requests
   - Server validates token
   - Server checks permissions
   - Server processes or rejects request

4. **Token Refresh Flow**:
   - Access token expires
   - Client uses refresh token to get new access token
   - Server validates refresh token
   - New access token is issued

## Integration with Client Applications

### Client Application Configuration

Client applications connect to the authentication service by:

1. Configuring authentication endpoints
2. Managing token storage
3. Implementing login/registration UI
4. Adding token refresh logic
5. Handling authentication errors

### Example Client Integration (React)

```javascript
// authService.js
import axios from 'axios';

const API_URL = 'https://auth.yourdomain.com/api/auth/';

// Create axios instance with auth headers
const authAPI = axios.create({
  baseURL: API_URL,
  withCredentials: true
});

// Add token refresh interceptor
authAPI.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    
    if (error.response.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      try {
        const refreshToken = localStorage.getItem('refreshToken');
        const response = await axios.post(`${API_URL}refresh`, { refreshToken });
        
        const { accessToken } = response.data;
        localStorage.setItem('accessToken', accessToken);
        
        // Update authorization header
        originalRequest.headers['Authorization'] = `Bearer ${accessToken}`;
        return axios(originalRequest);
      } catch (refreshError) {
        // Refresh token expired or invalid, redirect to login
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }
    
    return Promise.reject(error);
  }
);

// Authentication methods
export const login = async (email, password) => {
  const response = await authAPI.post('login', { email, password });
  localStorage.setItem('accessToken', response.data.accessToken);
  localStorage.setItem('refreshToken', response.data.refreshToken);
  return response.data;
};

export const register = async (userData) => {
  return await authAPI.post('register', userData);
};

export const logout = async () => {
  const response = await authAPI.post('logout');
  localStorage.removeItem('accessToken');
  localStorage.removeItem('refreshToken');
  return response.data;
};

export const getCurrentUser = async () => {
  return await authAPI.get('me');
};
```

## Security Considerations

1. **Environment Security**:
   - Use `.env` files for local development only
   - Use Docker secrets or a vault solution for production
   - Never commit secrets to version control

2. **Network Security**:
   - Use internal Docker networks for service-to-service communication
   - Expose only necessary ports
   - Use HTTPS for all external communication

3. **Container Security**:
   - Use non-root users in containers
   - Keep images updated with security patches
   - Scan images for vulnerabilities

4. **Data Security**:
   - Use strong encryption for sensitive data
   - Implement proper password hashing (bcrypt/Argon2)
   - Regular database backups
   - Audit logging for security events

## Scaling Considerations

For high-availability and scalability:

1. **Horizontal Scaling**:
   - Make the Auth API stateless
   - Run multiple instances behind a load balancer
   - Use Redis for shared state

2. **Database Scaling**:
   - Consider PostgreSQL replication for read scaling
   - Implement connection pooling
   - Optimize queries with proper indexing

3. **Docker Swarm/Kubernetes**:
   - For production deployments, consider orchestration
   - Define resource limits
   - Implement health checks
   - Use rolling updates for zero downtime

## Monitoring and Maintenance

1. **Logging**:
   - Structured logging (JSON format)
   - Log aggregation (ELK stack, Grafana Loki)
   - Security event logging

2. **Metrics**:
   - Authentication attempts (success/failure)
   - Token issuance rate
   - API response times
   - Error rates

3. **Health Checks**:
   - Database connectivity
   - Redis connectivity
   - API endpoint health

## Summary

A containerized authentication service provides:

1. **Security**: Dedicated service focusing solely on authentication concerns
2. **Reusability**: Single sign-on across multiple applications
3. **Maintainability**: Updates to auth logic in one place
4. **Scalability**: Independently scale the auth service based on demand
5. **Resilience**: Isolated service with its own resources

This architecture allows you to create a robust, central authentication system that multiple applications can leverage, while maintaining good security practices through containerization and proper network isolation.

---

[<- Back to Main Topic](./07-auth-system.md) | [Next Sub-Topic: Role-Based Access Control ->](./07b-rbac.md)
