# 11a. Svelte in Full-Stack Applications 🧩

[<- Back to Main Topic](./11-client-server-architecture.md)

## Overview

Svelte has emerged as a powerful framework for building modern web applications. In the Medicine project, Svelte serves as the frontend framework, providing a reactive and component-based architecture for the user interface. This sub-note explores how Svelte integrates with a Node.js/Express backend in a full-stack application.

## Key Concepts

### Svelte Component Structure

A Svelte component consists of three main sections:

```svelte
<script>
  // JavaScript logic
  import { onMount } from "svelte";
  import { BASE_URL } from "../stores/generalStore.js";
  
  // Reactive variables (Svelte 5 syntax)
  let data = $state([]);
  
  onMount(async () => {
    // Component initialization
    const response = await fetch(`${$BASE_URL}/api/data`);
    const result = await response.json();
    data = result.data;
  });
  
  // Event handlers
  function handleClick() {
    data = [...data, { id: Date.now(), text: "New item" }];
  }
</script>

<style>
  /* Scoped CSS */
  .container {
    padding: 1rem;
    border-radius: 4px;
    background-color: #f9f9f9;
  }
  
  .item {
    margin-bottom: 0.5rem;
    padding: 0.5rem;
    border: 1px solid #ddd;
  }
</style>

<!-- HTML template with reactive bindings -->
<div class="container">
  <h2>Data Items</h2>
  
  {#each data as item}
    <div class="item">
      <span>{item.text}</span>
    </div>
  {/each}
  
  <button on:click={handleClick}>Add Item</button>
</div>
```

### Lifecycle Methods

Svelte provides several lifecycle methods for components:

1. **onMount**: Runs when a component is first rendered to the DOM
   ```javascript
   onMount(() => {
     // Fetch data, set up timers, etc.
     return () => {
       // Cleanup function (equivalent to componentWillUnmount in React)
     };
   });
   ```

2. **beforeUpdate**: Runs before the DOM is updated
   ```javascript
   beforeUpdate(() => {
     // Access the DOM before it updates
   });
   ```

3. **afterUpdate**: Runs after the DOM is updated
   ```javascript
   afterUpdate(() => {
     // Access the DOM after it updates
   });
   ```

4. **onDestroy**: Runs when a component is removed from the DOM
   ```javascript
   onDestroy(() => {
     // Clean up resources, event listeners, etc.
   });
   ```

### Reactivity in Svelte

Svelte's reactivity system is one of its key features, allowing for simple and intuitive state management:

#### Component-Level State (Svelte 5)

```javascript
// Using $state (Svelte 5)
let count = $state(0);

// Update directly triggers reactivity
function increment() {
  count += 1;
}
```

#### Derived Values

```javascript
// Reactive declarations (calculated values)
$: doubled = count * 2;
$: isEven = count % 2 === 0;
```

#### Reactive Statements

```javascript
// Run code when dependencies change
$: {
  console.log(`Count changed to ${count}`);
  // Additional code to run when count changes
}
```

### Store-Based State Management

For application-wide state, Svelte provides stores:

```javascript
// stores/generalStore.js
import { writable, readable, derived } from 'svelte/store';

// Writable store (can be updated from anywhere)
export const count = writable(0);

// Read-only store
export const BASE_URL = readable(import.meta.env.VITE_BASE_URL || "http://localhost:8080");

// Derived store (calculated from other stores)
export const doubledCount = derived(count, $count => $count * 2);
```

Using stores in components:

```svelte
<script>
  import { count, doubledCount } from '../stores/generalStore.js';
  
  function increment() {
    $count += 1; // Auto-subscribed with $ prefix
  }
</script>

<button on:click={increment}>Increment: {$count}</button>
<p>Doubled: {$doubledCount}</p>
```

## Implementation Patterns

### Component Organization

In the Medicine project, components are organized hierarchically:

```
src/
├── components/          # Reusable UI components
│   └── Employees/
│       └── Employees.svelte
├── pages/               # Page-level components (routes)
│   ├── Home/
│   │   └── Home.svelte
│   ├── Pharmacy/
│   │   └── Pharmacy.svelte
│   └── About/
│       └── About.svelte
├── stores/              # Global state management
│   └── generalStore.js
├── util/                # Utility functions
│   └── fetch.js
├── App.svelte           # Root component
└── main.js              # Entry point
```

This structure separates concerns and promotes reusability:

1. **Pages**: Container components that represent routes
2. **Components**: Reusable UI elements used across pages
3. **Stores**: Shared state accessible to multiple components
4. **Utilities**: Helper functions for common tasks

### Routing

The Medicine project uses svelte-routing for client-side navigation:

```svelte
<!-- App.svelte -->
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

### Data Fetching

The project includes utility functions for standardized API calls:

```javascript
// util/fetch.js
export async function fetchGet(url) {
    try {
        const response = await fetch(url, {
            credentials: "include" // Include cookies for session management
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
        credentials: "include",
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

Using these utilities in components:

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

## Common Challenges and Solutions

### Challenge 1: Managing Session State

When working with server-side sessions, it's important to include credentials in fetch requests.

**Solution:**

```javascript
// Always include credentials in fetch requests
fetch(url, {
    credentials: "include" // Sends cookies with cross-origin requests
})
```

### Challenge 2: Cross-Origin Requests

Working with separate client and server origins requires proper CORS configuration.

**Solution:**

On the server:
```javascript
// In server/app.js
app.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
    res.header("Access-Control-Allow-Credentials", "true");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    next();
});
```

### Challenge 3: Environment-Specific Configuration

Different environments (development, production) may require different configurations.

**Solution:**

```javascript
// In stores/generalStore.js
import { readable } from "svelte/store";

// Use environment variables for configuration
export const BASE_URL = readable(import.meta.env.VITE_BASE_URL || "http://localhost:8080");
```

With corresponding `.env` files:
```
# .env.development
VITE_BASE_URL=http://localhost:8080

# .env.production
VITE_BASE_URL=https://api.example.com
```

### Challenge 4: Handling Loading and Error States

API requests may take time or fail, requiring appropriate UI feedback.

**Solution:**

```svelte
<script>
  let data = $state([]);
  let loading = $state(true);
  let error = $state(null);
  
  onMount(async () => {
    try {
      loading = true;
      error = null;
      const result = await fetchGet(`${$BASE_URL}/api/data`);
      data = result.data;
    } catch (err) {
      error = err.message || "Failed to load data";
    } finally {
      loading = false;
    }
  });
</script>

{#if loading}
  <div class="loading">Loading...</div>
{:else if error}
  <div class="error">{error}</div>
{:else}
  <!-- Normal UI -->
  <div class="data-list">
    {#each data as item}
      <div class="item">{item.name}</div>
    {/each}
  </div>
{/if}
```

## Practical Example

The Medicine project's Pharmacy component demonstrates these patterns in action:

```svelte
<script>
    import { onMount } from "svelte";

    import Employees from "../../components/Employees/Employees.svelte";

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
</script>

<h1>Pharmacy</h1>

<Employees />

{#each pills as pill}
    <h3>{pill.name}</h3>
{/each}

<button onclick={fillPrescription}>Fill Prescription</button>
```

This component:
1. Imports a reusable `Employees` component
2. Uses global configuration from the store
3. Fetches data on mount
4. Handles user interactions (button click)
5. Maintains and displays component state

## Benefits of Svelte in Full-Stack Applications

1. **Minimal Boilerplate**: Svelte's clean syntax reduces code complexity
2. **Built-in Reactivity**: Simple state management without extra libraries
3. **Scope CSS**: Component-scoped CSS prevents style conflicts
4. **Runtime Performance**: Svelte compiles to highly optimized vanilla JavaScript
5. **Small Bundle Size**: Results in faster page loads for users
6. **Progressive Enhancement**: Works well with server-side rendering approaches
7. **Intuitive API**: Flatter learning curve compared to other frameworks

## Integration with Express.js

The Svelte frontend and Express backend communicate through well-defined APIs:

1. **API Design**: Consistent data format (`{ data: ... }`)
2. **Authentication**: Session-based with cookies
3. **Error Handling**: Standardized approaches on both ends
4. **State Synchronization**: Client reflects server state

This architecture allows for flexibility in deployment:
- During development: Separate client and server processes
- In production: Single server for both API and static files

## Summary

Svelte provides an elegant solution for building the frontend of full-stack applications. Its reactive model and component-based architecture integrate well with Express.js backends, creating a cohesive developer experience. The Medicine project demonstrates how these technologies can work together effectively, with clean separation of concerns and standardized communication patterns.

---

[<- Back to Main Topic](./11-client-server-architecture.md)
