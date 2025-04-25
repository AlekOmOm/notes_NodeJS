# 9. PostgreSQL on Home Server 🏠

[<- Back: Docker Deployment](./08-docker-deployment.md)

## Table of Contents

- [Benefits of a Home Server](#benefits-of-a-home-server)
- [Hardware Requirements](#hardware-requirements)
- [Installation Options](#installation-options)
- [Network Configuration](#network-configuration)
- [Security Considerations](#security-considerations)
- [Backup Strategy](#backup-strategy)
- [Centralized Auth Service Setup](#centralized-auth-service-setup)
- [Monitoring and Maintenance](#monitoring-and-maintenance)

## Benefits of a Home Server

Setting up PostgreSQL on a home server creates a centralized database infrastructure with numerous advantages:

1. **Centralized Data Storage**: All your applications connect to a single database server
2. **Consistent Backup Strategy**: Implement backups in one location
3. **Resource Efficiency**: Applications don't need to run their own database instances
4. **Simplified Management**: Database configuration, updates, and monitoring in one place
5. **Dedicated Authentication Service**: Build once, use across multiple applications
6. **Development/Testing Environment**: Local environment that mirrors production

## Hardware Requirements

PostgreSQL doesn't require high-end hardware for personal or small application use:

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| **CPU** | 1 core | 2+ cores | More cores improve concurrent query performance |
| **RAM** | 1 GB | 4-8 GB | Affects query cache and connection handling |
| **Storage** | 10 GB SSD | 100+ GB SSD | SSDs dramatically improve performance |
| **Network** | 100 Mbps | 1 Gbps | For remote access and replication |
| **Power** | UPS recommended | UPS required | Prevents corruption during power loss |

Viable home server options:
- Raspberry Pi 4 (4GB or 8GB RAM) for light usage
- Retired desktop computer 
- Mini PCs (Intel NUC, HP MicroServer)
- Purpose-built NAS with Docker support (Synology, QNAP)

## Installation Options

Three main approaches to run PostgreSQL on a home server:

### 1. Native Installation

Direct installation on the host operating system:

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# Start service
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Configure for remote access
sudo nano /etc/postgresql/13/main/postgresql.conf
# Modify: listen_addresses = '*'

sudo nano /etc/postgresql/13/main/pg_hba.conf
# Add: host all all 192.168.1.0/24 md5
```

**Pros**: Best performance, direct access to system resources  
**Cons**: Less isolation, harder to migrate, OS-dependent

### 2. Docker Container (Recommended)

Run PostgreSQL in a Docker container:

```yaml
# docker-compose.yml
version: '3.8'
services:
  postgres:
    image: postgres:15
    container_name: homeserver_postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-admin}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-securepassword}
      POSTGRES_DB: ${POSTGRES_DB:-main}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    ports:
      - "5432:5432"
    networks:
      - postgres_network

networks:
  postgres_network:
    driver: bridge

volumes:
  postgres_data:
    driver: local
```

**Pros**: Isolated, easily upgradable, OS-agnostic, reproducible setup  
**Cons**: Slight performance overhead, requires Docker knowledge

### 3. Virtual Machine

Run PostgreSQL in a dedicated VM:

```bash
# Using Proxmox, VirtualBox, or similar
# 1. Create Ubuntu/Debian VM with 2 vCPUs, 4GB RAM, 50GB storage
# 2. Install PostgreSQL within the VM
# 3. Configure networking for access from host network
```

**Pros**: Complete isolation, snapshots, resource control  
**Cons**: Higher overhead, more complex setup, higher memory usage

## Network Configuration

### Internal Network Access

Allow applications on your home network to connect:

1. **Fixed IP Address**:
   ```bash
   # Set static IP for server (Ubuntu example)
   sudo nano /etc/netplan/01-netcfg.yaml
   
   # Add configuration:
   network:
     version: 2
     ethernets:
       eth0:
         dhcp4: no
         addresses: [192.168.1.10/24]
         gateway4: 192.168.1.1
         nameservers:
           addresses: [1.1.1.1, 8.8.8.8]
   
   # Apply changes
   sudo netplan apply
   ```

2. **PostgreSQL Listening Configuration**:
   ```
   # postgresql.conf
   listen_addresses = '*'  # Listen on all interfaces
   ```

3. **Client Authentication**:
   ```
   # pg_hba.conf
   
   # Allow specific network
   host    all             all             192.168.1.0/24          md5
   
   # Or specific IP addresses
   host    all             all             192.168.1.20/32         md5
   ```

### External Access (Optional)

For accessing PostgreSQL from outside your home network:

1. **VPN Approach (Recommended)**:
   - Set up WireGuard or OpenVPN on your router or a dedicated server
   - Connect to VPN then access PostgreSQL normally
   - No direct external exposure of your database

2. **Port Forwarding (Use with caution)**:
   - Configure your router to forward port 5432 to your PostgreSQL server
   - Use strong passwords and TLS
   - Consider non-standard port to avoid automated scans

3. **SSH Tunneling**:
   ```bash
   # From remote machine
   ssh -L 5432:localhost:5432 user@your-home-server-ip
   
   # Then connect locally to forwarded port
   psql -h localhost -U dbuser -d dbname
   ```

## Security Considerations

Home servers are vulnerable to different threats than cloud infrastructure:

1. **Physical Security**:
   - Keep server in secure location
   - Use disk encryption for sensitive data
   - Configure BIOS/UEFI password

2. **Network Security**:
   ```
   # pg_hba.conf - restrict to specific users
   host    myapp           app_user        192.168.1.0/24          md5
   host    all             postgres        127.0.0.1/32            md5
   ```

3. **Firewall Configuration**:
   ```bash
   # UFW example (Ubuntu)
   sudo ufw allow from 192.168.1.0/24 to any port 5432
   sudo ufw deny 5432
   ```

4. **TLS/SSL Encryption**:
   ```bash
   # Generate self-signed certificate
   openssl req -new -x509 -days 365 -nodes -text -out server.crt \
     -keyout server.key -subj "/CN=postgres-homeserver"
   
   # Configure PostgreSQL
   # postgresql.conf
   ssl = on
   ssl_cert_file = 'server.crt'
   ssl_key_file = 'server.key'
   
   # pg_hba.conf
   hostssl all all 192.168.1.0/24 md5
   ```

5. **Regular Updates**:
   ```bash
   # Set up automatic updates 
   sudo apt install unattended-upgrades
   sudo dpkg-reconfigure unattended-upgrades
   ```

## Backup Strategy

Critical for home servers where hardware may be less reliable:

1. **Automated Backups**:
   ```bash
   # Create backup script
   cat > /opt/scripts/pg_backup.sh << 'EOF'
   #!/bin/bash
   
   BACKUP_DIR="/backups"
   TIMESTAMP=$(date +%Y%m%d_%H%M%S)
   
   # Full database dump
   pg_dumpall -U postgres > $BACKUP_DIR/full_backup_$TIMESTAMP.sql
   
   # Compress
   gzip $BACKUP_DIR/full_backup_$TIMESTAMP.sql
   
   # Delete backups older than 30 days
   find $BACKUP_DIR -name "full_backup_*.sql.gz" -mtime +30 -delete
   EOF
   
   # Make executable
   chmod +x /opt/scripts/pg_backup.sh
   
   # Add to crontab
   (crontab -l 2>/dev/null; echo "0 2 * * * /opt/scripts/pg_backup.sh") | crontab -
   ```

2. **Off-site Backups**:
   ```bash
   # Sync to external storage
   rsync -avz /backups/ /mnt/external_drive/postgres_backups/
   
   # Or cloud storage (rclone example)
   rclone copy /backups/ remote:postgres-backups
   ```

3. **Point-in-Time Recovery**:
   ```
   # postgresql.conf
   wal_level = replica
   archive_mode = on
   archive_command = 'cp %p /var/lib/postgresql/archive/%f'
   ```

4. **Backup Verification**:
   ```bash
   # Test restore on a regular basis
   pg_restore -d postgres_test /backups/latest_backup.sql
   ```

## Centralized Auth Service Setup

Running a dedicated authentication service on your home server:

### Architecture

```
┌────────────────────┐     ┌────────────────┐     ┌────────────────┐
│                    │     │                │     │                │
│  Web Application 1 │     │  Auth Service  │     │  PostgreSQL    │
│  (Remote Server)   │◄────┤  (Home Server) │◄────┤  (Home Server) │
│                    │     │                │     │                │
└────────────────────┘     └────────────────┘     └────────────────┘
         ▲                        ▲
         │                        │
         │                        │
         │                        │
┌────────┴───────────┐    ┌───────┴────────┐
│                    │    │                │
│  Web Application 2 │    │  Mobile App    │
│  (Remote Server)   │    │                │
│                    │    │                │
└────────────────────┘    └────────────────┘
```

### Implementation Steps

1. **Create Auth Database**:
   ```sql
   CREATE DATABASE auth_service;
   CREATE USER auth_service_user WITH PASSWORD 'secure_password';
   GRANT ALL PRIVILEGES ON DATABASE auth_service TO auth_service_user;
   ```

2. **Auth Service API**:
   Create an Express.js API service with endpoints:

   ```javascript
   // auth-service/app.js
   import express from 'express';
   import cors from 'cors';
   import helmet from 'helmet';
   import authRoutes from './routes/auth.js';
   
   const app = express();
   
   // Middleware
   app.use(helmet());
   app.use(cors({
     origin: ['https://yourapp1.com', 'https://yourapp2.com'],
     credentials: true
   }));
   app.use(express.json());
   
   // Routes
   app.use('/api/auth', authRoutes);
   
   // Error handling
   app.use((err, req, res, next) => {
     console.error(err.stack);
     res.status(500).json({ message: 'Internal server error' });
   });
   
   const PORT = process.env.PORT || 3000;
   app.listen(PORT, () => {
     console.log(`Auth service running on port ${PORT}`);
   });
   ```

3. **Auth Service Endpoints**:
   ```javascript
   // routes/auth.js
   import { Router } from 'express';
   import { login, register, validateToken } from '../controllers/auth.js';
   
   const router = Router();
   
   router.post('/login', login);
   router.post('/register', register);
   router.post('/validate', validateToken);
   router.post('/refresh', refreshToken);
   router.post('/logout', logout);
   
   export default router;
   ```

4. **Docker Compose for Auth Service**:
   ```yaml
   # docker-compose.yml
   version: '3.8'
   services:
     auth_service:
       build: ./auth-service
       restart: unless-stopped
       ports:
         - "3000:3000"
       environment:
         NODE_ENV: production
         DB_HOST: postgres
         DB_USER: auth_service_user
         DB_PASSWORD: secure_password
         DB_NAME: auth_service
         JWT_SECRET: your-secret-key
       depends_on:
         - postgres
       networks:
         - app_network
     
     postgres:
       image: postgres:15
       # ...other PostgreSQL config from earlier examples
   
   networks:
     app_network:
       driver: bridge
   ```

5. **Client Integration**:
   ```javascript
   // In your web applications
   async function login(email, password) {
     const response = await fetch('https://auth.yourhomeserver.com/api/auth/login', {
       method: 'POST',
       headers: { 'Content-Type': 'application/json' },
       body: JSON.stringify({ email, password })
     });
     
     return await response.json();
   }
   
   async function validateToken(token) {
     const response = await fetch('https://auth.yourhomeserver.com/api/auth/validate', {
       method: 'POST',
       headers: { 'Content-Type': 'application/json' },
       body: JSON.stringify({ token })
     });
     
     return await response.json();
   }
   ```

## Monitoring and Maintenance

Keep your home PostgreSQL server running smoothly:

1. **Performance Monitoring**:
   ```sql
   -- Check active queries
   SELECT pid, now() - pg_stat_activity.query_start AS duration, query
   FROM pg_stat_activity
   WHERE state = 'active' AND now() - pg_stat_activity.query_start > interval '5 minutes';
   
   -- Check table sizes
   SELECT table_name, pg_size_pretty(pg_total_relation_size(quote_ident(table_name)))
   FROM information_schema.tables
   WHERE table_schema = 'public'
   ORDER BY pg_total_relation_size(quote_ident(table_name)) DESC;
   
   -- Check index usage
   SELECT indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
   FROM pg_stat_user_indexes
   ORDER BY idx_scan DESC;
   ```

2. **Automated Health Checks**:
   ```bash
   # Create health check script
   cat > /opt/scripts/pg_healthcheck.sh << 'EOF'
   #!/bin/bash
   
   # Check if PostgreSQL is running
   if ! systemctl is-active --quiet postgresql; then
     echo "PostgreSQL is not running!"
     systemctl start postgresql
     exit 1
   fi
   
   # Check if database is responsive
   if ! psql -U postgres -c 'SELECT 1' > /dev/null 2>&1; then
     echo "PostgreSQL is not responding!"
     exit 1
   fi
   
   # Check disk space
   USAGE=$(df -h | grep '/var/lib/postgresql' | awk '{print $5}' | tr -d '%')
   if [ "$USAGE" -gt 85 ]; then
     echo "Disk space critical: $USAGE%"
     exit 1
   fi
   
   echo "PostgreSQL health check passed"
   exit 0
   EOF
   
   # Make executable
   chmod +x /opt/scripts/pg_healthcheck.sh
   
   # Add to crontab to run every hour
   (crontab -l 2>/dev/null; echo "0 * * * * /opt/scripts/pg_healthcheck.sh") | crontab -
   ```

3. **Monitoring Dashboard**:
   - Install pgAdmin on your home server for a web interface
   - Or set up Grafana with PostgreSQL data source for metrics visualization

   ```yaml
   # docker-compose extension for monitoring
   services:
     # ... existing services
     
     pgadmin:
       image: dpage/pgadmin4
       environment:
         PGADMIN_DEFAULT_EMAIL: admin@example.com
         PGADMIN_DEFAULT_PASSWORD: admin_password
       ports:
         - "5050:80"
       volumes:
         - pgadmin_data:/var/lib/pgadmin
       networks:
         - app_network
     
     grafana:
       image: grafana/grafana
       ports:
         - "3001:3000"
       volumes:
         - grafana_data:/var/lib/grafana
       networks:
         - app_network
   
   volumes:
     # ... existing volumes
     pgadmin_data:
     grafana_data:
   ```

4. **Regular Maintenance**:
   ```sql
   -- Vacuum database (reclaim space and update statistics)
   VACUUM ANALYZE;
   
   -- Run more aggressive cleanup on specific tables
   VACUUM FULL my_large_table;
   
   -- Update statistics
   ANALYZE;
   
   -- Reindex to improve performance
   REINDEX TABLE frequently_updated_table;
   ```

5. **Version Upgrades**:
   Plan periodic upgrades to newer PostgreSQL versions:

   ```bash
   # For Docker installations, update image tag in docker-compose.yml
   # Change:
   image: postgres:15
   # To:
   image: postgres:16
   
   # Then recreate container
   docker-compose up -d postgres
   ```

6. **Log Rotation**:
   ```
   # postgresql.conf
   logging_collector = on
   log_directory = 'pg_log'
   log_filename = 'postgresql-%a.log'
   log_truncate_on_rotation = on
   log_rotation_age = 1d
   log_rotation_size = 0
   ```

## Integrating with Multiple Applications

Making your home server PostgreSQL instance serve multiple applications:

1. **Database Separation**:
   ```sql
   -- Create separate database for each application
   CREATE DATABASE app1;
   CREATE DATABASE app2;
   CREATE DATABASE auth_service;
   
   -- Create application-specific users
   CREATE USER app1_user WITH PASSWORD 'password1';
   GRANT ALL PRIVILEGES ON DATABASE app1 TO app1_user;
   
   CREATE USER app2_user WITH PASSWORD 'password2';
   GRANT ALL PRIVILEGES ON DATABASE app2 TO app2_user;
   ```

2. **Connection String Management**:
   ```javascript
   // In your application's .env file
   DATABASE_URL=postgres://app1_user:password1@home-server-ip:5432/app1
   
   // For Docker Compose
   environment:
     - DATABASE_URL=postgres://app1_user:password1@postgres:5432/app1
   ```

3. **Resource Allocation**:
   ```
   # postgresql.conf - adjust limits per workload
   
   # Memory settings
   shared_buffers = 1GB               # 25% of available RAM
   work_mem = 32MB                    # For complex queries
   maintenance_work_mem = 256MB       # For maintenance operations
   
   # Connection limits
   max_connections = 100              # Adjust based on expected load
   ```

4. **Availability Monitoring**:
   Set up a simple status page for your applications to check before attempting connections:

   ```javascript
   // status-service/app.js
   import express from 'express';
   import pg from 'pg';
   
   const app = express();
   const { Pool } = pg;
   
   const pool = new Pool({
     user: 'status_checker',
     host: 'postgres',
     database: 'postgres',
     password: 'status_password',
     port: 5432,
   });
   
   app.get('/status', async (req, res) => {
     try {
       const result = await pool.query('SELECT 1');
       res.json({ status: 'ok', timestamp: new Date() });
     } catch (error) {
       res.status(500).json({ status: 'error', message: error.message });
     }
   });
   
   app.listen(3100, () => {
     console.log('Status service running on port 3100');
   });
   ```

---

[<- Back: Docker Deployment](./08-docker-deployment.md)
