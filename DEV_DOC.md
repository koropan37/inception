# Developer Documentation - Inception

This document explains how to set up, develop, and maintain the Inception infrastructure project.

## Prerequisites

### Required Software

- **Operating System**: Linux (Debian/Ubuntu recommended)
- **Docker Engine**: 20.10 or higher
- **Docker Compose**: V2 or higher
- **Make**: GNU Make 4.0+
- **Git**: For version control
- **OpenSSL**: For SSL certificate generation

### Installation (Debian/Ubuntu)

```bash
# Update package list
sudo apt-get update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group (avoid using sudo)
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose V2
sudo apt-get install docker-compose-plugin

# Install other dependencies
sudo apt-get install make git openssl

# Verify installations
docker --version
docker compose version
make --version
```

## Environment Setup from Scratch

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/inception.git
cd inception
```

### 2. Create Directory Structure

The project expects the following structure:

```
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                    # Gitignored
│   ├── db_root_password.txt
│   ├── db_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env                    # Gitignored
    ├── .env.example
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       ├── entrypoint.sh
        │       └── healthcheck.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── www.conf
        │   └── tools/
        │       ├── entrypoint.sh
        │       └── healthcheck.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       ├── entrypoint.sh
        │       └── healthcheck.sh
        └── bonus/
            └── adminer/
                ├── Dockerfile
                └── tools/
                    └── healthcheck.sh
```

### 3. Configure Environment Variables

```bash
# Copy example file
cp srcs/.env.example srcs/.env

# Edit with your values
nano srcs/.env
```

**Required variables in `.env`:**

```bash
# Domain Configuration
DOMAIN_NAME=skimura.42.fr

# WordPress Configuration
WP_TITLE="My Blog"
WP_ADMIN_USER=admin
WP_ADMIN_EMAIL=admin@example.com
WP_USER=author
WP_USER_EMAIL=author@example.com

# Database Configuration
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
```

### 4. Create Secrets

```bash
# Create secrets directory
mkdir -p secrets

# Generate secure passwords
openssl rand -base64 32 > secrets/db_root_password.txt
openssl rand -base64 32 > secrets/db_password.txt
openssl rand -base64 32 > secrets/wp_admin_password.txt
openssl rand -base64 32 > secrets/wp_user_password.txt

# Set secure permissions
chmod 600 secrets/*

# Verify
ls -la secrets/
```

### 5. Configure Git Ignore

Create `.gitignore`:

```bash
# Secrets
secrets/

# Environment
srcs/.env

# Data directories
data/

# Docker
*.log
.DS_Store
```

### 6. Set Up Data Directories

```bash
# Directories will be created automatically by Makefile
# But you can create them manually:
mkdir -p ~/data/mariadb
mkdir -p ~/data/wordpress
```

## Building and Launching

### Using Makefile (Recommended)

```bash
# Build and start everything
make

# Or step by step:
make build      # Build all images
make up         # Start containers
make logs       # View logs
make ps         # Check status
make down       # Stop containers
make clean      # Remove containers and images
make fclean     # Complete cleanup (removes data)
make re         # Rebuild everything
```

### Using Docker Compose Directly

```bash
# Build images
docker compose -f srcs/docker-compose.yml build

# Start containers
docker compose -f srcs/docker-compose.yml up -d

# View logs
docker compose -f srcs/docker-compose.yml logs -f

# Check status
docker compose -f srcs/docker-compose.yml ps

# Stop containers
docker compose -f srcs/docker-compose.yml down

# Remove volumes
docker compose -f srcs/docker-compose.yml down -v
```

## Container Management Commands

### Basic Operations

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View container logs
docker logs mariadb
docker logs -f wordpress  # Follow mode

# Execute command in container
docker exec -it mariadb bash
docker exec wordpress ls -la /var/www/wordpress

# Inspect container
docker inspect mariadb

# View container resource usage
docker stats
```

### Service-Specific Commands

#### MariaDB

```bash
# Access MySQL shell
docker exec -it mariadb mysql -u root -p"$(cat secrets/db_root_password.txt)"

# Test connection
docker exec mariadb mysqladmin ping -h localhost -u root -p"$(cat secrets/db_root_password.txt)"

# Backup database
docker exec mariadb mysqldump -u root -p"$(cat secrets/db_root_password.txt)" wordpress > backup.sql

# Restore database
docker exec -i mariadb mysql -u root -p"$(cat secrets/db_root_password.txt)" wordpress < backup.sql
```

#### WordPress

```bash
# Access WP-CLI
docker exec wordpress wp --info --allow-root

# List users
docker exec wordpress wp user list --allow-root

# Create new user
docker exec wordpress wp user create newuser user@example.com --role=author --allow-root

# Update WordPress
docker exec wordpress wp core update --allow-root
```

#### NGINX

```bash
# Test configuration
docker exec nginx nginx -t

# Reload configuration
docker exec nginx nginx -s reload

# View access logs
docker exec nginx tail -f /var/log/nginx/access.log

# View error logs
docker exec nginx tail -f /var/log/nginx/error.log
```

## Volume Management

### Data Persistence

Data is stored in bind mounts:

```bash
# MariaDB data
ls -la ~/data/mariadb/
# Contains: ibdata1, mysql/, wordpress/, etc.

# WordPress files
ls -la ~/data/wordpress/
# Contains: wp-config.php, wp-content/, wp-admin/, etc.
```

### Volume Commands

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect inception_mariadb_data

# Remove all volumes
docker volume prune

# Backup volumes
tar -czf mariadb-backup.tar.gz ~/data/mariadb
tar -czf wordpress-backup.tar.gz ~/data/wordpress

# Restore volumes
tar -xzf mariadb-backup.tar.gz -C ~
tar -xzf wordpress-backup.tar.gz -C ~
```

### Data Location

| Service | Container Path | Host Path (Bind Mount) |
|---------|---------------|----------------------|
| MariaDB | `/var/lib/mysql` | `~/data/mariadb` |
| WordPress | `/var/www/wordpress` | `~/data/wordpress` |
| Nginx | `/var/www/wordpress` | `~/data/wordpress` (shared) |

## Development Workflow

### Making Changes

1. **Modify Dockerfile or configuration:**
```bash
nano srcs/requirements/nginx/conf/nginx.conf
```

2. **Rebuild specific service:**
```bash
docker compose -f srcs/docker-compose.yml build nginx
docker compose -f srcs/docker-compose.yml up -d nginx
```

3. **Test changes:**
```bash
docker compose -f srcs/docker-compose.yml logs -f nginx
curl -Ik https://skimura.42.fr
```

### Debugging

```bash
# Enter container shell
docker exec -it nginx bash

# Check processes
docker exec nginx ps aux

# Check network connectivity
docker exec wordpress ping mariadb

# View environment variables
docker exec wordpress env

# Check file permissions
docker exec wordpress ls -la /var/www/wordpress
```

### Testing Health Checks

```bash
# Manual health check execution
docker exec mariadb healthcheck.sh
echo $?  # 0 = success, 1 = failure

docker exec wordpress healthcheck.sh
docker exec nginx healthcheck.sh
docker exec adminer healthcheck.sh

# View health status
docker inspect --format='{{json .State.Health}}' mariadb | jq
```

## Network Architecture

### Network Configuration

```yaml
networks:
  inception:
    driver: bridge
```

All services communicate through the `inception` network.

### Service Communication

```bash
# From wordpress container
docker exec wordpress ping mariadb          # Works (DNS resolution)
docker exec wordpress curl http://nginx     # Works (internal network)

# From host
curl https://skimura.42.fr                  # Works (port forwarding)
ping mariadb                                 # Doesn't work (isolated network)
```

### Port Mapping

| Service | Internal Port | External Port | Protocol |
|---------|--------------|---------------|----------|
| NGINX | 443 | 443 | HTTPS |
| Adminer | 8080 | 8081 | HTTP |
| MariaDB | 3306 | (not exposed) | MySQL |
| WordPress | 9000 | (not exposed) | FastCGI |

### Network Debugging

```bash
# List networks
docker network ls

# Inspect network
docker network inspect inception

# View connected containers
docker network inspect inception --format='{{range .Containers}}{{.Name}} {{end}}'

# Test connectivity
docker exec wordpress nc -zv mariadb 3306
```

## Security Considerations

### Secrets Management

```bash
# Secrets are mounted at /run/secrets/ in containers
docker exec mariadb ls /run/secrets/
# Output: db_root_password  db_password

# Reading secrets in scripts
docker exec mariadb cat /run/secrets/db_root_password
```

### Container Permissions

```bash
# Check running user
docker exec mariadb whoami        # mysql
docker exec wordpress whoami      # www-data
docker exec nginx whoami          # www-data

# File ownership
docker exec wordpress ls -la /var/www/wordpress/
# Should be www-data:www-data
```

### SSL/TLS Configuration

```bash
# Certificate location
docker exec nginx ls -la /etc/nginx/ssl/
# inception.crt, inception.key

# Test SSL configuration
docker exec nginx openssl s_client -connect localhost:443 -tls1_2
```

## Troubleshooting

### Build Failures

```bash
# Clean build cache
docker builder prune -a

# Rebuild with no cache
docker compose -f srcs/docker-compose.yml build --no-cache

# Check Dockerfile syntax
docker run --rm -i hadolint/hadolint < srcs/requirements/nginx/Dockerfile
```

### Container Won't Start

```bash
# Check logs
docker compose -f srcs/docker-compose.yml logs mariadb

# Check entrypoint script
docker compose -f srcs/docker-compose.yml run --rm mariadb bash
# Then manually run commands from entrypoint.sh
```

### Permission Issues

```bash
# Fix data directory permissions
chmod -R 755 ~/data/mariadb
chmod -R 755 ~/data/wordpress

# Fix ownership (if needed)
chown -R $USER:$USER ~/data/
```

### Network Issues

```bash
# Restart Docker daemon
sudo systemctl restart docker

# Recreate network
docker network rm inception
docker network create inception
```

## Performance Optimization

### Image Size

```bash
# Check image sizes
docker images

# Remove dangling images
docker image prune

# Multi-stage builds (if applicable)
# Already optimized in current Dockerfiles
```

### Container Resources

```bash
# Limit resources in docker-compose.yml
services:
  mariadb:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
```

### Cache Optimization

```bash
# Order Dockerfile commands from least to most frequently changing
# Keep package installations before code copies
# Use .dockerignore to exclude unnecessary files
```

## Testing

### Manual Testing Checklist

- [ ] All containers start successfully
- [ ] Health checks pass for all services
- [ ] WordPress accessible at https://skimura.42.fr
- [ ] WordPress admin login works
- [ ] Database connection works
- [ ] Adminer accessible and can connect to database
- [ ] Data persists after `docker compose down`
- [ ] SSL certificate is valid (self-signed accepted)
- [ ] No exposed ports except 443 and 8081

### Automated Testing

```bash
# Test script example
#!/bin/bash
set -e

echo "Starting services..."
make up

echo "Waiting for services..."
sleep 30

echo "Testing NGINX..."
curl -Ik https://skimura.42.fr | grep "HTTP/2 200"

echo "Testing Adminer..."
curl -I http://localhost:8081 | grep "HTTP/1.1 200"

echo "Testing health checks..."
docker inspect --format='{{.State.Health.Status}}' mariadb | grep "healthy"
docker inspect --format='{{.State.Health.Status}}' wordpress | grep "healthy"
docker inspect --format='{{.State.Health.Status}}' nginx | grep "healthy"

echo "All tests passed!"
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Inception CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Docker
        uses: docker/setup-buildx-action@v1
      
      - name: Create secrets
        run: |
          mkdir -p secrets
          echo "test_password" > secrets/db_root_password.txt
          echo "test_password" > secrets/db_password.txt
          echo "test_password" > secrets/wp_admin_password.txt
          echo "test_password" > secrets/wp_user_password.txt
      
      - name: Build images
        run: make build
      
      - name: Start services
        run: make up
      
      - name: Run tests
        run: ./test.sh
```

## Maintenance

### Regular Tasks

```bash
# Weekly: Check logs for errors
docker compose -f srcs/docker-compose.yml logs --tail=100 | grep -i error

# Monthly: Update base images
docker compose -f srcs/docker-compose.yml build --pull

# Monthly: Clean unused resources
docker system prune -a --volumes

# Backup data weekly
tar -czf backup-$(date +%Y%m%d).tar.gz ~/data/
```

### Monitoring

```bash
# Container resource usage
docker stats --no-stream

# Disk usage
docker system df

# Log sizes
du -sh ~/data/wordpress/wp-content/debug.log
```

## Additional Resources

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Configuration Guide](https://nginx.org/en/docs/)
- [WordPress Development](https://developer.wordpress.org/)
- [MariaDB Documentation](https://mariadb.org/documentation/)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Test thoroughly
5. Submit a pull request

---

For user-level documentation, see [USER_DOC.md](USER_DOC.md).