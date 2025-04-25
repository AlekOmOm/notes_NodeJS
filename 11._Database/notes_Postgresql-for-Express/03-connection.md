# 3. Connecting PostgreSQL to Express 🔌

[<- Back: Setting Up PostgreSQL](./02-setup.md) | [Next: PostgreSQL Schema Design ->](./04-schema-design.md)

## Table of Contents

- [Node.js PostgreSQL Libraries](#nodejs-postgresql-libraries)
- [Setting Up Connection Pools](#setting-up-connection-pools)
- [Environment Configuration](#environment-configuration)
- [Database Connection Module](#database-connection-module)
- [Connection Error Handling](#connection-error-handling)
- [Migrating from SQLite](#migrating-from-sqlite)

## Node.js PostgreSQL Libraries

Several libraries are available for connecting Node.js/Express applications to PostgreSQL:

| Library | Description | Best For |
|---------|------------|----------|
| **pg** (node-postgres) | Low-level client with Promise support | Direct SQL control, core functionality |
| **pg-promise** | Promise wrapper with extended features | Projects with complex SQL needs |
| **Sequelize** | Full ORM with PostgreSQL support | Object-oriented access, multiple DB support |
| **Prisma** | Modern TypeScript ORM | Type safety, schema generation |
| **Knex.js** | SQL query builder | Query building, migrations |

For a direct transition from SQLite, **pg** (node-postgres) offers the simplest learning curve while maintaining full SQL control.

```bash
# Install the pg library
npm install pg
```

## Setting Up Connection Pools

Connection pooling is essential for PostgreSQL performance. Unlike SQLite's file-based access, PostgreSQL requires managing concurrent network connections.

```javascript
// database/connection.js
import pg from 'pg';
const { Pool } = pg;

// Create a connection pool
const pool = new Pool({
  user: process.env.PGUSER || 'myuser',
  host: process.env.PGHOST || 'localhost',
  database: process.env.PGDATABASE || 'myapp',
  password: process.env.PGPASSWORD || 'mypassword',
  port: process.env.PGPORT || 5432,
  // Optional: connection/idle timeouts
  connectionTimeoutMillis: 0,
  idleTimeoutMillis: 10000,
  // Optional: max number of clients in the pool
  max: 20
});

// Test the connection
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Database connection error:', err);
  } else {
    console.log('Connected to PostgreSQL database at:', res.rows[0].now);
  }
});

export default pool;
```

### Key Connection Pool Parameters

- **max**: Maximum number of clients (default: 10)
- **idleTimeoutMillis**: How long a client can remain idle (default: 10000ms)
- **connectionTimeoutMillis**: Connection timeout (default: 0, no timeout)
- **allowExitOnIdle**: Close idle clients on process exit

## Environment Configuration

Storing database credentials in environment variables is a security best practice:

```bash
# .env file
PGUSER=myuser
PGHOST=localhost
PGDATABASE=myapp
PGPASSWORD=mypassword
PGPORT=5432
```

Setup with dotenv:

```javascript
// At the top of app.js or index.js
import dotenv from 'dotenv';
dotenv.config();

// Then import your connection module
import pool from './database/connection.js';
```

## Database Connection Module

To provide an interface similar to what you had with SQLite, you can create a compatibility layer:

```javascript
// database/connection.js
import pg from 'pg';
const { Pool } = pg;

const pool = new Pool({
  user: process.env.PGUSER,
  host: process.env.PGHOST,
  database: process.env.PGDATABASE,
  password: process.env.PGPASSWORD,
  port: process.env.PGPORT
});

// Create a compatibility layer for SQLite-style code
const connection = {
  // For executing queries without results (CREATE TABLE, etc.)
  exec: async (sql) => {
    try {
      await pool.query(sql);
      return true;
    } catch (err) {
      console.error('exec error:', err);
      throw err;
    }
  },
  
  // For queries with parameters that modify data (INSERT, UPDATE, DELETE)
  run: async (sql, params = []) => {
    try {
      const result = await pool.query(sql, params);
      return {
        lastID: result.rows[0]?.id || null,
        changes: result.rowCount
      };
    } catch (err) {
      console.error('run error:', err);
      throw err;
    }
  },
  
  // For getting a single row
  get: async (sql, params = []) => {
    try {
      const result = await pool.query(sql, params);
      return result.rows[0];
    } catch (err) {
      console.error('get error:', err);
      throw err;
    }
  },
  
  // For getting multiple rows
  all: async (sql, params = []) => {
    try {
      const result = await pool.query(sql, params);
      return result.rows;
    } catch (err) {
      console.error('all error:', err);
      throw err;
    }
  },
  
  // For transactions
  transaction: async (callback) => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }
};

// Test connection
pool.query('SELECT NOW()')
  .then(res => console.log('PostgreSQL connected:', res.rows[0].now))
  .catch(err => console.error('Connection error:', err));

export default connection;
```

## Connection Error Handling

PostgreSQL connections may fail for various reasons, so robust error handling is essential:

```javascript
// Event listeners for the pool
pool.on('error', (err, client) => {
  console.error('Unexpected error on idle client', err);
  // Application-specific error handling
});

// Reconnection logic
const MAX_RETRIES = 5;
const RETRY_INTERVAL = 5000; // 5 seconds

const connectWithRetry = async (retries = MAX_RETRIES) => {
  try {
    await pool.query('SELECT 1');
    console.log('Database connection established');
    return true;
  } catch (err) {
    if (retries === 0) {
      console.error('Max retries reached, giving up');
      throw err;
    }
    
    console.log(`Connection failed, retrying... (${retries} attempts left)`);
    await new Promise(resolve => setTimeout(resolve, RETRY_INTERVAL));
    return connectWithRetry(retries - 1);
  }
};

// Use this during application startup
connectWithRetry().catch(err => {
  console.error('Could not connect to database:', err);
  process.exit(1);
});
```

## Migrating from SQLite

When moving from SQLite to PostgreSQL, you'll need to adapt your queries:

### Parameter Placeholders

```javascript
// SQLite
db.run("INSERT INTO users (name, email) VALUES (?, ?)", [name, email]);

// PostgreSQL
db.run("INSERT INTO users (name, email) VALUES ($1, $2)", [name, email]);
```

### Returning Inserted IDs

```javascript
// SQLite - lastID is returned in the result object
const result = await db.run("INSERT INTO users (name) VALUES (?)", [name]);
const userId = result.lastID;

// PostgreSQL - must use RETURNING clause
const result = await db.run("INSERT INTO users (name) VALUES ($1) RETURNING id", [name]);
const userId = result.rows[0].id;
```

### Handling NULL Values

```javascript
// SQLite is loose with NULL handling
db.get("SELECT * FROM users WHERE last_login IS NULL");

// PostgreSQL is strict with NULLs
db.get("SELECT * FROM users WHERE last_login IS NULL");
// OR for comparing variables:
db.get("SELECT * FROM users WHERE ($1::timestamp IS NULL AND last_login IS NULL) OR last_login = $1", [lastLogin]);
```

### Case Sensitivity

PostgreSQL is case-sensitive for identifiers unless they're quoted:

```sql
-- This works in SQLite but may fail in PostgreSQL if created with different case
SELECT * FROM Users;  -- Might not match 'users' table

-- PostgreSQL solutions:
SELECT * FROM users;  -- Use consistent casing
-- OR
SELECT * FROM "Users";  -- Quote identifiers when needed
```

---

[<- Back: Setting Up PostgreSQL](./02-setup.md) | [Next: PostgreSQL Schema Design ->](./04-schema-design.md)
