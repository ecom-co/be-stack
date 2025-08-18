#!/bin/bash
set -e

# Generic Service Initialization Framework
# Can be used for any service: Elasticsearch, PostgreSQL, Redis, RabbitMQ, etc.

# Configuration (override via environment variables)
SERVICE_NAME="${SERVICE_NAME:-unknown}"
SETUP_MARKER_DIR="${SETUP_MARKER_DIR:-/data}"
SETUP_MARKER="${SETUP_MARKER_DIR}/.${SERVICE_NAME}_initialized"
SETUP_TIMEOUT="${SETUP_TIMEOUT:-300}"
VALIDATION_RETRIES="${VALIDATION_RETRIES:-3}"
HEALTH_CHECK_URL="${HEALTH_CHECK_URL:-}"
HEALTH_CHECK_CMD="${HEALTH_CHECK_CMD:-}"

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "[${timestamp}] ${BLUE}ℹ️  ${SERVICE_NAME}${NC}: $*" ;;
        "SUCCESS") echo -e "[${timestamp}] ${GREEN}✅ ${SERVICE_NAME}${NC}: $*" ;;
        "WARN")  echo -e "[${timestamp}] ${YELLOW}⚠️  ${SERVICE_NAME}${NC}: $*" ;;
        "ERROR") echo -e "[${timestamp}] ${RED}❌ ${SERVICE_NAME}${NC}: $*" ;;
        *) echo -e "[${timestamp}] ${SERVICE_NAME}: $*" ;;
    esac
}

# Check if service is ready
wait_for_service() {
    local wait_count=0
    local max_wait=$((SETUP_TIMEOUT / 5))
    
    log "INFO" "Waiting for $SERVICE_NAME to be ready..."
    
    while [[ $wait_count -lt $max_wait ]]; do
        if check_service_health; then
            log "SUCCESS" "$SERVICE_NAME is ready"
            return 0
        fi
        
        ((wait_count++))
        sleep 5
        
        if [[ $wait_count -eq $max_wait ]]; then
            log "ERROR" "Timeout waiting for $SERVICE_NAME"
            return 1
        fi
    done
}

# Generic health check (override this function in specific service scripts)
check_service_health() {
    if [[ -n "$HEALTH_CHECK_URL" ]]; then
        curl -s -f "$HEALTH_CHECK_URL" >/dev/null 2>&1
    elif [[ -n "$HEALTH_CHECK_CMD" ]]; then
        eval "$HEALTH_CHECK_CMD" >/dev/null 2>&1
    else
        log "WARN" "No health check defined for $SERVICE_NAME"
        return 0
    fi
}

# Check if setup is already completed
is_setup_complete() {
    # Level 1: Check marker file (fast)
    if [[ ! -f "$SETUP_MARKER" ]]; then
        log "INFO" "No setup marker found, will run initialization"
        return 1
    fi
    
    local marker_date
    marker_date=$(cat "$SETUP_MARKER" 2>/dev/null || echo "unknown")
    log "INFO" "Found setup marker from: $marker_date"
    
    # Level 2: Validate service is working (if validation function exists)
    if declare -f validate_setup_complete >/dev/null; then
        if validate_setup_complete; then
            log "SUCCESS" "Setup validation passed (marker + service check)"
            return 0
        else
            log "WARN" "Marker exists but validation failed - forcing re-setup"
            rm -f "$SETUP_MARKER"
            return 1
        fi
    else
        log "SUCCESS" "Setup marker found (no validation function defined)"
        return 0
    fi
}

# Create setup marker
create_setup_marker() {
    mkdir -p "$(dirname "$SETUP_MARKER")"
    echo "$(date -Iseconds)" > "$SETUP_MARKER"
    log "SUCCESS" "Created setup marker: $SETUP_MARKER"
}

# Main setup orchestration
run_service_setup() {
    log "INFO" "🚀 Starting $SERVICE_NAME initialization"
    
    # Quick check for completed setup
    if is_setup_complete; then
        log "SUCCESS" "$SERVICE_NAME already configured"
        return 0
    fi
    
    # Wait for service to be ready
    if ! wait_for_service; then
        log "ERROR" "Service $SERVICE_NAME not ready, cannot proceed"
        return 1
    fi
    
    # Run service-specific setup
    log "INFO" "🔧 Running $SERVICE_NAME setup..."
    if declare -f run_custom_setup >/dev/null; then
        if run_custom_setup; then
            log "SUCCESS" "Custom setup completed successfully"
        else
            log "ERROR" "Custom setup failed"
            return 1
        fi
    else
        log "WARN" "No custom setup function defined"
    fi
    
    # Validate setup was successful
    log "INFO" "🧪 Validating setup..."
    local retry_count=0
    
    while [[ $retry_count -lt $VALIDATION_RETRIES ]]; do
        if declare -f validate_setup_complete >/dev/null; then
            if validate_setup_complete; then
                create_setup_marker
                log "SUCCESS" "Setup completed and validated successfully"
                return 0
            fi
        else
            # No validation function, assume success
            create_setup_marker
            log "SUCCESS" "Setup completed (no validation function defined)"
            return 0
        fi
        
        ((retry_count++))
        log "WARN" "Validation attempt $retry_count/$VALIDATION_RETRIES failed, retrying..."
        sleep 3
    done
    
    log "ERROR" "Setup validation failed after $VALIDATION_RETRIES attempts"
    return 1
}

# Force reset setup (utility function)
reset_setup() {
    if [[ -f "$SETUP_MARKER" ]]; then
        rm -f "$SETUP_MARKER"
        log "SUCCESS" "Setup marker removed - next restart will re-run setup"
    else
        log "INFO" "No setup marker found to remove"
    fi
}

# Help function
show_help() {
    echo "Generic Service Setup Framework"
    echo ""
    echo "Environment Variables:"
    echo "  SERVICE_NAME        - Name of the service (required)"
    echo "  SETUP_MARKER_DIR    - Directory for marker file (default: /data)"
    echo "  SETUP_TIMEOUT       - Timeout in seconds (default: 300)"
    echo "  VALIDATION_RETRIES  - Number of validation retries (default: 3)"
    echo "  HEALTH_CHECK_URL    - URL to check service health"
    echo "  HEALTH_CHECK_CMD    - Command to check service health"
    echo ""
    echo "Functions to implement in your service script:"
    echo "  run_custom_setup()     - Your service-specific setup logic"
    echo "  validate_setup_complete() - Validate setup was successful"
    echo "  check_service_health() - Override default health check"
    echo ""
    echo "Usage:"
    echo "  source this file, then call: run_service_setup"
    echo "  To reset: reset_setup"
}

# Export functions for use in other scripts
export -f log wait_for_service check_service_health is_setup_complete
export -f create_setup_marker run_service_setup reset_setup show_help
