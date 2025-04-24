# 11. Client-Server Architecture in Full-Stack Applications 🏗️

[Back to Middleware and Security](./10-middleware-security.md) | [Back Home ->](./README.md)

## Table of Contents

- [Project Structure Overview](#project-structure-overview)
- [Client-Side Implementation with Svelte](#client-side-implementation-with-svelte)
- [Server-Side Variants](#server-side-variants)
- [Data Flow and Communication](#data-flow-and-communication)
- [State Management](#state-management)
- [Server-Side Rendering](#server-side-rendering)

## Project Structure Overview

The Medicine project demonstrates a comprehensive approach to full-stack development, with clear separation of concerns between client and server components. The project is organized into three main directories:

```
medicine/
├── client/                 # Svelte frontend
│   ├── src/
│   │   ├── components/     # Reusable UI components
│   │   ├── pages/          # Page components
│   │   ├── stores/         # Svelte stores
│   │   ├── util/           # Utility functions
│   │   ├── App.svelte      # Root component
│   │   └── main.js         # Entry point
│   ├── index.html          # HTML template
│   └── package.json        # Frontend dependencies
├── server/                 # Regular Express.js backend
│   ├── routers/            # Route handlers
│   ├── app.js              # Server configuration
│   └── package.json        # Backend dependencies
└── serverSSR/              # Server-side rendering backend
    ├── routers/            # Route handlers
    ├── app.js              # SSR server configuration
    └── package.json        # SSR dependencies
```

### Key Design Principles

1. **Separation of Concerns**: Clear boundaries between frontend (UI/UX) and backend (business logic/data access)
2. **Component-Based Architecture**: Modular design with reusable components
3. **Configuration Flexibility**: Environment variables and external configuration
4. **API-First Approach**: Consistent RESTful API design
5. **Multiple Deployment Options**: Support for both client-side and server-side rendering

## Client-Side Implementation with Svelte

The client-side application is built with Svelte, a modern JavaScript framework that compiles components at build time rather than using a virtual DOM at runtime.

### Svelte Project Structure

The Svelte application follows a well-organized structure:

```javascript
// main.js - Application entry point
import { mount } from 'svelte'
import './app.css'
import App from './App.svelte'

const app = mount(App, {
  target: document.getElementById('app'),
})

export default app
```

### Component Architecture

Components are organized hierarchically:

1. **App.svelte**: Root component that sets up routing
2. **Pages**: Container components for specific routes
3. **Components**: Reusable UI elements

```svelte
<!-- App.svelte - Root component with routing -->
<script>
  import { Router, Link, Route } from "svelte-routing";
  import Home from "./pages/Home/Home.svelte";
  import Pharmacy from "./pages/Pharmacy/Pharmacy.svelte";
  import About from "./pages/About/About.svelte";

  export let url = "";
</script>

<Router {url}>
  <nav>
    <Link to="/">Home</Link>
    <Link to="/pharmacy">Pharmacy</Link>
    <Link to="/about">About</Link>
  </nav>

  <div>
    <Route path="/" >
        <Home />
    </Route>
    <Route path="/about"><About /></Route>
    <Route path="/pharmacy"><Pharmacy></Pharmacy></Route>
  </div>
</Router>
```

### Component Example

The `Employees` component demonstrates how to fetch and display data from the server:

```svelte
<!-- Employees.svelte -->
<script>
    import { onMount } from "svelte";
    import { BASE_URL } from "../../stores/generalStore.js";

    let employees = $state([]);

    onMount(() => {
        fetch($BASE_URL+"/employees")
        .then((response) => response.json())
        .then((result) => {
            employees = result.data;
        });
    });
</script>

<h3>Employees Available</h3>
{#each employees as employee }
    <h4>{employee}</h4>
{/each}
```

### State Management

Svelte offers two approaches to state management, both used in the Medicine project:

1. **Component-level state**: Using Svelte's reactive variables
   ```javascript
   let employees = $state([]); // Svelte 5 syntax
   ```

2. **Application-wide state**: Using Svelte stores
   ```javascript
   // generalStore.js
   import { readable } from "svelte/store";
   export const BASE_URL = readable(import.meta.env.VITE_BASE_URL || "http://localhost:8080");
   ```

## Server-Side Variants

The Medicine project includes two server implementations, demonstrating different approaches to backend architecture.

### Standard API Server

The standard server (`server/app.js`) focuses on providing API endpoints:

```javascript
// server/app.js
import 'dotenv/config';
import express from 'express';

const app = express();

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

const PORT = Number(process.env.PORT) || 8080;
app.listen(PORT, () => console.log("Server is running on port", PORT));
```

### Server-Side Rendering Server

The SSR server (`serverSSR/app.js`) extends the standard server by adding static file serving and a catch-all route for client-side routing:

```javascript
// serverSSR/app.js
import 'dotenv/config';
import express from 'express';
import path from 'path';

const app = express();

app.use(express.json());

// Serve static files from client build
app.use(express.static(path.resolve('../client/dist/')));

// Session middleware and routers (same as standard server)
// ...

// SPA fallback route for client-side routing
app.get("/{*splat}", (req, res) => {
  res.sendFile(path.resolve('../client/dist/index.html'));
});

const PORT = Number(process.env.PORT) || 8080;
app.listen(PORT, () => console.log("Server is running on port", PORT));
```

## Data Flow and Communication

The Medicine project demonstrates effective patterns for client-server communication.

### API Communication Utilities

The project includes utility functions for standardized API calls:

```javascript
// fetch.js
export async function fetchGet(url) {
    try {
        const response = await fetch(url, {
            credentials: "include"  // Include cookies in requests
        });
        const result = await response.json();
        return result;
    } catch (error) {
        console.log(error);
    }
}

export function fetchPost(url, body) {
    return fetch(url, {
        method: "POST",
        credentials: "include",  // Include cookies in requests
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(body)
    })
    .then((response) => response.json())
    .then((result) => result)
    .catch((error) => console.log(error));
}
```

### API Endpoints

API endpoints are organized into logical groups using Express routers:

```javascript
// employeesRouter.js
import { Router } from 'express';

const router = Router();

const employees = ["Ilmer", "Homer"];

router.get("/employees", (req, res) => {
    res.send({ data: employees });
});

export default router;
```

```javascript
// pillsRouter.js
import { Router } from 'express';

const router = Router();

router.get("/pills", (req, res) => {
    res.send({ data: req.session.pills || [] });
});

router.post("/pills", (req, res) => {
    if (!req.session.pills) {
        req.session.pills = [];
    }
    req.session.pills.push(req.body);

    res.send({ data: req.session.pills });
});

export default router;
```

### Using API Data in Components

Components consume API data and update their state accordingly:

```javascript
// In Pharmacy.svelte
import { onMount } from "svelte";
import { BASE_URL } from "../../stores/generalStore.js";
import { fetchGet, fetchPost } from "../../util/fetch.js";

let pills = $state([]);

onMount(async () => {
    pills = (await fetchGet($BASE_URL+"/pills")).data;
})

async function fillPrescription() {
    fetchPost($BASE_URL+"/pills", {
        name: "Ibuprofen"
    });
    pills = (await fetchGet($BASE_URL+"/pills")).data;
}
```

## State Management

The project demonstrates several approaches to state management across the client-server boundary.

### Session-Based State

Server-side session management is implemented using `express-session`:

```javascript
// Session setup in server/app.js
import session from 'express-session';

app.use(session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false }
}));
```

This enables storing user-specific data across requests:

```javascript
// Using session in pillsRouter.js
router.post("/pills", (req, res) => {
    if (!req.session.pills) {
        req.session.pills = [];
    }
    req.session.pills.push(req.body);

    res.send({ data: req.session.pills });
});
```

### Environment Variables

Configuration management using environment variables:

```javascript
// In server/app.js
const PORT = Number(process.env.PORT) || 8080;

// In client/src/stores/generalStore.js
export const BASE_URL = readable(import.meta.env.VITE_BASE_URL || "http://localhost:8080");
```

### Cross-Origin Resource Sharing (CORS)

CORS configuration for secure cross-origin requests:

```javascript
// In server/app.js
app.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
    res.header("Access-Control-Allow-Credentials", "true");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    next();
});
```

## Server-Side Rendering

The Medicine project includes a server-side rendering implementation that offers several advantages over pure client-side rendering.

### SSR Implementation

The SSR server serves pre-built Svelte components:

```javascript
// serverSSR/app.js
// Serve static files from client build
app.use(express.static(path.resolve('../client/dist/')));

// SPA fallback route for client-side routing
app.get("/{*splat}", (req, res) => {
  res.sendFile(path.resolve('../client/dist/index.html'));
});
```

### Benefits of SSR

1. **Improved SEO**: Search engines can index fully-rendered content
2. **Faster Initial Load**: First contentful paint happens sooner
3. **Better Performance on Low-Powered Devices**: Less client-side processing
4. **Improved Accessibility**: Content available without JavaScript

### Build Pipeline for SSR

The client includes a special build-watch script for development:

```json
// client/package.json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "build-watch": "vite build --watch",
    "preview": "vite preview"
  }
}
```

This watches for changes and rebuilds the client automatically, which is then immediately picked up by the SSR server.

## Key Takeaways

1. **Clear Separation of Concerns**: Frontend and backend have distinct responsibilities
2. **Consistent API Design**: Standardized data format with the `data` property
3. **Environment Configuration**: Using environment variables for flexibility
4. **Multiple Deployment Options**: Support for both client-side and server-side rendering
5. **Session Management**: Server-side state persistence with cookies
6. **Component Reusability**: Building UIs from composable components
7. **Unified API Patterns**: Consistent approach to data fetching and error handling

By examining the Medicine project, we can understand how modern web applications are structured, with a focus on maintainability, scalability, and performance.

---

[Back to Middleware and Security](./10-middleware-security.md) | [Back Home ->](./README.md)
