# E-commerce Development Environment

## Project Structure

```
├── docker-compose.yml          # Main compose file
├── .env                       # Centralized environment variables
├── services/                  # Service-specific configurations
│   ├── postgres/
│   │   ├── docker-compose.yml
│   │   └── init/
│   ├── redis/
│   │   ├── docker-compose.yml
│   │   └── redis.conf
│   ├── rabbitmq/
│   │   ├── docker-compose.yml
│   │   └── rabbitmq.conf
│   ├── elasticsearch/
│   │   ├── docker-compose.yml
│   │   └── elasticsearch.yml
│   ├── kibana/
│   │   ├── docker-compose.yml
│   │   └── kibana.yml
│   └── pgadmin/
│       ├── docker-compose.yml
│       └── servers.json
```

## Quick Start

1. **Start all services:**
   ```bash
   docker-compose up -d
   ```

2. **Start specific services:**
   ```bash
   docker-compose up -d postgres redis
   ```

3. **View logs:**
   ```bash
   docker-compose logs -f api
   ```

## Service Access

- **API Server:** http://localhost:3012
- **API Docs:** http://localhost:3012/docs
- **PostgreSQL:** localhost:5443
- **Redis:** localhost:6390
- **RabbitMQ Management:** http://localhost:15683
- **Elasticsearch:** http://localhost:9201
- **Kibana:** http://localhost:5602
- **PgAdmin:** http://localhost:8081

## Environment Variables

All credentials and configuration are centralized in `.env` file. Update this file to change database passwords, ports, etc.

## Individual Service Management

Each service has its own folder with:
- `docker-compose.yml` - Service definition
- Configuration files (redis.conf, elasticsearch.yml, etc.)
- Initialization scripts (for postgres)

## Development

The API service is configured for development with:
- Hot reload enabled
- Debug port exposed (9230)
- Volume mounting for live code changes