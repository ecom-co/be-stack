#!/bin/bash
set -e

# Master setup script for all services
# This orchestrates the setup of multiple services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-setup.sh"

# Service definitions
declare -A SERVICES=(
    ["elasticsearch"]="/services/elasticsearch/init/setup-elasticsearch.sh"
    ["postgres"]="/services/postgres/init/setup-postgres.sh"
    ["redis"]="/services/redis/init/setup-redis.sh"
    ["rabbitmq"]="/services/rabbitmq/init/setup-rabbitmq.sh"
)

# Setup order (dependencies)
SETUP_ORDER=("postgres" "redis" "rabbitmq" "elasticsearch")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_master() {
    local level="$1"
    shift
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "[${timestamp}] ${BLUE}🎯 MASTER${NC}: $*" ;;
        "SUCCESS") echo -e "[${timestamp}] ${GREEN}✅ MASTER${NC}: $*" ;;
        "WARN")  echo -e "[${timestamp}] ${YELLOW}⚠️  MASTER${NC}: $*" ;;
        "ERROR") echo -e "[${timestamp}] ${RED}❌ MASTER${NC}: $*" ;;
    esac
}

# Setup all services
setup_all_services() {
    log_master "INFO" "🚀 Starting setup for all services..."
    local failed_services=()
    
    for service in "${SETUP_ORDER[@]}"; do
        if [[ -n "${SERVICES[$service]}" ]]; then
            local setup_script="${SERVICES[$service]}"
            
            if [[ -f "$setup_script" ]]; then
                log_master "INFO" "Setting up $service..."
                if bash "$setup_script" setup; then
                    log_master "SUCCESS" "$service setup completed"
                else
                    log_master "ERROR" "$service setup failed"
                    failed_services+=("$service")
                fi
            else
                log_master "WARN" "Setup script not found: $setup_script"
                failed_services+=("$service")
            fi
        fi
    done
    
    if [[ ${#failed_services[@]} -eq 0 ]]; then
        log_master "SUCCESS" "🎉 All services setup completed successfully!"
        return 0
    else
        log_master "ERROR" "Failed services: ${failed_services[*]}"
        return 1
    fi
}

# Reset all services
reset_all_services() {
    log_master "INFO" "🔄 Resetting all services..."
    
    for service in "${SETUP_ORDER[@]}"; do
        if [[ -n "${SERVICES[$service]}" ]]; then
            local setup_script="${SERVICES[$service]}"
            
            if [[ -f "$setup_script" ]]; then
                log_master "INFO" "Resetting $service..."
                bash "$setup_script" reset
            fi
        fi
    done
    
    log_master "SUCCESS" "All services reset completed"
}

# Setup specific service
setup_service() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        log_master "ERROR" "Service name required"
        return 1
    fi
    
    if [[ -z "${SERVICES[$service]}" ]]; then
        log_master "ERROR" "Unknown service: $service"
        log_master "INFO" "Available services: ${!SERVICES[*]}"
        return 1
    fi
    
    local setup_script="${SERVICES[$service]}"
    
    if [[ -f "$setup_script" ]]; then
        log_master "INFO" "Setting up $service..."
        if bash "$setup_script" setup; then
            log_master "SUCCESS" "$service setup completed"
        else
            log_master "ERROR" "$service setup failed"
            return 1
        fi
    else
        log_master "ERROR" "Setup script not found: $setup_script"
        return 1
    fi
}

# Show status of all services
show_status() {
    log_master "INFO" "📊 Checking setup status for all services..."
    
    for service in "${SETUP_ORDER[@]}"; do
        if [[ -n "${SERVICES[$service]}" ]]; then
            local setup_script="${SERVICES[$service]}"
            
            if [[ -f "$setup_script" ]]; then
                # Check if marker file exists
                local marker_dir=""
                case "$service" in
                    "elasticsearch") marker_dir="/data/elasticsearch" ;;
                    "postgres") marker_dir="/data/postgres" ;;
                    "redis") marker_dir="/data/redis" ;;
                    "rabbitmq") marker_dir="/data/rabbitmq" ;;
                esac
                
                if [[ -f "$marker_dir/.${service}_initialized" ]]; then
                    local init_date
                    init_date=$(cat "$marker_dir/.${service}_initialized" 2>/dev/null || echo "unknown")
                    log_master "SUCCESS" "$service: ✅ Initialized ($init_date)"
                else
                    log_master "INFO" "$service: ⏳ Not initialized"
                fi
            else
                log_master "WARN" "$service: ❓ No setup script"
            fi
        fi
    done
}

# Help function
show_help() {
    echo "🎯 Master Service Setup Script"
    echo ""
    echo "Usage: $0 [command] [service]"
    echo ""
    echo "Commands:"
    echo "  setup-all          Setup all services in order"
    echo "  setup <service>    Setup specific service"
    echo "  reset-all          Reset all service markers"
    echo "  reset <service>    Reset specific service marker"
    echo "  status             Show setup status of all services"
    echo "  list               List available services"
    echo "  help               Show this help"
    echo ""
    echo "Available services: ${!SERVICES[*]}"
    echo ""
    echo "Setup order: ${SETUP_ORDER[*]}"
}

# Main function
main() {
    local command="${1:-help}"
    local service="$2"
    
    case "$command" in
        "setup-all")
            setup_all_services
            ;;
        "setup")
            setup_service "$service"
            ;;
        "reset-all")
            reset_all_services
            ;;
        "reset")
            if [[ -n "$service" && -n "${SERVICES[$service]}" ]]; then
                bash "${SERVICES[$service]}" reset
            else
                log_master "ERROR" "Service name required or unknown service: $service"
                return 1
            fi
            ;;
        "status")
            show_status
            ;;
        "list")
            echo "Available services:"
            for service in "${!SERVICES[@]}"; do
                echo "  - $service"
            done
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

main "$@"
