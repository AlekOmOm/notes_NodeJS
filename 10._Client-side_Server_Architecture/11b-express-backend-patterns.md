# 11b. Express.js Backend Patterns 🔧

[<- Back to Main Topic](./11-client-server-architecture.md)

## Overview

Express.js is a minimalist web framework for Node.js that provides a robust set of features for building web applications and APIs. In the Medicine project, Express serves as the backbone of both the standard API server and the server-side rendering variant. This sub-note explores effective patterns for structuring and implementing Express.js backends in full-stack applications.

## Key Concepts

### Express Application Setup

The core of an Express application is the app instance:

```javascript
import express from 'express';
const app = express();

// Configure middleware
app.use(express.json());  // Parse JSON request bodies

// Define routes
app.get('/', (req, res) => {
  res.send('Hello World!');
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### Middleware

Middleware functions are the building blocks of Express applications. They have access to the request, response, and next middleware function in the application's request-response cycle.

#### Built-in Middleware

```javascript
// Parse JSON request bodies
app.use(express.json());

// Parse URL-encoded request bodies (form data)
app.use(express.urlencoded({ extended: true }));

// Serve static files
app.use(express.static('public'));
```

#### Custom Middleware

```javascript
// Logging middleware
function requestLogger(req, res, next) {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
}

// Apply middleware to all routes
app.use(requestLogger);

// Authentication middleware
function authenticate(req, res, next) {
  if (req.session && req.session.authenticated) {
    return next();
  }
  res.status(401).send({ message: 'Authentication required' });
}

// Apply middleware to specific routes
app.get('/profile', authenticate, (req, res) => {
  res.send({ message: 'Protected content' });
});
```

### Router Implementation

Express routers allow you to modularize route handling:

```javascript
// employeesRouter.js
import { Router } from 'express';
const router = Router();

const employees = ["Ilmer", "Homer"];

// Define routes on the router
router.get("/employees", (req, res) => {
    res.send({ data: employees });
});

router.post("/employees", (req, res) => {
    const newEmployee = req.body.name;
    employees.push(newEmployee);
    res.status(201).send({ data: employees });
});

// Export the router
export default router;

// In app.js
import employeesRouter from './routers/employeesRouter.js';
app.use(employeesRouter);  // Mount the router
```

### Error Handling

Express provides a special type of middleware for error handling:

```javascript
// Route handler with error handling
app.get('/data', async (req, res, next) => {
  try {
    // Operation that might fail
    const data = await fetchDataFromDatabase();
    res.send({ data });
  } catch (error) {
    // Pass error to error-handling middleware
    next(error);
  }
});

// Error-handling middleware (must have 4 parameters)
app.use((err, req, res, next) => {
  console.error(err.stack);
  
  // Send appropriate response based on environment
  const message = process.env.NODE_ENV === 'production'
    ? 'Something went wrong'
    : err.message;
    
  res.status(500).send({ error: message });
});
```

## Implementation Patterns

### RESTful API Structure

The Medicine project follows RESTful principles for API design:

```javascript
// pillsRouter.js
import { Router } from 'express';
const router = Router();

// GET /pills - Get all pills
router.get("/pills", (req, res) => {
    res.send({ data: req.session.pills || [] });
});

// POST /pills - Create a new pill
router.post("/pills", (req, res) => {
    if (!req.session.pills) {
        req.session.pills = [];
    }
    req.session.pills.push(req.body);
    res.send({ data: req.session.pills });
});

// Additional RESTful routes (not in the current project)
// GET /pills/:id - Get a specific pill
// PUT /pills/:id - Update a specific pill
// DELETE /pills/:id - Delete a specific pill

export default router;
```

### Session Management

The project uses express-session for managing user sessions:

```javascript
import session from 'express-session';

app.use(session({
    secret: process.env.SESSION_SECRET,  // Secret used to sign the session ID cookie
    resave: false,  // Don't save session if unmodified
    saveUninitialized: true,  // Save uninitialized sessions
    cookie: { 
        secure: false,  // Only use secure cookies in production
        maxAge: 24 * 60 * 60 * 1000  // 24 hours
    }
}));
```

Using sessions to store user-specific data:

```javascript
// Store data in session
router.post('/login', (req, res) => {
  // Authentication logic (simplified)
  const user = authenticate(req.body.username, req.body.password);
  
  if (user) {
    // Save user info in session
    req.session.authenticated = true;
    req.session.userId = user.id;
    req.session.username = user.username;
    
    res.send({ message: 'Login successful' });
  } else {
    res.status(401).send({ message: 'Invalid credentials' });
  }
});

// Access session data
router.get('/profile', (req, res) => {
  if (req.session.authenticated) {
    res.send({
      message: 'Welcome to your profile',
      username: req.session.username
    });
  } else {
    res.status(401).send({ message: 'Please log in first' });
  }
});

// Clear session
router.get('/logout', (req, res) => {
  req.session.destroy(err => {
    if (err) {
      return res.status(500).send({ message: 'Logout failed' });
    }
    res.send({ message: 'Logged out successfully' });
  });
});
```

### CORS Configuration

For cross-origin requests from a separate frontend:

```javascript
// Method 1: Custom CORS middleware
app.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
    res.header("Access-Control-Allow-Credentials", "true");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
    
    // Handle preflight requests
    if (req.method === 'OPTIONS') {
        return res.sendStatus(200);
    }
    
    next();
});

// Method 2: Using cors package
import cors from 'cors';

app.use(cors({
    origin: process.env.NODE_ENV === 'production'
        ? 'https://yourapp.com'
        : 'http://localhost:5173',
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
```

### Environment Configuration

Using dotenv for environment-specific configuration:

```javascript
// Load environment variables from .env file
import 'dotenv/config';

// Access environment variables
const PORT = Number(process.env.PORT) || 8080;
const SESSION_SECRET = process.env.SESSION_SECRET || 'fallback-secret-key';

// Conditional logic based on environment
if (process.env.NODE_ENV === 'production') {
    // Production-specific configuration
    app.set('trust proxy', 1);  // Trust first proxy
    sessionOptions.cookie.secure = true;  // Use secure cookies
}
```

### Server-Side Rendering Setup

The Medicine project includes an SSR server variant:

```javascript
// serverSSR/app.js
import path from 'path';

// Serve static files from client build directory
app.use(express.static(path.resolve('../client/dist/')));

// API routes
import employeesRouter from './routers/employeesRouter.js';
app.use(employeesRouter);
import pillsRouter from './routers/pillsRouter.js';
app.use(pillsRouter);

// SPA fallback for client-side routing
app.get("/{*splat}", (req, res) => {
  res.sendFile(path.resolve('../client/dist/index.html'));
});
```

## Common Challenges and Solutions

### Challenge 1: Asynchronous Error Handling

Errors in asynchronous functions don't propagate to Express error handlers automatically.

**Solution:**

```javascript
// Using async/await with try/catch
app.get('/data', async (req, res, next) => {
  try {
    const result = await someAsyncOperation();
    res.send({ data: result });
  } catch (error) {
    next(error);  // Pass to Express error handler
  }
});

// Alternative: Promise-based approach
app.get('/data', (req, res, next) => {
  someAsyncOperation()
    .then(result => res.send({ data: result }))
    .catch(next);  // Pass error to Express error handler
});
```

### Challenge 2: Managing Complex Routes

As applications grow, route management can become complex.

**Solution:**

```javascript
// Organize routes by domain
import authRouter from './routers/authRouter.js';
import userRouter from './routers/userRouter.js';
import productRouter from './routers/productRouter.js';

// Mount routers with prefixes
app.use('/auth', authRouter);
app.use('/users', userRouter);
app.use('/products', productRouter);

// This creates routes like:
// /auth/login, /auth/register
// /users, /users/:id
// /products, /products/:id
```

### Challenge 3: Rate Limiting

Protecting endpoints from abuse is important in production applications.

**Solution:**

```javascript
import rateLimit from 'express-rate-limit';

// Basic rate limiter
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 100,  // Limit each IP to 100 requests per windowMs
  standardHeaders: true,  // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false,  // Disable the `X-RateLimit-*` headers
});

// Apply to all routes
app.use(apiLimiter);

// Or apply to specific routes
app.use('/api/', apiLimiter);
```

### Challenge 4: Session Stores for Production

The default in-memory session store is not suitable for production.

**Solution:**

```javascript
import session from 'express-session';
import RedisStore from 'connect-redis';
import { createClient } from 'redis';

// Create Redis client
const redisClient = createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379'
});
redisClient.connect().catch(console.error);

// Configure session with Redis store
app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: { secure: process.env.NODE_ENV === 'production' }
}));
```

## Practical Example

The Medicine project's server setup demonstrates these patterns:

```javascript
// server/app.js
import 'dotenv/config';
import express from 'express';

const app = express();

// Middleware
app.use(express.json());

// CORS configuration
app.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
    res.header("Access-Control-Allow-Credentials", "true");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    next();
});

// Session middleware
import session from 'express-session';
app.use(session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false }
}));

// Routers
import employeesRouter from './routers/employeesRouter.js';
app.use(employeesRouter);
import pillsRouter from './routers/pillsRouter.js';
app.use(pillsRouter);

// Start server
const PORT = Number(process.env.PORT) || 8080;
app.listen(PORT, () => console.log("Server is running on port", PORT));
```

This setup:
1. Loads environment variables
2. Sets up middleware for parsing JSON
3. Configures CORS for cross-origin requests
4. Configures session management
5. Registers modular routers
6. Starts the server on the configured port

## Best Practices for Express Backends

1. **Use Middleware Effectively**: Apply middleware in the correct order
2. **Modularize Routes**: Use Express Router to organize endpoints
3. **Handle Errors Consistently**: Implement global error handling middleware
4. **Validate Input**: Validate and sanitize all user input
5. **Secure Sessions**: Use secure cookies and appropriate session stores
6. **Implement CORS Properly**: Configure CORS based on your deployment needs
7. **Use Environment Variables**: Keep configuration flexible across environments
8. **Structure API Responses Consistently**: Use standard formats (`{ data: ... }` or `{ error: ... }`)
9. **Implement Rate Limiting**: Protect endpoints from abuse
10. **Add Security Headers**: Use Helmet.js or similar for security headers

## Deploying Express Applications

Express backends can be deployed in various ways:

1. **Traditional Hosting**:
   - Node.js-friendly hosting platforms (Heroku, DigitalOcean, etc.)
   - Run with process managers like PM2

2. **Containerization**:
   ```dockerfile
   FROM node:18-alpine
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci --only=production
   COPY . .
   EXPOSE 8080
   CMD ["node", "app.js"]
   ```

3. **Serverless**:
   - Use Express adapters for serverless platforms
   - Or refactor to use platform-specific APIs

4. **Reverse Proxy**:
   - Place Nginx or similar in front of Express
   - Handle TLS termination and static file serving at the proxy level

## Summary

Express.js provides a flexible foundation for building backend services in full-stack applications. Its middleware-based architecture and routing system enable clean organization of code, while its ecosystem offers solutions for common challenges like session management, CORS, and security. When paired with a frontend framework like Svelte, it creates a powerful combination for building modern web applications.

The Medicine project demonstrates how to structure an Express application with clear separation of concerns, modular routing, and support for both API-only and server-side rendering deployments.

---

[<- Back to Main Topic](./11-client-server-architecture.md)
