# 8. Docker Deployment 🐳

[<- Back: Authentication System Setup](./07-auth-system.md) | [Next: PostgreSQL on Home Server ->](./09-postgresql-on-homeserver.md)

## Table of Contents

- [Container Basics](#container-basics)
- [PostgreSQL Docker Configuration](#postgresql-docker-configuration)
- [Environment Variables](#environment-variables)
- [Data Persistence](#data-persistence)
- [Multi-Container Setups](#multi-container-setups)
- [Deployment Strategies](#deployment-strategies)
- [Monitoring and Maintenance](#monitoring-and-maintenance)

## Container Basics

Docker containers provide a consistent, isolated environment for PostgreSQL:

### Why Use Docker for PostgreSQL

1. **Consistency**: Same database environment across development, testing, and production
2. **Isolation**: Database runs in a contained environment without affecting other services
3. **Portability**: Easy deployment across different platforms and cloud providers
4. **Version Management**: Simple upgrades and downgrade procedures
5. **Resource Control**: Limit CPU, memory, and disk usage

### Core Docker Concepts for PostgreSQL

- **Images**: Pre-built PostgreSQL templates (e.g., `postgres:15`)
- **Containers**: Running instances of PostgreSQL images
- **Volumes**: Persistent storage for database files
- **Networks**: Communication between containers and external services
- **Docker Compose**: Tool for defining multi-container applications

## PostgreSQL Docker Configuration

### Basic PostgreSQL Container

```bash
# Run a simple PostgreSQL container
docker run --name postgres-db \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_DB=myapp \
  -p 5432:5432 \
  -d postgres:15
```

### Docker Compose Configuration

```yaml
# docker-compose.yml - Basic PostgreSQL setup
version: '3.8'
services:
  postgres:
    image: postgres:15
    container_name: postgres-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-myuser}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-mysecretpassword}
      POSTGRES_DB: ${POSTGRES_DB:-myapp}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init:/docker-entrypoint-initdb.d

volumes:
  postgres_data:
```

### Customizing PostgreSQL Configuration

```yaml
# docker-compose.yml with custom PostgreSQL configuration
services:
  postgres:
    # ... basic configuration
    command: postgres -c max_connections=200 -c shared_buffers=512MB
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgresql.conf:/etc/postgresql/postgresql.conf
      - ./pg_hba.conf:/etc/postgresql/pg_hba.conf
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
```

Example `postgresql.conf` file with performance tuning:

```
# postgresql.conf
listen_addresses = '*'
max_connections = 100
shared_buffers = 256MB
work_mem = 16MB
maintenance_work_mem = 64MB
effective_cache_size = 1GB
synchronous_commit = off  # For higher performance (with some data loss risk)
wal_buffers = 16MB
checkpoint_completion_target = 0.9
random_page_cost = 1.1   # For SSD storage
```

## Environment Variables

Docker allows configuring PostgreSQL via environment variables:

### Critical Configuration Variables

```yaml
environment:
  # Basic configuration
  POSTGRES_USER: myuser
  POSTGRES_PASSWORD: mysecretpassword
  POSTGRES_DB: myapp
  
  # Optional configurations
  PGDATA: /var/lib/postgresql/data/pgdata
  POSTGRES_INITDB_ARGS: "--data-checksums --encoding=UTF8"
  POSTGRES_HOST_AUTH_METHOD: md5
```

### Using .env Files

Create a `.env` file for sensitive data:

```
# .env
POSTGRES_USER=myuser
POSTGRES_PASSWORD=verysecretpassword
POSTGRES_DB=myapp
POSTGRES_PORT=5432
```

Reference in Docker Compose:

```yaml
# docker-compose.yml
services:
  postgres:
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    ports:
      - "${POSTGRES_PORT}:5432"
```

### Setting Database Parameters

```yaml
environment:
  # Performance tuning
  POSTGRES_SHARED_BUFFERS: 256MB
  POSTGRES_WORK_MEM: 16MB
  POSTGRES_EFFECTIVE_CACHE_SIZE: 1GB
  POSTGRES_MAX_CONNECTIONS: 100
```

## Data Persistence

Ensuring PostgreSQL data survives container restarts and updates:

### Volume Types

```yaml
volumes:
  # Named volume (managed by Docker)
  postgres_data:/var/lib/postgresql/data
  
  # Bind mount (direct path on host)
  - /my/host/data:/var/lib/postgresql/data
  
  # Bind mount for initialization scripts
  - ./init-scripts:/docker-entrypoint-initdb.d
```

### Backup and Restore with Docker

```bash
# Backup PostgreSQL database
docker exec -t postgres-db pg_dumpall -c -U myuser > backup_$(date +%Y-%m-%d_%H-%M-%S).sql

# Restore from backup
cat backup_file.sql | docker exec -i postgres-db psql -U myuser -d myapp
```

Scheduled backup with cron:

```bash
#!/bin/bash
# backup-postgres.sh
BACKUP_DIR="/path/to/backups"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
CONTAINER="postgres-db"
USER="myuser"

docker exec -t $CONTAINER pg_dumpall -c -U $USER > $BACKUP_DIR/backup_$TIMESTAMP.sql
gzip $BACKUP_DIR/backup_$TIMESTAMP.sql

# Delete backups older than 7 days
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +7 -delete
```

Add to crontab:

```
0 2 * * * /path/to/backup-postgres.sh
```

## Multi-Container Setups

Combining PostgreSQL with other services:

### Express API with PostgreSQL

```yaml
# docker-compose.yml
version: '3.8'
services:
  api:
    build: ./api
    container_name: express-api
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      DATABASE_URL: postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
    depends_on:
      - postgres
    networks:
      - app-network

  postgres:
    image: postgres:15
    container_name: postgres-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-myuser}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-mysecretpassword}
      POSTGRES_DB: ${POSTGRES_DB:-myapp}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  postgres_data:
```

### Adding pgAdmin for Database Management

```yaml
# Adding pgAdmin to the composition
services:
  # ... existing services

  pgadmin:
    image: dpage/pgadmin4
    container_name: pgadmin
    restart: unless-stopped
    ports:
      - "5050:80"
    environment:
      PGADMIN_DEFAULT_EMAIL: ${PGADMIN_EMAIL:-admin@example.com}
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD:-admin}
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    depends_on:
      - postgres
    networks:
      - app-network

volumes:
  # ... existing volumes
  pgadmin_data:
```

### Full-Stack Application Example

```yaml
# Complete development stack
version: '3.8'
services:
  frontend:
    build: ./frontend
    container_name: react-frontend
    restart: unless-stopped
    ports:
      - "80:80"
    networks:
      - app-network

  api:
    build: ./api
    container_name: express-api
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: development
      DATABASE_URL: postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      REDIS_URL: redis://redis:6379
    depends_on:
      - postgres
      - redis
    volumes:
      - ./api:/usr/src/app
      - /usr/src/app/node_modules
    networks:
      - app-network

  postgres:
    image: postgres:15
    container_name: postgres-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-myuser}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-mysecretpassword}
      POSTGRES_DB: ${POSTGRES_DB:-myapp}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network

  redis:
    image: redis:7
    container_name: redis-cache
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - app-network

  pgadmin:
    image: dpage/pgadmin4
    container_name: pgadmin
    restart: unless-stopped
    ports:
      - "5050:80"
    environment:
      PGADMIN_DEFAULT_EMAIL: ${PGADMIN_EMAIL:-admin@example.com}
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD:-admin}
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    depends_on:
      - postgres
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
  pgadmin_data:
```

## Deployment Strategies

Approaches for deploying PostgreSQL in different environments:

### Development Environment

```yaml
# docker-compose.dev.yml
version: '3.8'
services:
  postgres:
    image: postgres:15
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: dev_user
      POSTGRES_PASSWORD: dev_password
      POSTGRES_DB: dev_db
    volumes:
      - postgres_dev:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d

volumes:
  postgres_dev:
```

### Testing Environment

```yaml
# docker-compose.test.yml
version: '3.8'
services:
  postgres:
    image: postgres:15
    ports:
      - "5433:5432"  # Different port to avoid conflicts
    environment:
      POSTGRES_USER: test_user
      POSTGRES_PASSWORD: test_password
      POSTGRES_DB: test_db
    tmpfs: /var/lib/postgresql/data  # Use RAM for faster tests
```

### Production Environment

```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  postgres:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_prod:/var/lib/postgresql/data
    expose:
      - "5432"  # Only expose to internal network
    networks:
      - backend_network
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

networks:
  backend_network:
    driver: bridge

volumes:
  postgres_prod:
    driver: local
    driver_opts:
      type: 'none'
      o: 'bind'
      device: '/mnt/data/postgres'
```

### Docker Swarm or Kubernetes

For production deployments with high availability, consider:

1. **Docker Swarm**: Simple cluster management
2. **Kubernetes**: Advanced orchestration with StatefulSets for PostgreSQL

```yaml
# kubernetes-postgres.yml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: "postgres"
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secrets
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secrets
              key: password
        - name: POSTGRES_DB
          value: myapp
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
```

## Monitoring and Maintenance

Keeping PostgreSQL containers healthy:

### Container Health Checks

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U myuser -d myapp"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s
```

### Monitoring Tools

```yaml
# Add Prometheus and Grafana for monitoring
services:
  # ... existing services
  
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    networks:
      - monitoring_network
  
  grafana:
    image: grafana/grafana
    container_name: grafana
    ports:
      - "3001:3000"
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: grafana
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - monitoring_network

networks:
  # ... existing networks
  monitoring_network:
    driver: bridge

volumes:
  # ... existing volumes
  prometheus_data:
  grafana_data:
```

### Automated Backups Container

```yaml
services:
  # ... existing services
  
  postgres-backup:
    image: prodrigestivill/postgres-backup-local
    container_name: postgres-backup
    restart: unless-stopped
    volumes:
      - /path/to/backups:/backups
    environment:
      POSTGRES_HOST: postgres
      POSTGRES_DB: myapp
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      SCHEDULE: '@daily'
      BACKUP_KEEP_DAYS: 7
      BACKUP_KEEP_WEEKS: 4
      BACKUP_KEEP_MONTHS: 6
    networks:
      - app-network
    depends_on:
      - postgres
```

### Automatic Container Updates

Use Watchtower to automatically update containers:

```yaml
services:
  # ... existing services
  
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --interval 86400 --cleanup
    restart: unless-stopped
```

### Practical Docker Scripts

**Start Services**:

```bash
#!/bin/bash
# start-postgres.sh

# Load environment variables
set -a
source .env
set +a

# Start containers
docker-compose -f docker-compose.yml up -d

# Check logs
docker-compose logs -f postgres
```

**Backup Database**:

```bash
#!/bin/bash
# backup-postgres.sh

# Load environment variables
set -a
source .env
set +a

# Set backup directory and filename
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/postgres_backup_$TIMESTAMP.sql"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Create backup
echo "Creating backup: $BACKUP_FILE"
docker-compose exec -T postgres pg_dumpall -c -U $POSTGRES_USER > $BACKUP_FILE

# Compress backup
gzip $BACKUP_FILE
echo "Backup compressed: $BACKUP_FILE.gz"

# Delete backups older than 7 days
find $BACKUP_DIR -name "postgres_backup_*.sql.gz" -mtime +7 -delete
echo "Old backups cleaned up"
```

**Restore Database**:

```bash
#!/bin/bash
# restore-postgres.sh

# Load environment variables
set -a
source .env
set +a

# Check if backup file is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <backup_file>"
  exit 1
fi

BACKUP_FILE=$1

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE"
  exit 1
fi

# Uncompress if needed
if [[ "$BACKUP_FILE" == *.gz ]]; then
  echo "Uncompressing backup file..."
  gunzip -c "$BACKUP_FILE" > "${BACKUP_FILE%.gz}"
  BACKUP_FILE="${BACKUP_FILE%.gz}"
fi

# Restore database
echo "Restoring from: $BACKUP_FILE"
cat "$BACKUP_FILE" | docker-compose exec -T postgres psql -U $POSTGRES_USER

echo "Restore completed"
```

---

[<- Back: Authentication System Setup](./07-auth-system.md) | [Next: PostgreSQL on Home Server ->](./09-postgresql-on-homeserver.md)
