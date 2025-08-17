#!/bin/bash
set -e

# Environment variables with defaults
ELASTICSEARCH_ELASTIC_PASSWORD="${ELASTICSEARCH_ELASTIC_PASSWORD:-ElasticSuper2025}"
ELASTICSEARCH_ADMIN_USER="${ELASTICSEARCH_ADMIN_USER:-admin_ecom}"
ELASTICSEARCH_ADMIN_PASSWORD="${ELASTICSEARCH_ADMIN_PASSWORD:-AdminSearch2025}"
ELASTICSEARCH_KIBANA_PASSWORD="${ELASTICSEARCH_KIBANA_PASSWORD:-KibanaService2025}"
ELASTICSEARCH_DEV_USER="${ELASTICSEARCH_DEV_USER:-dev_ecom}"
ELASTICSEARCH_DEV_PASSWORD="${ELASTICSEARCH_DEV_PASSWORD:-DevSearch2025}"

echo "🚀 Starting Elasticsearch user setup..."
echo "Waiting for Elasticsearch to be ready..."

# Wait for Elasticsearch to start
timeout=120
retry_count=0
max_retries=24
es_ready=false

while [ $retry_count -lt $max_retries ]; do
  echo "⏳ Attempt $((retry_count + 1))/$max_retries - checking Elasticsearch..."
  
  # Try different methods to check if ES is ready
  # Method 1: Check if ES is responding (might return 401 if security is enabled, that's OK)
  if curl -s -f "http://localhost:9200" >/dev/null 2>&1; then
    echo "✅ Elasticsearch is responding!"
    es_ready=true
    break
  fi
  
  # Method 2: Check with potential elastic user (in case it's already configured)
  if curl -s -u "elastic:${ELASTICSEARCH_ELASTIC_PASSWORD}" "http://localhost:9200/_cluster/health" >/dev/null 2>&1; then
    echo "✅ Elasticsearch is responding with authentication!"
    es_ready=true
    break
  fi
  
  # Method 3: Check if we get a 401 (which means ES is up but needs auth)
  response_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:9200" 2>/dev/null || echo "000")
  if [ "$response_code" = "401" ]; then
    echo "✅ Elasticsearch is responding (security enabled)!"
    es_ready=true
    break
  fi
  
  sleep 5
  retry_count=$((retry_count + 1))
done

if [ "$es_ready" = false ]; then
  echo "❌ ERROR: Timeout waiting for Elasticsearch"
  exit 1
fi

echo "🔐 Setting up user authentication..."

# Function to check if user exists
user_exists() {
  local username="$1"
  local auth_user="${2:-elastic}"
  local auth_pass="${3:-${ELASTICSEARCH_ELASTIC_PASSWORD}}"
  
  response_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "$auth_user:$auth_pass" \
    "http://localhost:9200/_security/user/$username" 2>/dev/null || echo "000")
  
  [ "$response_code" = "200" ]
}

# Function to check if role exists
role_exists() {
  local rolename="$1"
  local auth_user="${2:-elastic}"
  local auth_pass="${3:-${ELASTICSEARCH_ELASTIC_PASSWORD}}"
  
  response_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "$auth_user:$auth_pass" \
    "http://localhost:9200/_security/role/$rolename" 2>/dev/null || echo "000")
  
  [ "$response_code" = "200" ]
}

# Function to make API calls with retry
make_api_call() {
  local method="$1"
  local endpoint="$2" 
  local data="$3"
  local description="$4"
  local auth_user="${5:-elastic}"
  local auth_pass="${6:-${ELASTICSEARCH_ELASTIC_PASSWORD}}"
  local max_attempts=3
  
  echo "📝 Setting up $description..."
  
  for attempt in $(seq 1 $max_attempts); do
    # Use temporary file to capture full response
    temp_file=$(mktemp)
    
    # Make the API call
    http_code=$(curl -s -w "%{http_code}" \
      -u "$auth_user:$auth_pass" \
      -X "$method" "http://localhost:9200$endpoint" \
      -H "Content-Type: application/json" \
      -d "$data" \
      -o "$temp_file" 2>/dev/null || echo "000")
    
    response_body=$(cat "$temp_file" 2>/dev/null || echo "")
    rm -f "$temp_file"
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
      echo "✅ Successfully set up $description"
      return 0
    elif [ "$http_code" = "400" ] && echo "$response_body" | grep -q "already exists"; then
      echo "ℹ️  $description already exists, skipping..."
      return 0
    else
      echo "⚠️  Attempt $attempt/$max_attempts - Issue with $description (HTTP $http_code): $response_body"
      if [ $attempt -lt $max_attempts ]; then
        echo "🔄 Retrying in 2 seconds..."
        sleep 2
      fi
    fi
  done
  
  echo "❌ Failed to set up $description after $max_attempts attempts"
  return 1
}

echo "🔑 Step 1: Setting password for kibana_system user..."
make_api_call "POST" "/_security/user/kibana_system/_password" \
  "{\"password\": \"${ELASTICSEARCH_KIBANA_PASSWORD}\"}" \
  "kibana_system user password"

# Step 2: Create admin role (check if exists first)
echo "👑 Step 2: Creating admin role..."
if role_exists "${ELASTICSEARCH_ADMIN_USER}_role"; then
  echo "ℹ️  Admin role already exists, skipping creation..."
else
  make_api_call "POST" "/_security/role/${ELASTICSEARCH_ADMIN_USER}_role" \
    '{
      "cluster": ["all"],
      "indices": [{"names": ["*"], "privileges": ["all"]}]
    }' \
    "admin role (${ELASTICSEARCH_ADMIN_USER}_role)"
fi

# Step 3: Create admin user (check if exists first)
echo "👨‍💼 Step 3: Creating admin user..."
if user_exists "${ELASTICSEARCH_ADMIN_USER}"; then
  echo "ℹ️  Admin user already exists, updating password..."
  make_api_call "POST" "/_security/user/${ELASTICSEARCH_ADMIN_USER}/_password" \
    "{\"password\": \"${ELASTICSEARCH_ADMIN_PASSWORD}\"}" \
    "admin user password update"
else
  make_api_call "POST" "/_security/user/${ELASTICSEARCH_ADMIN_USER}" \
    "{
      \"password\": \"${ELASTICSEARCH_ADMIN_PASSWORD}\",
      \"roles\": [\"superuser\", \"${ELASTICSEARCH_ADMIN_USER}_role\"],
      \"full_name\": \"E-commerce Admin\",
      \"email\": \"admin@ecommerce.local\"
    }" \
    "admin user (${ELASTICSEARCH_ADMIN_USER})"
fi

# Step 4: Create developer role (check if exists first)
echo "🧑‍💻 Step 4: Creating developer role..."
if role_exists "${ELASTICSEARCH_DEV_USER}_role"; then
  echo "ℹ️  Developer role already exists, skipping creation..."
else
  make_api_call "POST" "/_security/role/${ELASTICSEARCH_DEV_USER}_role" \
    '{
      "cluster": ["monitor"],
      "indices": [
        {
          "names": ["products*", "orders*", "users*", "ecom-*"],
          "privileges": ["read", "write", "create", "index", "delete", "manage"]
        }
      ]
    }' \
    "developer role (${ELASTICSEARCH_DEV_USER}_role)"
fi

# Step 5: Create developer user (check if exists first)
echo "👨‍💻 Step 5: Creating developer user..."
if user_exists "${ELASTICSEARCH_DEV_USER}"; then
  echo "ℹ️  Developer user already exists, updating password..."
  make_api_call "POST" "/_security/user/${ELASTICSEARCH_DEV_USER}/_password" \
    "{\"password\": \"${ELASTICSEARCH_DEV_PASSWORD}\"}" \
    "developer user password update"
else
  make_api_call "POST" "/_security/user/${ELASTICSEARCH_DEV_USER}" \
    "{
      \"password\": \"${ELASTICSEARCH_DEV_PASSWORD}\",
      \"roles\": [\"kibana_user\", \"${ELASTICSEARCH_DEV_USER}_role\"],
      \"full_name\": \"E-commerce Developer\",
      \"email\": \"dev@ecommerce.local\"
    }" \
    "developer user (${ELASTICSEARCH_DEV_USER})"
fi

echo ""
echo "🎉 Elasticsearch users setup completed successfully!"
echo "================================================"
echo "📋 User Summary:"
echo "   🔹 elastic user: ${ELASTICSEARCH_ELASTIC_PASSWORD} (built-in superuser)"
echo "   🔹 kibana_system user: ${ELASTICSEARCH_KIBANA_PASSWORD} (for Kibana service)"
echo "   🔹 ${ELASTICSEARCH_ADMIN_USER} user: ${ELASTICSEARCH_ADMIN_PASSWORD} (custom admin with full access)"
echo "   🔹 ${ELASTICSEARCH_DEV_USER} user: ${ELASTICSEARCH_DEV_PASSWORD} (custom developer with limited access)"
echo "================================================"
echo ""

# Test connections
echo "🧪 Testing user connections..."
test_users=(
  "elastic:${ELASTICSEARCH_ELASTIC_PASSWORD}"
  "${ELASTICSEARCH_ADMIN_USER}:${ELASTICSEARCH_ADMIN_PASSWORD}"
  "${ELASTICSEARCH_DEV_USER}:${ELASTICSEARCH_DEV_PASSWORD}"
)

for user_pass in "${test_users[@]}"; do
  user=$(echo $user_pass | cut -d: -f1)
  echo -n "🔍 Testing user '$user'... "
  
  if curl -s -u "$user_pass" "http://localhost:9200/_cluster/health" >/dev/null 2>&1; then
    echo "✅ SUCCESS"
  else
    echo "❌ FAILED"
  fi
done

echo ""
echo "🏁 Setup complete!"
echo "💡 If any tests failed, try running the script again or check the Elasticsearch logs."