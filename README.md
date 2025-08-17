# E-commerce Backend Stack

A comprehensive development environment for the e-commerce platform, providing all necessary infrastructure services.

## 🏗️ Project Structure

```
ecom-be-stack/
├── docker-compose.yml            # Top-level orchestration
├── .env                         # Environment variables (copy from .env.example)
├── .env.example                 # Template with placeholder credentials
├── services/                    # Individual service configurations
│   ├── postgres/
│   │   ├── docker-compose.yml
│   │   ├── Dockerfile
│   │   └── init/                 # Database initialization scripts
│   ├── redis/
│   │   ├── docker-compose.yml
│   │   ├── redis.conf
│   │   └── users.acl
│   ├── rabbitmq/
│   │   ├── docker-compose.yml
│   │   ├── rabbitmq.conf
│   │   └── definitions.json
│   ├── elasticsearch/
│   │   ├── docker-compose.yml
│   │   ├── Dockerfile
│   │   ├── elasticsearch.yml
│   │   └── init/                 # User setup and entrypoint scripts
│   ├── kibana/
│   │   ├── docker-compose.yml
│   │   ├── Dockerfile
│   │   ├── kibana.yml
│   │   └── init/                 # Kibana initialization scripts
│   └── pgadmin/
│       ├── docker-compose.yml
│       ├── servers-dev.json
│       └── servers.json
├── scripts/                     # Utility scripts
└── README.md
```

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose installed
- At least 4GB RAM available for containers

### Setup
1. **Clone and setup environment:**
   ```bash
   git clone <repository-url>
   cd ecom-be-stack
   cp .env.example .env
   ```

2. **Edit credentials in `.env` file:**
   - Replace all `your_*_here` placeholders with secure passwords
   - Keep usernames or customize as needed

3. **Create network (optional, one-time):**
   ```bash
   docker network create ecom-network
   ```

4. **Start all services:**
   ```bash
   ./docker.sh up
   # Or manually:
   docker-compose up -d
   ```

## 🔧 Service Management

### Using Helper Scripts

**Linux/macOS:**
```bash
./docker.sh up      # Start all services  
./docker.sh down    # Stop all services
./docker.sh logs    # Follow logs
./docker.sh clean   # Clean containers/volumes (interactive)
```

**Windows (PowerShell):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\docker.ps1 up
.\docker.ps1 down  
.\docker.ps1 logs
.\docker.ps1 clean
```

### Manual Docker Commands

```bash
# Start specific services
docker-compose up -d postgres redis

# View service logs
docker-compose logs -f elasticsearch

# Restart a service
docker-compose restart kibana

# Check service status
docker-compose ps
```

## 🌐 Service Access

| Service | Host Access | Management UI | Default Credentials |
|---------|------------|---------------|-------------------|
| **PostgreSQL** | `localhost:5443` | PgAdmin: `http://localhost:8081` | See .env file |
| **Redis** | `localhost:6390` | - | See .env file |
| **RabbitMQ** | `localhost:5683` | `http://localhost:15683` | See .env file |
| **Elasticsearch** | `localhost:9201` | - | See .env file |
| **Kibana** | `http://localhost:5602` | Web UI | Use `admin_ecom` or `dev_ecom` |
| **PgAdmin** | `http://localhost:8081` | Web UI | See .env file |

## 👥 User Management

### Elasticsearch/Kibana Users
- **`elastic`**: Built-in superuser (full access)
- **`admin_ecom`**: Custom admin user (superuser privileges) 
- **`dev_ecom`**: Developer user (limited access to ecom indices)
- **`kibana_system`**: Service account (for Kibana ↔ Elasticsearch communication)

### Database Users
- **Admin User**: Full database access (migrations, maintenance)
- **Developer User**: Limited access (application runtime)

## 🔒 Security Configuration

### Environment Variables
All sensitive data is configured via `.env` file:
- Database passwords
- Redis authentication 
- RabbitMQ credentials
- Elasticsearch user passwords
- Kibana service credentials
- PgAdmin login

### Network Security
- Services communicate via internal Docker network `ecom-network`
- Only necessary ports are exposed to host
- Service-to-service authentication enabled

## 🛠️ Development Integration

### Backend Application
The backend application (`ecom-backend`) connects to these services using:

**Development URLs (from host):**
```
DATABASE_URL=postgresql://dev_user:password@localhost:5443/ecommerce_db
REDIS_URL=redis://dev_user:password@localhost:6390
RABBITMQ_URL=amqp://dev_user:password@localhost:5683/
ELASTICSEARCH_URL=http://dev_user:password@localhost:9201
```

**Container-to-Container URLs:**
```  
DATABASE_INTERNAL_URL=postgresql://dev_user:password@postgres:5432/ecommerce_db
REDIS_INTERNAL_URL=redis://dev_user:password@redis:6379
RABBITMQ_INTERNAL_URL=amqp://dev_user:password@rabbitmq:5672/
ELASTICSEARCH_INTERNAL_URL=http://dev_user:password@elasticsearch:9200
```

## 🐛 Troubleshooting

### Common Issues

**Container startup failures:**
```bash
# Check container status
docker-compose ps

# View logs for specific service
docker-compose logs service-name

# Restart problematic service
docker-compose restart service-name
```

**Network connectivity issues:**
```bash
# Verify network exists
docker network inspect ecom-network

# Connect container to network manually
docker network connect ecom-network container-name
```

**Port conflicts:**
```bash
# Check what's using a port (macOS/Linux)
lsof -i :5443

# Windows
netstat -ano | findstr :5443
```

**Permission issues:**
```bash
# Fix Docker permission issues (Linux)
sudo chown -R $USER:$USER .
```

### Health Checks

**Elasticsearch:**
```bash
curl -u "admin_ecom:password" http://localhost:9201/_cluster/health
```

**PostgreSQL:**
```bash
docker exec ecom-postgres pg_isready -U admin_ecom -d ecommerce_db
```

**Redis:**
```bash
docker exec ecom-redis redis-cli -a password ping
```

## 📁 Data Persistence

All services use Docker volumes for data persistence:
- `ecom_postgres_data`: Database files
- `ecom_redis_data`: Redis snapshots  
- `ecom_rabbitmq_data`: Queue data
- `ecom_elasticsearch_data`: Search indices
- `ecom_pgadmin_data`: PgAdmin configurations

## 🔄 Maintenance

### Backup
```bash
# Database backup
docker exec ecom-postgres pg_dump -U admin_ecom ecommerce_db > backup.sql

# Elasticsearch backup
docker exec ecom-elasticsearch curl -X POST "localhost:9200/_snapshot/backup/snapshot_1"
```

### Updates
```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d
```

### Cleanup
```bash
# Remove all containers and volumes (WARNING: DATA LOSS)
./docker.sh clean

# Manual cleanup
docker-compose down -v
docker system prune
```

## 📚 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)  
- [Elasticsearch Documentation](https://www.elastic.co/guide/index.html)
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)

---
**Need help?** Check the troubleshooting section or create an issue in the repository.