#!/bin/bash

echo "Setting up Elasticsearch users..."

# Wait for Elasticsearch container to be healthy
echo "Waiting for Elasticsearch to be ready..."
while ! docker exec ecom-elasticsearch curl -u "elastic:${ELASTICSEARCH_ADMIN_PASSWORD}" -f "http://localhost:9200/_cluster/health" > /dev/null 2>&1; do
    echo "Waiting for Elasticsearch..."
    sleep 5
done

echo "Elasticsearch is ready. Creating users..."
docker exec ecom-elasticsearch /usr/share/elasticsearch/setup-users.sh

echo "✅ Elasticsearch setup completed!"
