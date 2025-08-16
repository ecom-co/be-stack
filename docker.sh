#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to start services
start_services() {
    print_status "Starting ecommerce development environment..."
    
    # Create network if it doesn't exist
    docker network create ecom-network 2>/dev/null || true
    
    # Create external volumes
    docker volume create ecom_postgres_data 2>/dev/null || true
    docker volume create ecom_redis_data 2>/dev/null || true
    docker volume create ecom_rabbitmq_data 2>/dev/null || true
    docker volume create ecom_pgadmin_data 2>/dev/null || true
    docker volume create ecom_elasticsearch_data 2>/del || true
    
    # Start services
    docker-compose up -d
    
    print_status "Services started successfully!"
    print_status "Access points:"
    echo "  - PostgreSQL: localhost:5443"
    echo "  - Redis: localhost:6390"
    echo "  - RabbitMQ Management: http://localhost:15683"
    echo "  - Elasticsearch: http://localhost:9201"
    echo "  - Kibana: http://localhost:5602"
    echo "  - PgAdmin: http://localhost:8081"
}

# Function to stop services
stop_services() {
    print_status "Stopping ecommerce development environment..."
    
    docker-compose down
    
    print_status "Services stopped successfully!"
}

# Function to restart services
restart_services() {
    print_status "Restarting ecommerce development environment..."
    stop_services
    sleep 2
    start_services
}

# Function to show logs
show_logs() {
    if [ -n "$2" ]; then
        print_status "Showing logs for service: $2"
        docker-compose logs -f "$2"
    else
        print_status "Showing logs for all services..."
        docker-compose logs -f
    fi
}

# Function to show status
show_status() {
    print_status "Service status:"
    docker-compose ps
}

# Function to clean project resources only
clean_all() {
    print_warning "This will remove ecommerce project containers, images, and volumes!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up ecommerce project Docker resources..."
        
        # Stop and remove project containers
        docker-compose down -v 2>/dev/null || true
        
        # Remove project containers by name pattern
        docker rm -f $(docker ps -aq --filter "name=ecom-*") 2>/dev/null || true
        
        # Remove project images by name pattern
        docker rmi $(docker images --filter "reference=*ecom*" -q) 2>/dev/null || true
        docker rmi $(docker images --filter "reference=*ecommerce*" -q) 2>/dev/null || true
        
        # Remove project volumes
        docker volume rm ecom_postgres_data ecom_redis_data ecom_rabbitmq_data ecom_pgadmin_data ecom_elasticsearch_data 2>/dev/null || true
        
        # Remove project network
        docker network rm ecom-network 2>/dev/null || true
        
        # Clean only dangling resources (safe)
        docker system prune -f
        
        print_status "Ecommerce project Docker resources cleaned!"
    else
        print_status "Clean operation cancelled."
    fi
}

# Main script logic
case "$1" in
    "up"|"start")
        start_services
        ;;
    "down"|"stop")
        stop_services
        ;;
    "restart")
        restart_services
        ;;
    "logs")
        show_logs "$@"
        ;;
    "status"|"ps")
        show_status
        ;;
    "clean")
        clean_all
        ;;
    "test")
        print_status "Testing all service connections..."
        ./scripts/test-connections.sh
        ;;
    "seed")
        print_status "Seeding development data..."
        ./scripts/seed-data.sh
        ;;
    *)
        echo "Usage: $0 {up|down|restart|logs|status|clean|test|seed}"
        echo ""
        echo "Commands:"
        echo "  up/start    - Start all services"
        echo "  down/stop   - Stop all services"
        echo "  restart     - Restart all services"
        echo "  logs [service] - Show logs (optionally for specific service)"
        echo "  status/ps   - Show service status"
        echo "  clean       - Clean all Docker containers, images, and volumes"
        echo "  test        - Test all service connections"
        echo "  seed        - Seed development data"
        echo ""
        echo "Examples:"
        echo "  $0 up"
        echo "  $0 test"
        echo "  $0 seed"
        echo "  $0 logs postgres"
        echo "  $0 clean"
        exit 1
        ;;
esac