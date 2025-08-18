#!/bin/bash
set -e

# Elasticsearch-specific setup

# Service configuration
export SERVICE_NAME="elasticsearch"
export SETUP_MARKER_DIR="/data/elasticsearch"
export HEALTH_CHECK_URL="http://ecom-elasticsearch:9200/_cluster/health"
export SETUP_TIMEOUT=180

# Source common framework after config
source /scripts/common-setup.sh

# Elasticsearch-specific environment variables
ELASTICSEARCH_ELASTIC_PASSWORD="${ELASTICSEARCH_ELASTIC_PASSWORD:-ElasticSuper2025}"
ELASTICSEARCH_ADMIN_USER="${ELASTICSEARCH_ADMIN_USER:-admin_ecom}"
ELASTICSEARCH_ADMIN_PASSWORD="${ELASTICSEARCH_ADMIN_PASSWORD:-AdminSearch2025}"
ELASTICSEARCH_KIBANA_PASSWORD="${ELASTICSEARCH_KIBANA_PASSWORD:-KibanaService2025}"
ELASTICSEARCH_DEV_USER="${ELASTICSEARCH_DEV_USER:-dev_ecom}"
ELASTICSEARCH_DEV_PASSWORD="${ELASTICSEARCH_DEV_PASSWORD:-DevSearch2025}"

# Override health check for Elasticsearch
check_service_health() {
    # Try different methods to check if ES is ready
    if curl -s -f "http://ecom-elasticsearch:9200" >/dev/null 2>&1; then
        return 0
    elif curl -s -u "elastic:${ELASTICSEARCH_ELASTIC_PASSWORD}" "http://ecom-elasticsearch:9200/_cluster/health" >/dev/null 2>&1; then
        return 0
    elif [[ "$(curl -s -o /dev/null -w "%{http_code}" "http://ecom-elasticsearch:9200" 2>/dev/null || echo "000")" = "401" ]]; then
        return 0  # 401 means ES is up but needs auth
    fi
    return 1
}

# Validate that users were created successfully
validate_setup_complete() {
    # Check if admin user exists and can authenticate
    curl -s -u "${ELASTICSEARCH_ADMIN_USER}:${ELASTICSEARCH_ADMIN_PASSWORD}" \
         "http://ecom-elasticsearch:9200/_security/user/${ELASTICSEARCH_ADMIN_USER}" >/dev/null 2>&1
}

# Elasticsearch-specific setup logic
run_custom_setup() {
    log "INFO" "Setting up Elasticsearch users and roles..."
    
    # Function to make API calls with retry
    make_api_call() {
        local method="$1"
        local endpoint="$2" 
        local data="$3"
        local description="$4"
        local auth_user="${5:-elastic}"
        local auth_pass="${6:-${ELASTICSEARCH_ELASTIC_PASSWORD}}"
        local max_attempts=3
        
        log "INFO" "Setting up $description..."
        
        for attempt in $(seq 1 $max_attempts); do
            local temp_file
            temp_file=$(mktemp)
            
            local http_code
            http_code=$(curl -s -w "%{http_code}" \
              -u "$auth_user:$auth_pass" \
              -X "$method" "http://ecom-elasticsearch:9200$endpoint" \
              -H "Content-Type: application/json" \
              -d "$data" \
              -o "$temp_file" 2>/dev/null || echo "000")
            
            local response_body
            response_body=$(cat "$temp_file" 2>/dev/null || echo "")
            rm -f "$temp_file"
            
            if [[ "$http_code" = "200" ]] || [[ "$http_code" = "201" ]]; then
                log "SUCCESS" "Successfully set up $description"
                return 0
            elif [[ "$http_code" = "400" ]] && echo "$response_body" | grep -q "already exists"; then
                log "INFO" "$description already exists, skipping..."
                return 0
            else
                log "WARN" "Attempt $attempt/$max_attempts - Issue with $description (HTTP $http_code): $response_body"
                if [[ $attempt -lt $max_attempts ]]; then
                    sleep 2
                fi
            fi
        done
        
        log "ERROR" "Failed to set up $description after $max_attempts attempts"
        return 1
    }

    # Set kibana_system password
    make_api_call "POST" "/_security/user/kibana_system/_password" \
      "{\"password\": \"${ELASTICSEARCH_KIBANA_PASSWORD}\"}" \
      "kibana_system user password"

    # Create admin role
    make_api_call "POST" "/_security/role/${ELASTICSEARCH_ADMIN_USER}_role" \
      '{
        "cluster": ["all"],
        "indices": [{"names": ["*"], "privileges": ["all"]}]
      }' \
      "admin role (${ELASTICSEARCH_ADMIN_USER}_role)"

    # Create admin user
    make_api_call "POST" "/_security/user/${ELASTICSEARCH_ADMIN_USER}" \
      "{
        \"password\": \"${ELASTICSEARCH_ADMIN_PASSWORD}\",
        \"roles\": [\"superuser\", \"${ELASTICSEARCH_ADMIN_USER}_role\"],
        \"full_name\": \"E-commerce Admin\",
        \"email\": \"admin@ecommerce.local\"
      }" \
      "admin user (${ELASTICSEARCH_ADMIN_USER})"

    # Create developer role
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

    # Create developer user
    make_api_call "POST" "/_security/user/${ELASTICSEARCH_DEV_USER}" \
      "{
        \"password\": \"${ELASTICSEARCH_DEV_PASSWORD}\",
        \"roles\": [\"kibana_user\", \"${ELASTICSEARCH_DEV_USER}_role\"],
        \"full_name\": \"E-commerce Developer\",
        \"email\": \"dev@ecommerce.local\"
      }" \
      "developer user (${ELASTICSEARCH_DEV_USER})"

    log "SUCCESS" "All Elasticsearch users and roles created successfully"
    return 0
}

# Run the setup
main() {
    case "${1:-setup}" in
        "setup")
            run_service_setup
            ;;
        "reset")
            reset_setup
            ;;
        "help")
            show_help
            ;;
        *)
            echo "Usage: $0 [setup|reset|help]"
            exit 1
            ;;
    esac
}

main "$@"
