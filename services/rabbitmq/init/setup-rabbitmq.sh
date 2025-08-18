#!/bin/bash
set -e

# RabbitMQ-specific setup

# Service configuration
export SERVICE_NAME="rabbitmq"
export SETUP_MARKER_DIR="/data/rabbitmq"
export HEALTH_CHECK_CMD="rabbitmqctl -n rabbit@ecom-rabbitmq node_health_check"
export SETUP_TIMEOUT=120

# Source common framework after config
source /scripts/common-setup.sh

# RabbitMQ-specific environment variables
RABBITMQ_DEFAULT_USER="${RABBITMQ_DEFAULT_USER:-admin}"
RABBITMQ_DEFAULT_PASS="${RABBITMQ_DEFAULT_PASS:-AdminRabbit2025}"
RABBITMQ_APP_USER="${RABBITMQ_APP_USER:-app_user}"
RABBITMQ_APP_PASSWORD="${RABBITMQ_APP_PASSWORD:-AppRabbit2025}"
RABBITMQ_VHOST="${RABBITMQ_VHOST:-ecommerce}"

# Override health check for RabbitMQ
check_service_health() {
    # Try to connect to RabbitMQ management API
    curl -s -u "${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}" \
         "http://ecom-rabbitmq:15672/api/overview" >/dev/null 2>&1
}

# Validate RabbitMQ setup
validate_setup_complete() {
    # Check if vhost and users exist via management API
    curl -s -u "${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}" \
         "http://ecom-rabbitmq:15672/api/vhosts/${RABBITMQ_VHOST}" >/dev/null 2>&1 && \
    curl -s -u "${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}" \
         "http://ecom-rabbitmq:15672/api/users/${RABBITMQ_APP_USER}" >/dev/null 2>&1
}

# RabbitMQ-specific setup logic
run_custom_setup() {
    log "INFO" "Setting up RabbitMQ vhosts and users via Management API..."
    
    # Create virtual host via API
    curl -s -u "${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}" \
         -X PUT "http://ecom-rabbitmq:15672/api/vhosts/${RABBITMQ_VHOST}" \
         -H "Content-Type: application/json" || {
        log "INFO" "Virtual host $RABBITMQ_VHOST might already exist"
    }
    
    # Create application user via API
    curl -s -u "${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}" \
         -X PUT "http://ecom-rabbitmq:15672/api/users/${RABBITMQ_APP_USER}" \
         -H "Content-Type: application/json" \
         -d "{\"password\":\"${RABBITMQ_APP_PASSWORD}\",\"tags\":\"management\"}" || {
        log "INFO" "User $RABBITMQ_APP_USER might already exist"
    }
    
    # Set permissions via API
    curl -s -u "${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}" \
         -X PUT "http://ecom-rabbitmq:15672/api/permissions/${RABBITMQ_VHOST}/${RABBITMQ_APP_USER}" \
         -H "Content-Type: application/json" \
         -d "{\"configure\":\".*\",\"write\":\".*\",\"read\":\".*\"}"
    
    curl -s -u "${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}" \
         -X PUT "http://ecom-rabbitmq:15672/api/permissions/${RABBITMQ_VHOST}/${RABBITMQ_DEFAULT_USER}" \
         -H "Content-Type: application/json" \
         -d "{\"configure\":\".*\",\"write\":\".*\",\"read\":\".*\"}"
    
    log "SUCCESS" "RabbitMQ setup completed"
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
