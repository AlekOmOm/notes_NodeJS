# 9. Svelte Components and Data Flow 🧩

[<- Back to Forms and Introduction to Svelte](./08-forms-svelte.md) | [Next: Middleware and Security ->](./10-middleware-security.md)

## Table of Contents

- [Component Hierarchy in Svelte](#component-hierarchy-in-svelte)
- [Props and Data Passing](#props-and-data-passing)
- [Component Communication](#component-communication)
- [Context API](#context-api)
- [Svelte Stores](#svelte-stores)
- [Slots and Content Projection](#slots-and-content-projection)
- [Component Lifecycle](#component-lifecycle)

## Component Hierarchy in Svelte

Web frameworks like Svelte organize applications into component trees with parent-child relationships. Understanding this hierarchy is essential for building well-structured applications.

### Basic Component Structure

```
App (Root Component)
├── Header
│   ├── Logo
│   └── Navigation
├── Main
│   ├── Sidebar
│   └── Content
│       ├── ArticleList
│       │   └── ArticleCard
│       └── Pagination
└── Footer
```

In this tree structure:
- Parent components contain and control child components
- Data flows down from parents to children (via props)
- Events flow up from children to parents (via custom events)

### Component Relationships

#### Parent Component

```html
<!-- Parent.svelte -->
<script>
  import Child from './Child.svelte';
  
  let parentData = "Data from parent";
  
  function handleChildEvent(event) {
    console.log(`Child said: ${event.detail}`);
  }
</script>

<div class="parent">
  <h2>Parent Component</h2>
  
  <!-- Pass data down, listen for events up -->
  <Child 
    message={parentData} 
    on:childEvent={handleChildEvent} 
  />
</div>
```

#### Child Component

```html
<!-- Child.svelte -->
<script>
  import { createEventDispatcher } from 'svelte';
  
  // Receive data from parent
  export let message;
  
  // Set up event dispatcher
  const dispatch = createEventDispatcher();
  
  function sendToParent() {
    // Send data up to parent
    dispatch('childEvent', 'Hello from child!');
  }
</script>

<div class="child">
  <h3>Child Component</h3>
  <p>Received: {message}</p>
  <button on:click={sendToParent}>Send to Parent</button>
</div>
```

### Component Tree Visualization

![Component Hierarchy](https://svelte.dev/tutorial/svelte/diagram.svg)

This visualization shows how data flows down through props (blue arrows) while events bubble up (red arrows).

## Props and Data Passing

Svelte provides several ways to pass data between components.

### Basic Props

```html
<!-- Parent.svelte -->
<script>
  import ProductCard from './ProductCard.svelte';
  
  const product = {
    id: 1,
    name: 'Ergonomic Chair',
    price: 199.99,
    inStock: true
  };
</script>

<ProductCard 
  name={product.name}
  price={product.price}
  inStock={product.inStock}
/>

<!-- Shorthand if variable names match prop names -->
<ProductCard {...product} />
```

```html
<!-- ProductCard.svelte -->
<script>
  // Declare props with defaults
  export let id;
  export let name = 'Unknown Product';
  export let price = 0;
  export let inStock = false;
  export let discount = 0; // Optional prop
  
  // Computed property based on props
  $: finalPrice = price * (1 - discount/100);
</script>

<div class="product-card">
  <h3>{name}</h3>
  <p class="price">${finalPrice.toFixed(2)}</p>
  {#if discount > 0}
    <p class="discount">Sale: {discount}% off!</p>
  {/if}
  <p class="stock">
    {inStock ? 'In Stock' : 'Out of Stock'}
  </p>
</div>
```

### Spread Props

When you have an object with properties that match prop names:

```html
<script>
  import UserProfile from './UserProfile.svelte';
  
  const user = {
    name: 'John Doe',
    email: 'john@example.com',
    avatar: '/images/john.jpg',
    role: 'admin'
  };
</script>

<!-- Pass all properties of user as separate props -->
<UserProfile {...user} />
```

### Rest Properties

For collecting "extra" props:

```html
<!-- Button.svelte -->
<script>
  export let variant = 'primary';
  export let size = 'medium';
  
  // Rest props get everything else
  // (useful for forwarding HTML attributes)
  export let $$restProps;
</script>

<button 
  class="btn btn-{variant} btn-{size}" 
  {...$$restProps}
>
  <slot></slot>
</button>
```

```html
<!-- Usage -->
<Button 
  variant="danger" 
  size="large" 
  disabled={true} 
  data-testid="submit-btn"
>
  Submit
</Button>
```

### Reactive Declarations

Props trigger updates in dependent values:

```html
<script>
  export let width = 0;
  export let height = 0;
  
  // Recalculated when width or height changes
  $: area = width * height;
  $: aspectRatio = width / height;
  
  // Reactive statements
  $: {
    console.log(`Dimensions changed: ${width}x${height}`);
    console.log(`Area: ${area}, Aspect Ratio: ${aspectRatio}`);
  }
</script>
```

## Component Communication

Svelte components communicate through props (parent to child) and events (child to parent).

### Custom Events

To communicate from child to parent:

```html
<!-- Child.svelte -->
<script>
  import { createEventDispatcher } from 'svelte';
  
  export let item;
  
  const dispatch = createEventDispatcher();
  
  function handleRemove() {
    dispatch('remove', {
      id: item.id,
      name: item.name
    });
  }
  
  function handleEdit() {
    dispatch('edit', {
      id: item.id,
      value: item.name
    });
  }
</script>

<div class="item">
  <span>{item.name}</span>
  <button on:click={handleEdit}>Edit</button>
  <button on:click={handleRemove}>Remove</button>
</div>
```

```html
<!-- Parent.svelte -->
<script>
  import Item from './Item.svelte';
  
  let items = [
    { id: 1, name: 'Apple' },
    { id: 2, name: 'Banana' },
    { id: 3, name: 'Cherry' }
  ];
  
  function removeItem(event) {
    const { id } = event.detail;
    items = items.filter(item => item.id !== id);
  }
  
  function editItem(event) {
    const { id, value } = event.detail;
    // Open edit dialog, etc.
    console.log(`Editing item ${id}: ${value}`);
  }
</script>

<ul>
  {#each items as item (item.id)}
    <li>
      <Item 
        item={item} 
        on:remove={removeItem} 
        on:edit={editItem}
      />
    </li>
  {/each}
</ul>
```

### Event Forwarding

Parent components can forward events from child components:

```html
<!-- Child.svelte -->
<script>
  import { createEventDispatcher } from 'svelte';
  const dispatch = createEventDispatcher();
</script>

<button on:click={() => dispatch('message', 'Hello!')}>
  Click Me
</button>
```

```html
<!-- Intermediate.svelte -->
<script>
  import Child from './Child.svelte';
  // No need to define handlers, just forward the event
</script>

<!-- Use on:message without a value to forward the event -->
<Child on:message />
```

```html
<!-- Parent.svelte -->
<script>
  import Intermediate from './Intermediate.svelte';
  
  function handleMessage(event) {
    alert(event.detail);
  }
</script>

<Intermediate on:message={handleMessage} />
```

### Binding to Component Props

Two-way binding allows for bidirectional data flow:

```html
<!-- Parent.svelte -->
<script>
  import NumberInput from './NumberInput.svelte';
  
  let value = 5;
  
  $: squared = value * value;
</script>

<NumberInput bind:value />
<p>The square of {value} is {squared}</p>
```

```html
<!-- NumberInput.svelte -->
<script>
  export let value;
  export let min = 0;
  export let max = 100;
  
  function handleInput(event) {
    const newValue = Number(event.target.value);
    value = Math.min(max, Math.max(min, newValue));
  }
</script>

<input 
  type="number" 
  {min} 
  {max} 
  {value} 
  on:input={handleInput}
/>
```

## Context API

For sharing data between components without explicitly passing props through every level, Svelte provides a Context API.

### Setting Context

```html
<!-- App.svelte -->
<script>
  import { setContext } from 'svelte';
  import { writable } from 'svelte/store';
  import Layout from './Layout.svelte';
  
  // Create a theme store
  const theme = writable('light');
  
  // Set it in context with a key
  setContext('theme', {
    theme,
    toggleTheme: () => theme.update(t => t === 'light' ? 'dark' : 'light')
  });
  
  // Set another context value
  setContext('user', {
    name: 'John Doe',
    role: 'admin'
  });
</script>

<Layout />
```

### Getting Context

```html
<!-- DeepChild.svelte (can be nested at any level) -->
<script>
  import { getContext } from 'svelte';
  
  // Get the theme context
  const { theme, toggleTheme } = getContext('theme');
  
  // Get the user context
  const user = getContext('user');
</script>

<div class="card" class:dark={$theme === 'dark'}>
  <p>Current user: {user.name}</p>
  <p>Current theme: {$theme}</p>
  <button on:click={toggleTheme}>
    Toggle Theme
  </button>
</div>
```

### Context API Characteristics

- Context is set in a component and available to all its descendants
- Values don't trigger reactive updates unless they're stores
- Each component tree has its own context (not global)
- Keys should be non-colliding (use symbols for guaranteed uniqueness)

## Svelte Stores

Stores provide a way to manage shared state across components.

### Basic Writable Store

```javascript
// stores/count.js
import { writable } from 'svelte/store';

// Create a writable store with initial value 0
export const count = writable(0);

// Optional: Export convenience methods
export function increment() {
  count.update(n => n + 1);
}

export function decrement() {
  count.update(n => n - 1);
}

export function reset() {
  count.set(0);
}
```

### Using Stores in Components

```html
<!-- Counter.svelte -->
<script>
  import { count, increment, decrement, reset } from './stores/count.js';
  
  // Local variable derived from store
  let doubleCount;
  
  // Subscribe to the store and update local variable
  count.subscribe(value => {
    doubleCount = value * 2;
  });
  
  // Auto-unsubscribe when component is destroyed
</script>

<div>
  <h2>Count: {$count}</h2>
  <p>Double: {doubleCount}</p>
  
  <button on:click={decrement}>-</button>
  <button on:click={increment}>+</button>
  <button on:click={reset}>Reset</button>
</div>
```

### Auto-subscription with $-prefix

Svelte provides a shorthand for subscribing to stores:

```html
<script>
  import { count } from './stores/count.js';
  
  // $count automatically subscribes and unsubscribes
  $: doubled = $count * 2;
  
  function increment() {
    // Update store with $ syntax
    $count += 1;
  }
</script>

<div>
  <h2>Count: {$count}</h2>
  <p>Double: {doubled}</p>
  
  <button on:click={() => $count -= 1}>-</button>
  <button on:click={increment}>+</button>
  <button on:click={() => $count = 0}>Reset</button>
</div>
```

### Custom Stores

You can create more complex stores with custom logic:

```javascript
// stores/todoStore.js
import { writable } from 'svelte/store';

// Create a custom store
function createTodoStore() {
  const { subscribe, set, update } = writable([]);
  
  return {
    subscribe,
    add: (text) => update(todos => [...todos, { 
      id: Date.now(), 
      text, 
      completed: false 
    }]),
    remove: (id) => update(todos => 
      todos.filter(todo => todo.id !== id)
    ),
    toggle: (id) => update(todos => 
      todos.map(todo => 
        todo.id === id 
          ? { ...todo, completed: !todo.completed } 
          : todo
      )
    ),
    clear: () => set([])
  };
}

export const todos = createTodoStore();
```

```html
<!-- TodoList.svelte -->
<script>
  import { todos } from './stores/todoStore.js';
  
  let newTodo = '';
  
  function addTodo() {
    if (newTodo.trim()) {
      todos.add(newTodo);
      newTodo = '';
    }
  }
</script>

<div>
  <h2>Todo List</h2>
  
  <form on:submit|preventDefault={addTodo}>
    <input bind:value={newTodo} placeholder="Add a new task...">
    <button type="submit">Add</button>
  </form>
  
  <ul>
    {#each $todos as todo (todo.id)}
      <li>
        <input 
          type="checkbox" 
          checked={todo.completed} 
          on:change={() => todos.toggle(todo.id)}
        >
        <span class:completed={todo.completed}>
          {todo.text}
        </span>
        <button on:click={() => todos.remove(todo.id)}>
          Delete
        </button>
      </li>
    {/each}
  </ul>
  
  {#if $todos.length > 0}
    <button on:click={() => todos.clear()}>
      Clear All
    </button>
  {/if}
</div>

<style>
  .completed {
    text-decoration: line-through;
    opacity: 0.6;
  }
</style>
```

### Different Types of Stores

Svelte provides three main types of stores:

1. **Writable Stores**: Full read/write access

```javascript
import { writable } from 'svelte/store';

const count = writable(0);
count.set(1);            // Set a new value
count.update(n => n + 1); // Update based on current value
```

2. **Readable Stores**: Read-only access from outside

```javascript
import { readable } from 'svelte/store';

// Initial value and start function that returns a stop function
const time = readable(new Date(), function start(set) {
  const interval = setInterval(() => {
    set(new Date());
  }, 1000);
  
  return function stop() {
    clearInterval(interval);
  };
});
```

3. **Derived Stores**: Computed from other stores

```javascript
import { writable, derived } from 'svelte/store';

const count = writable(0);
const doubled = derived(count, $count => $count * 2);
const delayed = derived(
  count, 
  ($count, set) => {
    // Asynchronous derivation
    const timeout = setTimeout(() => set($count * 2), 1000);
    return () => clearTimeout(timeout);
  },
  0 // Initial value while waiting
);
```

## Slots and Content Projection

Svelte's slot system allows components to receive and render content provided by parent components.

### Basic Slots

```html
<!-- Card.svelte -->
<div class="card">
  <div class="card-header">
    <slot name="header">
      <!-- Default content for header slot -->
      <h2>Default Title</h2>
    </slot>
  </div>
  
  <div class="card-body">
    <!-- Default (unnamed) slot -->
    <slot>
      <!-- Default content -->
      <p>No content provided</p>
    </slot>
  </div>
  
  <div class="card-footer">
    <slot name="footer"></slot>
  </div>
</div>
```

```html
<!-- Usage -->
<script>
  import Card from './Card.svelte';
</script>

<Card>
  <h2 slot="header">Custom Header</h2>
  
  <!-- Goes into the default slot -->
  <p>This is the main content of the card.</p>
  <p>It can include multiple elements.</p>
  
  <div slot="footer">
    <button>Cancel</button>
    <button>Save</button>
  </div>
</Card>
```

### Slot Props

Pass data back to the parent from slots:

```html
<!-- FancyList.svelte -->
<script>
  export let items = [];
</script>

<ul>
  {#each items as item, index}
    <li>
      <slot {item} {index}>
        <!-- Default rendering -->
        {item}
      </slot>
    </li>
  {/each}
</ul>
```

```html
<!-- Usage -->
<script>
  import FancyList from './FancyList.svelte';
  
  const fruits = ['Apple', 'Banana', 'Cherry', 'Date'];
</script>

<FancyList items={fruits} let:item let:index>
  <div class="fruit">
    <span>{index + 1}.</span>
    <strong>{item}</strong>
  </div>
</FancyList>
```

### Checking Slot Content

You can check if slots have content:

```html
<script>
  // Get a reference to the slot
  let headerSlot;
</script>

<div class="panel">
  {#if headerSlot}
    <div class="panel-header">
      <slot name="header" bind:this={headerSlot}></slot>
    </div>
  {/if}
  
  <div class="panel-body">
    <slot></slot>
  </div>
</div>
```

## Component Lifecycle

Understanding the component lifecycle is important for managing resources and side effects.

### Lifecycle Functions

```html
<script>
  import { onMount, onDestroy, beforeUpdate, afterUpdate } from 'svelte';
  
  export let data;
  let element;
  
  // Called when the component is mounted to the DOM
  onMount(() => {
    console.log('Component mounted');
    fetchData();
    
    // Setting up resources
    const interval = setInterval(() => {
      console.log('Interval tick');
    }, 1000);
    
    // Return a function that cleans up resources
    return () => {
      console.log('Cleanup from onMount');
      clearInterval(interval);
    };
  });
  
  // Called before the DOM is updated
  beforeUpdate(() => {
    console.log('Before component update');
    // Save scroll position, etc.
  });
  
  // Called after the DOM is updated
  afterUpdate(() => {
    console.log('After component update');
    // Restore scroll position, focus elements, etc.
  });
  
  // Called when the component is destroyed
  onDestroy(() => {
    console.log('Component will be destroyed');
    // Clean up resources, event listeners, etc.
  });
  
  async function fetchData() {
    // Async operations after mount
  }
</script>

<div bind:this={element}>
  Content: {data}
</div>
```

### Reactive Statements in the Lifecycle

```html
<script>
  export let userId;
  
  let user = null;
  let loading = false;
  let error = null;
  
  // Re-run whenever userId changes
  $: {
    if (userId) {
      loadUser(userId);
    }
  }
  
  async function loadUser(id) {
    loading = true;
    error = null;
    
    try {
      const response = await fetch(`/api/users/${id}`);
      if (!response.ok) throw new Error('Failed to load user');
      user = await response.json();
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
</script>

{#if loading}
  <p>Loading...</p>
{:else if error}
  <p class="error">{error}</p>
{:else if user}
  <div class="user-profile">
    <h2>{user.name}</h2>
    <!-- User details -->
  </div>
{:else}
  <p>No user selected</p>
{/if}
```

### Tick Function

For when you need to wait for the DOM to update:

```html
<script>
  import { tick } from 'svelte';
  
  let messages = [];
  let scrollArea;
  
  async function addMessage(text) {
    messages = [...messages, text];
    
    // Wait for DOM to update
    await tick();
    
    // Now we can manipulate the updated DOM
    scrollArea.scrollTop = scrollArea.scrollHeight;
  }
</script>

<div class="chat">
  <div class="messages" bind:this={scrollArea}>
    {#each messages as message}
      <div class="message">{message}</div>
    {/each}
  </div>
  
  <button on:click={() => addMessage('New message')}>
    Add Message
  </button>
</div>
```

---

[<- Back to Main Note](./README.md) | [Next: Middleware and Security ->](./10-middleware-security.md)
