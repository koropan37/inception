# Inception

*This project has been created as part of the 42 curriculum by skimura.*

## Description

Inception is a system administration project that focuses on using Docker to set up a small infrastructure composed of different services. The project requires building custom Docker images and orchestrating them using Docker Compose to create a fully functional WordPress website with the following architecture:

- **NGINX** with TLSv1.2 or TLSv1.3 only
- **WordPress + php-fpm** (without nginx)
- **MariaDB** (without nginx)
- **Volumes** for WordPress database and website files
- **Docker network** for inter-container communication
- **Bonus services**: Adminer, Redis, FTP, static website, etc.

### Goals

- Learn Docker containerization and orchestration
- Understand service isolation and inter-container communication
- Practice system administration with Docker Compose
- Implement security best practices (TLS, secrets, network isolation)

### Architecture

```
┌─────────────────────────────────────────┐
│           Host Machine (VM)             │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │      Docker Network (bridge)       │ │
│  │                                    │ │
│  │  ┌─────────┐   ┌──────────┐        │ │
│  │  │  NGINX  │──▶│WordPress │        │ │
│  │  │  :443   │   │ php-fpm  │        │ │
│  │  └─────────┘   └──────────┘        │ │
│  │                      │             │ │
│  │                      ▼             │ │
│  │                ┌──────────┐        │ │
│  │                │ MariaDB  │        │ │
│  │                │  :3306   │        │ │
│  │                └──────────┘        │ │
│  │                                    │ │
│  │  ┌─────────┐                       │ │
│  │  │ Adminer │                       │ │
│  │  │  :8080  │                       │ │
│  │  └─────────┘                       │ │
│  └────────────────────────────────────┘ │
│                                         │
│  Volumes (Bind Mounts):                 │
│  - /home/skimura/data/mariadb           │
│  - /home/skimura/data/wordpress         │
└─────────────────────────────────────────┘
```

## Instructions

### Prerequisites

- Docker Engine 20.10+
- Docker Compose V2+
- Make
- OpenSSL (for SSL certificate generation)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/inception.git
cd inception
```

2. Create secrets files:
```bash
mkdir -p secrets
echo "your_root_password" > secrets/db_root_password.txt
echo "your_db_password" > secrets/db_password.txt
echo "your_wp_admin_password" > secrets/wp_admin_password.txt
echo "your_wp_user_password" > secrets/wp_user_password.txt
chmod 600 secrets/*
```

3. Configure environment variables:
```bash
cp srcs/.env.example srcs/.env
# Edit srcs/.env with your domain name and credentials
```

### Build and Run

```bash
# Build all images and start containers
make

# Or step by step:
make build    # Build Docker images
make up       # Start containers

# View logs
make logs

# Check container status
make ps

# Stop containers
make down

# Complete cleanup (removes volumes)
make fclean

# Rebuild everything
make re
```

### Access Services

After successful deployment:

- **WordPress**: `https://skimura.42.fr` (or your configured domain)
- **Adminer**: `http://localhost:8081`

**Note**: Add `127.0.0.1 skimura.42.fr` to `/etc/hosts` if testing locally.

### SSL Certificate

The project automatically generates a self-signed SSL certificate. For production use, replace it with a valid certificate:

```bash
# Certificate location in container
/etc/nginx/ssl/inception.crt
/etc/nginx/ssl/inception.key
```

## Project Design Choices

### Docker Usage

This project uses Docker for several key reasons:

1. **Isolation**: Each service runs in its own container with minimal dependencies
2. **Reproducibility**: Anyone can rebuild the exact same environment
3. **Portability**: Works on any system with Docker installed
4. **Scalability**: Easy to add more services or scale existing ones

### Sources Included

```
inception/
├── Makefile                    # Build automation
├── secrets/                    # Sensitive data (gitignored)
│   ├── db_root_password.txt
│   ├── db_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env                    # Environment variables
    ├── docker-compose.yml      # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── bonus/
            └── adminer/
                ├── Dockerfile
                └── tools/
```

### Technical Comparisons

#### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker |
|--------|-----------------|---------|
| **Resource Usage** | High (full OS per VM) | Low (shared kernel) |
| **Startup Time** | Minutes | Seconds |
| **Isolation** | Complete (hardware-level) | Process-level |
| **Portability** | Limited (hypervisor-dependent) | High (runs anywhere) |
| **Use Case** | Complete OS isolation needed | Microservices, development |

**Choice for Inception**: Docker is ideal because we need lightweight, isolated services that can communicate efficiently, not full OS isolation.

#### Secrets vs Environment Variables

| Aspect | Secrets | Environment Variables |
|--------|---------|----------------------|
| **Security** | Encrypted at rest, mounted as tmpfs | Visible in `docker inspect` |
| **Storage** | External files | `.env` file or inline |
| **Access** | `/run/secrets/` (read-only) | Shell environment |
| **Rotation** | Easy (update file) | Requires rebuild |

**Choice for Inception**: Docker Secrets for passwords (db_root_password, db_password, etc.) and environment variables for non-sensitive config (domain name, database name).

```yaml
# Secrets (sensitive)
secrets:
  db_root_password:
    file: ../secrets/db_root_password.txt

# Environment (non-sensitive)
environment:
  - MYSQL_DATABASE=${MYSQL_DATABASE}
```

#### Docker Network vs Host Network

| Aspect | Docker Network (bridge) | Host Network |
|--------|------------------------|--------------|
| **Isolation** | Containers isolated from host | Direct host network access |
| **Port Conflicts** | No conflicts (internal ports) | Must avoid host port conflicts |
| **DNS** | Service name resolution | Manual IP management |
| **Security** | Better (isolated) | Lower (exposed to host) |

**Choice for Inception**: Docker bridge network (`inception`) because:
- Services communicate via DNS (e.g., `mariadb:3306`)
- Better isolation and security
- No port conflicts between projects

```yaml
networks:
  inception:
    driver: bridge
```

#### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|---------------|-------------|
| **Management** | Docker-managed | User-managed |
| **Location** | `/var/lib/docker/volumes/` | User-specified path |
| **Portability** | High (OS-independent) | Low (path-dependent) |
| **Backup** | `docker volume` commands | Standard filesystem tools |
| **Development** | Production use | Development, debugging |

**Choice for Inception**: Bind mounts to specific directories (`~/data/`) because:
- Subject requires volume mounting to host directories
- Easy to locate and backup data
- Simple debugging (direct host access)
- Clear data persistence location

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/skimura/data/mariadb
```

## Resources

### Official Documentation

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [MariaDB Documentation](https://mariadb.org/documentation/)
- [WP-CLI Documentation](https://wp-cli.org/)

### Tutorials and Articles

- [Docker Networking](https://docs.docker.com/network/)
- [Docker Secrets Management](https://docs.docker.com/engine/swarm/secrets/)
- [SSL/TLS Best Practices](https://wiki.mozilla.org/Security/Server_Side_TLS)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.php)

### AI Usage

AI (GitHub Copilot and ChatGPT) was used for:

1. **Documentation writing**: Structuring README files and explaining technical concepts
2. **Debugging assistance**: Identifying issues with Docker healthchecks and container startup order
3. **Script generation**: Creating entrypoint scripts for MariaDB and WordPress initialization
4. **Configuration optimization**: Suggesting NGINX and PHP-FPM configurations
5. **Error resolution**: Interpreting Docker and system error messages

**Tasks performed manually**:
- All Dockerfile creation and customization
- Docker Compose orchestration design
- Security configuration (TLS, secrets, network isolation)
- Testing and validation of the complete infrastructure
- Makefile automation
- Architecture decisions

## Features

- ✅ TLS 1.2/1.3 encryption for HTTPS
- ✅ Automatic WordPress installation via WP-CLI
- ✅ Persistent data storage with bind mounts
- ✅ Health checks for all services
- ✅ Secrets management for passwords
- ✅ Service orchestration with dependencies
- ✅ Bonus: Adminer for database administration
- ✅ Automatic container restart on failure
- ✅ Network isolation between services

## License

This project is part of the 42 School curriculum and follows its academic policies.

---

For detailed usage instructions, see [USER_DOC.md](USER_DOC.md).  
For development setup, see [DEV_DOC.md](DEV_DOC.md).