# 4. HTML and Time in JavaScript ⏰

[<- Back to Main Note](./README.md) | [Next: Export and Import ->](./05-export-import.md)

## Table of Contents

- [Working with Time in JavaScript](#working-with-time-in-javascript)
- [Deployment Strategies](#deployment-strategies)
- [Fetch API for Client-Server Communication](#fetch-api-for-client-server-communication)
- [Building a Full CRUDable REST API](#building-a-full-crudable-rest-api)
- [Error Handling](#error-handling)

## Working with Time in JavaScript

JavaScript provides several ways to work with dates and time.

### Creating Date Objects

```javascript
// Current date and time
const now = new Date();

// Specific date and time (year, month (0-11), day, hour, minute, second, millisecond)
const specificDate = new Date(2023, 5, 15, 14, 30, 0); // June 15, 2023, 14:30:00

// From ISO string
const isoDate = new Date('2023-06-15T14:30:00Z');

// From timestamp (milliseconds since January 1, 1970)
const timestampDate = new Date(1686838200000);
```

### Getting Date Components

```javascript
const now = new Date();

// Basic components
const year = now.getFullYear(); // e.g., 2023
const month = now.getMonth(); // 0-11 (0 = January)
const day = now.getDate(); // 1-31
const hours = now.getHours(); // 0-23
const minutes = now.getMinutes(); // 0-59
const seconds = now.getSeconds(); // 0-59
const millis = now.getMilliseconds(); // 0-999

// Day of week
const dayOfWeek = now.getDay(); // 0-6 (0 = Sunday)

// Timestamp (milliseconds since epoch)
const timestamp = now.getTime();

// Get timezone offset in minutes
const timezoneOffset = now.getTimezoneOffset();
```

### Formatting Dates

Standard ways to format dates:

```javascript
const date = new Date('2023-06-15T14:30:00Z');

// Built-in methods
date.toString(); // "Thu Jun 15 2023 16:30:00 GMT+0200 (Central European Summer Time)"
date.toDateString(); // "Thu Jun 15 2023"
date.toTimeString(); // "16:30:00 GMT+0200 (Central European Summer Time)"
date.toISOString(); // "2023-06-15T14:30:00.000Z"
date.toUTCString(); // "Thu, 15 Jun 2023 14:30:00 GMT"
date.toLocaleDateString(); // "6/15/2023" (depends on locale)
date.toLocaleTimeString(); // "4:30:00 PM" (depends on locale)
date.toLocaleString(); // "6/15/2023, 4:30:00 PM" (depends on locale)
```

Using locale options for better formatting:

```javascript
const date = new Date('2023-06-15T14:30:00Z');

// Format with locale and options
const options = { 
  weekday: 'long', // 'long', 'short', 'narrow'
  year: 'numeric', 
  month: 'long', // 'numeric', '2-digit', 'long', 'short', 'narrow'
  day: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  timeZoneName: 'short' // 'short', 'long'
};

// Format with US English locale
console.log(date.toLocaleString('en-US', options));
// Thursday, June 15, 2023, 02:30:00 PM GMT+2

// Format with German locale
console.log(date.toLocaleString('de-DE', options));
// Donnerstag, 15. Juni 2023, 14:30:00 GMT+2
```

### Manipulating Dates

```javascript
const date = new Date('2023-06-15T14:30:00Z');

// Setting components
date.setFullYear(2024);
date.setMonth(0); // January
date.setDate(1);
date.setHours(12);
date.setMinutes(0);
date.setSeconds(0);

// Adding time
// Add one day
date.setDate(date.getDate() + 1);

// Add one week
date.setDate(date.getDate() + 7);

// Add one month (careful with month boundaries)
date.setMonth(date.getMonth() + 1);

// Add one year
date.setFullYear(date.getFullYear() + 1);

// Add hours/minutes/seconds
date.setHours(date.getHours() + 2); // Add 2 hours
date.setMinutes(date.getMinutes() + 30); // Add 30 minutes
date.setSeconds(date.getSeconds() + 15); // Add 15 seconds
```

### Date Arithmetic

```javascript
const start = new Date('2023-06-15T10:00:00Z');
const end = new Date('2023-06-15T16:30:00Z');

// Calculate difference in milliseconds
const diffMs = end - start; // 23400000 ms

// Convert to more readable units
const diffSeconds = Math.floor(diffMs / 1000);
const diffMinutes = Math.floor(diffMs / (1000 * 60));
const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
```

### Working with Timers

```javascript
// Execute once after a delay
const timeoutId = setTimeout(() => {
  console.log('Executed after 2 seconds');
}, 2000);

// Cancel the timeout if needed
clearTimeout(timeoutId);

// Execute repeatedly at an interval
const intervalId = setInterval(() => {
  console.log('Executed every 1 second');
}, 1000);

// Stop the interval
clearInterval(intervalId);
```

### Date Libraries

For more complex date operations, consider using libraries:

- **date-fns**: Functional, modular approach to date manipulation
- **luxon**: Modern, powerful library from the former maintainer of Moment.js
- **Day.js**: Minimalist alternative to Moment.js with compatible API

```bash
npm install date-fns
```

```javascript
import { format, addDays, differenceInDays } from 'date-fns';

const today = new Date();
const nextWeek = addDays(today, 7);

console.log(format(today, 'PPP')); // "June 15th, 2023"
console.log(differenceInDays(nextWeek, today)); // 7
```

## Deployment Strategies

Deploying Node.js applications requires careful planning and execution.

### Preparing for Deployment

1. **Environment Variables**: Use `.env` files for local development but never commit them
2. **Configuration**: Set up config files for different environments
3. **Dependencies**: Make sure all dependencies are properly listed in `package.json`
4. **Scripts**: Create proper npm scripts for build and start
5. **Testing**: Run tests before deployment

```javascript
// config.js - Example configuration based on environment
export const config = {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  dbUrl: process.env.DATABASE_URL,
  jwtSecret: process.env.JWT_SECRET,
  cors: {
    origin: process.env.NODE_ENV === 'production' 
      ? process.env.ALLOWED_ORIGIN 
      : '*'
  }
};
```

### Platform as a Service (PaaS)

PaaS providers like Heroku, Render, or Fly.io make deployment simple:

#### Deploying to Render

1. Create `render.yaml` file:

```yaml
services:
  - type: web
    name: my-node-app
    env: node
    buildCommand: npm install
    startCommand: npm start
    envVars:
      - key: NODE_ENV
        value: production
      - key: PORT
        value: 10000
```

2. Connect your GitHub repository to Render
3. Configure environment variables in the Render dashboard

#### Deploying to Vercel

Vercel is excellent for frontend or Next.js applications:

1. Create a `vercel.json` file for a Node.js API:

```json
{
  "version": 2,
  "builds": [
    {
      "src": "app.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "app.js"
    }
  ]
}
```

2. Install Vercel CLI: `npm install -g vercel`
3. Deploy: `vercel`

### Docker Containers

For more control, use Docker:

1. Create a `Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

ENV PORT=3000
ENV NODE_ENV=production

EXPOSE 3000

CMD ["node", "app.js"]
```

2. Build and run:

```bash
docker build -t my-node-app .
docker run -p 3000:3000 my-node-app
```

### Continuous Integration/Deployment

Set up GitHub Actions for CI/CD:

```yaml
# .github/workflows/main.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Use Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm test
        
  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to production
        uses: some-deployment-action@v1
        with:
          api-key: ${{ secrets.DEPLOY_API_KEY }}
```

## Fetch API for Client-Server Communication

The Fetch API is the modern way to make HTTP requests in JavaScript.

### Basic GET Request

```javascript
fetch('https://api.example.com/products')
  .then(response => {
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    return response.json();
  })
  .then(data => {
    console.log('Products:', data);
    // Process the data
  })
  .catch(error => {
    console.error('Fetch error:', error);
  });
```

### Using Async/Await

```javascript
async function getProducts() {
  try {
    const response = await fetch('https://api.example.com/products');
    
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    
    const data = await response.json();
    console.log('Products:', data);
    return data;
  } catch (error) {
    console.error('Fetch error:', error);
    throw error; // Re-throw to handle at caller level if needed
  }
}

// Using the function
getProducts()
  .then(products => {
    // Do something with products
  })
  .catch(error => {
    // Handle errors
  });
```

### POST Request

```javascript
async function createProduct(product) {
  try {
    const response = await fetch('https://api.example.com/products', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(product)
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Error creating product:', error);
    throw error;
  }
}

// Using the function
const newProduct = {
  name: 'Wireless Headphones',
  price: 149.99,
  category: 'audio'
};

createProduct(newProduct)
  .then(createdProduct => {
    console.log('Created:', createdProduct);
  })
  .catch(error => {
    // Handle errors
  });
```

### PUT and DELETE Requests

```javascript
// PUT request to update a product
async function updateProduct(id, updates) {
  const response = await fetch(`https://api.example.com/products/${id}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(updates)
  });
  
  if (!response.ok) {
    throw new Error(`HTTP error! Status: ${response.status}`);
  }
  
  return await response.json();
}

// DELETE request to remove a product
async function deleteProduct(id) {
  const response = await fetch(`https://api.example.com/products/${id}`, {
    method: 'DELETE'
  });
  
  if (!response.ok) {
    throw new Error(`HTTP error! Status: ${response.status}`);
  }
  
  // For 204 No Content responses
  if (response.status === 204) {
    return true;
  }
  
  return await response.json(); // Some APIs return data on DELETE
}
```

### Fetch with Request Options

More advanced Fetch options:

```javascript
const fetchOptions = {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token,
    'X-Custom-Header': 'CustomValue'
  },
  body: JSON.stringify(data),
  mode: 'cors', // 'cors', 'no-cors', 'same-origin'
  credentials: 'include', // 'include', 'same-origin', 'omit'
  cache: 'no-cache', // 'default', 'no-cache', 'reload', 'force-cache', 'only-if-cached'
  redirect: 'follow', // 'follow', 'error', 'manual'
  referrerPolicy: 'no-referrer', // 'no-referrer', 'no-referrer-when-downgrade', 'origin', 'origin-when-cross-origin', 'same-origin', 'strict-origin', 'strict-origin-when-cross-origin', 'unsafe-url'
  integrity: 'sha256-abcdef...' // Subresource Integrity value
};

fetch('https://api.example.com/data', fetchOptions)
  .then(response => response.json())
  .then(data => console.log(data))
  .catch(error => console.error('Error:', error));
```

### Uploading Files with Fetch

```javascript
async function uploadFile(file) {
  const formData = new FormData();
  formData.append('file', file);
  
  const response = await fetch('https://api.example.com/upload', {
    method: 'POST',
    body: formData,
    // Don't set Content-Type header - browser will set it with boundary
  });
  
  if (!response.ok) {
    throw new Error(`Upload failed: ${response.status}`);
  }
  
  return await response.json();
}

// Usage in a form
document.querySelector('form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const fileInput = document.querySelector('input[type="file"]');
  if (fileInput.files.length > 0) {
    try {
      const result = await uploadFile(fileInput.files[0]);
      console.log('Upload success:', result);
    } catch (error) {
      console.error('Upload error:', error);
    }
  }
});
```

## Building a Full CRUDable REST API

Let's create a complete REST API for a products resource:

### Server Setup

```javascript
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));

// Mock database
let products = [
  { id: 1, name: 'Laptop', price: 999.99, category: 'electronics' },
  { id: 2, name: 'Smartphone', price: 699.99, category: 'electronics' },
  { id: 3, name: 'Coffee Maker', price: 79.99, category: 'home' }
];

// Routes will go here

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### API Endpoints

```javascript
// GET all products (Read)
app.get('/api/products', (req, res) => {
  // Get query parameters for filtering
  const { category, minPrice, maxPrice } = req.query;
  
  let results = [...products];
  
  // Apply filters if provided
  if (category) {
    results = results.filter(p => p.category === category);
  }
  
  if (minPrice) {
    results = results.filter(p => p.price >= parseFloat(minPrice));
  }
  
  if (maxPrice) {
    results = results.filter(p => p.price <= parseFloat(maxPrice));
  }
  
  res.json({
    count: results.length,
    data: results
  });
});

// GET single product by ID (Read)
app.get('/api/products/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const product = products.find(p => p.id === id);
  
  if (!product) {
    return res.status(404).json({ message: 'Product not found' });
  }
  
  res.json(product);
});

// POST new product (Create)
app.post('/api/products', (req, res) => {
  const { name, price, category } = req.body;
  
  // Validation
  if (!name || name.trim() === '') {
    return res.status(400).json({ message: 'Name is required' });
  }
  
  if (typeof price !== 'number' || price <= 0) {
    return res.status(400).json({ message: 'Price must be a positive number' });
  }
  
  // Find the next ID (in a real app, this would be handled by the database)
  const nextId = Math.max(...products.map(p => p.id), 0) + 1;
  
  // Create new product
  const newProduct = {
    id: nextId,
    name: name.trim(),
    price,
    category: category || 'uncategorized'
  };
  
  // Add to "database"
  products.push(newProduct);
  
  // Return the created product with 201 Created status
  res.status(201).json(newProduct);
});

// PUT update product (Update)
app.put('/api/products/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const { name, price, category } = req.body;
  
  // Find product index
  const productIndex = products.findIndex(p => p.id === id);
  
  if (productIndex === -1) {
    return res.status(404).json({ message: 'Product not found' });
  }
  
  // Validation
  if (name !== undefined && (typeof name !== 'string' || name.trim() === '')) {
    return res.status(400).json({ message: 'Name cannot be empty' });
  }
  
  if (price !== undefined && (typeof price !== 'number' || price <= 0)) {
    return res.status(400).json({ message: 'Price must be a positive number' });
  }
  
  // Update product
  const updatedProduct = {
    ...products[productIndex],
    name: name !== undefined ? name.trim() : products[productIndex].name,
    price: price !== undefined ? price : products[productIndex].price,
    category: category !== undefined ? category : products[productIndex].category
  };
  
  products[productIndex] = updatedProduct;
  
  res.json(updatedProduct);
});

// PATCH update product (Partial Update)
app.patch('/api/products/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const updates = req.body;
  
  // Find product index
  const productIndex = products.findIndex(p => p.id === id);
  
  if (productIndex === -1) {
    return res.status(404).json({ message: 'Product not found' });
  }
  
  // Validation
  if (updates.name !== undefined && (typeof updates.name !== 'string' || updates.name.trim() === '')) {
    return res.status(400).json({ message: 'Name cannot be empty' });
  }
  
  if (updates.price !== undefined && (typeof updates.price !== 'number' || updates.price <= 0)) {
    return res.status(400).json({ message: 'Price must be a positive number' });
  }
  
  // Update product
  const updatedProduct = {
    ...products[productIndex],
    ...updates,
    // Ensure name is trimmed if provided
    name: updates.name !== undefined 
      ? updates.name.trim() 
      : products[productIndex].name
  };
  
  products[productIndex] = updatedProduct;
  
  res.json(updatedProduct);
});

// DELETE product (Delete)
app.delete('/api/products/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const initialLength = products.length;
  
  // Filter out the product to delete
  products = products.filter(p => p.id !== id);
  
  // Check if a product was removed
  if (products.length === initialLength) {
    return res.status(404).json({ message: 'Product not found' });
  }
  
  // Return 204 No Content for successful deletion
  res.status(204).send();
});
```

## Error Handling

Proper error handling improves the reliability and user experience of your application.

### Error Handling Middleware

```javascript
// Define error types
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;
    
    Error.captureStackTrace(this, this.constructor);
  }
}

// Route-specific error
app.get('/api/products/:id', (req, res, next) => {
  const id = parseInt(req.params.id);
  const product = products.find(p => p.id === id);
  
  if (!product) {
    return next(new AppError('Product not found', 404));
  }
  
  res.json(product);
});

// Global error handling middleware (must be after all routes)
app.use((err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';
  
  // Logging
  console.error('ERROR:', err);
  
  // Development error response (with stack trace)
  if (process.env.NODE_ENV === 'development') {
    res.status(err.statusCode).json({
      status: err.status,
      message: err.message,
      stack: err.stack,
      error: err
    });
  } 
  // Production error response (clean)
  else {
    // Only show operational errors to the client
    if (err.isOperational) {
      res.status(err.statusCode).json({
        status: err.status,
        message: err.message
      });
    } 
    // For programming or unknown errors, don't leak error details
    else {
      res.status(500).json({
        status: 'error',
        message: 'Something went wrong'
      });
    }
  }
});

// 404 handler for undefined routes (must be after all defined routes)
app.all('*', (req, res, next) => {
  next(new AppError(`Can't find ${req.originalUrl} on this server!`, 404));
});
```

### Async Handler Utility

To avoid repetitive try-catch blocks:

```javascript
// Utility to handle async routes
const catchAsync = fn => {
  return (req, res, next) => {
    fn(req, res, next).catch(next);
  };
};

// Use it with route handlers
app.get('/api/products', catchAsync(async (req, res) => {
  // Can use await here without try-catch
  const { category } = req.query;
  
  // Simulating async database query
  const results = await findProducts(category);
  
  res.json({
    count: results.length,
    data: results
  });
}));

// Simulation of async function
async function findProducts(category) {
  // In a real app, this would query a database
  return new Promise((resolve) => {
    setTimeout(() => {
      const results = category
        ? products.filter(p => p.category === category)
        : products;
      resolve(results);
    }, 100);
  });
}
```

---

[<- Back to Main Note](./README.md) | [Next: Export and Import ->](./05-export-import.md)
