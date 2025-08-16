#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Testing E-commerce Stack Connections..."
echo "=========================================="

# Load environment variables
source .env

# Test PostgreSQL Admin
echo -n "📊 PostgreSQL (Admin): "
if PGPASSWORD=$POSTGRES_ADMIN_PASSWORD psql -h localhost -p 5443 -U $POSTGRES_ADMIN_USER -d $POSTGRES_DB -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

# Test PostgreSQL Developer
echo -n "📊 PostgreSQL (Developer): "
if PGPASSWORD=$POSTGRES_DEV_PASSWORD psql -h localhost -p 5443 -U $POSTGRES_DEV_USER -d $POSTGRES_DB -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

# Test Redis Admin
echo -n "🔴 Redis (Admin): "
if redis-cli -h localhost -p 6390 -a $REDIS_ADMIN_PASSWORD ping > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

# Test Redis Developer
echo -n "🔴 Redis (Developer): "
if redis-cli -h localhost -p 6390 --user dev_ecom --pass $REDIS_DEV_PASSWORD ping > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

# Test RabbitMQ Management
echo -n "🐰 RabbitMQ Management: "
if curl -s -u $RABBITMQ_ADMIN_USER:$RABBITMQ_ADMIN_PASS http://localhost:15683/api/overview > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

# Test Elasticsearch Admin
echo -n "🔍 Elasticsearch (Admin): "
if curl -s -u elastic:$ELASTICSEARCH_ADMIN_PASSWORD http://localhost:9201/_cluster/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

# Test Elasticsearch Developer
echo -n "🔍 Elasticsearch (Developer): "
if curl -s -u dev_ecom:$ELASTICSEARCH_DEV_PASSWORD http://localhost:9201/_cluster/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

# Test Kibana
echo -n "📈 Kibana: "
if curl -s http://localhost:5602/api/status > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

# Test PgAdmin
echo -n "🐘 PgAdmin: "
if curl -s http://localhost:8081/misc/ping > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

echo ""
echo "🎯 Connection URLs for your application:"
echo "========================================"
echo "DATABASE_URL: $DATABASE_URL"
echo "REDIS_URL: $REDIS_URL"
echo "RABBITMQ_URL: $RABBITMQ_URL"
echo "ELASTICSEARCH_URL: $ELASTICSEARCH_URL"

echo ""
echo "🌐 Web Interfaces:"
echo "=================="
echo "PgAdmin: http://localhost:8081"
echo "RabbitMQ: http://localhost:15683"
echo "Kibana: http://localhost:5602"
echo "Elasticsearch: http://localhost:9201"