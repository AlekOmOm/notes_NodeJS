# 1. Introduction to Node.js 🌟

[<- Back to Home](./README.md) | [Next: First Server ->](./02-first-server.md)

## Table of Contents

- [What is Node.js?](#what-is-nodejs)
- [JavaScript Variables and Data Types](#javascript-variables-and-data-types)
- [REST API Conventions](#rest-api-conventions)
- [Clean Code Principles](#clean-code-principles)
- [Working with Git](#working-with-git)

## What is Node.js?

Node.js is a JavaScript runtime built on Chrome's V8 JavaScript engine that allows you to run JavaScript code on the server side. Unlike traditional JavaScript that runs in browsers, Node.js enables JavaScript to run on servers, creating a unified language across the full stack.

### Key Characteristics of Node.js

- **Non-blocking I/O**: Node.js uses an event-driven, non-blocking I/O model making it lightweight and efficient.
- **Single-threaded**: Uses an event loop to handle asynchronous operations efficiently.
- **NPM (Node Package Manager)**: Provides access to the world's largest software registry.
- **Cross-platform**: Runs on Windows, Linux, Unix, macOS, etc.

### Running Node.js Files

To run a JavaScript file with Node.js:

```javascript
// hello.js
console.log("Hello, Node.js!");
```

Execute in terminal:
```bash
node hello.js
```

## JavaScript Variables and Data Types

JavaScript has various data types that form the building blocks of your applications.

### Variable Declaration

```javascript
// Constant (use whenever possible)
const PI = 3.14159;

// Variable (can be reassigned)
let count = 0;
count += 1;

// Avoid using var (function-scoped, hoisted)
var oldWay = "outdated"; // Avoid this
```

### Primitive Data Types

1. **Number**
   ```javascript
   const integer = 42;
   const float = 3.14;
   const scientific = 1.23e6; // 1,230,000
   ```

2. **String**
   ```javascript
   const single = 'Hello';
   const double = "World";
   const template = `Hello ${double}`; // Template literals for interpolation
   ```

3. **Boolean**
   ```javascript
   const isTrue = true;
   const isFalse = false;
   ```

4. **Null & Undefined**
   ```javascript
   const emptyValue = null; // Intentional absence of value
   let undefinedVar; // Value not yet assigned
   ```

5. **Symbol** (ES6)
   ```javascript
   const uniqueKey = Symbol('description');
   ```

6. **BigInt** (ES2020)
   ```javascript
   const bigNumber = 9007199254740991n;
   ```

### Reference Data Types

1. **Object**
   ```javascript
   const person = {
     name: "John",
     age: 30,
     greet() {
       return `Hello, my name is ${this.name}`;
     }
   };
   ```

2. **Array**
   ```javascript
   const fruits = ["apple", "banana", "cherry"];
   const mixed = [1, "two", { three: 3 }];
   ```

3. **Function**
   ```javascript
   function add(a, b) {
     return a + b;
   }
   const multiply = (a, b) => a * b;
   ```

### Type Coercion

JavaScript has implicit type coercion which can lead to unexpected results:

```javascript
console.log(5 + "5"); // "55" (string concatenation)
console.log(5 - "5"); // 0 (numeric subtraction)
console.log("5" == 5); // true (loose equality)
console.log("5" === 5); // false (strict equality)
```

**Best practice**: Always use strict equality (`===` and `!==`) to avoid type coercion issues.

## REST API Conventions

Representational State Transfer (REST) is an architectural style for designing networked applications. The course follows three key conventions for REST APIs:

### 1. Using the Right HTTP Methods

Use HTTP methods that match the CRUD operations you're performing:

| HTTP Method | CRUD Operation | Description |
|-------------|---------------|-------------|
| GET | Read | Retrieve resources without side effects |
| POST | Create | Create new resources |
| PUT | Update | Replace an entire resource |
| PATCH | Update | Partially update a resource |
| DELETE | Delete | Remove a resource |

### 2. Endpoint Ordering

Organize your endpoints from most specific to least specific to prevent routing conflicts:

```javascript
// Correct ordering (most specific first)
app.get("/wines/:id/reviews", getWineReviews);
app.get("/wines/:id", getWineById);
app.get("/wines", getAllWines);

// Incorrect (would never reach individual wines)
app.get("/wines", getAllWines);
app.get("/wines/:id", getWineById); // Would never reach this route
```

### 3. Resource Naming

Use resource names that reflect collections in your system:

- **Use nouns, not verbs**: `/wines` not `/getWines`
- **Use plural nouns**: `/wines` not `/wine`
- **Use resource hierarchy**: `/wines/42/reviews` for nested resources
- **Use kebab-case for multi-word resources**: `/wine-varieties` not `/wine_varieties`

Example of a well-designed wine API:

```
GET /wines - List all wines
GET /wines/42 - Get wine with ID 42
POST /wines - Create a new wine
PUT /wines/42 - Update wine with ID 42
DELETE /wines/42 - Delete wine with ID 42
GET /wines/42/reviews - Get all reviews for wine with ID 42
```

## Clean Code Principles

Clean code is essential for maintainability and collaboration. Key principles include:

### Meaningful Names

```javascript
// Bad
const d = new Date();
const x = calculateTotal(items);

// Good
const currentDate = new Date();
const totalPrice = calculateTotal(items);
```

### Functions Should Do One Thing

```javascript
// Bad
function processUserData(user) {
  validateUser(user);
  saveUserToDatabase(user);
  sendWelcomeEmail(user);
}

// Good
function processUserData(user) {
  validateUser(user);
  const savedUser = saveUserToDatabase(user);
  notifyUser(savedUser);
}
```

### Comments Only When Necessary

Code should be self-documenting:

```javascript
// Bad
// Check if user is adult
if (user.age >= 18) { ... }

// Good (self-explanatory)
if (user.isAdult()) { ... }

// Good (complex logic needs explanation)
// Hash must begin with three zeros to be valid in our consensus algorithm
if (blockHash.startsWith("000")) { ... }
```

### Error Handling

```javascript
// Bad
try {
  readFileAndProcess();
} catch (error) {
  console.log("Error");
}

// Good
try {
  readFileAndProcess();
} catch (error) {
  logger.error("Failed to process file", { error, path: filePath });
  throw new ApplicationError("File processing failed", { cause: error });
}
```

## Working with Git

Git is essential for version control in development projects.

### Basic Git Commands

```bash
# Initialize a repository
git init

# Clone an existing repository
git clone https://github.com/user/repository.git

# Check status
git status

# Add files to staging
git add filename
git add .  # Add all changes

# Commit changes
git commit -m "Descriptive commit message"

# Push changes to remote
git push origin main

# Pull latest changes
git pull

# Create and switch to a new branch
git checkout -b feature-branch

# Switch between branches
git checkout branch-name
```

### Git Best Practices

1. **Commit often** with clear, descriptive messages
2. **Pull before push** to avoid merge conflicts
3. **Use branches** for new features or bug fixes
4. **Review your changes** before committing
5. **Use .gitignore** to exclude unnecessary files (node_modules, .env, etc.)

---

[<- Back to Main Note](./README.md) | [Next: First Server ->](./02-first-server.md)
