#!/bin/bash
set -e

# Management script for the stack
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    echo "🎯 E-commerce Backend Stack Management"
    echo "====================================="
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start          Start all services with init"
    echo "  stop           Stop all services"
    echo "  restart        Restart all services"
    echo "  status         Show status of all services"
    echo "  logs           Show logs from all services"
    echo "  logs-init      Show logs from init container only"
    echo "  reset          Reset all service data (WARNING: destroys data)"
    echo "  reset-init     Reset only init markers (re-run setup)"
    echo "  build          Build init container"
    echo "  clean          Clean up everything (containers, volumes, networks)"
    echo ""
    echo "Examples:"
    echo "  $0 start                    # Start the entire stack"
    echo "  $0 logs ecom-elasticsearch  # Show ES logs only"
    echo "  $0 reset-init              # Force re-run setup"
}

start_stack() {
    echo "🚀 Starting E-commerce Backend Stack..."
    bash "$SCRIPT_DIR/start.sh"
}

stop_stack() {
    echo "🛑 Stopping all services..."
    docker compose down
}

restart_stack() {
    echo "🔄 Restarting all services..."
    docker compose down
    docker compose up -d
}

show_status() {
    echo "📊 Service Status:"
    echo "=================="
    docker compose ps
    
    echo ""
    echo "🔍 Init Container Status:"
    echo "========================"
    if docker ps -a --filter "name=ecom-init" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "ecom-init"; then
        docker ps -a --filter "name=ecom-init" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "Init container not found"
    fi
}

show_logs() {
    if [[ -n "$1" ]]; then
        echo "📋 Showing logs for: $1"
        docker compose logs -f "$1"
    else
        echo "📋 Showing logs for all services:"
        docker compose logs -f
    fi
}

show_init_logs() {
    echo "📋 Init container logs:"
    docker logs ecom-init 2>/dev/null || echo "Init container not found or no logs available"
}

build_init() {
    echo "🏗️  Building init container..."
    docker compose build ecom-init
}

reset_data() {
    echo "⚠️  WARNING: This will destroy all data!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Stopping services and removing volumes..."
        docker compose down -v
        docker volume rm ecom_postgres_data ecom_redis_data ecom_rabbitmq_data ecom_elasticsearch_data ecom_pgadmin_data 2>/dev/null || true
        echo "✅ Data reset complete"
    else
        echo "❌ Reset cancelled"
    fi
}

reset_init() {
    echo "🔄 Resetting init markers (will re-run setup on next start)..."
    
    # Remove marker files from volumes
    docker run --rm \
        -v ecom_elasticsearch_data:/data/elasticsearch \
        -v ecom_postgres_data:/data/postgres \
        -v ecom_redis_data:/data/redis \
        -v ecom_rabbitmq_data:/data/rabbitmq \
        alpine:latest sh -c "
        find /data -name '.*_initialized' -delete
        echo 'Init markers removed'
    "
    
    # Remove the init container so it will re-run
    docker rm ecom-init 2>/dev/null || echo "Init container not found (already removed)"
    
    echo "✅ Init reset complete. Next start will re-run setup."
}

clean_all() {
    echo "🧹 Cleaning up everything..."
    read -p "This will remove ALL containers, volumes, and networks. Continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker compose down -v --remove-orphans
        docker volume rm ecom_postgres_data ecom_redis_data ecom_rabbitmq_data ecom_elasticsearch_data ecom_pgadmin_data 2>/dev/null || true
        docker network rm ecom-network 2>/dev/null || true
        docker system prune -f
        echo "✅ Cleanup complete"
    else
        echo "❌ Cleanup cancelled"
    fi
}

# Main command handler
case "${1:-help}" in
    "start")
        start_stack
        ;;
    "stop")
        stop_stack
        ;;
    "restart")
        restart_stack
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs "$2"
        ;;
    "logs-init")
        show_init_logs
        ;;
    "build")
        build_init
        ;;
    "reset")
        reset_data
        ;;
    "reset-init")
        reset_init
        ;;
    "clean")
        clean_all
        ;;
    "help"|*)
        show_help
        ;;
esac
