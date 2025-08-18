# Migration from docker.sh to manage.sh

## Changes Made

### 1. File Changes
- **Backup Created**: `docker.sh` → `docker.sh.backup`
- **New Wrapper**: Created new `docker.sh` that redirects to `manage.sh`
- **Primary Script**: `manage.sh` is now the main management script

### 2. Command Mapping
| Old docker.sh Command | New manage.sh Command | Notes |
|------------------------|------------------------|-------|
| `./docker.sh up`       | `./manage.sh start`    | Now includes automatic initialization |
| `./docker.sh down`     | `./manage.sh stop`     | Same functionality |
| `./docker.sh restart`  | `./manage.sh restart`  | Same functionality |
| `./docker.sh logs`     | `./manage.sh logs`     | Same functionality |
| `./docker.sh status`   | `./manage.sh status`   | Enhanced with init container status |
| `./docker.sh clean`    | `./manage.sh clean`    | Enhanced interactive cleanup |
| `./docker.sh test`     | `./scripts/test-connections.sh` | Direct script call |
| `./docker.sh seed`     | `./scripts/seed-data.sh` | Direct script call |
| `./docker.sh setup-es` | *Integrated into start* | Now automatic on startup |

### 3. New Features in manage.sh
- **Init Container Pattern**: Automatic service initialization
- **logs-init**: View init container logs specifically
- **reset-init**: Reset only initialization markers
- **build**: Build init container
- **Enhanced Status**: Shows both services and init container status

### 4. Backward Compatibility
- Old `docker.sh` commands still work through the wrapper
- Users are notified about the migration
- No breaking changes for existing workflows

### 5. Documentation Updated
- README.md updated to prioritize `manage.sh`
- Legacy `docker.sh` marked as backward compatibility
- Examples updated to use new commands

## Usage Recommendations

### For New Users
Use `manage.sh` directly:
```bash
./manage.sh start    # Start everything with auto-init
./manage.sh status   # Check all services
./manage.sh logs     # View all logs
```

### For Existing Users
Gradually migrate to `manage.sh`, but `docker.sh` still works:
```bash
./docker.sh up      # Still works, redirects to manage.sh
./manage.sh start   # Preferred new way
```
