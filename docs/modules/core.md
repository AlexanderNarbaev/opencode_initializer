# Core Module (00-core.sh)

> **Version:** v14.0.0  
> **File:** `src/lib/00-core.sh`  
> **Dependencies:** `helpers.sh`

## Overview

Core infrastructure module shared across all lib modules. Provides fundamental utilities for system detection, configuration management, and service port resolution.

## Functions

### System Detection

#### `_check_bash_version()`
Checks bash version compatibility and warns if using older versions.

```bash
_check_bash_version
# Output: Warning if bash < 4.0
```

### Service Management

#### `_service_mode(service_name)`
Gets service mode (local/external/disabled) from configuration.

```bash
mode=$(_service_mode "postgres")
# Returns: "local", "external", or "disabled"
```

#### `_resolve_service_port(service_name, default_port)`
Resolves service port with fallback to default.

```bash
port=$(_resolve_service_port "postgres" 5432)
# Returns: configured port or default
```

#### `_find_free_port(start_port)`
Finds available port starting from given port.

```bash
port=$(_find_free_port 8080)
# Returns: first available port >= 8080
```

#### `_port_is_free(port)`
Checks if port is available.

```bash
if _port_is_free 8080; then
  echo "Port 8080 is available"
fi
```

#### `_port_listening_owner(port)`
Gets process listening on port.

```bash
owner=$(_port_listening_owner 8080)
# Returns: process name or empty string
```

### Configuration Management

#### `_set_config(key, value)`
Sets configuration value in setup.conf.

```bash
_set_config "POSTGRES_PORT" "5432"
```

#### `_get_config(key)`
Gets configuration value from setup.conf.

```bash
port=$(_get_config "POSTGRES_PORT")
# Returns: configured value or empty string
```

### Service Port Lookup

#### `_get_service_port(service_name)`
Gets default port for service.

```bash
port=$(_get_service_port "postgres")
# Returns: "5432"
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SCRIPT_VERSION` | Script version | `v14.0.0` |
| `ARCH` | System architecture | Auto-detected |
| `PKG_MANAGER` | Package manager | Auto-detected |
| `SETUP_CONF` | Setup configuration file | `~/.config/opencode-setup/setup.conf` |
| `DL_CACHE` | Download cache directory | `~/.cache/opencode-setup` |

## Usage

```bash
# Source the module
source src/lib/helpers.sh
source src/lib/00-core.sh

# Use functions
_core_help                    # Show help
port=$(_get_service_port "postgres")
_set_config "MY_VAR" "value"
```

## Architecture Detection

The module automatically detects:
- **Architecture:** amd64, arm64
- **Package Manager:** apt, dnf, pacman, apk, zypper, brew
- **OS:** Ubuntu, Debian, and derivatives

## Error Handling

All functions use `set -euo pipefail` for strict error handling. Errors are logged via `err()` and `warn()` functions from `helpers.sh`.

## See Also

- [helpers.sh](helpers.md) - Helper functions
- [00d-parallel.sh](parallel.md) - Parallel execution
- [00e-cache-mgr.sh](cache.md) - Cache management
