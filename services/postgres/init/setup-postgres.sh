#!/bin/bash
set -e

# PostgreSQL-specific setup using common framework

# Service configuration
export SERVICE_NAME="postgresql"
export SETUP_MARKER_DIR="/data/postgres"
export HEALTH_CHECK_CMD="pg_isready -h ecom-postgres -p 5432"
export SETUP_TIMEOUT=120

# Source common framework after config
source /scripts/common-setup.sh

# PostgreSQL-specific environment variables
POSTGRES_DB="${POSTGRES_DB:-ecommerce}"
POSTGRES_USER="${POSTGRES_USER:-ecom_user}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-EcomPass2025}"
POSTGRES_ADMIN_USER="${POSTGRES_ADMIN_USER:-admin}"
POSTGRES_ADMIN_PASSWORD="${POSTGRES_ADMIN_PASSWORD:-AdminPass2025}"
POSTGRES_DEV_USER="${POSTGRES_DEV_USER:-dev_ecom}"
POSTGRES_DEV_PASSWORD="${POSTGRES_DEV_PASSWORD:-DevEcom2025}"

# Override health check for PostgreSQL
check_service_health() {
    pg_isready -h ecom-postgres -p 5432 >/dev/null 2>&1
}

# Validate PostgreSQL setup
validate_setup_complete() {
    # Check if database and users exist
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h ecom-postgres -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
        -c "SELECT 1;" >/dev/null 2>&1
}

# PostgreSQL-specific setup logic
run_custom_setup() {
    log "INFO" "Setting up PostgreSQL databases and users..."
    
    # Create database on the Postgres service using the configured bootstrap user
    PGPASSWORD="$POSTGRES_PASSWORD" createdb -h ecom-postgres -p 5432 -U "$POSTGRES_USER" "$POSTGRES_DB" 2>/dev/null || {
        log "INFO" "Database $POSTGRES_DB already exists or creation failed"
    }
    
    # Create users and grant permissions
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h ecom-postgres -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<EOF
-- Create application user
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$POSTGRES_USER') THEN
        CREATE ROLE $POSTGRES_USER LOGIN PASSWORD '$POSTGRES_PASSWORD';
    END IF;
END
\$\$;

-- Create admin user
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$POSTGRES_ADMIN_USER') THEN
        CREATE ROLE $POSTGRES_ADMIN_USER LOGIN PASSWORD '$POSTGRES_ADMIN_PASSWORD' SUPERUSER;
    END IF;
END
\$\$;

-- Create developer user
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$POSTGRES_DEV_USER') THEN
        CREATE ROLE $POSTGRES_DEV_USER LOGIN PASSWORD '$POSTGRES_DEV_PASSWORD';
    END IF;
END
\$\$;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;
GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_ADMIN_USER;
-- Grant appropriate privileges to developer user (limited but able to develop)
GRANT CONNECT ON DATABASE $POSTGRES_DB TO $POSTGRES_DEV_USER;
GRANT USAGE, CREATE ON SCHEMA public TO $POSTGRES_DEV_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $POSTGRES_DEV_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $POSTGRES_DEV_USER;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $POSTGRES_DEV_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $POSTGRES_DEV_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $POSTGRES_DEV_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $POSTGRES_DEV_USER;
EOF

    log "SUCCESS" "PostgreSQL setup completed"
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
