# 10. Middleware and Security in Express 🛡️

[<- Back to Main Note](./README.md)

## Table of Contents

- [Express Middleware Fundamentals](#express-middleware-fundamentals)
- [Middleware Order and Execution Flow](#middleware-order-and-execution-flow)
- [Common Middleware Use Cases](#common-middleware-use-cases)
- [Rate Limiting](#rate-limiting)
- [Sessions](#sessions)
- [JWT vs. Sessions](#jwt-vs-sessions)
- [Password Hashing](#password-hashing)
- [Security Best Practices](#security-best-practices)

## Express Middleware Fundamentals

Middleware functions are the backbone of Express applications. They are functions that have access to the request object (`req`), the response object (`res`), and the `next` middleware function in the application's request-response cycle.

### Basic Middleware Structure

```javascript
function myMiddleware(req, res, next) {
  // Do something with req or res
  console.log(`Request received at: ${new Date().toISOString()}`);
  
  // Call next() to pass control to the next middleware
  next();
}

// Apply to all routes
app.use(myMiddleware);

// Or apply to a specific route
app.get('/profile', myMiddleware, (req, res) => {
  res.send('Profile page');
});
```

### Middleware Capabilities

Middleware functions can:

1. Execute any code
2. Make changes to request and response objects
3. End the request-response cycle
4. Call the next middleware in the stack

```javascript
function ipLogger(req, res, next) {
  console.log(`Request from IP: ${req.ip}`);
  next();
}

function authCheck(req, res, next) {
  if (req.session && req.session.authenticated) {
    // Add user information to the request
    req.user = req.session.user;
    return next();
  }
  
  // End request-response cycle by sending a response
  res.status(401).send({ message: "Authentication required" });
}
```

## Middleware Order and Execution Flow

The order in which middleware is registered is crucial, as middleware functions are executed sequentially.

### Sequential Execution

```javascript
// This will be executed first
app.use((req, res, next) => {
  console.log('First middleware');
  next();
});

// This will be executed second
app.use((req, res, next) => {
  console.log('Second middleware');
  next();
});

// Route-specific middleware chain
app.get('/room', 
  (req, res, next) => {
    console.log('Middleware for /room (1)');
    next();
  },
  (req, res, next) => {
    console.log('Middleware for /room (2)');
    next();
  },
  (req, res) => {
    res.send({ message: "Welcome to the room" });
  }
);
```

### Error Handling Middleware

Error-handling middleware takes four arguments instead of three:

```javascript
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send('Something broke!');
});
```

### Skip Remaining Middleware

You can skip remaining middleware by not calling `next()`:

```javascript
function earlyResponse(req, res, next) {
  if (req.query.quick === 'true') {
    return res.send('Early response'); // Stops here, next() isn't called
  }
  next(); // Continue to next middleware
}
```

## Common Middleware Use Cases

Express applications typically use several types of middleware for different purposes.

### Built-in Middleware

```javascript
// Parse JSON request bodies
app.use(express.json());

// Parse URL-encoded request bodies
app.use(express.urlencoded({ extended: true }));

// Serve static files
app.use(express.static('public'));
```

### Third-party Middleware

```javascript
// Security headers with Helmet
import helmet from 'helmet';
app.use(helmet());

// CORS handling
import cors from 'cors';
app.use(cors());

// Request logging with Morgan
import morgan from 'morgan';
app.use(morgan('dev'));
```

### Custom Authentication Middleware

```javascript
function isAdmin(req, res, next) {
  // Check database if user is admin
  const userIsAdmin = true; // Simulated DB check
  
  if (userIsAdmin) {
    // Attach data to request object for use in route handlers
    req.isAdmin = true;
    req.username = "Admin User";
    return next();
  }
  
  res.status(403).send({ message: "Forbidden: Admin access required" });
}

// Use in specific routes
app.get("/admin/dashboard", isAdmin, (req, res) => {
  // Access data attached by middleware
  console.log(`Admin access by: ${req.username}`);
  res.send({ message: "Admin dashboard" });
});
```

## Rate Limiting

Rate limiting protects your API from abuse by limiting how many requests a client can make in a given time period.

### Basic Rate Limiter Setup

```javascript
import { rateLimit } from 'express-rate-limit';

// General rate limiter for all routes
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  limit: 300, // 300 requests per window
  standardHeaders: 'draft-8', // RateLimit headers
  legacyHeaders: false, // X-RateLimit headers 
});

app.use(generalLimiter);
```

### Specialized Rate Limiters

Different routes may need different rate limits:

```javascript
// Stricter rate limiter for authentication routes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  limit: 5, // 5 login attempts per 15 minutes
  standardHeaders: 'draft-8',
  legacyHeaders: false
});

// Apply to authentication routes
app.use("/auth", authLimiter);
```

### Rate Limiter Options

- `windowMs`: Time window in milliseconds
- `limit`: Max requests per window
- `standardHeaders`: Controls `RateLimit` header behavior
- `legacyHeaders`: Controls `X-RateLimit-*` headers
- `store`: Optional store for distributed applications (Redis, Memcached)
- `skipSuccessfulRequests`: Skip successful requests (status 2xx/3xx)
- `skipFailedRequests`: Skip failed requests (status 4xx/5xx)
- `keyGenerator`: Function to generate client identifier (defaults to IP)

## Sessions

Sessions allow servers to maintain state between requests from the same client.

### Setting Up Sessions

```javascript
import session from 'express-session';

app.use(session({
  secret: 'keyboard cat', // Used to sign the session ID cookie
  resave: false, // Don't save session if unmodified
  saveUninitialized: false, // Don't create session until something stored
  cookie: { 
    secure: false, // Should be true in production with HTTPS
    maxAge: 1000 * 60 * 60 * 24 // 1 day
  }
}));
```

### Using Sessions

```javascript
// Store data in the session
app.post('/login', (req, res) => {
  // Authenticate user (simplified)
  if (req.body.username === 'user' && req.body.password === 'pass') {
    req.session.authenticated = true;
    req.session.user = {
      id: 1,
      username: req.body.username
    };
    res.send({ message: 'Login successful' });
  } else {
    res.status(401).send({ message: 'Invalid credentials' });
  }
});

// Read data from the session
app.get('/profile', (req, res) => {
  if (req.session.authenticated) {
    res.send({ 
      message: 'Profile page',
      user: req.session.user
    });
  } else {
    res.status(401).send({ message: 'Please login first' });
  }
});

// Clear session data (logout)
app.get('/logout', (req, res) => {
  req.session.destroy(err => {
    if (err) {
      res.status(500).send({ message: 'Logout failed' });
    } else {
      res.send({ message: 'Logged out successfully' });
    }
  });
});
```

### Session Stores

For production applications, use dedicated session stores instead of the default memory store:

```javascript
import session from 'express-session';
import RedisStore from 'connect-redis';
import { createClient } from 'redis';

// Redis client setup
const redisClient = createClient();
redisClient.connect().catch(console.error);

// Redis store
const redisStore = new RedisStore({
  client: redisClient,
  prefix: 'sess:'
});

// Session middleware with Redis store
app.use(session({
  store: redisStore,
  secret: 'keyboard cat',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: true, maxAge: 86400000 }
}));
```

## JWT vs. Sessions

JSON Web Tokens (JWT) and sessions are two common approaches for handling authentication and maintaining state.

### JWT (JSON Web Tokens)

JWTs are self-contained tokens that include user data and are signed to prevent tampering.

**Basic JWT Implementation:**

```javascript
import jwt from 'jsonwebtoken';

// JWT secret key (should be in environment variables)
const JWT_SECRET = 'your-secret-key';

// Generate token
app.post('/login', (req, res) => {
  // Authenticate user (simplified)
  if (req.body.username === 'user' && req.body.password === 'pass') {
    // Create payload
    const payload = {
      userId: 123,
      username: req.body.username,
      role: 'user'
    };
    
    // Generate token
    const token = jwt.sign(payload, JWT_SECRET, { 
      expiresIn: '1h' // Token expires in 1 hour
    });
    
    res.json({ token });
  } else {
    res.status(401).send({ message: 'Invalid credentials' });
  }
});

// Verify token middleware
function authenticateJWT(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (authHeader) {
    const token = authHeader.split(' ')[1]; // Extract token from "Bearer <token>"
    
    jwt.verify(token, JWT_SECRET, (err, user) => {
      if (err) {
        return res.status(403).json({ message: 'Invalid token' });
      }
      
      // Add user data to request
      req.user = user;
      next();
    });
  } else {
    res.status(401).json({ message: 'Authentication required' });
  }
}

// Protected route using JWT
app.get('/profile', authenticateJWT, (req, res) => {
  res.json({ 
    message: 'Profile page',
    user: req.user
  });
});
```

### Comparison: JWT vs Sessions

| Feature | JWT | Sessions |
|---------|-----|----------|
| **Storage** | Client-side (stateless) | Server-side (stateful) |
| **Scalability** | Excellent (no server storage) | Requires session store for scaling |
| **Security** | Signature prevents tampering | Server controls all data |
| **Revocation** | Difficult (requires blacklist) | Easy (delete from store) |
| **Data Size** | Limited (increases token size) | Unlimited (only ID sent to client) |
| **Complexity** | More complex implementation | Simpler implementation |
| **Cross-domain** | Works well across domains | Requires special CORS setup |

### When to Use JWT

- Microservices architecture
- Distributed systems
- Single sign-on (SSO) requirements
- Mobile applications
- When statelessness is a priority

### When to Use Sessions

- When immediate revocation is needed
- For storing large amounts of user data
- When simplicity is preferred
- When working within a single domain
- When handling sensitive information

## Password Hashing

Proper password storage is critical for security. Never store plain-text passwords!

### Using bcrypt

```javascript
import bcrypt from 'bcryptjs';

// Hash a password
async function hashPassword(password) {
  // Salt rounds (higher is more secure but slower)
  const saltRounds = 12;
  
  // Generate hash
  const hashedPassword = await bcrypt.hash(password, saltRounds);
  return hashedPassword;
}

// Verify a password
async function verifyPassword(password, hashedPassword) {
  // Returns true if the password matches
  const isMatch = await bcrypt.compare(password, hashedPassword);
  return isMatch;
}

// Usage in registration
app.post('/signup', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    // Hash the password
    const hashedPassword = await hashPassword(password);
    
    // Save user to database (simplified)
    // db.users.create({ username, password: hashedPassword });
    
    res.status(201).json({ message: 'User created' });
  } catch (error) {
    res.status(500).json({ message: 'Error creating user' });
  }
});

// Usage in login
app.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    // Get user from database (simplified)
    // const user = await db.users.findOne({ username });
    const user = { 
      id: 1, 
      username: 'user', 
      hashedPassword: '$2b$13$itEyvDYgMA0tJWBvCTTQoeOVX0Eu3jBVxzVeVl6W1wFHnXXIoEAr2'
    };
    
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    // Verify password
    const isMatch = await verifyPassword(password, user.hashedPassword);
    
    if (isMatch) {
      // Create session or JWT
      req.session.authenticated = true;
      req.session.user = { id: user.id, username: user.username };
      
      res.json({ message: 'Login successful' });
    } else {
      res.status(401).json({ message: 'Invalid credentials' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Error during login' });
  }
});
```

## Security Best Practices

Implementing middleware and authentication is just one part of securing your application.

### Using Helmet for Security Headers

```javascript
import helmet from 'helmet';

// Apply helmet with default settings
app.use(helmet());

// Or customize specific headers
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "trusted-cdn.com"]
      }
    },
    crossOriginEmbedderPolicy: false
  })
);
```

Helmet sets several HTTP headers to improve security:

- `Content-Security-Policy`: Controls allowed sources of content
- `X-XSS-Protection`: Mitigates cross-site scripting attacks
- `X-Frame-Options`: Prevents clickjacking
- `X-Content-Type-Options`: Prevents MIME type sniffing
- `Strict-Transport-Security`: Enforces HTTPS
- `Referrer-Policy`: Controls the Referer header
- And more...

### Additional Security Measures

1. **CORS Protection**
   ```javascript
   import cors from 'cors';
   
   // Restrictive CORS - only allow specific origin
   app.use(cors({
     origin: 'https://example.com',
     methods: ['GET', 'POST'],
     allowedHeaders: ['Content-Type', 'Authorization']
   }));
   ```

2. **Input Validation**
   ```javascript
   import { body, validationResult } from 'express-validator';
   
   app.post('/user',
     // Validate and sanitize input
     body('username').isAlphanumeric().trim().escape(),
     body('email').isEmail().normalizeEmail(),
     body('password').isLength({ min: 8 }),
     
     (req, res) => {
       // Check for validation errors
       const errors = validationResult(req);
       if (!errors.isEmpty()) {
         return res.status(400).json({ errors: errors.array() });
       }
       
       // Process valid input
       // ...
     }
   );
   ```

3. **Cookie Security**
   ```javascript
   app.use(session({
     // Other options...
     cookie: {
       secure: true, // HTTPS only
       httpOnly: true, // Not accessible via JavaScript
       sameSite: 'strict', // Same-site policy
       domain: 'example.com', // Specific domain
       path: '/', // Specific path
       maxAge: 3600000 // 1 hour in milliseconds
     }
   }));
   ```

4. **Error Handling**
   ```javascript
   // Custom error handler
   app.use((err, req, res, next) => {
     // Log error for debugging
     console.error(err.stack);
     
     // Don't expose error details in production
     if (process.env.NODE_ENV === 'production') {
       res.status(500).json({ message: 'Server error occurred' });
     } else {
       res.status(500).json({
         message: err.message,
         stack: err.stack
       });
     }
   });
   ```

5. **Preventing NoSQL Injection**
   ```javascript
   // Use parameterized queries or ORM
   // Instead of:
   // db.users.findOne({ username: req.body.username })
   
   // Better:
   import mongoose from 'mongoose';
   const User = mongoose.model('User', userSchema);
   
   // Using the model with sanitized inputs
   const user = await User.findOne({ username: req.body.username });
   ```

---

[<- Back to Main Note](./README.md)