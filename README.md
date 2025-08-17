# E-commerce Development Environment

## Project Structure

```
ecom-be-stack/
├── docker-compose.yml            # Top-level compose that references services/*
├── .env                         # Optional central env file (stack-wide vars)
├── services/                    # Per-service compose fragments and configs
│   ├── postgres/
│   │   ├── docker-compose.yml
│   │   ├── Dockerfile
│   │   └── init/                 # SQL and init scripts
│   ├── redis/
│   │   ├── docker-compose.yml
│   │   └── redis.conf
│   ├── rabbitmq/
│   │   ├── docker-compose.yml
│   │   ├── rabbitmq.conf
│   │   └── definitions.json
│   ├── elasticsearch/
│   │   ├── docker-compose.yml
│   │   ├── Dockerfile
│   │   ├── elasticsearch.yml
│   │   └── init/                 # entrypoint + user-setup scripts
│   ├── kibana/
│   │   ├── docker-compose.yml
│   │   └── kibana.yml
│   └── pgadmin/
│       ├── docker-compose.yml
│       └── servers-dev.json
└── README.md
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
# E-commerce Stack — development services

This folder contains the local infrastructure used by the backend during development: Postgres, Redis, RabbitMQ, Elasticsearch, Kibana and PgAdmin.

Quick summary
- Top-level compose: `docker-compose.yml` (references `services/*`)
- Per-service definitions: `services/*/docker-compose.yml`
- Project name: `ecom` (containers will be named `ecom-postgres`, `ecom-redis`, etc.)
- Shared network: `ecom-network` (recommended to be external so multiple compose projects can share it)

Quick start
1. (Optional, one-time) Create the shared network if you don't want compose to create it:
   ```bash
   docker network create ecom-network
   ```
2. Start the stack:
   ```bash
   docker compose -f docker-compose.yml up -d
   ```
3. Stop the stack:
   ```bash
   docker compose -f docker-compose.yml down
   ```

Scripts
- `docker.sh` — helper script (Linux / macOS) shipped in this folder to create volumes/network and to start/stop/restart/show logs/clean the stack. Use:
   ```bash
   ./docker.sh up      # start
   ./docker.sh down    # stop
   ./docker.sh logs    # follow logs
   ./docker.sh clean   # remove containers/images/volumes (interactive)
   ```

- `docker.ps1` — PowerShell helper for Windows with equivalent commands. Run from PowerShell (you may need to allow script execution first):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   .\docker.ps1 up
   .\docker.ps1 down
   .\docker.ps1 logs
   .\docker.ps1 clean
   ```

Service list & ports (host -> container)
- ecom-postgres: 5443 -> 5432
- ecom-redis: 6390 -> 6379
- ecom-rabbitmq: 5683 -> 5672 (management: 15683)
- ecom-elasticsearch: 9201 -> 9200
- ecom-kibana: 5602 -> 5601
- ecom-pgadmin: 8081 -> 80

Networking notes
- We recommend using a single Docker network named `ecom-network` so services started from `ecom-be-stack` and `ecom-backend` can resolve each other by name. If you prefer compose to manage the network lifecycle, remove the `external: true` flag from the network declaration in the compose file(s).


Backend build
 - Backend build/readme and private-package details live in the `ecom-backend` repository. See `ecom-backend/README.md` for instructions about building the backend image and handling any private npm packages or tokens.

Troubleshooting
- DNS/ENOTFOUND: if the API cannot resolve `ecom-postgres`/`ecom-redis`/etc, ensure the container is attached to `ecom-network`. Use `docker network inspect ecom-network` and `docker network connect ecom-network <container>`.
- Port conflicts: if a container fails to bind a host port, verify no local process already uses that port (macOS: `lsof -i :3012`).

Files
- `docker-compose.yml` — top-level stack compose
- `services/*/docker-compose.yml` — per-service fragments and configs
- `services/*/init` — initialization scripts used by some services
- `docker.sh` — helper script to manage the local stack (start/stop/logs/clean)

If you'd like, I can also add a small `Makefile` with `start|stop|build-backend` targets and a GitHub Actions snippet showing how to build backend images securely with secrets.