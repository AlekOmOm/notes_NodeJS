# 5. Export and Import in JavaScript 📤

[<- Back to HTML and Time in JavaScript](./04-html-time.md) | [Next: Client vs. Server ->](./06-client-server.md)

## Table of Contents

- [Module Systems in JavaScript](#module-systems-in-javascript)
- [ES Modules vs. CommonJS](#es-modules-vs-commonjs)
- [Using Modules in the Browser](#using-modules-in-the-browser)
- [Serving Static Files in Express](#serving-static-files-in-express)
- [Client-Side vs. Server-Side Redirection](#client-side-vs-server-side-redirection)
- [Project Structure Best Practices](#project-structure-best-practices)

## Module Systems in JavaScript

JavaScript modules allow you to break up your code into separate files for better organization, reusability, and maintenance.

### Why Use Modules?

- **Maintainability**: Smaller, self-contained files are easier to maintain
- **Namespace Management**: Avoid global namespace pollution
- **Reusability**: Import functionality across multiple files
- **Dependency Management**: Explicitly state dependencies

## ES Modules vs. CommonJS

JavaScript has two main module systems: ES Modules (ESM) and CommonJS (CJS). ES Modules is the modern standard, while CommonJS has been the traditional approach in Node.js.

### ES Modules (ESM)

ES Modules were introduced in ES6 (ECMAScript 2015) and are now the standard for JavaScript.

#### Exporting in ES Modules

```javascript
// Named exports
export const PI = 3.14159;
export function squareArea(side) {
  return side * side;
}

export class Circle {
  constructor(radius) {
    this.radius = radius;
  }
  
  getArea() {
    return Math.PI * this.radius * this.radius;
  }
}

// Alternative syntax: export at the end
const triangleArea = (base, height) => 0.5 * base * height;
const doubleValue = x => x * 2;

export { triangleArea, doubleValue };

// Default export (one per module)
export default function calculateArea(shape, dimensions) {
  // Implementation
}
```

#### Importing in ES Modules

```javascript
// Import default export
import calculateArea from './shapes.js';

// Import named exports
import { PI, squareArea, Circle } from './shapes.js';

// Import with alias
import { triangleArea as getTriangleArea } from './shapes.js';

// Import all exports as a namespace
import * as Shapes from './shapes.js';
console.log(Shapes.PI); // 3.14159
const myCircle = new Shapes.Circle(5);

// Import both default and named exports
import calculateArea, { PI, squareArea } from './shapes.js';

// Dynamic import (returns a promise)
const mathModule = await import('./math.js');
console.log(mathModule.add(2, 3)); // 5
```

### CommonJS (CJS)

CommonJS is the traditional module system used in Node.js.

#### Exporting in CommonJS

```javascript
// exports object approach
exports.PI = 3.14159;
exports.squareArea = function(side) {
  return side * side;
};

// module.exports approach (overwrites exports object)
module.exports = {
  PI: 3.14159,
  squareArea: function(side) {
    return side * side;
  },
  Circle: class Circle {
    constructor(radius) {
      this.radius = radius;
    }
    
    getArea() {
      return Math.PI * this.radius * this.radius;
    }
  }
};

// Exporting a single function/class
module.exports = function calculateArea(shape, dimensions) {
  // Implementation
};
```

#### Importing in CommonJS

```javascript
// Import the entire module
const shapes = require('./shapes');
console.log(shapes.PI); // 3.14159

// Import with destructuring (ES6 feature)
const { PI, squareArea } = require('./shapes');
console.log(PI); // 3.14159

// When a single function is exported
const calculateArea = require('./shapes');
calculateArea('circle', { radius: 5 });
```

### Key Differences Between ESM and CJS

| Feature | ES Modules | CommonJS |
|---------|------------|----------|
| Syntax | `import`/`export` | `require()`/`exports` or `module.exports` |
| Loading | Static (parsed before execution) | Dynamic (during execution) |
| Asynchronous | Yes (can use dynamic import) | No (synchronous only) |
| Tree-shaking | Supported | Not supported |
| File extension | Typically `.mjs` in Node.js | Typically `.cjs` in modern Node.js, or `.js` |
| Browser support | Native in modern browsers | Requires bundlers (webpack, etc.) |
| Top-level await | Supported | Not supported |

### Using ESM in Node.js

To use ES Modules in Node.js:

1. Set `"type": "module"` in `package.json`:
   ```json
   {
     "name": "my-app",
     "version": "1.0.0",
     "type": "module"
   }
   ```

2. Or use the `.mjs` extension for specific files:
   ```javascript
   // math.mjs
   export function add(a, b) {
     return a + b;
   }
   ```

3. Or run Node with the `--input-type=module` flag:
   ```bash
   node --input-type=module app.js
   ```

## Using Modules in the Browser

Modern browsers support ES modules natively, allowing for better code organization in frontend JavaScript.

### Adding the `type="module"` Attribute

To use ES modules in HTML, add the `type="module"` attribute to your script tag:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ES Modules Example</title>
</head>
<body>
  <h1>ES Modules in the Browser</h1>
  
  <!-- Traditional script (global scope) -->
  <script src="traditional.js"></script>
  
  <!-- ES Module script (isolated scope) -->
  <script type="module" src="main.js"></script>
</body>
</html>
```

### Example of Browser Modules

**utils.js**:
```javascript
// Export utility functions
export function formatPrice(price) {
  return `$${price.toFixed(2)}`;
}

export function capitalize(text) {
  return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
}
```

**product-class.js**:
```javascript
// Export a class
export default class Product {
  constructor(name, price) {
    this.name = name;
    this.price = price;
  }
  
  getDetails() {
    return `${this.name}: $${this.price.toFixed(2)}`;
  }
}
```

**main.js**:
```javascript
// Import from other modules
import { formatPrice, capitalize } from './utils.js';
import Product from './product-class.js';

// Use the imported functionality
const product = new Product('laptop', 999.99);
console.log(product.getDetails());

const productName = capitalize(product.name);
const formattedPrice = formatPrice(product.price);

document.addEventListener('DOMContentLoaded', () => {
  const app = document.getElementById('app');
  
  if (app) {
    app.innerHTML = `
      <div class="product">
        <h2>${productName}</h2>
        <p>Price: ${formattedPrice}</p>
      </div>
    `;
  }
});
```

### Important Considerations for Browser Modules

1. **CORS restrictions**: Modules must be served with proper CORS headers when loaded from different origins
2. **File paths**: Always use relative paths (`./` or `../`) for local modules
3. **Strict mode**: Modules are always executed in strict mode
4. **Deferred by default**: Module scripts are deferred automatically
5. **No access to global `this`**: `this` is `undefined` at the top level, not `window`
6. **Single instance**: Each module is executed only once, regardless of how many times it's imported

### Using Dynamic Imports

For code-splitting and conditional loading:

```javascript
document.getElementById('load-chart').addEventListener('click', async () => {
  try {
    // Dynamically import the chart module only when needed
    const { createChart } = await import('./chart.js');
    createChart('chart-container', data);
  } catch (error) {
    console.error('Failed to load chart module:', error);
  }
});
```

## Serving Static Files in Express

Express provides built-in middleware for serving static files, such as CSS, JavaScript, images, and more.

### Basic Static File Serving

```javascript
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const app = express();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Serve static files from the 'public' directory
app.use(express.static(path.join(__dirname, 'public')));

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

With this setup, files in the `public` directory are served at the root URL path:

```
Project Structure:
/public
  /css
    styles.css
  /js
    main.js
  /images
    logo.png

URL Mapping:
http://localhost:3000/css/styles.css   → /public/css/styles.css
http://localhost:3000/js/main.js       → /public/js/main.js
http://localhost:3000/images/logo.png  → /public/images/logo.png
```

### Serving from Multiple Directories

```javascript
// Serve static files from multiple directories
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.static(path.join(__dirname, 'assets')));
```

The order matters: when a file with the same name exists in both directories, the one in the first directory takes precedence.

### Using a URL Prefix

```javascript
// Serve static files with a URL prefix
app.use('/static', express.static(path.join(__dirname, 'public')));
```

With this setup, files are served with the `/static` prefix:

```
URL Mapping with Prefix:
http://localhost:3000/static/css/styles.css   → /public/css/styles.css
http://localhost:3000/static/js/main.js       → /public/js/main.js
```

### Static File Serving Options

```javascript
app.use(express.static(path.join(__dirname, 'public'), {
  dotfiles: 'ignore', // How to handle dotfiles: 'allow', 'deny', 'ignore'
  etag: true, // Enable or disable etag generation
  extensions: ['html', 'htm'], // Try these extensions if there's no extension in the URL
  index: 'index.html', // Default file to serve when a directory is requested
  lastModified: true, // Enable or disable Last-Modified header
  maxAge: '1d', // Cache-Control max-age in milliseconds or string format
  setHeaders: (res, path, stat) => {
    // Custom function to set headers on the response
    res.set('x-timestamp', Date.now());
    
    // Set different cache control for different file types
    if (path.endsWith('.html')) {
      res.set('Cache-Control', 'no-cache');
    } else if (path.endsWith('.css') || path.endsWith('.js')) {
      res.set('Cache-Control', 'public, max-age=86400'); // 1 day
    }
  }
}));
```

### Security Considerations

1. **Don't serve sensitive directories**: Never serve directories like `node_modules` or configuration directories
2. **Use a dedicated public directory**: Only place publicly accessible files in the static directory
3. **Enable HTTPS**: When serving static assets in production
4. **Set proper CSP headers**: Use Content Security Policy headers to prevent XSS attacks
5. **Configure proper caching**: Use appropriate Cache-Control headers for different types of assets
6. **Validate file paths**: Ensure paths can't access files outside the intended directory

## Client-Side vs. Server-Side Redirection

Redirection is the process of directing users from one URL to another. Understanding the differences between client-side and server-side redirection is important for proper web application architecture.

### Server-Side Redirection

Server-side redirection happens on the server before any content is sent to the browser.

#### Implementation in Express

```javascript
// 302 Found (temporary redirect)
app.get('/old-page', (req, res) => {
  res.redirect('/new-page');
});

// 301 Moved Permanently (permanent redirect)
app.get('/old-permanent', (req, res) => {
  res.redirect(301, '/new-permanent');
});

// Redirect with path construction
app.get('/user/:id/profile', (req, res) => {
  res.redirect(`/profiles/${req.params.id}`);
});

// Redirect to external site
app.get('/external', (req, res) => {
  res.redirect('https://example.com');
});
```

#### Advantages of Server-Side Redirection

1. **SEO friendly**: Search engines understand HTTP redirects
2. **Clean user experience**: User sees the new URL in the address bar
3. **Works without JavaScript**: No client-side code required
4. **Can happen before any page loads**: No page load required before redirect

#### Disadvantages of Server-Side Redirection

1. **Requires server round-trip**: Additional network request
2. **Less interactive control**: Can't easily add animations or transitions
3. **Less conditional logic**: Harder to implement complex redirection rules

### Client-Side Redirection

Client-side redirection occurs in the browser after the page has at least partially loaded.

#### Implementation in JavaScript

```javascript
// Basic redirect
window.location.href = '/new-page';

// Replace current history entry (user can't go back)
window.location.replace('/new-page');

// Using History API to add a new entry without refreshing
history.pushState({ page: 1 }, 'New Page Title', '/new-page');

// Using client-side router libraries (e.g., React Router)
router.navigate('/new-page');
```

#### Advantages of Client-Side Redirection

1. **No additional server request**: Can be faster for SPA navigation
2. **More interactive control**: Can add animations or transitions
3. **Conditional logic**: Can implement complex redirection rules
4. **Preserves application state**: Can maintain in-memory data

#### Disadvantages of Client-Side Redirection

1. **Requires JavaScript**: Doesn't work if JavaScript is disabled
2. **SEO challenges**: Search engines might not properly index SPAs without additional steps
3. **Initial page load required**: Must wait for at least some JavaScript to execute
4. **Security considerations**: Can be manipulated by malicious scripts

### When to Use Each Method

**Use Server-Side Redirection For:**
- Permanent URL changes (301 redirects)
- Authentication requirements
- URL normalization
- Redirecting after form submissions
- SEO-sensitive pages

**Use Client-Side Redirection For:**
- Single-page application navigation
- Interactive user flows
- Conditional redirects based on client state
- Preserving in-memory application state
- Transitions and animations between pages

### Hybrid Approach

In modern applications, a hybrid approach is common:

1. **Server-side for initial routing**: Handle authentication and initial page access
2. **Client-side for SPA navigation**: Handle application internal navigation
3. **Server-side fallbacks**: Ensure the application works even without JavaScript

## Project Structure Best Practices

Organizing your project files properly will improve maintainability and development efficiency.

### Frontend Structure

A typical frontend structure for an Express application:

```
public/
├── assets/
│   ├── images/
│   │   └── logo.png
│   └── fonts/
│       └── roboto.woff2
├── css/
│   ├── reset.css
│   ├── main.css
│   └── components/
│       ├── header.css
│       └── footer.css
├── js/
│   ├── main.js
│   ├── utils/
│   │   └── helpers.js
│   └── components/
│       ├── header.js
│       └── footer.js
└── index.html
```

### Backend Structure

A well-organized Express application structure:

```
/
├── public/           # Static files (CSS, JS, images)
├── views/            # Template files (if using a template engine)
├── src/              # Application source code
│   ├── api/          # API routes and controllers
│   │   ├── users/    # User-related routes and controllers
│   │   └── products/ # Product-related routes and controllers
│   ├── config/       # Configuration files
│   │   └── index.js  # Main configuration
│   ├── middleware/   # Custom middleware functions
│   │   ├── auth.js   # Authentication middleware
│   │   └── errors.js # Error handling middleware
│   ├── models/       # Data models
│   │   ├── user.js   # User model
│   │   └── product.js # Product model
│   ├── services/     # Business logic services
│   │   ├── userService.js
│   │   └── emailService.js
│   └── utils/        # Utility functions
│       ├── logger.js
│       └── helpers.js
├── test/             # Test files
├── .env.example      # Example environment variables
├── .gitignore        # Git ignore file
├── package.json      # Project dependencies
└── server.js         # Application entry point
```

### Module Organization Principles

1. **Group by feature**: Organize related components, styles, and scripts together
2. **Separate concerns**: Keep business logic, data access, and presentation separate
3. **Consistent naming**: Use clear and consistent naming conventions
4. **Minimize nesting**: Avoid deeply nested folders
5. **Keep related files together**: Files that change together should be located together

### Import Path Best Practices

1. **Use relative paths for closely related modules**:
   ```javascript
   // When importing from the same directory or a direct subdirectory
   import { formatDate } from './utils.js';
   import User from './models/user.js';
   ```

2. **Consider aliases for deeply nested imports**:
   ```javascript
   // Without aliases (confusing and brittle)
   import config from '../../../config/database.js';
   
   // With aliases (clearer intent)
   import config from '@config/database.js';
   ```

3. **Be consistent with import style**:
   - Group imports by type (external, internal, relative)
   - Order imports consistently (alphabetical, by path length, etc.)
   - Use consistent syntax for imports

---

[<- Back to Main Note](./README.md) | [Next: Client vs. Server ->](./06-client-server.md)
