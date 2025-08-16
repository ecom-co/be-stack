#!/bin/bash

# This script runs Elasticsearch and auto-creates users when ready

# Start Elasticsearch in background
echo "Starting Elasticsearch..."
/usr/local/bin/docker-entrypoint.sh elasticsearch &
ES_PID=$!

# Wait and setup users with health check
(
    echo "Waiting for Elasticsearch to be ready..."
    
    # Wait for ES to be healthy
    retry_count=0
    max_retries=30
    
    while [ $retry_count -lt $max_retries ]; do
        echo "Health check attempt $((retry_count + 1))/$max_retries..."
        
        if curl -s -u "elastic:${ELASTICSEARCH_ADMIN_PASSWORD}" "http://localhost:9200/_cluster/health" | grep -q '"status":"green\|yellow"'; then
            echo "✅ Elasticsearch is ready! Running user setup..."
            /usr/share/elasticsearch/setup-users.sh || echo "⚠️ User setup failed or already completed"
            break
        fi
        
        sleep 5
        retry_count=$((retry_count + 1))
    done
    
    if [ $retry_count -ge $max_retries ]; then
        echo "❌ Timeout waiting for Elasticsearch to be ready"
    fi
) &

# Wait for Elasticsearch main process
echo "Waiting for Elasticsearch main process..."
wait $ES_PID
