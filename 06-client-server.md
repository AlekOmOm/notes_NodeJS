# 6. Client vs. Server in Web Development 🔐

[<- Back to Main Note](./README.md) | [Next: Server-side Rendering ->](./07-ssr-routers.md)

## Table of Contents

- [Understanding Client-Server Architecture](#understanding-client-server-architecture)
- [Environment Variables in Node.js](#environment-variables-in-nodejs)
- [Package.json Scripts](#packagejson-scripts)
- [Fetching in Node.js](#fetching-in-nodejs)
- [Semantic HTML](#semantic-html)
- [File Organization Best Practices](#file-organization-best-practices)

## Understanding Client-Server Architecture

The web operates on a client-server model, where responsibilities are divided between client-side (frontend) and server-side (backend) components.

### Client-Side (Frontend)

The client-side runs in the user's browser and handles:

- User interface presentation
- Handling user input
- Client-side validation
- Temporary data storage (localStorage, sessionStorage, cookies)
- Making requests to servers (fetch, axios, etc.)

**Key Technologies**:
- HTML: Structure
- CSS: Presentation
- JavaScript: Behavior
- Frameworks: React, Vue, Svelte, Angular

### Server-Side (Backend)

The server-side runs on a remote server and handles:

- Processing requests from clients
- Business logic implementation
- Data persistence (databases)
- Authentication and authorization
- File processing and storage
- Serving responses

**Key Technologies**:
- Node.js, Python, Ruby, Java, PHP, etc.
- Express, Koa, Fastify, etc. (for Node.js)
- Databases: MongoDB, PostgreSQL, MySQL, etc.
- ORM/ODM libraries: Mongoose, Sequelize, TypeORM

### Comparison Table

| Aspect | Client-Side | Server-Side |
|--------|------------|-------------|
| Execution environment | Browser | Server |
| Visibility of code | Visible to users | Hidden from users |
| Security for sensitive operations | Less secure | More secure |
| Performance impact | Depends on user's device | Depends on server capacity |
| Offline capabilities | Possible with PWA techniques | Not applicable |
| Scalability | Limited by browser capabilities | Can scale horizontally |
| Development concerns | Browser compatibility | Server resources, security |

### Communication Between Client and Server

The client and server communicate through HTTP/HTTPS requests:

1. **Client makes a request**: Browser sends HTTP request to server
2. **Server processes request**: Server executes code to handle the request
3. **Server sends response**: Server sends HTTP response back to client
4. **Client renders response**: Browser processes and displays the response

Popular data formats for communication:
- JSON (JavaScript Object Notation)
- XML (less common in modern applications)
- Plain text
- Binary data (for files, images, etc.)

## Environment Variables in Node.js

Environment variables allow you to store configuration information outside your code, making your application more secure and flexible across different environments.

### Why Use Environment Variables?

- **Security**: Keep sensitive information (API keys, passwords) out of your code
- **Environment-specific configuration**: Different settings for development, testing, and production
- **Flexibility**: Change configuration without modifying code
- **12-Factor App compliance**: Following best practices for modern applications

### Accessing Environment Variables in Node.js

Node.js provides the `process.env` object to access environment variables:

```javascript
// Access an environment variable
const port = process.env.PORT || 3000;
const dbUrl = process.env.DATABASE_URL || 'mongodb://localhost:27017/myapp';
const apiKey = process.env.API_KEY;

console.log(`Server running on port ${port}`);
```

### Setting Environment Variables

**Temporarily (command line)**:

```bash
# Linux/macOS
PORT=4000 NODE_ENV=development node app.js

# Windows (CMD)
set PORT=4000 && set NODE_ENV=development && node app.js

# Windows (PowerShell)
$env:PORT=4000; $env:NODE_ENV="development"; node app.js
```

**Permanently (system settings)**:

Set environment variables through your operating system's settings or shell configuration (`.bashrc`, `.zshrc`, etc.).

### Using .env Files

The `dotenv` package allows loading variables from a `.env` file:

**Installation**:
```bash
npm install dotenv
```

**.env file**:
```
PORT=4000
NODE_ENV=development
DATABASE_URL=mongodb://localhost:27017/myapp
API_KEY=your_secret_key_here
```

**Loading in your application**:
```javascript
// Load as early as possible in your application
import dotenv from 'dotenv';
dotenv.config();

// Now process.env contains variables from .env file
const port = process.env.PORT || 3000;
```

### Environment-Specific .env Files

For different environments, you can use multiple .env files:

```
.env                # Default environment variables
.env.development    # Development-specific variables
.env.test           # Testing-specific variables
.env.production     # Production-specific variables
```

Loading a specific environment:

```javascript
import dotenv from 'dotenv';

// Load based on NODE_ENV
dotenv.config({ path: `.env.${process.env.NODE_ENV || 'development'}` });
```

### Security Best Practices

1. **Never commit .env files to version control**:
   ```
   # .gitignore
   .env
   .env.*
   ```

2. **Provide an example file**:
   ```
   # .env.example (safe to commit)
   PORT=3000
   NODE_ENV=development
   DATABASE_URL=mongodb://localhost:27017/myapp
   API_KEY=your_api_key_here
   ```

3. **Validate required variables**:
   ```javascript
   const requiredEnvVars = ['DATABASE_URL', 'API_KEY'];
   
   for (const envVar of requiredEnvVars) {
     if (!process.env[envVar]) {
       console.error(`Error: Environment variable ${envVar} is required`);
       process.exit(1);
     }
   }
   ```

4. **Sanitize sensitive information in logs**:
   ```javascript
   // Don't do this
   console.log(`Connected to database at ${process.env.DATABASE_URL}`);
   
   // Do this instead
   console.log(`Connected to database successfully`);
   ```

## Package.json Scripts

The `scripts` section in package.json allows you to define custom commands for your project, making common tasks easier to execute.

### Basic Scripts

```json
{
  "name": "my-node-app",
  "version": "1.0.0",
  "scripts": {
    "start": "node app.js",
    "dev": "nodemon app.js",
    "test": "jest",
    "lint": "eslint ."
  }
}
```

Run these scripts with `npm run [script-name]`:
```bash
npm run dev    # Start development server with nodemon
npm run test   # Run tests
npm start      # Special case, can be run as just "npm start"
```

### Using Environment Variables in Scripts

```json
{
  "scripts": {
    "start": "node app.js",
    "dev": "NODE_ENV=development nodemon app.js",
    "prod": "NODE_ENV=production node app.js",
    "test": "NODE_ENV=test jest"
  }
}
```

### Pre/Post Scripts

npm automatically runs scripts with names prefixed by "pre" or "post" before or after the named script:

```json
{
  "scripts": {
    "prebuild": "rimraf dist",
    "build": "webpack",
    "postbuild": "echo Build completed!"
  }
}
```

When you run `npm run build`, the scripts execute in this order:
1. `prebuild`
2. `build`
3. `postbuild`

### Passing Arguments to Scripts

```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  }
}
```

You can also pass additional arguments with `--`:
```bash
npm run test -- --verbose
```

### Script Composition

Combine multiple commands:

```json
{
  "scripts": {
    "clean": "rimraf dist",
    "build:css": "postcss src/css -o dist/css",
    "build:js": "webpack --config webpack.config.js",
    "build": "npm run clean && npm run build:css && npm run build:js",
    "watch": "concurrently \"npm run build:css -- --watch\" \"npm run build:js -- --watch\""
  }
}
```

### Common Script Patterns

```json
{
  "scripts": {
    "start": "node dist/index.js",
    "dev": "nodemon src/index.js",
    "build": "babel src -d dist",
    "test": "jest",
    "test:watch": "jest --watch",
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "format": "prettier --write .",
    "prepare": "husky install"
  }
}
```

## Fetching in Node.js

While browsers have a built-in `fetch` API, Node.js requires external packages or configuration to make HTTP requests.

### Fetch in Modern Node.js

Node.js (v18+) includes a built-in `fetch` API that works similarly to the browser version:

```javascript
// Native fetch in Node.js v18+
async function getUsers() {
  try {
    const response = await fetch('https://api.example.com/users');
    
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Fetch error:', error);
    throw error;
  }
}

getUsers()
  .then(users => console.log(users))
  .catch(error => console.error(error));
```

### Using Axios

For older Node.js versions or more features, axios is a popular alternative:

```bash
npm install axios
```

```javascript
import axios from 'axios';

async function getUsers() {
  try {
    const response = await axios.get('https://api.example.com/users');
    return response.data;
  } catch (error) {
    console.error('Error fetching users:', error);
    throw error;
  }
}

// POST request with axios
async function createUser(userData) {
  try {
    const response = await axios.post('https://api.example.com/users', userData, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.API_TOKEN}`
      }
    });
    return response.data;
  } catch (error) {
    console.error('Error creating user:', error);
    throw error;
  }
}
```

### Using node-fetch (for Node.js < v18)

```bash
npm install node-fetch
```

```javascript
import fetch from 'node-fetch';

async function getUsers() {
  try {
    const response = await fetch('https://api.example.com/users');
    
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Fetch error:', error);
    throw error;
  }
}
```

### Setting Up a Request Client

Creating a reusable request client:

```javascript
import axios from 'axios';

// Create a configured axios instance
const apiClient = axios.create({
  baseURL: process.env.API_BASE_URL || 'https://api.example.com',
  timeout: 5000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
});

// Add request interceptor
apiClient.interceptors.request.use(config => {
  // Add token to all requests
  const token = process.env.API_TOKEN;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Add response interceptor
apiClient.interceptors.response.use(
  response => response,
  error => {
    // Log errors, retry requests, etc.
    console.error('API request failed:', error.message);
    return Promise.reject(error);
  }
);

// Export for use in services
export default apiClient;
```

Then use it in your services:

```javascript
import apiClient from '../utils/apiClient.js';

export const userService = {
  async getAll() {
    const response = await apiClient.get('/users');
    return response.data;
  },
  
  async getById(id) {
    const response = await apiClient.get(`/users/${id}`);
    return response.data;
  },
  
  async create(userData) {
    const response = await apiClient.post('/users', userData);
    return response.data;
  }
};
```

## Semantic HTML

Semantic HTML uses elements that clearly describe their meaning to both the browser and the developer, improving accessibility, SEO, and code maintainability.

### Key Semantic Elements

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Semantic HTML Example</title>
</head>
<body>
  <!-- Page header with site branding -->
  <header>
    <h1>Site Title</h1>
    <nav>
      <ul>
        <li><a href="/">Home</a></li>
        <li><a href="/about">About</a></li>
        <li><a href="/contact">Contact</a></li>
      </ul>
    </nav>
  </header>

  <!-- Main content area -->
  <main>
    <!-- Main article or content -->
    <article>
      <header>
        <h2>Article Title</h2>
        <p>Published on <time datetime="2023-06-15">June 15, 2023</time></p>
      </header>
      
      <section>
        <h3>First Section</h3>
        <p>Content of the first section...</p>
      </section>
      
      <section>
        <h3>Second Section</h3>
        <p>Content of the second section...</p>
        
        <figure>
          <img src="image.jpg" alt="Descriptive text">
          <figcaption>Figure caption</figcaption>
        </figure>
      </section>
      
      <footer>
        <p>Article footer with metadata</p>
      </footer>
    </article>
    
    <!-- Sidebar or complementary content -->
    <aside>
      <h3>Related Articles</h3>
      <ul>
        <li><a href="#">Related Article 1</a></li>
        <li><a href="#">Related Article 2</a></li>
      </ul>
    </aside>
  </main>

  <!-- Page footer -->
  <footer>
    <p>&copy; 2023 Your Website</p>
    <address>
      Contact: <a href="mailto:info@example.com">info@example.com</a>
    </address>
  </footer>
</body>
</html>
```

### Commonly Used Semantic Elements

| Element | Purpose |
|---------|---------|
| `<header>` | Introductory content, navigation |
| `<nav>` | Navigation links |
| `<main>` | Main content of the page |
| `<article>` | Self-contained content |
| `<section>` | Thematic grouping of content |
| `<aside>` | Indirectly related content |
| `<footer>` | Footer for page or section |
| `<figure>` | Self-contained content with `<figcaption>` |
| `<time>` | Date/time |
| `<mark>` | Highlighted text |
| `<details>` | Collapsible content with `<summary>` |

### Footer Implementation

A common challenge is keeping the footer at the bottom of the page, even when content is short:

```html
<body>
  <div class="page-container">
    <header>...</header>
    <main>...</main>
    <footer>...</footer>
  </div>
</body>
```

```css
/* Method 1: Flexbox */
.page-container {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

main {
  flex: 1; /* Takes up all available space */
}

/* Method 2: Grid */
.page-container {
  display: grid;
  grid-template-rows: auto 1fr auto;
  min-height: 100vh;
}

/* Method 3: Old school (if you need to support very old browsers) */
.page-container {
  position: relative;
  min-height: 100vh;
  padding-bottom: 60px; /* Height of the footer */
}

footer {
  position: absolute;
  bottom: 0;
  width: 100%;
  height: 60px;
}
```

### Benefits of Semantic HTML

1. **Accessibility**: Screen readers and assistive technologies understand page structure
2. **SEO**: Search engines better understand content and relationships
3. **Maintainability**: Easier to read and understand code
4. **Consistency**: Standardized approach to structuring content
5. **Mobile readiness**: Better adaptation to different screen sizes and devices

## File Organization Best Practices

Properly organizing your files clarifies which are intended for client-side versus server-side execution.

### Client-Side Files

Client-side files are sent to the browser:

```
public/               # Files served directly to clients
├── css/              # Stylesheets
│   ├── main.css
│   └── components/
├── js/               # Client-side JavaScript
│   ├── main.js
│   └── components/
├── images/           # Image assets
├── fonts/            # Font files
└── index.html        # Main HTML file
```

### Server-Side Files

Server-side files run on the server and are not exposed to clients:

```
src/                  # Server application code
├── config/           # Configuration files
├── controllers/      # Request handlers
├── middleware/       # Express middleware
├── models/           # Data models
├── routes/           # API routes
├── services/         # Business logic
├── utils/            # Utility functions
└── app.js            # Main application file
```

### Clear Separation

Maintain clear separation by:

1. **Never mixing client and server code in the same file**
2. **Never exposing server-side directories to the client**
3. **Using a consistent naming convention**
4. **Using a "views" directory for templates (if using server-side rendering)**

### Example Full Project Structure

```
project-root/
├── public/               # Client-side files (static)
│   ├── css/
│   ├── js/
│   ├── images/
│   └── ...
├── src/                  # Server-side code
│   ├── config/
│   ├── controllers/
│   ├── ...
│   └── app.js
├── views/                # Server-side templates (if using SSR)
│   ├── layouts/
│   ├── partials/
│   └── pages/
├── tests/                # Test files
├── .env.example          # Example environment variables
├── .gitignore            # Git ignore file
├── package.json          # Project dependencies
└── README.md             # Project documentation
```

When discussing code with others, always clarify whether you're referring to client-side or server-side files to avoid confusion.

---

[<- Back to Main Note](./README.md) | [Next: Server-side Rendering ->](./07-ssr-routers.md)
