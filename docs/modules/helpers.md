# Helpers Module (helpers.sh)

> **File:** `src/lib/helpers.sh`  
> **Dependencies:** None

## Overview

Core helper functions used across all modules. Provides logging, error handling, and utility functions.

## Functions

### Logging

#### `log(message)`
Logs informational message.

```bash
log "Installation complete"
```

#### `warn(message)`
Logs warning message.

```bash
warn "Deprecated feature used"
```

#### `err(message)`
Logs error message.

```bash
err "File not found"
```

#### `info(message)`
Logs informational message (alias for log).

```bash
info "Processing..."
```

#### `section(title)`
Logs section header.

```bash
section "Installation"
```

### Utility

#### `command_exists(command)`
Checks if command exists.

```bash
if command_exists "git"; then
  echo "Git is installed"
fi
```

#### `confirm(prompt)`
Asks for user confirmation.

```bash
if confirm "Continue?"; then
  # User confirmed
fi
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GREEN` | Green color code | `\033[0;32m` |
| `RED` | Red color code | `\033[0;31m` |
| `YELLOW` | Yellow color code | `\033[0;33m` |
| `NC` | No color code | `\033[0m` |

## Usage

```bash
# Source the module
source src/lib/helpers.sh

# Use functions
log "Hello"
warn "Warning"
err "Error"
section "Section Title"
```

## See Also

- [core.md](core.md) - Core infrastructure
- [config.md](config.md) - Configuration system
- [logging.md](logging.md) - Logging system
