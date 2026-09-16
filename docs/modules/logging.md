# Logging Module (00y-logging.sh)

> **Version:** v15.1.0  
> **File:** `src/lib/00y-logging.sh`  
> **Dependencies:** `helpers.sh`, `00-core.sh`

## Overview

Unified logging system for OpenCode Initializer. Provides centralized logging with levels, rotation, and analysis.

## Functions

### Initialization

#### `_logging_init()`
Initializes logging directory and rotates logs if needed.

```bash
_logging_init
# Creates: ~/.cache/opencode-setup/logs/
```

### Log Functions

#### `log_debug(message)`
Logs debug message.

```bash
log_debug "Debug message"
# Output: [2026-09-16T15:31:55Z] [debug] Debug message
```

#### `log_info(message)`
Logs info message.

```bash
log_info "Info message"
# Output: [2026-09-16T15:31:55Z] [info] Info message
```

#### `log_warn(message)`
Logs warning message.

```bash
log_warn "Warning message"
# Output: [2026-09-16T15:31:55Z] [warn] Warning message
```

#### `log_error(message)`
Logs error message.

```bash
log_error "Error message"
# Output: [2026-09-16T15:31:55Z] [error] Error message
```

#### `log_fatal(message)`
Logs fatal message and exits.

```bash
log_fatal "Fatal message"
# Output: [2026-09-16T15:31:55Z] [fatal] Fatal message
# Exit: 1
```

### Maintenance

#### `_logging_rotate()`
Rotates log files when they exceed maximum size.

```bash
_logging_rotate
# Moves: opencode.log → opencode.log.1
# Creates: new opencode.log
```

#### `_logging_analyze()`
Analyzes log file and shows statistics.

```bash
_logging_analyze
# Output:
# Log Analysis
#   Log file: ~/.cache/opencode-setup/logs/opencode.log
#   Size: 1.2M
#   Lines: 1234
#
# Level distribution:
#   debug        100
#   info         1000
#   warn         100
#   error        30
#   fatal        4
#
# Recent errors:
#   [2026-09-16T15:31:55Z] [error] Error message
```

#### `_logging_clear()`
Clears all log files.

```bash
_logging_clear
# Removes: ~/.cache/opencode-setup/logs/*.log*
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `_LOG_DIR` | Log directory | `~/.cache/opencode-setup/logs` |
| `_LOG_FILE` | Log file | `~/.cache/opencode-setup/logs/opencode.log` |
| `_LOG_LEVEL` | Log level | `info` |
| `_LOG_MAX_SIZE` | Maximum log size | `10485760` (10MB) |
| `_LOG_MAX_FILES` | Maximum log files | `5` |
| `_LOG_FORMAT` | Log format | `text` |

## Log Levels

| Level | Description | Color |
|-------|-------------|-------|
| `debug` | Debug messages | Gray |
| `info` | Information messages | Green |
| `warn` | Warning messages | Yellow |
| `error` | Error messages | Red |
| `fatal` | Fatal messages | Red Bold |

## Usage

```bash
# Source the module
source src/lib/00y-logging.sh

# Initialize logging
_logging_init

# Log messages
log_debug "Debug message"
log_info "Info message"
log_warn "Warning message"
log_error "Error message"
# log_fatal "Fatal message"  # Exits after logging

# Analyze logs
_logging_analyze

# Clear logs
_logging_clear
```

## Log File Format

### Text Format
```
[2026-09-16T15:31:55Z] [info] Info message
[2026-09-16T15:31:55Z] [warn] Warning message
[2026-09-16T15:31:55Z] [error] Error message
```

### JSON Format
```json
{"timestamp":"2026-09-16T15:31:55Z","level":"info","message":"Info message"}
{"timestamp":"2026-09-16T15:31:55Z","level":"warn","message":"Warning message"}
{"timestamp":"2026-09-16T15:31:55Z","level":"error","message":"Error message"}
```

## Configuration

### Environment Variables
```bash
export LOG_LEVEL=debug          # Set log level
export LOG_MAX_SIZE=10485760    # Set max log size (10MB)
export LOG_MAX_FILES=5          # Set max log files
export LOG_FORMAT=json          # Set log format
```

## See Also

- [core.md](core.md) - Core infrastructure
- [config.md](config.md) - Configuration system
- [cli.md](../cli.md) - CLI interface
