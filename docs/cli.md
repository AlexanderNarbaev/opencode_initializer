# CLI Interface (src/cli.sh)

> **Version:** v15.1.0  
> **File:** `src/cli.sh`  
> **Dependencies:** `helpers.sh`, `00-core.sh`

## Overview

Unified command-line interface for OpenCode Initializer. Provides a single entry point for all modules and commands.

## Usage

```bash
# Show help
./src/cli.sh help

# Show version
./src/cli.sh version

# Initialize environment
./src/cli.sh init

# Show system status
./src/cli.sh status

# Manage configuration
./src/cli.sh config show
./src/cli.sh config edit
./src/cli.sh config reset

# Security scanning
./src/cli.sh security scan
./src/cli.sh security audit

# Cache management
./src/cli.sh cache status
./src/cli.sh cache clear

# Template management
./src/cli.sh template list

# Skill management
./src/cli.sh skill list

# Agent orchestration
./src/cli.sh agent status
```

## Commands

### `init`
Initializes OpenCode environment with default configuration.

```bash
./src/cli.sh init
# Creates:
#   ~/.config/opencode-setup/setup.conf
#   ~/.cache/opencode-setup/
#   ~/.local/share/opencode/
```

### `install [target]`
Installs modules and dependencies.

```bash
./src/cli.sh install all      # Install all modules
./src/cli.sh install core     # Install core modules
./src/cli.sh install services # Install services
./src/cli.sh install tools    # Install tools
```

### `status`
Shows system status including modules, services, and configuration.

```bash
./src/cli.sh status
# Output:
# System Status
#   Version: 15.1.0
#   Modules: 143
#   Tests: 132
#   Documentation: 137
#
# Configuration
#   Config: ~/.config/opencode-setup/setup.conf
#   TOML: ~/.config/opencode-setup/setup.toml
#
# Services
#   postgres: running (port 5432)
#   redis: running (port 6379)
#   qdrant: stopped (port 6333)
```

### `config [action]`
Manages configuration.

```bash
./src/cli.sh config show   # Show configuration
./src/cli.sh config edit   # Edit configuration
./src/cli.sh config reset  # Reset to defaults
```

### `security [action]`
Security scanning and audit.

```bash
./src/cli.sh security scan  # Scan for secrets
./src/cli.sh security audit # Audit permissions
```

### `cache [action]`
Cache management.

```bash
./src/cli.sh cache status  # Show cache status
./src/cli.sh cache clear   # Clear cache
```

### `template [action]`
Template management.

```bash
./src/cli.sh template list  # List templates
```

### `skill [action]`
Skill management.

```bash
./src/cli.sh skill list  # List skills
```

### `agent [action]`
Agent orchestration.

```bash
./src/cli.sh agent status  # Show agent status
```

## Options

| Option | Description |
|--------|-------------|
| `--help`, `-h` | Show help |
| `--version`, `-v` | Show version |
| `--verbose` | Enable verbose output |
| `--dry-run` | Dry run mode |
| `--force` | Force operation |

## Examples

```bash
# Initialize and check status
./src/cli.sh init
./src/cli.sh status

# Run security scan
./src/cli.sh security scan

# Clear cache
./src/cli.sh cache clear

# List available templates
./src/cli.sh template list
```

## Integration

The CLI integrates with all modules:
- **Core:** System detection, configuration
- **Parallel:** Installation engine
- **Cache:** Download caching
- **Security:** Secret scanning, permission audit
- **Templates:** Project templates
- **Skills:** Skill management
- **Agents:** Agent orchestration

## See Also

- [core.md](modules/core.md) - Core infrastructure
- [config.md](modules/config.md) - Configuration system
- [logging.md](modules/logging.md) - Logging system
