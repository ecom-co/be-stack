#!/bin/bash
set -e

# Redis-specific setup

# Service configuration
export SERVICE_NAME="redis"
export SETUP_MARKER_DIR="/data/redis"
export HEALTH_CHECK_CMD="redis-cli -h ecom-redis -p 6379 --user \"$REDIS_ADMIN_USER\" --pass \"$REDIS_ADMIN_PASSWORD\" ping"
export SETUP_TIMEOUT=60

# Source common framework after config
source /scripts/common-setup.sh

# Redis-specific environment variables
REDIS_ADMIN_USER="${REDIS_ADMIN_USER:-admin_ecom}"
REDIS_ADMIN_PASSWORD="${REDIS_ADMIN_PASSWORD:-AdminCache2025}"
REDIS_DEV_USER="${REDIS_DEV_USER:-dev_ecom}"
REDIS_DEV_PASSWORD="${REDIS_DEV_PASSWORD:-DevCache2025}"

# Override health check for Redis (use admin user since default is disabled)
check_service_health() {
    redis-cli -h ecom-redis -p 6379 --user "$REDIS_ADMIN_USER" --pass "$REDIS_ADMIN_PASSWORD" ping >/dev/null 2>&1
}

# Validate Redis setup
validate_setup_complete() {
    # Check if ACL users exist and can login
    if redis-cli -h ecom-redis -p 6379 --user "$REDIS_ADMIN_USER" --pass "$REDIS_ADMIN_PASSWORD" ACL LIST | grep -q "$REDIS_ADMIN_USER"; then
        return 0
    fi
    return 1
}

# Redis-specific setup logic
run_custom_setup() {
    log "INFO" "Setting up Redis ACL users..."
    # Create admin and dev users using ACL
    # Note: avoid shell redirection; pass password token as argument ("<password>" must be prefixed with >)
    redis-cli -h ecom-redis -p 6379 ACL SETUSER "$REDIS_ADMIN_USER" on ">${REDIS_ADMIN_PASSWORD}" "~*" "+@all"
    redis-cli -h ecom-redis -p 6379 ACL SETUSER "$REDIS_DEV_USER" on ">${REDIS_DEV_PASSWORD}" "~*" "+@read" "+@write" "+@list" "+ping"
    redis-cli -h ecom-redis -p 6379 ACL SAVE

    # Now test admin user connection (ACL)
    if redis-cli -h ecom-redis -p 6379 --user "$REDIS_ADMIN_USER" --pass "$REDIS_ADMIN_PASSWORD" ping >/dev/null 2>&1; then
        log "SUCCESS" "Admin user ($REDIS_ADMIN_USER) is working"
    else
        log "ERROR" "Admin user ($REDIS_ADMIN_USER) connection failed"
        return 1
    fi

    # Test dev user connection (ACL)
    if redis-cli -h ecom-redis -p 6379 --user "$REDIS_DEV_USER" --pass "$REDIS_DEV_PASSWORD" ping >/dev/null 2>&1; then
        log "SUCCESS" "Dev user ($REDIS_DEV_USER) is working"
    else
        log "ERROR" "Dev user ($REDIS_DEV_USER) connection failed"
        return 1
    fi

    log "SUCCESS" "Redis ACL users created and verified"
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
