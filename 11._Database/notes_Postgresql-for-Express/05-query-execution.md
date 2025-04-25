# 5. Query Execution 🔍

[<- Back: PostgreSQL Schema Design](./04-schema-design.md) | [Next: PostgreSQL Features ->](./06-postgresql-features.md)

## Table of Contents

- [Parameter Binding](#parameter-binding)
- [Prepared Statements](#prepared-statements)
- [Query Types](#query-types)
- [Transaction Management](#transaction-management)
- [Performance Considerations](#performance-considerations)
- [Debugging Queries](#debugging-queries)
- [Migrating SQLite Queries](#migrating-sqlite-queries)

## Parameter Binding

PostgreSQL uses numbered parameters (`$1`, `$2`, etc.) instead of SQLite's question marks (`?`):

```javascript
// SQLite style
db.get("SELECT * FROM users WHERE username = ? AND active = ?", 
  ["johndoe", true]);

// PostgreSQL style
db.get("SELECT * FROM users WHERE username = $1 AND active = $2", 
  ["johndoe", true]);
```

If using the compatibility layer from the previous sections, you'll need to convert parameters:

```javascript
// database/utils.js
export function convertQueryParams(sql) {
  // Replace ? with $1, $2, etc.
  let paramCounter = 0;
  return sql.replace(/\?/g, () => `$${++paramCounter}`);
}

// Usage in connection.js
const run = async (sql, params = []) => {
  const pgSql = convertQueryParams(sql);
  const result = await pool.query(pgSql, params);
  // ...
};
```

### Named Parameters

While PostgreSQL doesn't directly support named parameters, you can implement them:

```javascript
// Usage example
const namedQuery = {
  text: "SELECT * FROM users WHERE username = :username AND role = :role",
  params: { username: "johndoe", role: "admin" }
};

// Conversion function
function convertNamedParams(query) {
  const { text, params } = query;
  const paramValues = [];
  let index = 1;
  
  const processedText = text.replace(/:(\w+)/g, (match, paramName) => {
    if (params[paramName] === undefined) {
      throw new Error(`Missing parameter: ${paramName}`);
    }
    paramValues.push(params[paramName]);
    return `$${index++}`;
  });
  
  return { text: processedText, values: paramValues };
}

// Usage with pg
const { text, values } = convertNamedParams(namedQuery);
const result = await pool.query(text, values);
```

## Prepared Statements

Prepared statements improve security and performance by separating SQL from parameters:

```javascript
// Basic prepared statement with pg
const query = {
  name: 'fetch-user',
  text: 'SELECT * FROM users WHERE id = $1',
  values: [userId]
};

const result = await pool.query(query);
```

For frequently used queries, create a statement helper:

```javascript
// database/statements.js
export const statements = {
  fetchUser: {
    name: 'fetch-user',
    text: 'SELECT * FROM users WHERE id = $1'
  },
  createUser: {
    name: 'create-user',
    text: 'INSERT INTO users(username, email, password_hash) VALUES($1, $2, $3) RETURNING id'
  },
  // More prepared statements...
};

// Usage
import { statements } from './database/statements.js';

async function getUserById(id) {
  const result = await pool.query({
    ...statements.fetchUser,
    values: [id]
  });
  return result.rows[0];
}
```

## Query Types

Different query types in PostgreSQL with the `pg` library:

### SELECT Queries

```javascript
// Single row select
async function getUserById(id) {
  const result = await pool.query(
    'SELECT * FROM users WHERE id = $1', 
    [id]
  );
  return result.rows[0]; // or null if not found
}

// Multiple row select
async function getUsersByRole(role) {
  const result = await pool.query(
    'SELECT * FROM users WHERE role = $1', 
    [role]
  );
  return result.rows; // Array of matching rows
}

// Count query
async function countUsers() {
  const result = await pool.query('SELECT COUNT(*) FROM users');
  return parseInt(result.rows[0].count);
}
```

### INSERT Queries

```javascript
// Basic insert
async function createUser(username, email, passwordHash) {
  const result = await pool.query(
    'INSERT INTO users(username, email, password_hash) VALUES($1, $2, $3) RETURNING id', 
    [username, email, passwordHash]
  );
  return result.rows[0].id; // Get the inserted ID
}

// Multiple row insert
async function addGameTags(gameId, tags) {
  const values = tags.map(tag => `($1, $${tag.id})`).join(',');
  const params = [gameId, ...tags.map(tag => tag.id)];
  
  await pool.query(
    `INSERT INTO game_tags(game_id, tag_id) VALUES ${values}`,
    params
  );
}
```

### UPDATE Queries

```javascript
// Basic update
async function updateUserEmail(userId, newEmail) {
  const result = await pool.query(
    'UPDATE users SET email = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *', 
    [newEmail, userId]
  );
  return result.rows[0]; // Get the updated row
}

// Conditional update
async function activateUser(userId, activationCode) {
  const result = await pool.query(
    `UPDATE users 
     SET is_active = true, activated_at = CURRENT_TIMESTAMP 
     WHERE id = $1 AND activation_code = $2 AND is_active = false
     RETURNING *`, 
    [userId, activationCode]
  );
  
  return result.rowCount > 0; // True if a row was updated
}
```

### DELETE Queries

```javascript
// Basic delete
async function deleteUser(userId) {
  const result = await pool.query(
    'DELETE FROM users WHERE id = $1',
    [userId]
  );
  return result.rowCount; // Number of rows deleted
}

// Conditional delete
async function deleteExpiredSessions() {
  const result = await pool.query(
    'DELETE FROM sessions WHERE expires_at < CURRENT_TIMESTAMP',
    []
  );
  return result.rowCount; // Number of sessions deleted
}
```

## Transaction Management

Transactions ensure multiple operations succeed or fail as a unit:

```javascript
// With standard pg client
async function transferCredits(fromUserId, toUserId, amount) {
  const client = await pool.connect();
  
  try {
    // Start transaction
    await client.query('BEGIN');
    
    // Debit from source account
    const debitResult = await client.query(
      'UPDATE users SET credits = credits - $1 WHERE id = $2 AND credits >= $1 RETURNING id',
      [amount, fromUserId]
    );
    
    if (debitResult.rowCount === 0) {
      throw new Error('Insufficient credits');
    }
    
    // Credit to destination account
    await client.query(
      'UPDATE users SET credits = credits + $1 WHERE id = $2',
      [amount, toUserId]
    );
    
    // Record the transaction
    await client.query(
      'INSERT INTO credit_transfers(from_user_id, to_user_id, amount) VALUES($1, $2, $3)',
      [fromUserId, toUserId, amount]
    );
    
    // Commit transaction
    await client.query('COMMIT');
    return true;
  } catch (e) {
    // Rollback on error
    await client.query('ROLLBACK');
    throw e;
  } finally {
    // Release client back to pool
    client.release();
  }
}
```

### Using the Connection Adapter

With our SQLite compatibility layer:

```javascript
// Using the transaction method from our adapter
async function createUserWithProfile(userData, profileData) {
  return await connection.transaction(async (client) => {
    // Create user
    const userResult = await client.query(
      'INSERT INTO users(username, email) VALUES($1, $2) RETURNING id',
      [userData.username, userData.email]
    );
    const userId = userResult.rows[0].id;
    
    // Create profile with user ID
    await client.query(
      'INSERT INTO profiles(user_id, bio) VALUES($1, $2)',
      [userId, profileData.bio]
    );
    
    return userId;
  });
}
```

## Performance Considerations

### Query Optimization

1. **Use specific columns** instead of `SELECT *`
   ```sql
   -- Instead of
   SELECT * FROM users WHERE id = $1
   
   -- Use
   SELECT id, username, email FROM users WHERE id = $1
   ```

2. **Limit result sets** for pagination
   ```sql
   SELECT * FROM posts 
   ORDER BY created_at DESC 
   LIMIT $1 OFFSET $2
   ```

3. **Use COUNT efficiently**
   ```sql
   -- For checking existence, faster than COUNT(*)
   SELECT 1 FROM users WHERE role = 'admin' LIMIT 1
   
   -- For accurate counts with potential NULLs
   SELECT COUNT(*) FROM users WHERE last_login IS NOT NULL
   ```

4. **Combine related queries** to reduce roundtrips
   ```sql
   -- Get user and their latest posts in one query
   SELECT 
     u.id, u.username, u.email,
     p.id AS post_id, p.title, p.content, p.created_at
   FROM users u
   LEFT JOIN (
     SELECT DISTINCT ON (user_id) *
     FROM posts
     ORDER BY user_id, created_at DESC
   ) p ON u.id = p.user_id
   WHERE u.id = $1
   ```

### Connection Pool Settings

```javascript
const pool = new Pool({
  // Other connection settings...
  
  // Performance-related settings
  max: 20,                        // Maximum connections (default: 10)
  idleTimeoutMillis: 30000,       // How long a client can be idle (default: 10000)
  connectionTimeoutMillis: 2000,  // Connection timeout (default: 0)
  
  // Statement timeout (query)
  statement_timeout: 10000        // 10 seconds (protects against runaway queries)
});
```

## Debugging Queries

For development, add query logging:

```javascript
// Enhanced query method with logging
const query = async (text, params = []) => {
  const start = Date.now();
  
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    
    console.log({
      query: text,
      params,
      duration,
      rowCount: result.rowCount
    });
    
    return result;
  } catch (error) {
    console.error('Query error:', {
      query: text,
      params,
      error: error.message,
      stack: error.stack
    });
    throw error;
  }
};

// Usage
const users = await query('SELECT * FROM users WHERE role = $1', ['admin']);
```

For production, use a more structured approach:

```javascript
import winston from 'winston';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'database' },
  transports: [
    new winston.transports.File({ filename: 'logs/database.log' })
  ]
});

// In development, also log to console
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}

// Use in query method
const query = async (text, params = []) => {
  const start = Date.now();
  
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    
    logger.info({
      query: text,
      duration,
      rows: result.rowCount
    });
    
    return result;
  } catch (error) {
    logger.error({
      query: text,
      error: error.message
    });
    throw error;
  }
};
```

## Migrating SQLite Queries

Common SQLite query patterns and their PostgreSQL equivalents:

### Auto-incrementing IDs

```javascript
// SQLite - lastID is directly available
const result = await db.run("INSERT INTO users (name) VALUES (?)", [name]);
const newId = result.lastID;

// PostgreSQL - must use RETURNING
const result = await pool.query(
  "INSERT INTO users (name) VALUES ($1) RETURNING id", 
  [name]
);
const newId = result.rows[0].id;
```

### LIKE Queries (Case Sensitivity)

```javascript
// SQLite - LIKE is case-insensitive by default
db.all("SELECT * FROM users WHERE username LIKE ?", [`%${search}%`]);

// PostgreSQL - LIKE is case-sensitive by default
// For case-insensitive search, use ILIKE
pool.query("SELECT * FROM users WHERE username ILIKE $1", [`%${search}%`]);
```

### Date Handling

```javascript
// SQLite - dates as strings
db.run("INSERT INTO events (name, date) VALUES (?, ?)", 
  ["Event", "2023-06-15"]);

// PostgreSQL - use native date type
pool.query("INSERT INTO events (name, date) VALUES ($1, $2)", 
  ["Event", new Date(2023, 5, 15)]); // JavaScript months are 0-indexed

// PostgreSQL - working with timestamps
pool.query(`
  SELECT * FROM events 
  WHERE date BETWEEN $1::timestamp AND $2::timestamp`,
  ["2023-06-01", "2023-06-30"]
);
```

### RETURNING Clause

PostgreSQL's RETURNING clause provides data from modified rows:

```javascript
// Update and get updated data in one query
const result = await pool.query(`
  UPDATE users 
  SET last_login = CURRENT_TIMESTAMP
  WHERE id = $1
  RETURNING *`,
  [userId]
);

const updatedUser = result.rows[0];

// Delete and get deleted data
const result = await pool.query(`
  DELETE FROM temp_records
  WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '7 days'
  RETURNING id, created_at`,
  []
);

console.log(`Deleted ${result.rowCount} old records:`, result.rows);
```

### LIMIT and OFFSET

```javascript
// SQLite - LIMIT and OFFSET
db.all("SELECT * FROM posts ORDER BY date DESC LIMIT ? OFFSET ?", 
  [10, 20]);

// PostgreSQL - similar syntax
pool.query("SELECT * FROM posts ORDER BY date DESC LIMIT $1 OFFSET $2", 
  [10, 20]);
```

### Aggregation Functions

```javascript
// SQLite
db.get("SELECT COUNT(*) as count FROM users WHERE active = ?", [true]);

// PostgreSQL 
pool.query("SELECT COUNT(*) as count FROM users WHERE active = $1", [true])
  .then(result => {
    // Count is returned as a string
    const count = parseInt(result.rows[0].count);
  });
```

---

[<- Back: PostgreSQL Schema Design](./04-schema-design.md) | [Next: PostgreSQL Features ->](./06-postgresql-features.md)
