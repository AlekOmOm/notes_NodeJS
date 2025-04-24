# 11c. Server-Side Rendering Techniques 🖼️

[<- Back to Main Topic](./11-client-server-architecture.md)

## Overview

Server-Side Rendering (SSR) is a technique where web pages are generated on the server rather than in the browser. The Medicine project demonstrates a practical implementation of SSR with Express.js and Svelte. This sub-note explores SSR patterns, benefits, challenges, and implementation strategies in modern full-stack applications.

## Key Concepts

### What is Server-Side Rendering?

Server-Side Rendering is a rendering technique where:

1. The server generates the full HTML for a page
2. The client receives a complete, rendered page
3. JavaScript on the client takes over for interactivity ("hydration")

This contrasts with Client-Side Rendering (CSR), where:

1. The server sends minimal HTML with JavaScript
2. The client runs JavaScript to build the page
3. Content appears after JavaScript executes

### Types of Rendering Approaches

| Approach | Description | When to Use |
|----------|-------------|------------|
| **Client-Side Rendering (CSR)** | Renders entirely in the browser | Interactive apps, authenticated dashboards |
| **Server-Side Rendering (SSR)** | Renders HTML on server, hydrates on client | Public-facing pages, SEO-critical content |
| **Static Site Generation (SSG)** | Pre-renders at build time | Content that changes infrequently |
| **Incremental Static Regeneration (ISR)** | Pre-renders + revalidates periodically | Content with moderate update frequency |
| **Progressive Rendering** | Streams HTML from server in chunks | Large pages that benefit from streaming |

### The Render Cycle

1. **Server Phase**:
   - Receive request
   - Generate HTML (including data fetching)
   - Send complete HTML to client

2. **Client Phase**:
   - Parse and display HTML (fast initial render)
   - Load JavaScript
   - "Hydrate" the page (attach event handlers, initialize state)
   - React to user interaction

## Implementation Patterns

### Basic SSR Setup with Express and Svelte

The Medicine project demonstrates a straightforward approach to SSR:

```javascript
// serverSSR/app.js
import 'dotenv/config';
import express from 'express';
import path from 'path';

const app = express();

app.use(express.json());

// Serve static files from client build
app.use(express.static(path.resolve('../client/dist/')));

// Session and API routes
import session from 'express-session';
app.use(session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false }
}));

import employeesRouter from './routers/employeesRouter.js';
app.use(employeesRouter);
import pillsRouter from './routers/pillsRouter.js';
app.use(pillsRouter);

// SPA fallback for client-side routing
app.get("/{*splat}", (req, res) => {
  res.sendFile(path.resolve('../client/dist/index.html'));
});

const PORT = Number(process.env.PORT) || 8080;
app.listen(PORT, () => console.log("Server is running on port", PORT));
```

In this implementation:

1. Static assets (JS, CSS) are served from the client build directory
2. API endpoints are defined for data access
3. A fallback route handles client-side routing
4. Session state is maintained across requests

### Build Pipeline for SSR

The client-side code must be built before it can be served:

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

A typical development workflow:

1. Build the client: `npm run build` or `npm run build-watch`
2. Start the SSR server: `node serverSSR/app.js`
3. Access the application at `http://localhost:8080`

### More Advanced SSR Techniques

While the Medicine project uses a simpler approach, more sophisticated SSR implementations might include:

#### 1. Real-time Rendering with Svelte

```javascript
import { createSSRComponent } from 'svelte/server';
import App from '../client/src/App.svelte';

app.get('*', async (req, res) => {
  try {
    // Initial data loading
    const initialData = await fetchInitialData(req.path);
    
    // Render the app to a string
    const { html, head, css } = createSSRComponent(App, {
      url: req.url,
      initialData
    });
    
    // Send the complete HTML document
    res.send(`
      <!DOCTYPE html>
      <html>
        <head>
          ${head}
          <style>${css.code}</style>
        </head>
        <body>
          <div id="app">${html}</div>
          <script>
            window.__INITIAL_DATA__ = ${JSON.stringify(initialData)};
          </script>
          <script src="/build/bundle.js"></script>
        </body>
      </html>
    `);
  } catch (error) {
    res.status(500).send('Server error');
  }
});
```

#### 2. Streaming SSR (not in the Medicine project)

```javascript
import { renderToNodeStream } from 'some-streaming-renderer';

app.get('*', (req, res) => {
  // Start with the header
  res.write(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>My App</title>
        <link rel="stylesheet" href="/styles.css">
      </head>
      <body>
        <div id="app">
  `);
  
  // Stream the component rendering
  const stream = renderToNodeStream(App, { url: req.url });
  stream.pipe(res, { end: false });
  
  // When component is rendered, finish the HTML
  stream.on('end', () => {
    res.write(`
        </div>
        <script src="/bundle.js"></script>
      </body>
    </html>
    `);
    res.end();
  });
});
```

## Benefits of SSR

### 1. Improved SEO

Search engines can index fully-rendered HTML content:

```html
<!-- CSR initially shows -->
<div id="app"></div>

<!-- SSR provides complete content -->
<div id="app">
  <header>
    <h1>Medicine App</h1>
    <nav>...</nav>
  </header>
  <main>
    <h2>Employees Available</h2>
    <h4>Ilmer</h4>
    <h4>Homer</h4>
  </main>
</div>
```

### 2. Faster Initial Load

Users see content more quickly:

| Metric | SSR | CSR |
|--------|-----|-----|
| **First Paint** | Faster (pre-rendered HTML) | Slower (requires JS parsing) |
| **First Contentful Paint** | Immediate | After JS execution |
| **Time to Interactive** | After hydration | After rendering |

### 3. Performance on Low-Powered Devices

SSR reduces the client-side processing burden, improving performance on less powerful devices like:

- Older smartphones
- Budget devices
- Devices with limited CPU/memory

### 4. Accessibility and Progressive Enhancement

SSR provides a better experience for users with JavaScript limitations:

- Users with JavaScript disabled
- Browsers with limited JS support
- Screen readers and accessibility tools
- Network interruptions affecting JS loading

## Challenges and Solutions

### Challenge 1: Hydration Mismatch

Differences between server-rendered HTML and client expectations can cause errors.

**Solution:**

```javascript
// In client code
import { mount } from 'svelte';
import App from './App.svelte';

// Pass the same initial props used on the server
mount(App, {
  target: document.getElementById('app'),
  hydrate: true,  // Enable hydration mode
  props: window.__INITIAL_DATA__ || {}  // Use data from server
});
```

### Challenge 2: Data Fetching Complexity

Handling data fetching for both server and client can be challenging.

**Solution:**

```javascript
// Data fetching function used on both server and client
async function fetchData(path) {
  // Server-side fetch
  if (typeof window === 'undefined') {
    // Direct database access or internal API call
    return await internalFetch(path);
  }
  
  // Client-side fetch
  const response = await fetch(`/api${path}`);
  return await response.json();
}

// In component
export async function preload({ path }) {
  // Called on server during SSR
  return { data: await fetchData(path) };
}

// In component's script
export let data;  // Received from preload on server, props on client
```

### Challenge 3: Session Handling

Managing user sessions across server and client requires careful coordination.

**Solution:**

```javascript
// Server-side session setup
app.use(session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: { secure: process.env.NODE_ENV === 'production' }
}));

// Pass minimal session data to client (avoid sensitive info)
app.get('*', (req, res) => {
  // Extract only what's needed
  const clientSession = {
    authenticated: req.session.authenticated || false,
    username: req.session.username
  };
  
  // Include in the rendered HTML
  res.send(`
    <!DOCTYPE html>
    <html>
      <!-- ... -->
      <script>
        window.__SESSION__ = ${JSON.stringify(clientSession)};
      </script>
      <!-- ... -->
    </html>
  `);
});
```

### Challenge 4: Environment Differences

Code might behave differently on server vs. client.

**Solution:**

```javascript
// Safely detect environment
const isServer = typeof window === 'undefined';
const isClient = !isServer;

// Conditional logic
if (isServer) {
  // Server-only code
  // e.g., direct database access
} else {
  // Client-only code
  // e.g., browser APIs, window manipulation
}

// Safe access to browser APIs
const windowWidth = isClient ? window.innerWidth : 1200; // Default for server
```

## Performance Optimization

### Caching Strategies

```javascript
// Simple in-memory cache
const pageCache = new Map();

app.get('*', async (req, res) => {
  const cacheKey = req.url;
  
  // Check if page is in cache and not stale
  if (pageCache.has(cacheKey) && !isStale(pageCache.get(cacheKey))) {
    return res.send(pageCache.get(cacheKey).html);
  }
  
  // Render page
  const html = await renderPage(req.url);
  
  // Cache result
  pageCache.set(cacheKey, {
    html,
    timestamp: Date.now()
  });
  
  res.send(html);
});

// Cache invalidation on data changes
function invalidateCache(pattern) {
  for (const [key] of pageCache.entries()) {
    if (key.includes(pattern)) {
      pageCache.delete(key);
    }
  }
}
```

### Critical CSS Inlining

```javascript
// Extract and inline critical CSS
app.get('*', async (req, res) => {
  const { html, criticalCss } = await renderPage(req.url);
  
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <!-- Inline critical CSS for above-the-fold content -->
        <style>${criticalCss}</style>
        
        <!-- Load full CSS asynchronously -->
        <link rel="preload" href="/styles.css" as="style" onload="this.onload=null;this.rel='stylesheet'">
        <noscript><link rel="stylesheet" href="/styles.css"></noscript>
      </head>
      <body>
        <div id="app">${html}</div>
        <script src="/bundle.js" defer></script>
      </body>
    </html>
  `);
});
```

### Partial Hydration

```javascript
// Mark components that need hydration
const hydrationMap = {
  'InteractiveComponent': true,
  'StaticContent': false
};

// In client entry
function hydrateSelectively() {
  document.querySelectorAll('[data-hydrate]').forEach(el => {
    const componentName = el.dataset.component;
    
    if (hydrationMap[componentName]) {
      // Hydrate interactive components
      hydrate(componentName, { target: el });
    }
  });
}

// Wait for content to be visible
if ('IntersectionObserver' in window) {
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        hydrateSelectively();
        observer.disconnect();
      }
    });
  });
  
  observer.observe(document.getElementById('app'));
} else {
  // Fallback for browsers without IntersectionObserver
  hydrateSelectively();
}
```

## SSR in Production

### Deployment Considerations

1. **Server Resources**: SSR is more CPU-intensive than serving static files
2. **Caching Layers**: Implement CDN or edge caching for rendered pages
3. **Scaling Strategy**: Consider horizontal scaling for SSR servers
4. **Health Monitoring**: Watch for memory leaks or CPU spikes

### Production Architecture

```
        ┌─────────────┐
        │     CDN     │ ← Static assets (JS, CSS, images)
        └─────────────┘
              ↑
              │
┌─────────────┴─────────────┐
│       Load Balancer       │
└─────────────┬─────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
┌───▼───┐         ┌─────▼───┐
│ SSR   │         │ SSR     │
│ Node  │ ···     │ Node    │ ← Page rendering
│ Server│         │ Server  │
└───┬───┘         └─────┬───┘
    │                   │
    └─────────┬─────────┘
              │
┌─────────────▼─────────────┐
│      API Services         │ ← Data fetching
└─────────────┬─────────────┘
              │
┌─────────────▼─────────────┐
│      Database Layer       │ ← Persistence
└───────────────────────────┘
```

## Best Practices

1. **Start Simple**: Begin with basic SSR before adding optimizations
2. **Measure Performance**: Compare metrics like FCP, TTI between SSR and CSR
3. **Selective Hydration**: Only hydrate interactive parts of the page
4. **Avoid Double Data Fetching**: Share data between server and client
5. **Use Progressive Enhancement**: Ensure basic functionality works without JS
6. **Implement Proper Caching**: Cache rendered pages when appropriate
7. **Monitor Server Load**: Watch for resource utilization in production
8. **Test across Devices**: Verify performance across device types

## Summary

Server-Side Rendering offers significant benefits for initial load performance, SEO, and accessibility, at the cost of greater implementation complexity and server resource requirements. The Medicine project demonstrates a practical approach to SSR with Express and Svelte, focusing on a simple yet effective implementation.

As applications grow more complex, more sophisticated SSR techniques like streaming, partial hydration, and advanced caching become valuable tools for optimizing performance. By understanding these patterns and choosing the right approach for your specific use case, you can create web applications that provide the best possible user experience across all devices and connection speeds.

---

[<- Back to Main Topic](./11-client-server-architecture.md)
