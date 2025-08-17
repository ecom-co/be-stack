<#
.SYNOPSIS
  Helper script to manage the local ecom development stack on Windows (PowerShell).

USAGE
  ./docker.ps1 up
  ./docker.ps1 down
  ./docker.ps1 logs [service]
  ./docker.ps1 clean

NOTE
  Run from the `ecom-be-stack` folder. You may need to allow script execution:
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#>

param(
    [string]$Command,
    [string]$Service
)

function Write-Info($msg) { Write-Host "[INFO]  $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Write-Err ($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Ensure-CommandExists([string]$cmd) {
    try {
        & $cmd --version > $null 2>&1
        return $true
    } catch {
        return $false
    }
}

function Start-Services {
    Write-Info "Starting ecommerce development environment..."

    # Create network if it doesn't exist (ignore errors)
    try { docker network create ecom-network | Out-Null } catch {}

    # Create external volumes (ignore errors)
    try { docker volume create ecom_postgres_data | Out-Null } catch {}
    try { docker volume create ecom_redis_data | Out-Null } catch {}
    try { docker volume create ecom_rabbitmq_data | Out-Null } catch {}
    try { docker volume create ecom_pgadmin_data | Out-Null } catch {}
    try { docker volume create ecom_elasticsearch_data | Out-Null } catch {}

    # Start services
    docker compose up -d

    Write-Info "Services started successfully!"
    Write-Info "Access points:"
    Write-Host "  - PostgreSQL: localhost:5443"
    Write-Host "  - Redis: localhost:6390"
    Write-Host "  - RabbitMQ Management: http://localhost:15683"
    Write-Host "  - Elasticsearch: http://localhost:9201"
    Write-Host "  - Kibana: http://localhost:5602"
    Write-Host "  - PgAdmin: http://localhost:8081"
}

function Stop-Services {
    Write-Info "Stopping ecommerce development environment..."
    docker compose down
    Write-Info "Services stopped successfully!"
}

function Restart-Services {
    Write-Info "Restarting ecommerce development environment..."
    Stop-Services
    Start-Sleep -Seconds 2
    Start-Services
}

function Show-Logs {
    if ($Service) {
        Write-Info "Showing logs for service: $Service"
        docker compose logs -f $Service
    } else {
        Write-Info "Showing logs for all services..."
        docker compose logs -f
    }
}

function Show-Status {
    Write-Info "Service status:"
    docker compose ps
}

function Clean-All {
    Write-Warn "This will remove ecommerce project containers, images, and volumes!"
    $confirm = Read-Host "Are you sure? (y/N)"
    if ($confirm -notin @('y','Y')) {
        Write-Info "Clean operation cancelled."
        return
    }

    Write-Info "Cleaning up ecommerce project Docker resources..."

    # Stop and remove compose resources
    docker compose down -v 2>$null

    # Remove containers matching name pattern
    $containers = docker ps -aq --filter "name=ecom-"
    if ($containers) { docker rm -f $containers 2>$null }

    # Remove images matching reference
    $images = docker images --filter "reference=*ecom*" -q
    if ($images) { docker rmi $images 2>$null }
    $images2 = docker images --filter "reference=*ecommerce*" -q
    if ($images2) { docker rmi $images2 2>$null }

    # Remove known volumes
    try { docker volume rm ecom_postgres_data,ecom_redis_data,ecom_rabbitmq_data,ecom_pgadmin_data,ecom_elasticsearch_data -f 2>$null } catch {}

    # Remove network
    try { docker network rm ecom-network 2>$null } catch {}

    # Prune system (safe)
    docker system prune -f

    Write-Info "Ecommerce project Docker resources cleaned!"
}

function Run-Test {
    Write-Info "Testing all service connections..."
    if (Test-Path ./scripts/test-connections.sh) {
        & bash ./scripts/test-connections.sh
    } else {
        Write-Warn "No test script found at ./scripts/test-connections.sh"
    }
}

function Run-Seed {
    Write-Info "Seeding development data..."
    if (Test-Path ./scripts/seed-data.sh) {
        & bash ./scripts/seed-data.sh
    } else {
        Write-Warn "No seed script found at ./scripts/seed-data.sh"
    }
}

function Setup-ES {
    Write-Info "Setting up Elasticsearch users..."
    if (Test-Path ./setup-elasticsearch-users.sh) {
        & bash ./setup-elasticsearch-users.sh
    } else {
        Write-Warn "No setup script found at ./setup-elasticsearch-users.sh"
    }
}

switch ($Command) {
    'up'    { Start-Services; break }
    'start' { Start-Services; break }
    'down'  { Stop-Services; break }
    'stop'  { Stop-Services; break }
    'restart' { Restart-Services; break }
    'logs'  { Show-Logs; break }
    'status' { Show-Status; break }
    'ps'    { Show-Status; break }
    'clean' { Clean-All; break }
    'test'  { Run-Test; break }
    'seed'  { Run-Seed; break }
    'setup-es' { Setup-ES; break }
    default {
        Write-Host "Usage: .\docker.ps1 {up|down|restart|logs|status|clean|test|seed|setup-es} [service]"
        Write-Host ""
        Write-Host "Commands:"
        Write-Host "  up/start    - Start all services"
        Write-Host "  down/stop   - Stop all services"
        Write-Host "  restart     - Restart all services"
        Write-Host "  logs [svc]  - Show logs (optionally for specific service)"
        Write-Host "  status/ps   - Show service status"
        Write-Host "  clean       - Clean all Docker containers, images, and volumes"
        Write-Host "  test        - Test all service connections (calls ./scripts/test-connections.sh)"
        Write-Host "  seed        - Seed development data (calls ./scripts/seed-data.sh)"
        Write-Host "  setup-es    - Setup Elasticsearch users (calls ./setup-elasticsearch-users.sh)"
    }
}
