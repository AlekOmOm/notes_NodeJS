# 2. Setting Up PostgreSQL 🛠️

[<- Back: Introduction](./01-introduction.md) | [Next: Connecting PostgreSQL to Express ->](./03-connection.md)

---
- [2a. Docker Setup](./02a-docker-setup.md)
- [2b. Local Installation](./02b-local-installation.md)
---

## Table of Contents

- [Installation Options](#installation-options)
- [Docker Setup (Recommended)](#docker-setup-recommended)
- [Local Installation](#local-installation)
- [Database Creation](#database-creation)
- [User Management](#user-management)
- [Basic Configuration](#basic-configuration)

## Installation Options

There are two primary methods to set up PostgreSQL for your Express application:

1. **Docker container** (recommended): Isolated, consistent, and portable
2. **Local installation**: Direct install on development machine

Each approach has advantages depending on your workflow and deployment strategy.

## Docker Setup (Recommended)

Docker provides the simplest way to get started with PostgreSQL, especially for development environments.

### Quick Start with Docker Compose

Create a `docker-compose.yml` file in your project root:

```yaml
version: '3.8'
services:
  db:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
      POSTGRES_DB: myapp
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d

volumes:
  postgres_data:
```

### Starting the Container

```bash
# Start PostgreSQL container
docker-compose up -d

# View logs
docker-compose logs -f db

# Connect to PostgreSQL shell
docker exec -it <container_name> psql -U myuser -d myapp
```

### Initialization Scripts

Create an `init-scripts` directory in your project with SQL files to run on container startup:

```sql
-- init-scripts/01-schema.sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(100) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add more tables as needed
```

## Local Installation

For situations where Docker isn't an option, you can install PostgreSQL directly.

### Installation by Platform

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
```

**macOS (via Homebrew):**
```bash
brew install postgresql
brew services start postgresql
```

**Windows:**
Download the installer from the [PostgreSQL website](https://www.postgresql.org/download/windows/) and follow the installation wizard.

### Post-Installation Setup

After installation, you need to:
1. Start the PostgreSQL service
2. Set the password for the default `postgres` user

```bash
# Ubuntu/Debian
sudo service postgresql start
sudo -u postgres psql
postgres=# \password postgres

# macOS
psql postgres
postgres=# \password postgres
```

## Database Creation

Creating a database for your application:

```sql
-- Via psql command line
CREATE DATABASE myapp;

-- Or from terminal
createdb -U postgres myapp
```

Alternatively, create the database using node.js:

```javascript
import { Client } from 'pg';

const setupDatabase = async () => {
  // Connect to default postgres database first
  const client = new Client({
    host: 'localhost',
    port: 5432,
    user: 'postgres',
    password: 'your_password',
    database: 'postgres'
  });
  
  await client.connect();
  
  // Check if our database exists
  const res = await client.query(
    "SELECT 1 FROM pg_database WHERE datname = $1",
    ['myapp']
  );
  
  // Create if it doesn't exist
  if (res.rowCount === 0) {
    // Need to use template0 to avoid "database is being accessed by other users"
    await client.query('CREATE DATABASE myapp WITH TEMPLATE template0');
    console.log('Database created');
  } else {
    console.log('Database already exists');
  }
  
  await client.end();
};

setupDatabase().catch(console.error);
```

## User Management

For better security, create a dedicated user for your application:

```sql
-- Create user with password
CREATE USER myapp_user WITH PASSWORD 'secure_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE myapp TO myapp_user;

-- If using schemas, grant privileges on schema
\c myapp
GRANT ALL ON SCHEMA public TO myapp_user;

-- Grant privileges on future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO myapp_user;
```

## Basic Configuration

PostgreSQL's configuration is stored in `postgresql.conf` and `pg_hba.conf` files.

In Docker, you can pass configuration options via environment variables:

```yaml
environment:
  POSTGRES_USER: myuser
  POSTGRES_PASSWORD: mypassword
  POSTGRES_DB: myapp
  # Performance tuning
  POSTGRES_SHARED_BUFFERS: 256MB
  POSTGRES_WORK_MEM: 16MB
  POSTGRES_EFFECTIVE_CACHE_SIZE: 1GB
```

For local installations, you may need to modify these files directly:

```bash
# Find config file location
psql -U postgres -c 'SHOW config_file'
```

Common settings to adjust:

| Parameter | Description | Example Value |
|-----------|-------------|---------------|
| `max_connections` | Maximum concurrent connections | 100 |
| `shared_buffers` | Memory for caching | 25% of RAM |
| `work_mem` | Memory for sort operations | 4MB |
| `effective_cache_size` | Disk cache estimate | 50-75% of RAM |
| `listen_addresses` | Network interfaces to listen on | '*' for all |

---

[<- Back: Introduction](./01-introduction.md) | [Next: Connecting PostgreSQL to Express ->](./03-connection.md)
