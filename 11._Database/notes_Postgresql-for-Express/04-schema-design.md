# 4. PostgreSQL Schema Design 📊

[<- Back: Connecting PostgreSQL to Express](./03-connection.md) | [Next: Query Execution ->](./05-query-execution.md)

## Table of Contents

- [Data Types](#data-types)
- [Creating Tables](#creating-tables)
- [Constraints and Relationships](#constraints-and-relationships)
- [Schemas](#schemas)
- [Indexes](#indexes)
- [Migrations](#migrations)
- [Schema Comparison: SQLite vs PostgreSQL](#schema-comparison-sqlite-vs-postgresql)

## Data Types

PostgreSQL offers a rich set of data types beyond what's available in SQLite:

| Category | PostgreSQL Types | SQLite Equivalent | Notes |
|----------|------------------|-------------------|-------|
| **Numeric** | INTEGER, BIGINT, SMALLINT, DECIMAL, NUMERIC, REAL, DOUBLE PRECISION | INTEGER, REAL | PostgreSQL has more precise control over number size and precision |
| **String** | CHAR(n), VARCHAR(n), TEXT | TEXT | Text in PostgreSQL has explicit length limits with VARCHAR |
| **Boolean** | BOOLEAN | INTEGER (0/1) | True native boolean type |
| **Date/Time** | TIMESTAMP, DATE, TIME, INTERVAL, TIMESTAMPTZ | TEXT or INTEGER | True date/time types with timezone support |
| **Binary** | BYTEA | BLOB | For storing binary data |
| **JSON** | JSON, JSONB | TEXT | Native JSON support with indexing and operators |
| **Arrays** | Any type[] | No equivalent | Store arrays of values |
| **User-defined** | ENUM, Composite types | No equivalent | Custom types |
| **Geometric** | POINT, LINE, POLYGON | No equivalent | Spatial data |
| **Network** | INET, CIDR, MACADDR | No equivalent | Network address types |

### Key PostgreSQL-Specific Types

```sql
-- JSONB: Binary JSON with indexing
CREATE TABLE config (
    id SERIAL PRIMARY KEY,
    settings JSONB NOT NULL
);
INSERT INTO config (settings) VALUES ('{"theme": "dark", "notifications": true}');
SELECT * FROM config WHERE settings->>'theme' = 'dark';

-- Array types
CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    related_tags TEXT[]
);
INSERT INTO tags (name, related_tags) VALUES ('javascript', ARRAY['typescript', 'node.js']);
SELECT * FROM tags WHERE 'node.js' = ANY(related_tags);

-- Enumerated types
CREATE TYPE user_role AS ENUM ('admin', 'moderator', 'user');
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    role user_role NOT NULL DEFAULT 'user'
);
```

## Creating Tables

PostgreSQL CREATE TABLE syntax is similar to SQLite with some important differences:

```sql
-- Basic table creation
CREATE TABLE games (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    short_description TEXT,
    genre VARCHAR(50) CHECK (genre IN ('MMO', 'RPG', 'FPS')),
    release_date DATE,
    rating DECIMAL(3,1) CHECK (rating >= 0 AND rating <= 10),
    is_multiplayer BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- With foreign key
CREATE TABLE game_reviews (
    id SERIAL PRIMARY KEY,
    game_id INTEGER NOT NULL,
    reviewer_name VARCHAR(100) NOT NULL,
    content TEXT,
    score INTEGER CHECK (score >= 1 AND score <= 5),
    review_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE
);
```

### Auto-Incrementing IDs

PostgreSQL uses SERIAL (or BIGSERIAL for larger values) instead of SQLite's INTEGER PRIMARY KEY AUTOINCREMENT:

```sql
-- SQLite
id INTEGER PRIMARY KEY AUTOINCREMENT

-- PostgreSQL
id SERIAL PRIMARY KEY
```

For UUID primary keys (often preferred in distributed systems):

```sql
-- First, enable the uuid-ossp extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Then use UUID as primary key
CREATE TABLE sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,
    data JSONB
);
```

## Constraints and Relationships

PostgreSQL enforces constraints more strictly than SQLite:

```sql
-- Primary Key constraint
id SERIAL PRIMARY KEY

-- Foreign Key with cascade delete
FOREIGN KEY (runtime_environment_id) 
  REFERENCES runtime_environments (id) 
  ON DELETE CASCADE

-- Unique constraint
email VARCHAR(255) UNIQUE NOT NULL

-- Check constraint
age INTEGER CHECK (age >= 18)

-- Default values
created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP

-- Not null constraint
username VARCHAR(100) NOT NULL
```

### Relationship Types

```sql
-- One-to-One: User to Profile
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL,
    bio TEXT,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- One-to-Many: Author to Books
CREATE TABLE authors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author_id INTEGER NOT NULL,
    FOREIGN KEY (author_id) REFERENCES authors (id)
);

-- Many-to-Many: Students to Courses (with junction table)
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL
);

CREATE TABLE enrollments (
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE CASCADE
);
```

## Schemas

PostgreSQL supports schema namespaces to organize tables logically:

```sql
-- Create a schema
CREATE SCHEMA api;

-- Create table in schema
CREATE TABLE api.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL
);

-- Query from specific schema
SELECT * FROM api.users;

-- Set search path (default schema)
SET search_path TO api, public;
```

Common schema usages:
- `public`: Default schema
- `auth`: Authentication-related tables
- `api`: API-related data
- `audit`: Audit logs and history

## Indexes

Indexes improve query performance significantly:

```sql
-- Basic index
CREATE INDEX idx_games_title ON games (title);

-- Compound index (multiple columns)
CREATE INDEX idx_games_genre_rating ON games (genre, rating);

-- Unique index
CREATE UNIQUE INDEX idx_users_email ON users (email);

-- Partial index (only index some rows)
CREATE INDEX idx_reviews_high_score ON game_reviews (game_id) 
WHERE score > 4;

-- Expression index
CREATE INDEX idx_users_lower_email ON users (LOWER(email));

-- JSONB index
CREATE INDEX idx_config_settings ON config USING GIN (settings);
```

When to use different index types:
- B-tree (default): Most common, good for equality and range queries
- GIN: Good for JSONB and array columns
- GIST: Spatial data and full-text search
- Hash: Equality comparisons only (faster than B-tree for this case)

## Migrations

For evolving your database schema, migrations track changes in version control:

### Using Node.js Scripts

```javascript
// migrations/001-initial-schema.js
import connection from '../database/connection.js';

export async function up() {
  await connection.exec(`
    CREATE TABLE users (
      id SERIAL PRIMARY KEY,
      username VARCHAR(100) UNIQUE NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE TABLE sessions (
      id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
      user_id INTEGER NOT NULL,
      expires_at TIMESTAMPTZ NOT NULL,
      data JSONB,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    );
  `);
}

export async function down() {
  await connection.exec('DROP TABLE IF EXISTS sessions;');
  await connection.exec('DROP TABLE IF EXISTS users;');
}
```

### Migration Runner

```javascript
// database/migrate.js
import fs from 'fs/promises';
import path from 'path';
import connection from './connection.js';

async function createMigrationsTable() {
  await connection.exec(`
    CREATE TABLE IF NOT EXISTS migrations (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      applied_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  `);
}

async function getAppliedMigrations() {
  await createMigrationsTable();
  return await connection.all('SELECT name FROM migrations ORDER BY id');
}

async function migrate() {
  const applied = await getAppliedMigrations();
  const appliedMigrations = applied.map(m => m.name);
  
  const migrationFiles = await fs.readdir(path.join(process.cwd(), 'migrations'));
  const pendingMigrations = migrationFiles
    .filter(file => file.endsWith('.js') && !appliedMigrations.includes(file));
  
  for (const migrationFile of pendingMigrations.sort()) {
    const { up } = await import(`../migrations/${migrationFile}`);
    console.log(`Applying migration: ${migrationFile}`);
    
    try {
      await connection.transaction(async client => {
        await up(client);
        await client.query('INSERT INTO migrations (name) VALUES ($1)', [migrationFile]);
      });
      console.log(`Migration ${migrationFile} applied successfully.`);
    } catch (error) {
      console.error(`Migration ${migrationFile} failed:`, error);
      process.exit(1);
    }
  }
}

migrate().catch(console.error);
```

## Schema Comparison: SQLite vs PostgreSQL

Converting your SQLite schema to PostgreSQL:

### SQLite Schema

```sql
CREATE TABLE runtime_environments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    platform TEXT,
    version TEXT
);

CREATE TABLE games (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    short_description VARCHAR(500),
    genre TEXT CHECK(genre IN ('MMO', 'RPG', 'FPS')),
    runtime_environment_id INTEGER,
    FOREIGN KEY (runtime_environment_id) REFERENCES runtime_environments (id)
);
```

### PostgreSQL Equivalent

```sql
CREATE TABLE runtime_environments (
    id SERIAL PRIMARY KEY,
    platform TEXT NOT NULL,
    version TEXT
);

CREATE TABLE games (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    short_description VARCHAR(500),
    genre VARCHAR(50) CHECK(genre IN ('MMO', 'RPG', 'FPS')),
    runtime_environment_id INTEGER,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (runtime_environment_id) 
        REFERENCES runtime_environments (id)
        ON DELETE SET NULL
);
```

Key differences:
1. `SERIAL` instead of `INTEGER PRIMARY KEY AUTOINCREMENT`
2. Stricter data types (VARCHAR with length limits)
3. Explicit `NOT NULL` constraints
4. Addition of timestamp fields for tracking
5. Explicit foreign key behavior (ON DELETE SET NULL)

---

[<- Back: Connecting PostgreSQL to Express](./03-connection.md) | [Next: Query Execution ->](./05-query-execution.md)
