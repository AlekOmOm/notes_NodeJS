# 6. PostgreSQL Features ⚡

[<- Back: Query Execution](./05-query-execution.md) | [Next: Authentication System Setup ->](./07-auth-system.md)

## Table of Contents

- [JSON Data](#json-data)
- [Array Types](#array-types)
- [Full-Text Search](#full-text-search)
- [Triggers and Functions](#triggers-and-functions)
- [Inheritance and Partitioning](#inheritance-and-partitioning)
- [Performance Optimization](#performance-optimization)
- [Advanced Indexing](#advanced-indexing)

## JSON Data

PostgreSQL provides powerful JSON capabilities that SQLite lacks:

### JSON vs. JSONB

```sql
-- JSON: Stored as text, preserves formatting and order
CREATE TABLE config_json (
    id SERIAL PRIMARY KEY,
    data JSON
);

-- JSONB: Binary format, more efficient for operations and indexing
CREATE TABLE config_jsonb (
    id SERIAL PRIMARY KEY,
    data JSONB
);
```

### Accessing JSON Data

```sql
-- Insert JSON data
INSERT INTO config_jsonb (data) VALUES 
('{"app": "my_app", "version": "1.0", "settings": {"theme": "dark", "notifications": true}}');

-- Extract specific fields with -> and ->>
SELECT 
  data->'app' AS app_json,        -- Returns JSON: "my_app"
  data->>'app' AS app_text,       -- Returns text: my_app
  data->'settings'->'theme' AS theme  -- Nested access
FROM config_jsonb;

-- Filter by JSON values
SELECT * FROM config_jsonb 
WHERE data->>'app' = 'my_app' AND (data->'settings'->>'notifications')::boolean = true;
```

### JSON Operators

```sql
-- Check if key exists
SELECT * FROM config_jsonb WHERE data ? 'version';

-- Check if nested path exists
SELECT * FROM config_jsonb WHERE data @> '{"settings": {"theme": "dark"}}';

-- Update a JSON field
UPDATE config_jsonb 
SET data = jsonb_set(data, '{settings,theme}', '"light"')
WHERE data->>'app' = 'my_app';

-- Merge JSON objects
UPDATE config_jsonb
SET data = data || '{"updated_at": "2023-06-15", "settings": {"language": "en"}}'::jsonb
WHERE id = 1;
```

### Using JSON in Express

```javascript
// Store user preferences
async function saveUserPreferences(userId, preferences) {
  await pool.query(
    'UPDATE users SET preferences = $1 WHERE id = $2',
    [JSON.stringify(preferences), userId]
  );
}

// Retrieve and use JSON data
async function getUserSettings(userId) {
  const result = await pool.query(
    'SELECT preferences FROM users WHERE id = $1',
    [userId]
  );
  
  if (result.rows.length === 0) return null;
  
  // PostgreSQL already parses the JSON for you
  const preferences = result.rows[0].preferences;
  return preferences;
}
```

## Array Types

PostgreSQL supports arrays of any data type:

```sql
-- Create table with array columns
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    tags TEXT[] DEFAULT '{}',
    prices DECIMAL[] DEFAULT '{}'
);

-- Insert array data
INSERT INTO products (name, tags, prices)
VALUES 
('Smartphone', ARRAY['electronics', 'mobile', 'gadget'], ARRAY[499.99, 599.99, 699.99]),
('Headphones', ARRAY['electronics', 'audio'], ARRAY[99.99, 149.99]);

-- Query array elements
SELECT name, tags[1] AS primary_tag FROM products;

-- Check if array contains element
SELECT * FROM products WHERE 'audio' = ANY(tags);

-- Array functions
SELECT 
  name,
  array_length(tags, 1) AS tag_count,
  array_to_string(tags, ', ') AS tag_list
FROM products;

-- Append to array
UPDATE products 
SET tags = array_append(tags, 'sale') 
WHERE id = 1;

-- Remove from array
UPDATE products 
SET tags = array_remove(tags, 'mobile') 
WHERE id = 1;
```

### Using Arrays in Express

```javascript
// Store array data
async function addProduct(name, tags, prices) {
  return await pool.query(
    'INSERT INTO products (name, tags, prices) VALUES ($1, $2, $3) RETURNING id',
    [name, tags, prices] // Pass arrays directly
  );
}

// Query with array parameters
async function getProductsByTags(tagList) {
  return await pool.query(
    'SELECT * FROM products WHERE tags && $1',
    [tagList] // Array intersection
  );
}

// Manipulate arrays
async function addTagToProduct(productId, newTag) {
  return await pool.query(
    'UPDATE products SET tags = array_append(tags, $1) WHERE id = $2',
    [newTag, productId]
  );
}
```

## Full-Text Search

PostgreSQL provides built-in text search capabilities:

```sql
-- Create table with full-text search columns
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT,
    search_vector TSVECTOR
);

-- Create index for fast searches
CREATE INDEX articles_search_idx ON articles USING GIN(search_vector);

-- Create trigger to update search vector
CREATE OR REPLACE FUNCTION articles_search_trigger() RETURNS trigger AS $$
BEGIN
  NEW.search_vector = 
    setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.body, '')), 'B');
  RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER tsvector_update_trigger
BEFORE INSERT OR UPDATE ON articles
FOR EACH ROW EXECUTE FUNCTION articles_search_trigger();

-- Insert sample data
INSERT INTO articles (title, body) VALUES 
('PostgreSQL Full-text Search', 'Learning how to implement full-text search using PostgreSQL.'),
('Advanced Database Features', 'PostgreSQL offers many advanced features including JSON and array support.');

-- Basic search
SELECT id, title 
FROM articles 
WHERE search_vector @@ to_tsquery('english', 'postgresql & search');

-- Ranked search results
SELECT id, title, 
       ts_rank(search_vector, query) AS rank
FROM articles, to_tsquery('english', 'postgresql & search') query
WHERE search_vector @@ query
ORDER BY rank DESC;

-- Highlight matches
SELECT id, title,
       ts_headline('english', body, to_tsquery('english', 'postgresql'), 
                  'StartSel=<b>, StopSel=</b>, MaxWords=50, MinWords=5')
FROM articles
WHERE search_vector @@ to_tsquery('english', 'postgresql');
```

### Using Full-Text Search in Express

```javascript
// Search articles function
async function searchArticles(searchTerms) {
  // Convert input to tsquery format (term1 & term2)
  const queryTerms = searchTerms
    .trim()
    .split(/\s+/)
    .filter(term => term.length > 0)
    .join(' & ');
  
  if (!queryTerms) return [];
  
  const result = await pool.query(
    `SELECT 
       id, 
       title, 
       ts_headline('english', body, to_tsquery('english', $1)) AS excerpt,
       ts_rank(search_vector, to_tsquery('english', $1)) AS rank
     FROM articles
     WHERE search_vector @@ to_tsquery('english', $1)
     ORDER BY rank DESC
     LIMIT 10`,
    [queryTerms]
  );
  
  return result.rows;
}

// Express route
app.get('/api/search', async (req, res) => {
  try {
    const { query } = req.query;
    const results = await searchArticles(query);
    res.json(results);
  } catch (error) {
    console.error('Search error:', error);
    res.status(500).json({ error: 'Search failed' });
  }
});
```

## Triggers and Functions

PostgreSQL allows you to define custom functions and triggers:

```sql
-- Create function to set updated_at timestamp
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- Create audit log function
CREATE OR REPLACE FUNCTION audit_log()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_trail (
        table_name, 
        record_id, 
        action, 
        old_data, 
        new_data, 
        user_id
    ) VALUES (
        TG_TABLE_NAME,
        CASE WHEN TG_OP = 'DELETE' THEN OLD.id ELSE NEW.id END,
        TG_OP,
        CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE row_to_json(OLD) END,
        CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE row_to_json(NEW) END,
        current_setting('app.current_user_id', TRUE)::INTEGER
    );
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Apply audit trigger to users table
CREATE TRIGGER users_audit
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION audit_log();
```

### Setting User Context in Express

```javascript
// Middleware to set user ID in PostgreSQL session
function setUserContext(req, res, next) {
  if (req.user && req.user.id) {
    // Execute before any other DB queries in the request
    pool.query("SET LOCAL app.current_user_id = $1", [req.user.id])
      .then(() => next())
      .catch(next);
  } else {
    next();
  }
}

// Apply middleware to routes requiring authentication
app.use('/api/protected', authenticate, setUserContext);

// Now any database operations will have access to user ID for audit logs
app.post('/api/protected/items', async (req, res) => {
  try {
    const result = await pool.query(
      'INSERT INTO items (name, description) VALUES ($1, $2) RETURNING id',
      [req.body.name, req.body.description]
    );
    // The audit trigger will automatically log this action with the current user ID
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

## Inheritance and Partitioning

PostgreSQL supports table inheritance and partitioning for managing large datasets:

### Table Inheritance

```sql
-- Create parent table
CREATE TABLE logs (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    level TEXT,
    message TEXT
);

-- Create child tables that inherit structure
CREATE TABLE error_logs (
    error_code TEXT,
    stack_trace TEXT
) INHERITS (logs);

CREATE TABLE info_logs (
    source TEXT
) INHERITS (logs);

-- Insert into specific child tables
INSERT INTO error_logs (level, message, error_code, stack_trace)
VALUES ('ERROR', 'Connection failed', 'E1001', 'at line 42...');

INSERT INTO info_logs (level, message, source)
VALUES ('INFO', 'User logged in', 'auth_service');

-- Query all logs (from parent and children)
SELECT * FROM logs;

-- Query specific log type
SELECT * FROM ONLY error_logs;
```

### Table Partitioning

For large tables, partitioning improves performance:

```sql
-- Create partitioned table
CREATE TABLE measurements (
    id SERIAL,
    sensor_id INTEGER NOT NULL,
    recorded_at TIMESTAMP NOT NULL,
    temperature DECIMAL(5,2),
    humidity DECIMAL(5,2),
    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

-- Create partitions by time range
CREATE TABLE measurements_y2023m01 PARTITION OF measurements
    FOR VALUES FROM ('2023-01-01') TO ('2023-02-01');

CREATE TABLE measurements_y2023m02 PARTITION OF measurements
    FOR VALUES FROM ('2023-02-01') TO ('2023-03-01');

-- Insert data (automatically goes to correct partition)
INSERT INTO measurements (sensor_id, recorded_at, temperature, humidity)
VALUES (1, '2023-01-15 12:00:00', 22.5, 45.2);

-- Query specific timeframe
SELECT * FROM measurements
WHERE recorded_at BETWEEN '2023-01-01' AND '2023-01-31';
```

### Using Partitioning in Express

```javascript
// Create partition function
async function createMonthlyPartition(year, month) {
  const startDate = new Date(year, month - 1, 1);
  const endDate = new Date(year, month, 1);
  
  const partitionName = `measurements_y${year}m${month.toString().padStart(2, '0')}`;
  
  await pool.query(`
    CREATE TABLE IF NOT EXISTS ${partitionName} PARTITION OF measurements
    FOR VALUES FROM ($1) TO ($2)
  `, [startDate, endDate]);
  
  console.log(`Created partition ${partitionName}`);
}

// Maintenance job to create future partitions
async function setupPartitions() {
  // Create partitions for the next 3 months
  const now = new Date();
  for (let i = 0; i < 3; i++) {
    const targetDate = new Date(now);
    targetDate.setMonth(now.getMonth() + i);
    await createMonthlyPartition(targetDate.getFullYear(), targetDate.getMonth() + 1);
  }
}
```

## Performance Optimization

PostgreSQL provides tools for optimizing query performance:

### Analyzing Queries with EXPLAIN

```sql
-- Basic EXPLAIN
EXPLAIN SELECT * FROM users WHERE email = 'user@example.com';

-- With execution statistics
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'user@example.com';

-- More detailed output
EXPLAIN (FORMAT JSON, ANALYZE, BUFFERS) 
SELECT * FROM users WHERE email = 'user@example.com';
```

### Common Table Expressions (CTEs)

CTEs make complex queries more readable:

```sql
-- Calculate total sales by product category
WITH monthly_sales AS (
    SELECT 
        product_id,
        date_trunc('month', created_at) AS month,
        SUM(quantity * price) AS revenue
    FROM sales
    GROUP BY product_id, month
),
product_categories AS (
    SELECT p.id, p.name, c.name AS category
    FROM products p
    JOIN categories c ON p.category_id = c.id
)
SELECT 
    pc.category,
    ms.month,
    SUM(ms.revenue) AS total_revenue
FROM monthly_sales ms
JOIN product_categories pc ON ms.product_id = pc.id
GROUP BY pc.category, ms.month
ORDER BY ms.month, total_revenue DESC;
```

### Window Functions

Window functions perform calculations across rows:

```sql
-- Rank products by price within categories
SELECT 
    p.name,
    c.name AS category,
    p.price,
    RANK() OVER (PARTITION BY c.name ORDER BY p.price DESC) AS price_rank
FROM products p
JOIN categories c ON p.category_id = c.id;

-- Calculate running total of sales
SELECT 
    created_at::date AS date,
    amount,
    SUM(amount) OVER (ORDER BY created_at::date) AS running_total
FROM sales;

-- Calculate month-over-month growth percentage
SELECT 
    date_trunc('month', created_at) AS month,
    SUM(amount) AS monthly_sales,
    LAG(SUM(amount)) OVER (ORDER BY date_trunc('month', created_at)) AS prev_month_sales,
    CASE 
        WHEN LAG(SUM(amount)) OVER (ORDER BY date_trunc('month', created_at)) IS NULL THEN NULL
        ELSE (SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY date_trunc('month', created_at))) / 
             LAG(SUM(amount)) OVER (ORDER BY date_trunc('month', created_at)) * 100
    END AS growth_percentage
FROM sales
GROUP BY month
ORDER BY month;
```

### Using Window Functions in Express

```javascript
// Get user ranking by activity
async function getUserActivityRankings() {
  return await pool.query(`
    SELECT 
      u.id,
      u.username,
      COUNT(a.id) AS activity_count,
      DENSE_RANK() OVER (ORDER BY COUNT(a.id) DESC) AS activity_rank
    FROM users u
    LEFT JOIN user_activities a ON u.id = a.user_id
    WHERE u.is_active = true
    GROUP BY u.id, u.username
    ORDER BY activity_rank
  `);
}

// Get monthly sales with growth rates
async function getMonthlySalesGrowth() {
  return await pool.query(`
    WITH monthly_sales AS (
      SELECT 
        date_trunc('month', created_at) AS month,
        SUM(amount) AS total
      FROM sales
      GROUP BY month
      ORDER BY month
    )
    SELECT 
      to_char(month, 'YYYY-MM') AS month,
      total::numeric(10,2) AS sales,
      (total - LAG(total) OVER (ORDER BY month))::numeric(10,2) AS change,
      CASE 
        WHEN LAG(total) OVER (ORDER BY month) = 0 THEN NULL
        ELSE round((total - LAG(total) OVER (ORDER BY month)) / 
                   LAG(total) OVER (ORDER BY month) * 100, 2)
      END AS growth_percent
    FROM monthly_sales
  `);
}
```

## Advanced Indexing

PostgreSQL offers specialized index types for different use cases:

### Index Types

```sql
-- B-tree index (default, good for most cases)
CREATE INDEX idx_users_email ON users(email);

-- Hash index (equality comparisons only)
CREATE INDEX idx_sessions_token_hash ON sessions USING HASH (token);

-- GIN index (full-text search, jsonb, arrays)
CREATE INDEX idx_articles_search ON articles USING GIN (search_vector);
CREATE INDEX idx_user_preferences ON users USING GIN (preferences);
CREATE INDEX idx_product_tags ON products USING GIN (tags);

-- BRIN index (block range, good for time-series data)
CREATE INDEX idx_logs_created_at ON logs USING BRIN (created_at);

-- Partial index (subset of rows)
CREATE INDEX idx_active_users ON users (email) WHERE is_active = true;

-- Multi-column index (for compound conditions)
CREATE INDEX idx_products_category_price ON products (category_id, price);

-- Expression index (for function-based queries)
CREATE INDEX idx_users_email_lower ON users (LOWER(email));
```

### Analyzing Index Usage

```sql
-- Check index usage statistics
SELECT 
    relname AS table_name,
    indexrelname AS index_name,
    idx_scan AS number_of_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
JOIN pg_statio_user_indexes USING (indexrelid)
ORDER BY idx_scan DESC;

-- Find unused indexes
SELECT 
    indexrelid::regclass AS index_name,
    relid::regclass AS table_name,
    idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND idx_scan IS NOT NULL
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Index Maintenance

```sql
-- Rebuild index
REINDEX INDEX idx_users_email;

-- Rebuild all indexes on a table
REINDEX TABLE users;

-- Rebuild all indexes in a database
REINDEX DATABASE my_database;
```

### Using Indexes Effectively in Express

```javascript
// Create database model with index creation
const setupDatabase = async () => {
  // Create tables with indexes for common query patterns
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      email VARCHAR(255) UNIQUE NOT NULL,
      username VARCHAR(100) NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      is_active BOOLEAN DEFAULT true,
      last_login TIMESTAMPTZ,
      created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Index for login queries
    CREATE INDEX IF NOT EXISTS idx_users_email_active ON users (email) 
    WHERE is_active = true;
    
    -- Index for case-insensitive username searches
    CREATE INDEX IF NOT EXISTS idx_users_username_lower ON users (LOWER(username));
    
    -- Index for recent user activity queries
    CREATE INDEX IF NOT EXISTS idx_users_last_login ON users (last_login DESC NULLS LAST);
  `);
  
  console.log('Database setup complete with indexes');
};

// Write queries that leverage indexes
async function findUserByEmail(email) {
  // Uses idx_users_email_active index
  return await pool.query(
    'SELECT id, username FROM users WHERE email = $1 AND is_active = true',
    [email]
  );
}

async function searchUsersByUsername(searchTerm) {
  // Uses idx_users_username_lower index
  return await pool.query(
    'SELECT id, username, email FROM users WHERE LOWER(username) LIKE LOWER($1)',
    [`%${searchTerm}%`]
  );
}

async function getRecentlyActiveUsers(limit = 10) {
  // Uses idx_users_last_login index
  return await pool.query(
    'SELECT id, username, last_login FROM users WHERE last_login IS NOT NULL ORDER BY last_login DESC LIMIT $1',
    [limit]
  );
}
```

---

[<- Back: Query Execution](./05-query-execution.md) | [Next: Authentication System Setup ->](./07-auth-system.md)
