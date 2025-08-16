#!/bin/bash
set -e

# PostgreSQL initialization script for ecommerce backend
# This script has access to all environment variables

# Default passwords (fallback if env vars not set)
ADMIN_PASSWORD="${POSTGRES_ADMIN_PASSWORD:-AdminEcom2025}"
DEV_PASSWORD="${POSTGRES_DEV_PASSWORD:-DevEcom2025}"
DB_NAME="${POSTGRES_DB:-ecommerce_db}"

echo "Initializing PostgreSQL users and database..."
echo "Database: $DB_NAME"

# Connect to postgres database initially
export PGUSER="$POSTGRES_USER"
export PGPASSWORD="$POSTGRES_PASSWORD"
export PGDATABASE="postgres"

# Create database if it doesn't exist
psql -v ON_ERROR_STOP=1 <<-EOSQL
    SELECT 'CREATE DATABASE $DB_NAME'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME');
    \gexec
EOSQL

# Switch to the target database
export PGDATABASE="$DB_NAME"

# Create users with proper passwords
psql -v ON_ERROR_STOP=1 <<-EOSQL
    -- Create admin user with full privileges
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'admin_ecom') THEN
            CREATE USER admin_ecom WITH PASSWORD '$ADMIN_PASSWORD';
        END IF;
    END
    \$\$;

    -- Create developer user with limited privileges  
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'dev_ecom') THEN
            CREATE USER dev_ecom WITH PASSWORD '$DEV_PASSWORD';
        END IF;
    END
    \$\$;

    -- Grant privileges to admin user (full access)
    GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO admin_ecom;

    -- Grant privileges to developer user (read/write access)
    GRANT CONNECT ON DATABASE $DB_NAME TO dev_ecom;
    GRANT USAGE, CREATE ON SCHEMA public TO dev_ecom;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dev_ecom;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dev_ecom;
    GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO dev_ecom;

    -- Set default privileges for future objects
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO dev_ecom;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO dev_ecom;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO dev_ecom;
EOSQL

echo "PostgreSQL users and database initialized successfully!"
echo "Admin user: admin_ecom"
echo "Developer user: dev_ecom"
echo "Database: $DB_NAME"
