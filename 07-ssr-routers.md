# 7. Server-side Rendering and Routers 🖥️

[<- Back to Main Note](./README.md) | [Next: Forms and Svelte ->](./08-forms-svelte.md)

## Table of Contents

- [Server-side Rendering vs. Client-side Rendering](#server-side-rendering-vs-client-side-rendering)
- [File Operations in Node.js](#file-operations-in-nodejs)
- [Express Routers for Code Organization](#express-routers-for-code-organization)
- [Implementing Server-side Rendering](#implementing-server-side-rendering)
- [Optimizing Code Structure](#optimizing-code-structure)
- [Nodemon Configuration for Multiple Extensions](#nodemon-configuration-for-multiple-extensions)

## Server-side Rendering vs. Client-side Rendering

Web applications can render content either on the server (SSR) or on the client (CSR), each with different trade-offs.

### Server-side Rendering (SSR)

Server-side rendering generates the complete HTML on the server before sending it to the client.

**How SSR Works**:
1. Client makes a request to the server
2. Server processes the request
3. Server generates full HTML content
4. Server sends the complete HTML to the client
5. Browser displays the HTML
6. (Optional) Client-side JavaScript enhances interactivity

**Advantages of SSR**:
- Better initial load performance (especially on slow connections)
- Improved SEO as search engines see the full content
- Better accessibility for users with JavaScript disabled
- Avoids CORS issues (since all requests originate from server)
- Lower client-side resource requirements

**Disadvantages of SSR**:
- Higher server load
- More complex server setup
- Less interactive without additional client-side JavaScript
- Slower subsequent page navigations (full-page reloads)
- More bandwidth usage for page transitions

### Client-side Rendering (CSR)

Client-side rendering generates content in the browser using JavaScript.

**How CSR Works**:
1. Client makes a request to the server
2. Server sends minimal HTML with JavaScript links
3. Browser loads JavaScript
4. JavaScript runs and makes API requests
5. JavaScript renders the UI based on API responses

**Advantages of CSR**:
- Smoother user experience after initial load
- Reduced server load (just serving static files)
- Better separation of concerns (backend API, frontend UI)
- Faster navigation between pages (no full page reloads)
- Less bandwidth usage after initial load

**Disadvantages of CSR**:
- Slower initial load (must download and execute JavaScript)
- Potential SEO challenges
- Requires JavaScript to show content
- May require additional CORS configuration

### Performance Comparison

| Metric | Server-side Rendering | Client-side Rendering |
|--------|----------------------|----------------------|
| Time to First Contentful Paint | Faster | Slower |
| Time to Interactive | Depends on JS load | Depends on JS load |
| Subsequent Navigation | Slower (full reload) | Faster (no reload) |
| Server Resource Usage | Higher | Lower |
| Client Resource Usage | Lower | Higher |
| Bandwidth Usage | Higher per page | Higher initial, lower subsequent |

### Hybrid Approaches

Modern frameworks often use hybrid approaches:

1. **Progressive Enhancement**: Start with SSR for initial HTML, then enhance with JavaScript
2. **Hydration**: Server renders the initial HTML, client-side JavaScript "hydrates" it to make it interactive
3. **Static Site Generation (SSG)**: Pre-render pages at build time, serve as static files
4. **Incremental Static Regeneration (ISR)**: Generate static pages that update after a specified interval

## File Operations in Node.js

Working with files is a common requirement in server-side applications. Node.js provides built-in modules for file operations.

### The fs Module

The `fs` (file system) module enables interaction with the file system:

```javascript
// ES Modules syntax
import * as fs from 'fs';
import { promises as fsPromises } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get current file path and directory (ESM only)
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
```

### Reading Files

**Synchronous Reading** (blocks the event loop - use carefully):

```javascript
// Read a file synchronously
try {
  const data = fs.readFileSync(path.join(__dirname, 'file.txt'), 'utf8');
  console.log(data);
} catch (error) {
  console.error('Error reading file:', error);
}
```

**Callback-based Asynchronous Reading**:

```javascript
// Read a file asynchronously with callbacks
fs.readFile(path.join(__dirname, 'file.txt'), 'utf8', (error, data) => {
  if (error) {
    console.error('Error reading file:', error);
    return;
  }
  
  console.log(data);
});
```

**Promise-based Asynchronous Reading** (modern approach):

```javascript
// Read a file with promises
async function readFileContents(filePath) {
  try {
    const fullPath = path.resolve(__dirname, filePath);
    const data = await fsPromises.readFile(fullPath, 'utf8');
    return data;
  } catch (error) {
    console.error('Error reading file:', error);
    throw error;
  }
}

// Usage
readFileContents('file.txt')
  .then(data => console.log(data))
  .catch(error => console.error('Failed to read file:', error));
```

### Writing Files

**Synchronous Writing**:

```javascript
try {
  fs.writeFileSync(path.join(__dirname, 'output.txt'), 'Hello, world!', 'utf8');
  console.log('File written successfully');
} catch (error) {
  console.error('Error writing file:', error);
}
```

**Promise-based Asynchronous Writing**:

```javascript
async function writeToFile(filePath, content) {
  try {
    const fullPath = path.resolve(__dirname, filePath);
    await fsPromises.writeFile(fullPath, content, 'utf8');
    console.log(`File written successfully to ${fullPath}`);
  } catch (error) {
    console.error('Error writing file:', error);
    throw error;
  }
}

// Usage
writeToFile('output.txt', 'Hello, async world!')
  .catch(error => console.error('Failed to write file:', error));
```

### Checking if Files Exist

```javascript
// Using fs.promises
async function fileExists(filePath) {
  try {
    await fsPromises.access(filePath);
    return true;
  } catch {
    return false;
  }
}

// Alternative with fs.stat
async function checkFile(filePath) {
  try {
    const stats = await fsPromises.stat(filePath);
    return {
      exists: true,
      isFile: stats.isFile(),
      isDirectory: stats.isDirectory(),
      size: stats.size,
      created: stats.birthtime,
      modified: stats.mtime
    };
  } catch (error) {
    if (error.code === 'ENOENT') {
      return { exists: false };
    }
    throw error;
  }
}
```

### Working with Directories

```javascript
// Create a directory
async function createDirectory(dirPath) {
  try {
    await fsPromises.mkdir(dirPath, { recursive: true });
    console.log(`Directory created at ${dirPath}`);
  } catch (error) {
    console.error('Error creating directory:', error);
    throw error;
  }
}

// Read directory contents
async function listDirectoryContents(dirPath) {
  try {
    const files = await fsPromises.readdir(dirPath);
    return files;
  } catch (error) {
    console.error('Error reading directory:', error);
    throw error;
  }
}

// Get details of all files in a directory
async function getDirectoryDetails(dirPath) {
  try {
    const files = await fsPromises.readdir(dirPath);
    
    // Get details of each file
    const fileDetailsPromises = files.map(async (file) => {
      const filePath = path.join(dirPath, file);
      const stats = await fsPromises.stat(filePath);
      
      return {
        name: file,
        path: filePath,
        size: stats.size,
        isDirectory: stats.isDirectory(),
        created: stats.birthtime,
        modified: stats.mtime
      };
    });
    
    return Promise.all(fileDetailsPromises);
  } catch (error) {
    console.error('Error getting directory details:', error);
    throw error;
  }
}
```

### File Streams for Large Files

For large files, streams are more efficient than reading the entire file into memory:

```javascript
import fs from 'fs';

// Reading a large file with streams
function readLargeFile(filePath) {
  const readStream = fs.createReadStream(filePath, { encoding: 'utf8' });
  
  readStream.on('data', (chunk) => {
    console.log(`Received ${chunk.length} bytes of data`);
    // Process chunk
  });
  
  readStream.on('end', () => {
    console.log('Finished reading file');
  });
  
  readStream.on('error', (error) => {
    console.error('Error reading file:', error);
  });
}

// Writing a large file with streams
function writeLargeFile(data, filePath) {
  const writeStream = fs.createWriteStream(filePath);
  
  writeStream.write(data);
  writeStream.end();
  
  writeStream.on('finish', () => {
    console.log('Finished writing file');
  });
  
  writeStream.on('error', (error) => {
    console.error('Error writing file:', error);
  });
}

// Copy a file using streams
function copyFile(sourcePath, destinationPath) {
  const readStream = fs.createReadStream(sourcePath);
  const writeStream = fs.createWriteStream(destinationPath);
  
  readStream.pipe(writeStream);
  
  writeStream.on('finish', () => {
    console.log(`Copied ${sourcePath} to ${destinationPath}`);
  });
}
```

## Express Routers for Code Organization

As Express applications grow, organizing routes becomes essential for maintainability. Express Router helps modularize your code.

### Basic Router Structure

```javascript
// userRoutes.js
import express from 'express';
const router = express.Router();

// Define routes on the router
router.get('/', (req, res) => {
  res.json({ message: 'Get all users' });
});

router.get('/:id', (req, res) => {
  res.json({ message: `Get user with ID: ${req.params.id}` });
});

router.post('/', (req, res) => {
  res.status(201).json({ message: 'Create new user', data: req.body });
});

router.put('/:id', (req, res) => {
  res.json({ message: `Update user with ID: ${req.params.id}`, data: req.body });
});

router.delete('/:id', (req, res) => {
  res.json({ message: `Delete user with ID: ${req.params.id}` });
});

export default router;
```

### Using Routers in Main Application

```javascript
// app.js
import express from 'express';
import userRoutes from './routes/userRoutes.js';
import productRoutes from './routes/productRoutes.js';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Mount routers with a URL prefix
app.use('/api/users', userRoutes);
app.use('/api/products', productRoutes);

// Root route
app.get('/', (req, res) => {
  res.send('API is running');
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### Router-specific Middleware

You can apply middleware to specific routers:

```javascript
// authMiddleware.js
export const requireAuth = (req, res, next) => {
  // Check if user is authenticated
  const isAuthenticated = req.headers.authorization === 'Bearer valid-token';
  
  if (!isAuthenticated) {
    return res.status(401).json({ message: 'Authentication required' });
  }
  
  next();
};

// adminRoutes.js
import express from 'express';
import { requireAuth } from '../middleware/authMiddleware.js';

const router = express.Router();

// Apply middleware to all routes in this router
router.use(requireAuth);

router.get('/dashboard', (req, res) => {
  res.json({ message: 'Admin dashboard data' });
});

router.get('/users', (req, res) => {
  res.json({ message: 'Admin users management' });
});

export default router;

// app.js
import adminRoutes from './routes/adminRoutes.js';
// ...
app.use('/admin', adminRoutes);
```

### Nested Routers

You can nest routers for more complex hierarchies:

```javascript
// userPostsRoutes.js
import express from 'express';
const router = express.Router({ mergeParams: true }); // Important for accessing parent params

// This will be accessible at /api/users/:userId/posts
router.get('/', (req, res) => {
  res.json({ message: `Get all posts for user ${req.params.userId}` });
});

router.post('/', (req, res) => {
  res.status(201).json({ 
    message: `Create post for user ${req.params.userId}`,
    data: req.body
  });
});

router.get('/:postId', (req, res) => {
  res.json({ 
    message: `Get post ${req.params.postId} for user ${req.params.userId}`
  });
});

export default router;

// userRoutes.js
import express from 'express';
import userPostsRoutes from './userPostsRoutes.js';

const router = express.Router();

// User routes
router.get('/', (req, res) => {
  res.json({ message: 'Get all users' });
});

// Nest the posts router under users
router.use('/:userId/posts', userPostsRoutes);

export default router;
```

### Router Organization Patterns

#### By Resource Type

Organize routers by the resource they manage:

```
routes/
├── userRoutes.js
├── productRoutes.js
├── orderRoutes.js
└── paymentRoutes.js
```

#### By API Version

Support multiple API versions:

```
routes/
├── v1/
│   ├── userRoutes.js
│   └── productRoutes.js
└── v2/
    ├── userRoutes.js
    └── productRoutes.js
    
// app.js
import v1UserRoutes from './routes/v1/userRoutes.js';
import v2UserRoutes from './routes/v2/userRoutes.js';

app.use('/api/v1/users', v1UserRoutes);
app.use('/api/v2/users', v2UserRoutes);
```

#### By Access Level

Separate public and protected routes:

```
routes/
├── public/
│   ├── authRoutes.js
│   └── productRoutes.js
└── protected/
    ├── userRoutes.js
    └── adminRoutes.js
    
// app.js
import authRoutes from './routes/public/authRoutes.js';
import userRoutes from './routes/protected/userRoutes.js';
import { requireAuth } from './middleware/authMiddleware.js';

app.use('/api/auth', authRoutes);
app.use('/api/users', requireAuth, userRoutes);
```

## Implementing Server-side Rendering

Server-side rendering involves generating HTML on the server instead of relying on client-side JavaScript.

### Basic HTML Rendering in Express

```javascript
// app.js
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Basic route with HTML response
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Home Page</title>
      <link rel="stylesheet" href="/css/style.css">
    </head>
    <body>
      <header>
        <h1>Welcome to Our Website</h1>
        <nav>
          <ul>
            <li><a href="/">Home</a></li>
            <li><a href="/about">About</a></li>
            <li><a href="/contact">Contact</a></li>
          </ul>
        </nav>
      </header>
      <main>
        <p>This is a server-rendered page.</p>
      </main>
      <footer>
        <p>&copy; 2023 My Website</p>
      </footer>
      <script src="/js/main.js"></script>
    </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### Using Template Files

Rather than embedding HTML in your JavaScript files, you can read from template files:

```javascript
// File structure
// /
// ├── templates/
// │   ├── home.html
// │   ├── about.html
// │   └── contact.html
// └── public/
//     ├── css/
//     └── js/

import express from 'express';
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, 'public')));

// Helper function to read template files
async function renderTemplate(templatePath, data = {}) {
  try {
    let template = await fs.readFile(templatePath, 'utf8');
    
    // Replace placeholders with data
    for (const [key, value] of Object.entries(data)) {
      const placeholder = new RegExp(`{{\\s*${key}\\s*}}`, 'g');
      template = template.replace(placeholder, value);
    }
    
    return template;
  } catch (error) {
    console.error('Error rendering template:', error);
    throw error;
  }
}

// Routes
app.get('/', async (req, res) => {
  try {
    const content = await renderTemplate(
      path.join(__dirname, 'templates', 'home.html'),
      { 
        title: 'Home Page',
        content: 'Welcome to our website!',
        year: new Date().getFullYear()
      }
    );
    
    res.send(content);
  } catch (error) {
    res.status(500).send('Server error');
  }
});

app.get('/about', async (req, res) => {
  try {
    const content = await renderTemplate(
      path.join(__dirname, 'templates', 'about.html'),
      { 
        title: 'About Us',
        content: 'Learn more about our company.',
        year: new Date().getFullYear()
      }
    );
    
    res.send(content);
  } catch (error) {
    res.status(500).send('Server error');
  }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### Using Established Template Engines

For more complex needs, use established template engines like EJS, Pug, or Handlebars:

```bash
npm install ejs
```

```javascript
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

// Set up EJS as the view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Routes
app.get('/', (req, res) => {
  res.render('pages/home', {
    title: 'Home Page',
    content: 'Welcome to our website!',
    user: { name: 'Guest' }
  });
});

app.get('/about', (req, res) => {
  res.render('pages/about', {
    title: 'About Us',
    content: 'Learn more about our company.'
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

## Optimizing Code Structure

As applications grow, organizing code becomes increasingly important for maintainability.

### Separation of Concerns

Separate your code into distinct layers:

```
src/
├── controllers/    # Handle HTTP requests/responses
├── services/       # Business logic
├── models/         # Data models and database interactions
├── middleware/     # Express middleware
├── routes/         # Route definitions
├── utils/          # Helper functions
└── views/          # Templates
```

### Controller Example

```javascript
// controllers/userController.js
import userService from '../services/userService.js';

export const getUsers = async (req, res) => {
  try {
    const users = await userService.getAllUsers();
    res.render('users/index', { users });
  } catch (error) {
    res.status(500).render('error', { error });
  }
};

export const getUserById = async (req, res) => {
  try {
    const user = await userService.getUserById(req.params.id);
    
    if (!user) {
      return res.status(404).render('error', { message: 'User not found' });
    }
    
    res.render('users/detail', { user });
  } catch (error) {
    res.status(500).render('error', { error });
  }
};
```

### Service Example

```javascript
// services/userService.js
import userModel from '../models/userModel.js';

export default {
  async getAllUsers() {
    return await userModel.findAll();
  },
  
  async getUserById(id) {
    return await userModel.findById(id);
  },
  
  async createUser(userData) {
    // Business logic - validate, normalize, etc.
    const sanitizedData = {
      ...userData,
      username: userData.username.toLowerCase(),
      createdAt: new Date()
    };
    
    return await userModel.create(sanitizedData);
  }
};
```

### Routes Example

```javascript
// routes/userRoutes.js
import express from 'express';
import * as userController from '../controllers/userController.js';
import { requireAuth } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/', userController.getUsers);
router.get('/:id', userController.getUserById);
router.post('/', requireAuth, userController.createUser);
router.put('/:id', requireAuth, userController.updateUser);
router.delete('/:id', requireAuth, userController.deleteUser);

export default router;
```

### Main App File

```javascript
// app.js
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import userRoutes from './routes/userRoutes.js';
import productRoutes from './routes/productRoutes.js';
import { errorHandler } from './middleware/errorMiddleware.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// View engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Routes
app.use('/users', userRoutes);
app.use('/products', productRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).render('error', { message: 'Page not found' });
});

// Error handler
app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

## Nodemon Configuration for Multiple Extensions

When working with various file types, configure Nodemon to watch all relevant extensions.

### Basic Nodemon Configuration

Create a `nodemon.json` file in your project root:

```json
{
  "watch": ["src", "views", "public"],
  "ext": "js,json,html,css,ejs",
  "ignore": ["node_modules/*", "data/*"],
  "env": {
    "NODE_ENV": "development"
  }
}
```

### Running Nodemon with Configuration

```bash
# Run with config file
nodemon

# Or specify configuration in the command
nodemon --watch src --watch views --ext js,json,html app.js
```

### Nodemon in package.json Scripts

```json
{
  "scripts": {
    "start": "node src/app.js",
    "dev": "nodemon src/app.js",
    "dev:inspect": "nodemon --inspect src/app.js"
  }
}
```

### Advanced Configuration

For more complex setups:

```json
{
  "restartable": "rs",
  "ignore": [".git", "node_modules/**/node_modules", "dist"],
  "verbose": true,
  "execMap": {
    "js": "node --experimental-modules",
    "mjs": "node --experimental-modules"
  },
  "watch": ["src/", "views/", "public/css/", "public/js/"],
  "ext": "js,json,ts,html,ejs,css,scss",
  "env": {
    "NODE_ENV": "development"
  },
  "events": {
    "restart": "echo 'App restarted due to changes'",
    "crash": "echo 'App crashed - waiting for changes before restarting'"
  }
}
```

### Multiple Node.js Applications

For managing multiple applications, consider using Nodemon with different configurations:

```json
{
  "apps": [
    {
      "name": "api-server",
      "script": "src/api/server.js",
      "watch": ["src/api", "src/shared"],
      "ext": "js,json"
    },
    {
      "name": "web-server",
      "script": "src/web/server.js",
      "watch": ["src/web", "src/shared", "views"],
      "ext": "js,json,html,ejs"
    }
  ]
}
```

You can also use environment-specific configurations:

```json
{
  "development": {
    "watch": ["src", "views"],
    "ext": "js,json,html,ejs,css",
    "env": {
      "NODE_ENV": "development",
      "PORT": 3000
    }
  },
  "test": {
    "watch": ["src", "test"],
    "ext": "js,json",
    "env": {
      "NODE_ENV": "test",
      "PORT": 3001
    }
  }
}
```

### Watching Non-JavaScript Files

When your application depends on various file types, configure Nodemon to monitor them:

```json
{
  "watch": [
    "src/**/*.js",
    "views/**/*.ejs",
    "public/css/**/*.css",
    "public/js/**/*.js",
    "config/**/*.json"
  ],
  "ext": "js,json,ejs,css",
  "ignore": [
    "node_modules",
    "*.test.js",
    "*.spec.js"
  ]
}
```

Or by using the command line:

```bash
nodemon --watch src --watch views --watch public/css --ext js,json,ejs,css app.js
```

This setup ensures your server restarts when there are changes to any of the relevant files, making the development process more efficient, especially when working with server-side rendering where changes to templates and static assets are common.

---

[<- Back to Main Note](./README.md) | [Next: Forms and Svelte ->](./08-forms-svelte.md)
