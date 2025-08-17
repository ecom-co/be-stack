#!/bin/bash

# This script runs Kibana and waits for Elasticsearch to be ready

# Provide defaults for environment variables
ELASTICSEARCH_HOST="${ELASTICSEARCH_HOSTS:-http://ecom-elasticsearch:9200}"
ELASTICSEARCH_USERNAME="${ELASTICSEARCH_KIBANA_USER:-kibana_system}"
ELASTICSEARCH_PASSWORD="${ELASTICSEARCH_KIBANA_PASSWORD:-KibanaService2025}"

# Wait for Elasticsearch to be ready first
echo "Waiting for Elasticsearch to be ready..."

# Wait and check Elasticsearch health
(
    echo "Checking Elasticsearch health before starting Kibana..."
    
    retry_count=0
    max_retries=30
    
    while [ $retry_count -lt $max_retries ]; do
        echo "Health check attempt $((retry_count + 1))/$max_retries..."
        
        # Check if ES is responding and authentication works
        if health_response=$(curl -s -f -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" "${ELASTICSEARCH_HOST}/_cluster/health" 2>/dev/null); then
            if echo "$health_response" | grep -q '"status":"green\|yellow"'; then
                echo "✅ Elasticsearch is ready! Status: $(echo "$health_response" | jq -r .status 2>/dev/null || echo 'parsing failed')"
                break
            else
                echo "Elasticsearch responding but not ready. Status: $(echo "$health_response" | jq -r .status 2>/dev/null || echo 'parsing failed')"
            fi
        else
            echo "Elasticsearch not yet responding to health check or authentication failed"
        fi
        
        sleep 5
        retry_count=$((retry_count + 1))
    done
    
    if [ $retry_count -ge $max_retries ]; then
        echo "❌ Timeout waiting for Elasticsearch to be ready"
        exit 1
    fi
) 

echo "Starting Kibana..."
exec /usr/local/bin/kibana-docker
