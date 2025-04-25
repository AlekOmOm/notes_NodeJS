# 2a. PostgreSQL Docker Setup 🐳

[<- Back to Main Topic](./02-setup.md) | [Next Sub-Topic: Local Installation ->](./02b-local-installation.md)

## Overview

Using Docker for PostgreSQL deployment provides a clean, isolated environment that's consistent across development, testing, and production. This approach is particularly beneficial for developers transitioning from SQLite who want minimal interference with their local system.

## Key Concepts

### Docker Containers vs. Local Installation

Docker containers provide several advantages for PostgreSQL:

- **Isolation**: Database runs in its own container without affecting the host system
- **Consistency**: Same PostgreSQL version and configuration across all environments
- **Easy cleanup**: Remove containers without leaving traces on your system
- **Simplified setup**: No need to handle native installation dependencies
- **Version control**: Easily switch between PostgreSQL versions

### Docker Compose

Docker Compose lets you define multi-container applications in a single YAML file:

```yaml
# docker-compose.yml
version: '3.8'
services:
  postgres:
    image: postgres:15
    container_name: my_postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-myuser}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-mypassword}
      POSTGRES_DB: ${POSTGRES_DB:-myapp}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./sql:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U myuser -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

## Implementation Patterns

### Pattern 1: Basic Development Setup

Simple configuration for local development:

```yaml
# docker-compose.dev.yml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: dev_user
      POSTGRES_PASSWORD: dev_password
      POSTGRES_DB: dev_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data

volumes:
  postgres_dev_data:
```

**When to use this pattern:**
- Local development environment
- Quick setup for testing
- Single developer scenarios

### Pattern 2: Production-Ready Setup

Enhanced configuration with security and performance considerations:

```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  postgres:
    image: postgres:15
    container_name: prod_postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
      # Performance tuning
      POSTGRES_SHARED_BUFFERS: 256MB
      POSTGRES_EFFECTIVE_CACHE_SIZE: 768MB
      POSTGRES_WORK_MEM: 16MB
    volumes:
      - postgres_prod_data:/var/lib/postgresql/data
      - ./backup:/backup
    ports:
      - "127.0.0.1:5432:5432"  # Only accessible locally
    restart: always
    networks:
      - backend_network
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G

networks:
  backend_network:
    driver: bridge

volumes:
  postgres_prod_data:
    driver: local
```

**When to use this pattern:**
- Production deployments
- When security is critical
- Applications with performance requirements

## Common Challenges and Solutions

### Challenge 1: Data Persistence

If Docker containers are removed, you might lose your data.

**Solution:**

```yaml
volumes:
  - postgres_data:/var/lib/postgresql/data  # Named volume for persistence
  # For backups:
  - ./backups:/backups  # Mount a local directory for backups
```

Backup script:

```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y-%m-%d_%H-%M-%S)
docker exec -t my_postgres pg_dump -U myuser myapp > ./backups/myapp_$DATE.sql
```

### Challenge 2: Initial Database Setup

You need to create tables and seed data when the container first runs.

**Solution:**

Create initialization SQL scripts in a directory, then mount it:

```yaml
volumes:
  - ./sql:/docker-entrypoint-initdb.d  # Scripts here run on container first start
```

Example initialization script:

```sql
-- /sql/01-schema.sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(100) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- /sql/02-seed.sql
INSERT INTO users (username, email)
VALUES
  ('admin', 'admin@example.com'),
  ('test_user', 'test@example.com');
```

## Practical Example

A complete setup for a development environment with PostgreSQL and pgAdmin:

```javascript
// docker-compose.yml
version: '3.8'
services:
  postgres:
    image: postgres:15
    container_name: express_postgres
    environment:
      POSTGRES_USER: express_user
      POSTGRES_PASSWORD: express_password
      POSTGRES_DB: express_app
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./sql:/docker-entrypoint-initdb.d
    networks:
      - postgres_network
      
  pgadmin:
    image: dpage/pgadmin4
    container_name: express_pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: admin_password
    ports:
      - "5050:80"
    depends_on:
      - postgres
    networks:
      - postgres_network

networks:
  postgres_network:
    driver: bridge

volumes:
  postgres_data:
```

Usage commands:

```bash
# Start the containers
docker-compose up -d

# Check logs
docker-compose logs -f postgres

# Connect to PostgreSQL via command line
docker exec -it express_postgres psql -U express_user -d express_app

# Backup database
docker exec -t express_postgres pg_dump -U express_user -d express_app > backup.sql

# Restore database
cat backup.sql | docker exec -i express_postgres psql -U express_user -d express_app

# Stop containers
docker-compose down
```

## Summary

1. Docker provides a clean, isolated environment for PostgreSQL
2. Docker Compose simplifies multi-container setup
3. Volume mapping ensures data persistence
4. Initialization scripts automate database setup
5. Environment variables keep configurations flexible
6. Health checks ensure database availability
7. Network configuration enhances security

## Next Steps

Now that you understand how to set up PostgreSQL in Docker, you may want to learn about local installation options or connecting your Express application to the PostgreSQL database.

---

[<- Back to Main Topic](./02-setup.md) | [Next Sub-Topic: Local Installation ->](./02b-local-installation.md)
