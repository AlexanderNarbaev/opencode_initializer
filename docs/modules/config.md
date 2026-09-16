# Configuration Module (00x-config.sh)

> **Version:** v15.1.0  
> **File:** `src/lib/00x-config.sh`  
> **Dependencies:** `helpers.sh`, `00-core.sh`

## Overview

Unified configuration system for OpenCode Initializer. Provides centralized configuration management with validation, migration, and templates.

## Functions

### Initialization

#### `_config_init()`
Initializes configuration directory and creates default configuration if needed.

```bash
_config_init
# Creates: ~/.config/opencode-setup/
# Creates: ~/.config/opencode-setup/backup/
```

### Configuration Operations

#### `_config_load()`
Loads configuration from file.

```bash
_config_load
# Sources: ~/.config/opencode-setup/setup.conf
```

#### `_config_get(key, default)`
Gets configuration value.

```bash
port=$(_config_get "POSTGRES_PORT" "5432")
# Returns: configured value or default
```

#### `_config_set(key, value)`
Sets configuration value.

```bash
_config_set "POSTGRES_PORT" "5432"
# Updates: ~/.config/opencode-setup/setup.conf
```

### Validation

#### `_config_validate()`
Validates configuration against schema.

```bash
_config_validate
# Returns: 0 if valid, 1 if invalid
```

### Management

#### `_config_show()`
Shows current configuration.

```bash
_config_show
# Output: Configuration file contents
```

#### `_config_reset()`
Resets configuration to defaults.

```bash
_config_reset
# Creates backup and generates new default configuration
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `_CONFIG_DIR` | Configuration directory | `~/.config/opencode-setup` |
| `_CONFIG_FILE` | Configuration file | `~/.config/opencode-setup/setup.conf` |
| `_CONFIG_TOML` | TOML configuration | `~/.config/opencode-setup/setup.toml` |
| `_CONFIG_JSON` | JSON configuration | `~/.config/opencode-setup/config.json` |
| `_CONFIG_BACKUP` | Backup directory | `~/.config/opencode-setup/backup` |
| `_CONFIG_VERSION` | Configuration version | `1.0.0` |

## Configuration Schema

### Services
| Key | Description | Default |
|-----|-------------|---------|
| `POSTGRES_PORT` | PostgreSQL port | `5432` |
| `REDIS_PORT` | Redis port | `6379` |
| `QDRANT_PORT` | Qdrant port | `6333` |
| `PROMETHEUS_PORT` | Prometheus port | `9090` |
| `GRAFANA_PORT` | Grafana port | `3001` |

### Features
| Key | Description | Default |
|-----|-------------|---------|
| `PARALLEL_INSTALL` | Enable parallel installation | `true` |
| `DOWNLOAD_CACHE` | Enable download cache | `true` |
| `SECURITY_SCAN` | Enable security scanning | `true` |
| `AUTO_UPDATE` | Enable auto update | `true` |
| `VERBOSE` | Enable verbose output | `false` |
| `DRY_RUN` | Enable dry run mode | `false` |

### Paths
| Key | Description | Default |
|-----|-------------|---------|
| `DL_CACHE` | Download cache directory | `~/.cache/opencode-setup` |
| `SETUP_DIR` | Setup directory | `~/.config/opencode-setup` |
| `DATA_DIR` | Data directory | `~/.local/share/opencode` |

## Usage

```bash
# Source the module
source src/lib/00x-config.sh

# Initialize configuration
_config_init

# Load configuration
_config_load

# Get configuration value
port=$(_config_get "POSTGRES_PORT" "5432")

# Set configuration value
_config_set "POSTGRES_PORT" "5433"

# Validate configuration
_config_validate

# Show configuration
_config_show

# Reset configuration
_config_reset
```

## Configuration File Format

```bash
# OpenCode Initializer Configuration
# Version: 1.0.0
# Generated: 2026-09-16T15:31:55Z

# Services
POSTGRES_PORT=5432
REDIS_PORT=6379
QDRANT_PORT=6333

# Features
PARALLEL_INSTALL=true
DOWNLOAD_CACHE=true
SECURITY_SCAN=true

# Paths
DL_CACHE=~/.cache/opencode-setup
SETUP_DIR=~/.config/opencode-setup
DATA_DIR=~/.local/share/opencode
```

## See Also

- [core.md](core.md) - Core infrastructure
- [logging.md](logging.md) - Logging system
- [cli.md](../cli.md) - CLI interface
