# 2. First Server with Node.js 📦

[<- Back to Introduction to Node.js](./01-introduction.md) | [Next: Loop Methods ->](./03-loop-methods.md)

## Table of Contents

- [Code Conventions](#code-conventions)
- [Functions in JavaScript](#functions-in-javascript)
- [Package Management with NPM](#package-management-with-npm)
- [Creating an Express Server](#creating-an-express-server)
- [HTTP Methods and Routes](#http-methods-and-routes)
- [Sending Data with GET Requests](#sending-data-with-get-requests)

## Code Conventions

Following consistent code conventions improves code quality and maintainability. In modern JavaScript development, tools like ESLint help enforce these conventions.

### Strict Mode

Always use strict mode to catch common coding mistakes and prevent unsafe actions:

```javascript
"use strict";

// This will throw an error in strict mode
x = 3.14; // Error: x is not defined
```

Or in ES modules (where strict mode is enabled by default):

```javascript
// Strict mode is automatically enabled
export const myFunction = () => {
  // Code here runs in strict mode
};
```

### ESLint Configuration

ESLint provides automated code checking to enforce style rules. Example `.eslintrc.json`:

```json
{
  "env": {
    "node": true,
    "es2021": true
  },
  "extends": "eslint:recommended",
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "rules": {
    "indent": ["error", 2],
    "linebreak-style": ["error", "unix"],
    "quotes": ["error", "single"],
    "semi": ["error", "always"]
  }
}
```

Running ESLint:

```bash
npx eslint yourfile.js
```

## Functions in JavaScript

JavaScript offers multiple ways to define and use functions.

### Function Declaration

```javascript
function add(a, b) {
  return a + b;
}
```

- Hoisted (accessible before declaration)
- Clear syntax for named functions

### Function Expression

```javascript
const subtract = function(a, b) {
  return a - b;
};
```

- Not hoisted
- Can be anonymous or named
- Can be assigned to variables

### Arrow Functions

```javascript
const multiply = (a, b) => a * b;

// Multiple statements need curly braces
const divide = (a, b) => {
  if (b === 0) throw new Error("Division by zero");
  return a / b;
};
```

- More concise syntax
- Lexically bind `this`
- Implicit return when no curly braces

### Callback Functions

Callbacks are functions passed as arguments to other functions:

```javascript
// Function that accepts a callback
function fetchData(callback) {
  // Simulating async operation
  setTimeout(() => {
    const data = { name: "John", age: 30 };
    callback(data);
  }, 1000);
}

// Using the function with a callback
fetchData((data) => {
  console.log("Data received:", data);
});
```

Different callback syntaxes:

```javascript
// Inline anonymous function
button.addEventListener("click", function() {
  console.log("Button clicked!");
});

// Arrow function
button.addEventListener("click", () => console.log("Button clicked!"));

// Named function reference
function handleClick() {
  console.log("Button clicked!");
}
button.addEventListener("click", handleClick);
```

## Package Management with NPM

NPM (Node Package Manager) is the standard package manager for Node.js.

### Basic NPM Commands

```bash
# Initialize a new project
npm init

# Initialize with defaults
npm init -y

# Install a package
npm install express

# Install a development dependency
npm install --save-dev nodemon

# Install a package globally
npm install -g eslint

# Run a script defined in package.json
npm run start
```

### package.json

The `package.json` file is the heart of a Node.js project:

```json
{
  "name": "my-node-app",
  "version": "1.0.0",
  "description": "My first Node.js application",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "lint": "eslint ."
  },
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "nodemon": "^2.0.22",
    "eslint": "^8.40.0"
  }
}
```

Key sections include:
- **name, version, description**: Project metadata
- **main**: Entry point file
- **scripts**: Custom commands to run with `npm run <script-name>`
- **dependencies**: Production dependencies
- **devDependencies**: Development-only dependencies

### node_modules

The `node_modules` folder contains all installed packages. It should never be committed to version control - use `.gitignore` to exclude it:

```
# .gitignore
node_modules/
.env
```

## Creating an Express Server

Express is a minimal and flexible Node.js web application framework.

### Installing Express

```bash
npm install express
```

### Basic Express Server

```javascript
// Import express module
import express from 'express';

// Create an express application
const app = express();

// Define the port
const PORT = process.env.PORT || 3000;

// Create a route
app.get('/', (req, res) => {
  res.send('Hello, Express!');
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

For CommonJS (older Node.js versions):

```javascript
const express = require('express');
const app = express();
```

### Middleware

Express middleware functions have access to the request and response objects:

```javascript
// Simple logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next(); // Pass control to the next middleware
});

// Middleware for parsing JSON
app.use(express.json());

// Middleware for parsing URL-encoded data
app.use(express.urlencoded({ extended: true }));
```

## HTTP Methods and Routes

Express provides methods corresponding to HTTP verbs for defining routes.

### Basic Routing

```javascript
// GET request to retrieve data
app.get('/users', (req, res) => {
  // Logic to get all users
  res.json(users);
});

// GET request with URL parameter
app.get('/users/:id', (req, res) => {
  const userId = req.params.id;
  // Logic to get user by ID
  res.json(user);
});

// POST request to create data
app.post('/users', (req, res) => {
  const newUser = req.body;
  // Logic to create user
  res.status(201).json(newUser);
});

// PUT request to update data
app.put('/users/:id', (req, res) => {
  const userId = req.params.id;
  const userData = req.body;
  // Logic to update user
  res.json(updatedUser);
});

// DELETE request to remove data
app.delete('/users/:id', (req, res) => {
  const userId = req.params.id;
  // Logic to delete user
  res.status(204).send();
});
```

### Route Organization

Routes should be organized from most specific to least specific:

```javascript
// Most specific route first
app.get('/products/:id/reviews', (req, res) => {
  // Get reviews for a specific product
});

// Middle specificity
app.get('/products/:id', (req, res) => {
  // Get a specific product
});

// Least specific route last
app.get('/products', (req, res) => {
  // Get all products
});
```

## Sending Data with GET Requests

GET requests can include data through query parameters or route parameters.

### Query Parameters

Query parameters appear after the `?` in the URL:

```
GET /products?category=electronics&sort=price
```

Accessing query parameters in Express:

```javascript
app.get('/products', (req, res) => {
  const category = req.query.category;
  const sortBy = req.query.sort;
  
  console.log(`Category: ${category}, Sort by: ${sortBy}`);
  
  // Logic to filter and sort products
  res.json(filteredProducts);
});
```

### Route Parameters

Route parameters are segments of the URL path denoted by a colon:

```
GET /products/42
```

Accessing route parameters in Express:

```javascript
app.get('/products/:id', (req, res) => {
  const productId = req.params.id;
  
  console.log(`Product ID: ${productId}`);
  
  // Logic to find product by ID
  res.json(product);
});
```

### Multiple Parameters

You can use multiple route parameters and query parameters together:

```
GET /users/123/orders/456?format=detailed
```

```javascript
app.get('/users/:userId/orders/:orderId', (req, res) => {
  const userId = req.params.userId;
  const orderId = req.params.orderId;
  const format = req.query.format;
  
  // Logic to find order
  res.json(order);
});
```

### Sending Structured Data

Always use `res.json()` for sending structured data:

```javascript
app.get('/api/products', (req, res) => {
  const products = [
    { id: 1, name: 'Laptop', price: 999.99 },
    { id: 2, name: 'Smartphone', price: 699.99 }
  ];
  
  res.json(products);
});
```

---

[<- Back to Main Note](./README.md) | [Next: Loop Methods ->](./03-loop-methods.md)
