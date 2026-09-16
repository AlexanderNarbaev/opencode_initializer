# Parallel Execution Module (00d-parallel.sh)

> **Version:** v3.5.0  
> **File:** `src/lib/00d-parallel.sh`  
> **Dependencies:** `helpers.sh`, `00-core.sh`

## Overview

Parallel installation engine with dependency-aware execution. Provides layer-based parallel module execution with flock-based WAL (Write-Ahead Log).

## Functions

### Layer-Based Execution

#### `_parallel_run_layer(layer_name, modules...)`
Runs modules in parallel layers. All modules in a layer run concurrently; layer completes before next starts.

```bash
_parallel_run_layer "layer1" \
  "step1:module1.sh:Module 1" \
  "step2:module2.sh:Module 2" \
  "step3:module3.sh:Module 3"
```

**Parameters:**
- `layer_name`: Name of the execution layer
- `modules...`: Array of "step_key:module_path:display_name"

### Job Management

#### `_parallel_wait_all()`
Waits for all parallel jobs to complete and reports results.

```bash
_parallel_wait_all
# Output: Success/failure for each module
```

### Installation

#### `_parallel_install(modules...)`
Installs modules in parallel with dependency tracking.

```bash
_parallel_install "module1.sh" "module2.sh" "module3.sh"
```

### Skip Flags

#### `_process_skip_flags()`
Processes skip flags from environment variables.

```bash
_process_skip_flags
# Reads: SKIP_MODULES, SKIP_FLAGS
```

#### `_should_install(module_name)`
Checks if module should be installed.

```bash
if _should_install "postgres"; then
  # Install postgres
fi
```

#### `_mark_installed(module_name)`
Marks module as installed with timestamp.

```bash
_mark_installed "postgres"
# Creates: ~/.cache/opencode-setup/installed/postgres
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PARALLEL_MAX_JOBS` | Maximum parallel jobs | `nproc` or `4` |
| `_PARALLEL_PIDS` | Array of background PIDs | `()` |
| `_PARALLEL_NAMES` | Corresponding module names | `()` |
| `_PARALLEL_RESULTS` | Exit codes | `()` |

## Usage

```bash
# Source the module
source src/lib/helpers.sh
source src/lib/00-core.sh
source src/lib/00d-parallel.sh

# Show help
_parallel_help

# Run modules in parallel
_parallel_run_layer "infrastructure" \
  "postgres:install-postgres.sh:PostgreSQL" \
  "redis:install-redis.sh:Redis" \
  "qdrant:install-qdrant.sh:Qdrant"

# Wait for completion
_parallel_wait_all
```

## Dependency Layers

Modules are grouped by dependency layers:
1. **Layer 1:** Independent modules (run concurrently)
2. **Layer 2:** Depends on Layer 1 (runs after Layer 1)
3. **Layer 3:** Depends on Layer 2 (runs after Layer 2)

## Error Handling

- Each module runs in isolated subshell
- Exit codes collected via `_PARALLEL_RESULTS`
- Failed modules reported with error details
- WAL ensures atomicity

## Performance

- **Default concurrency:** CPU cores (`nproc`)
- **Configurable:** Set `PARALLEL_MAX_JOBS` environment variable
- **Flock-based WAL:** Prevents race conditions

## See Also

- [core.md](core.md) - Core infrastructure
- [cache.md](cache.md) - Cache management
- [helpers.sh](helpers.md) - Helper functions
