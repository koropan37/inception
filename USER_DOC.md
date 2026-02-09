# User Documentation - Inception

This document explains how to use the Inception infrastructure as an end user or system administrator.

## Services Provided

The Inception stack provides the following services:

### 1. WordPress Website
- **URL**: `https://skimura.42.fr`
- **Purpose**: Full-featured WordPress blog/website
- **Features**:
  - Content management system
  - User authentication
  - Media uploads
  - Theme and plugin support

### 2. NGINX Web Server
- **Port**: 443 (HTTPS only)
- **Purpose**: Reverse proxy and TLS termination
- **Features**:
  - TLS 1.2/1.3 encryption
  - Static file serving
  - FastCGI proxy to WordPress

### 3. MariaDB Database
- **Internal Port**: 3306 (not exposed)
- **Purpose**: Data storage for WordPress
- **Features**:
  - Persistent data storage
  - User management
  - WordPress database

### 4. Adminer (Bonus)
- **URL**: `http://localhost:8081`
- **Purpose**: Database management interface
- **Features**:
  - Visual database browser
  - SQL query execution
  - Table management

## Starting the Project

### First Time Setup

1. **Configure DNS** (if testing locally):
```bash
# Add to /etc/hosts
echo "127.0.0.1 skimura.42.fr" | sudo tee -a /etc/hosts
```

2. **Start all services**:
```bash
cd inception
make
```

This will:
- Build all Docker images (first time only)
- Create data directories
- Start all containers
- Initialize WordPress

### Subsequent Starts

```bash
# Start services
make up

# Or using Docker Compose directly
docker compose -f srcs/docker-compose.yml up -d
```

## Stopping the Project

### Graceful Shutdown

```bash
# Stop all containers (data persists)
make down
```

### Complete Cleanup

```bash
# Stop containers and remove all data
make fclean

# Warning: This deletes:
# - All containers
# - All images
# - All volumes and data
```

## Accessing Services

### WordPress Website

1. Open browser and navigate to: `https://skimura.42.fr`
2. Accept the self-signed certificate warning (for development)
3. You should see the WordPress homepage

### WordPress Admin Panel

1. Navigate to: `https://skimura.42.fr/wp-admin`
2. Login with credentials (see Credentials section below)
3. Access the WordPress dashboard

### Adminer (Database Management)

1. Navigate to: `http://localhost:8081`
2. Login with database credentials:
   - **System**: MySQL
   - **Server**: `mariadb`
   - **Username**: See `.env` file
   - **Password**: See `secrets/db_password.txt`
   - **Database**: `wordpress`

## Managing Credentials

### Location of Credentials

Credentials are stored in two locations:

#### 1. Secrets (Passwords)
```
inception/secrets/
├── db_root_password.txt       # MariaDB root password
├── db_password.txt            # WordPress database user password
├── wp_admin_password.txt      # WordPress admin password
└── wp_user_password.txt       # WordPress regular user password
```

#### 2. Environment Variables (Usernames, Non-Sensitive Config)
```
inception/srcs/.env
```

Contains:
- Domain name
- Database name
- Usernames
- Email addresses

### WordPress Login Credentials

**Administrator Account:**
- Username: Defined in `.env` as `WP_ADMIN_USER`
- Password: Contents of `secrets/wp_admin_password.txt`
- Email: Defined in `.env` as `WP_ADMIN_EMAIL`

**Regular User Account:**
- Username: Defined in `.env` as `WP_USER`
- Password: Contents of `secrets/wp_user_password.txt`
- Email: Defined in `.env` as `WP_USER_EMAIL`

### Changing Passwords

1. **Edit the secrets files**:
```bash
echo "new_password_here" > secrets/db_password.txt
```

2. **Recreate the containers**:
```bash
make re
```

**Warning**: Changing database passwords requires a complete rebuild (`make re`).

### Viewing Current Configuration

```bash
# View environment variables (non-sensitive)
cat srcs/.env

# View secrets (sensitive - be careful)
cat secrets/db_root_password.txt
```

## Checking Service Health

### Quick Status Check

```bash
# View all containers
make ps

# Expected output:
NAME        STATUS
mariadb     Up (healthy)
wordpress   Up (healthy)
nginx       Up (healthy)
adminer     Up (healthy)
```

### Detailed Health Information

```bash
# View real-time logs
make logs

# View specific service logs
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs nginx
```

### Health Check Indicators

| Status | Meaning | Action |
|--------|---------|--------|
| `Up (healthy)` | Service running correctly | None needed |
| `Up (starting)` | Service initializing | Wait 30-60 seconds |
| `Up (unhealthy)` | Service has issues | Check logs |
| `Exited` | Service crashed | Check logs, restart |

### Common Health Commands

```bash
# Check if WordPress is accessible
curl -Ik https://skimura.42.fr

# Check database connectivity
docker exec mariadb mysqladmin ping -h localhost -u root -p"$(cat secrets/db_root_password.txt)"

# Check NGINX status
docker exec nginx pidof nginx

# Check PHP-FPM status
docker exec wordpress pidof php-fpm8.2
```

## Troubleshooting

### Services Won't Start

1. Check logs:
```bash
make logs
```

2. Verify data directories exist:
```bash
ls -la ~/data/
```

3. Check for port conflicts:
```bash
sudo netstat -tulpn | grep -E ':(443|8081)'
```

### Website Not Accessible

1. Verify NGINX is running:
```bash
docker exec nginx pidof nginx
```

2. Check DNS resolution:
```bash
ping skimura.42.fr
# Should resolve to 127.0.0.1
```

3. Verify certificate:
```bash
docker exec nginx ls -la /etc/nginx/ssl/
```

### Database Connection Issues

1. Check MariaDB health:
```bash
docker exec mariadb healthcheck.sh
```

2. Verify credentials match:
```bash
# Compare .env and secrets
cat srcs/.env | grep MYSQL
cat secrets/db_password.txt
```

### Data Loss After Restart

This should not happen with bind mounts. Verify:

```bash
# Check data persists on host
ls -la ~/data/mariadb/
ls -la ~/data/wordpress/
```

If data is missing, you may need to rebuild:
```bash
make re
```

## Backup and Restore

### Creating a Backup

```bash
# Stop services
make down

# Backup data directories
tar -czf backup-$(date +%Y%m%d).tar.gz ~/data/

# Backup secrets
tar -czf secrets-backup-$(date +%Y%m%d).tar.gz secrets/

# Restart services
make up
```

### Restoring from Backup

```bash
# Stop services
make down

# Restore data
tar -xzf backup-YYYYMMDD.tar.gz -C ~

# Restore secrets
tar -xzf secrets-backup-YYYYMMDD.tar.gz

# Restart services
make up
```

## Maintenance

### Updating WordPress

WordPress updates are handled through the admin panel:

1. Login to `https://skimura.42.fr/wp-admin`
2. Navigate to Dashboard → Updates
3. Click "Update Now"

### Viewing Resource Usage

```bash
# Container resource usage
docker stats

# Disk usage
docker system df

# Volume sizes
du -sh ~/data/*
```

### Cleaning Up

```bash
# Remove unused Docker resources
docker system prune -a

# Remove old images
docker image prune -a
```

## Security Notes

- **Self-Signed Certificate**: The default certificate is self-signed. For production, replace with a valid certificate.
- **Password Storage**: Never commit `secrets/` directory to version control.
- **Network Exposure**: Only ports 443 and 8081 are exposed to the host.
- **Container Isolation**: Services communicate only through the Docker network.

## Support

For issues or questions:
1. Check logs: `make logs`
2. Review documentation: [README.md](README.md) and [DEV_DOC.md](DEV_DOC.md)
3. Check Docker documentation: https://docs.docker.com/
4. Verify system requirements are met