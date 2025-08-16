#!/bin/bash
set -e

# Provide defaults for environment variables
ELASTICSEARCH_ADMIN_PASSWORD="${ELASTICSEARCH_ADMIN_PASSWORD:-AdminSearch2025}"
ELASTICSEARCH_DEV_PASSWORD="${ELASTICSEARCH_DEV_PASSWORD:-DevSearch2025}"

# Wait for Elasticsearch to start and be ready
echo "Waiting for Elasticsearch to start and be ready..."
timeout=120
retry_count=0
max_retries=24

# Use elasticsearch hostname since we're in different container
ES_HOST="${ES_HOST:-ecom-elasticsearch:9200}"

while [ $retry_count -lt $max_retries ]; do
  echo "Attempt $((retry_count + 1))/$max_retries - checking Elasticsearch health..."
  
  # Check if ES is responding and has yellow/green status
  if health_response=$(curl -s -f -u "elastic:${ELASTICSEARCH_ADMIN_PASSWORD}" "http://$ES_HOST/_cluster/health" 2>/dev/null); then
    if echo "$health_response" | grep -q '"status":"green\|yellow"'; then
      echo "Elasticsearch is ready! Status: $(echo "$health_response" | jq -r .status)"
      break
    else
      echo "Elasticsearch responding but not ready. Status: $(echo "$health_response" | jq -r .status)"
    fi
  else
    echo "Elasticsearch not yet responding to health check"
  fi
  
  sleep 5
  retry_count=$((retry_count + 1))
done

if [ $retry_count -ge $max_retries ]; then
  echo "ERROR: Timeout waiting for Elasticsearch to be ready after $((max_retries * 5)) seconds"
  exit 1
fi

echo "Creating Elasticsearch users..."

# Function to make API call with error handling
make_api_call() {
  local method="$1"
  local endpoint="$2" 
  local data="$3"
  local description="$4"
  
  echo "Creating $description..."
  if response=$(curl -s -w "%{http_code}" -u "elastic:${ELASTICSEARCH_ADMIN_PASSWORD}" \
    -X "$method" "http://$ES_HOST$endpoint" \
    -H "Content-Type: application/json" \
    -d "$data"); then
    
    http_code="${response: -3}"
    response_body="${response%???}"
    
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
      echo "✓ Successfully created $description"
    else
      echo "⚠ API call for $description returned HTTP $http_code: $response_body"
      # Don't exit on error - user might already exist
    fi
  else
    echo "✗ Failed to make API call for $description"
    return 1
  fi
}

# Create developer role first
make_api_call "POST" "/_security/role/dev_ecom_role" '{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["products*", "orders*", "users*", "ecom-*"],
      "privileges": ["read", "write", "create", "index", "delete", "manage"]
    }
  ]
}' "developer role (dev_ecom_role)"

# Create developer user with limited permissions  
make_api_call "POST" "/_security/user/dev_ecom" "{
  \"password\": \"${ELASTICSEARCH_DEV_PASSWORD}\",
  \"roles\": [\"kibana_user\", \"dev_ecom_role\"],
  \"full_name\": \"E-commerce Developer\",
  \"email\": \"dev@ecommerce.local\"
}" "developer user (dev_ecom)"

echo "Elasticsearch users created successfully!"