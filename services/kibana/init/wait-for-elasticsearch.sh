#!/bin/bash
set -e

echo "Kibana wait-for-elasticsearch script"

# Provide defaults for environment variables
ELASTICSEARCH_HOST="${ELASTICSEARCH_HOSTS:-http://ecom-elasticsearch:9200}"
ELASTICSEARCH_USERNAME="${ELASTICSEARCH_KIBANA_USER:-kibana_system}"
ELASTICSEARCH_PASSWORD="${ELASTICSEARCH_KIBANA_PASSWORD:-KibanaService2025}"

echo "Waiting for Elasticsearch to start and be ready..."
timeout=300
retry_count=0
max_retries=60

while [ $retry_count -lt $max_retries ]; do
  echo "Attempt $((retry_count + 1))/$max_retries - checking Elasticsearch health..."
  
  # Check if ES is responding and has yellow/green status
  if health_response=$(curl -s -f -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" "${ELASTICSEARCH_HOST}/_cluster/health" 2>/dev/null); then
    if echo "$health_response" | grep -q '"status":"green\|yellow"'; then
      echo "Elasticsearch is ready! Status: $(echo "$health_response" | jq -r .status 2>/dev/null || echo 'unknown')"
      break
    else
      echo "Elasticsearch responding but not ready. Status: $(echo "$health_response" | jq -r .status 2>/dev/null || echo 'unknown')"
    fi
  else
    echo "Elasticsearch not yet responding to health check or authentication failed"
  fi
  
  sleep 5
  retry_count=$((retry_count + 1))
done

if [ $retry_count -ge $max_retries ]; then
  echo "ERROR: Timeout waiting for Elasticsearch to be ready after $((max_retries * 5)) seconds"
  exit 1
fi

echo "Elasticsearch is ready, proceeding with Kibana startup..."
