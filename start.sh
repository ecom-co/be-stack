#!/bin/bash
set -e

echo "🚀 E-commerce Backend Stack with Init Container"
echo "=============================================="

# Function to check if network exists
network_exists() {
    docker network ls | grep -q "ecom-network"
}

# Function to check if volumes exist
volume_exists() {
    local volume_name="$1"
    docker volume ls | grep -q "$volume_name"
}

# Create external network if it doesn't exist
if ! network_exists; then
    echo "🔗 Creating external network: ecom-network"
    docker network create ecom-network
else
    echo "✅ Network ecom-network already exists"
fi

# Create external volumes if they don't exist
volumes=("ecom_postgres_data" "ecom_redis_data" "ecom_rabbitmq_data" "ecom_pgadmin_data" "ecom_elasticsearch_data")
for volume in "${volumes[@]}"; do
    if ! volume_exists "$volume"; then
        echo "📦 Creating external volume: $volume"
        docker volume create "$volume"
    else
        echo "✅ Volume $volume already exists"
    fi
done

# Build and start services
echo "🏗️  Building and starting services..."
docker compose up --build -d

echo ""
echo "🎉 Services are starting up!"
echo "📊 Check status with: docker compose ps"
echo "📋 View logs with: docker compose logs -f"
echo "🔧 Init container will run setup once all services are healthy"
echo ""
echo "📱 Service URLs:"
echo "  🔍 Elasticsearch: http://localhost:9201"
echo "  🐘 PostgreSQL:    localhost:5443"
echo "  🟥 Redis:         localhost:6390"
echo "  🐰 RabbitMQ:      http://localhost:15683 (Management UI)"
echo "  📊 Kibana:        http://localhost:5602"
echo "  🔧 PgAdmin:       http://localhost:8081"
