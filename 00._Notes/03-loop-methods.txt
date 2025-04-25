# 3. Loop Methods and REST API Development 🔄

[<- Back to First Server with Node.js](./02-first-server.md) | [Next: HTML and Time ->](./04-html-time.md)

## Table of Contents

- [Nodemon for Development](#nodemon-for-development)
- [Modern Loop Methods in JavaScript](#modern-loop-methods-in-javascript)
- [Building a CRUDable REST API](#building-a-crudable-rest-api)
- [Anatomy of a URL](#anatomy-of-a-url)
- [Sending Data to the Server](#sending-data-to-the-server)
- [Serving HTML in Express](#serving-html-in-express)

## Nodemon for Development

Nodemon is a utility that monitors changes in your source code and automatically restarts your server, making development more efficient.

### Installation

```bash
# Local installation (recommended for projects)
npm install --save-dev nodemon

# Global installation
npm install -g nodemon
```

### Using Nodemon

```bash
# Run a script with nodemon
nodemon app.js

# Run with specific file extensions to watch
nodemon --ext js,json,html app.js
```

### Nodemon Configuration

Add a script to your `package.json`:

```json
{
  "scripts": {
    "dev": "nodemon app.js"
  }
}
```

Create a `nodemon.json` for more complex configurations:

```json
{
  "watch": ["src", "config"],
  "ext": "js,json,html",
  "ignore": ["node_modules", "public/generated"],
  "env": {
    "NODE_ENV": "development"
  }
}
```

### Limitations

- Not recommended for production environments
- May consume more resources than running Node directly
- Can cause issues with certain types of applications that manage their own process lifecycle

## Modern Loop Methods in JavaScript

Modern JavaScript emphasizes functional programming approaches to array operations instead of traditional `for` loops.

### map()

Transforms each element of an array and returns a new array:

```javascript
const numbers = [1, 2, 3, 4];
const doubled = numbers.map(num => num * 2);
// doubled = [2, 4, 6, 8]
```

Use `map` when you need to:
- Transform each item in an array
- Create a new array of the same length
- Convert data from one format to another

### filter()

Creates a new array with elements that pass a test:

```javascript
const numbers = [1, 2, 3, 4, 5, 6];
const evenNumbers = numbers.filter(num => num % 2 === 0);
// evenNumbers = [2, 4, 6]
```

Use `filter` when you need to:
- Remove items that don't meet certain criteria
- Find all matches for a condition
- Validate data

### reduce()

Reduces an array to a single value by applying a function to each element:

```javascript
const numbers = [1, 2, 3, 4];
const sum = numbers.reduce((total, num) => total + num, 0);
// sum = 10
```

Use `reduce` when you need to:
- Calculate a single value from an array
- Transform an array into a different data structure
- Combine operations that would otherwise require multiple array iterations

### find()

Returns the first element that matches a condition:

```javascript
const users = [
  { id: 1, name: 'Alice' },
  { id: 2, name: 'Bob' }
];
const bob = users.find(user => user.name === 'Bob');
// bob = { id: 2, name: 'Bob' }
```

### forEach()

Executes a function for each array element (doesn't return a new array):

```javascript
const numbers = [1, 2, 3];
numbers.forEach(num => console.log(num));
// Logs: 1, 2, 3
```

### Chaining Methods

Methods can be chained for complex operations:

```javascript
const numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

const result = numbers
  .filter(num => num % 2 === 0)   // Keep even numbers
  .map(num => num * 10)           // Multiply by 10
  .reduce((sum, num) => sum + num, 0); // Calculate sum

// result = 300 (from 2+4+6+8+10 -> 20+40+60+80+100 -> 300)
```

### Avoiding Side Effects

Keep operations functional by avoiding side effects:

```javascript
// Bad (with side effects)
const numbers = [1, 2, 3];
let total = 0;
numbers.forEach(num => {
  total += num;
});

// Good (functional approach)
const numbers = [1, 2, 3];
const total = numbers.reduce((sum, num) => sum + num, 0);
```

## Building a CRUDable REST API

A CRUDable REST API supports all basic data operations: Create, Read, Update, and Delete.

### API Structure

```javascript
import express from 'express';
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware for parsing JSON
app.use(express.json());

// In-memory data store (replace with database in production)
let products = [
  { id: 1, name: 'Laptop', price: 999.99 },
  { id: 2, name: 'Smartphone', price: 699.99 }
];

// Create - POST
app.post('/api/products', (req, res) => {
  const newProduct = {
    id: products.length + 1,
    name: req.body.name,
    price: req.body.price
  };
  
  products.push(newProduct);
  res.status(201).json(newProduct);
});

// Read (all) - GET
app.get('/api/products', (req, res) => {
  res.json(products);
});

// Read (one) - GET
app.get('/api/products/:id', (req, res) => {
  const productId = parseInt(req.params.id);
  const product = products.find(p => p.id === productId);
  
  if (!product) {
    return res.status(404).json({ message: 'Product not found' });
  }
  
  res.json(product);
});

// Update - PUT
app.put('/api/products/:id', (req, res) => {
  const productId = parseInt(req.params.id);
  const productIndex = products.findIndex(p => p.id === productId);
  
  if (productIndex === -1) {
    return res.status(404).json({ message: 'Product not found' });
  }
  
  const updatedProduct = {
    id: productId,
    name: req.body.name,
    price: req.body.price
  };
  
  products[productIndex] = updatedProduct;
  res.json(updatedProduct);
});

// Delete - DELETE
app.delete('/api/products/:id', (req, res) => {
  const productId = parseInt(req.params.id);
  const initialLength = products.length;
  
  products = products.filter(p => p.id !== productId);
  
  if (products.length === initialLength) {
    return res.status(404).json({ message: 'Product not found' });
  }
  
  res.status(204).send();
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### HTTP Status Codes

Proper status codes improve API usability:

| Status Code | Meaning | Example Use |
|-------------|---------|-------------|
| 200 | OK | Successful GET requests |
| 201 | Created | Successful POST requests |
| 204 | No Content | Successful DELETE requests |
| 400 | Bad Request | Invalid data submitted |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Authenticated but not authorized |
| 404 | Not Found | Resource doesn't exist |
| 500 | Server Error | Something went wrong on the server |

### Data Validation

Always validate user input before processing:

```javascript
app.post('/api/products', (req, res) => {
  // Validation
  const { name, price } = req.body;
  
  if (!name || name.trim() === '') {
    return res.status(400).json({ message: 'Name is required' });
  }
  
  if (typeof price !== 'number' || price <= 0) {
    return res.status(400).json({ message: 'Price must be a positive number' });
  }
  
  // Process the valid data
  const newProduct = {
    id: products.length + 1,
    name: name.trim(),
    price
  };
  
  products.push(newProduct);
  res.status(201).json(newProduct);
});
```

## Anatomy of a URL

Understanding URL structure is essential for web development.

### URL Components

```
https://www.example.com:443/path/to/resource?name=value&sort=desc#section
|      |     |       |   |               |                  |
|      |     |       |   |               |                  Fragment
|      |     |       |   |               Query parameters
|      |     |       |   Path
|      |     |       Port
|      |     Domain
|      Subdomain
Protocol
```

### URL Components Explained

1. **Protocol**: `https://` - Defines how data is transmitted (HTTP, HTTPS, FTP, etc.)
2. **Subdomain**: `www` - A subdivision of the main domain
3. **Domain**: `example.com` - The human-readable address of the server
4. **Port**: `:443` - The specific communication endpoint (default: 80 for HTTP, 443 for HTTPS)
5. **Path**: `/path/to/resource` - Identifies the specific resource on the server
6. **Query Parameters**: `?name=value&sort=desc` - Additional data sent to the server
7. **Fragment**: `#section` - Points to a specific part of the page (client-side only)

### Working with URL Components in Express

```javascript
app.get('/products/:category/:id', (req, res) => {
  // Path parameters
  const category = req.params.category;
  const productId = req.params.id;
  
  // Query parameters
  const sortBy = req.query.sort || 'name';
  const order = req.query.order || 'asc';
  
  // URL info
  const protocol = req.protocol; // 'http' or 'https'
  const host = req.get('host'); // e.g., 'localhost:3000'
  const originalUrl = req.originalUrl; // Full URL path + query
  
  // Response
  res.json({
    requestInfo: {
      category,
      productId,
      sortBy,
      order,
      fullUrl: `${protocol}://${host}${originalUrl}`
    },
    // Actual product data would be here
  });
});
```

## Sending Data to the Server

There are multiple ways to send data from a client to a server.

### URL Parameters

```
GET /api/products/electronics/42
```

```javascript
app.get('/api/products/:category/:id', (req, res) => {
  const category = req.params.category;
  const productId = req.params.id;
  
  // Use category and productId in your logic
});
```

### Query Parameters

```
GET /api/products?category=electronics&sort=price&order=desc
```

```javascript
app.get('/api/products', (req, res) => {
  const category = req.query.category;
  const sortBy = req.query.sort;
  const order = req.query.order;
  
  // Filter and sort products
});
```

### Request Body (JSON)

```
POST /api/products
Content-Type: application/json

{
  "name": "Wireless Headphones",
  "price": 149.99,
  "category": "audio"
}
```

```javascript
// Middleware to parse JSON bodies
app.use(express.json());

app.post('/api/products', (req, res) => {
  const newProduct = req.body;
  
  // Process the data
});
```

### Form Data

```
POST /api/products
Content-Type: application/x-www-form-urlencoded

name=Wireless+Headphones&price=149.99&category=audio
```

```javascript
// Middleware to parse URL-encoded form data
app.use(express.urlencoded({ extended: true }));

app.post('/api/products', (req, res) => {
  const newProduct = req.body;
  
  // Process the data
});
```

### Multipart Form Data (File Uploads)

For file uploads, you'll need a library like `multer`:

```bash
npm install multer
```

```javascript
import multer from 'multer';

// Configure storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  }
});

const upload = multer({ storage });

// Single file upload
app.post('/api/products/:id/image', upload.single('productImage'), (req, res) => {
  const productId = req.params.id;
  const imageFile = req.file;
  
  // Process the file and update the product
  res.json({
    message: 'Image uploaded successfully',
    file: imageFile.filename
  });
});

// Multiple file upload
app.post('/api/products/:id/gallery', upload.array('images', 5), (req, res) => {
  const productId = req.params.id;
  const imageFiles = req.files;
  
  // Process the files
  res.json({
    message: 'Gallery images uploaded successfully',
    files: imageFiles.map(file => file.filename)
  });
});
```

## Serving HTML in Express

Express can serve HTML files as well as API endpoints.

### Serving Static HTML Files

```javascript
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const app = express();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Serve static files from the 'public' directory
app.use(express.static(path.join(__dirname, 'public')));

// Define a route to serve a specific HTML file
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/about', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'about.html'));
});

app.listen(3000, () => {
  console.log('Server is running on port 3000');
});
```

### Sending Dynamic HTML

```javascript
app.get('/product/:id', (req, res) => {
  const productId = req.params.id;
  const product = products.find(p => p.id === parseInt(productId));
  
  if (!product) {
    return res.status(404).send('<h1>Product Not Found</h1>');
  }
  
  const html = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>${product.name}</title>
      <link rel="stylesheet" href="/css/styles.css">
    </head>
    <body>
      <header>
        <h1>Product Details</h1>
      </header>
      <main>
        <h2>${product.name}</h2>
        <p>Price: $${product.price.toFixed(2)}</p>
        <p>ID: ${product.id}</p>
      </main>
      <footer>
        <p>&copy; 2025 My Store</p>
      </footer>
      <script src="/js/main.js"></script>
    </body>
    </html>
  `;
  
  res.send(html);
});
```

### Using Template Engines

For more complex HTML generation, template engines are preferable:

```bash
npm install ejs
```

```javascript
// Set up EJS as the view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

app.get('/products', (req, res) => {
  res.render('products', {
    pageTitle: 'Product List',
    products: products
  });
});
```

Example EJS template (`views/products.ejs`):

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title><%= pageTitle %></title>
  <link rel="stylesheet" href="/css/styles.css">
</head>
<body>
  <header>
    <h1><%= pageTitle %></h1>
  </header>
  <main>
    <ul class="product-list">
      <% products.forEach(product => { %>
        <li class="product-item">
          <h2><%= product.name %></h2>
          <p class="price">$<%= product.price.toFixed(2) %></p>
          <a href="/product/<%= product.id %>">View Details</a>
        </li>
      <% }); %>
    </ul>
  </main>
  <footer>
    <p>&copy; 2025 My Store</p>
  </footer>
  <script src="/js/main.js"></script>
</body>
</html>
```

---

[<- Back to Main Note](./README.md) | [Next: HTML and Time ->](./04-html-time.md)
