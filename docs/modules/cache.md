# Cache Manager Module (00e-cache-mgr.sh)

> **Version:** v3.5.0  
> **File:** `src/lib/00e-cache-mgr.sh`  
> **Dependencies:** `helpers.sh`

## Overview

Centralized download caching with deduplication, integrity checks, and cleanup. Prevents re-downloading of already-fetched packages across runs.

## Functions

### Cache Initialization

#### `_cache_init()`
Initializes cache directory and index file.

```bash
_cache_init
# Creates: ~/.cache/opencode-setup/packages/.cache-index.json
```

### Cache Key Generation

#### `_cache_key(url)`
Generates cache key from URL using SHA256.

```bash
key=$(_cache_key "https://example.com/file.tar.gz")
# Returns: 16-character hash
```

### Cache Operations

#### `_cache_hit(url)`
Checks if URL is cached.

```bash
if _cache_hit "https://example.com/file.tar.gz"; then
  echo "File is cached"
fi
```

#### `_cache_get(url)`
Gets cached file path.

```bash
path=$(_cache_get "https://example.com/file.tar.gz")
# Returns: path to cached file
```

#### `_cache_store(url, file)`
Stores file in cache.

```bash
_cache_store "https://example.com/file.tar.gz" "/tmp/file.tar.gz"
```

#### `_cache_download(url, output)`
Downloads with caching. Returns cached file if available.

```bash
path=$(_cache_download "https://example.com/file.tar.gz" "/tmp/output.tar.gz")
```

### Cache Maintenance

#### `_cache_cleanup()`
Cleans old cache entries based on age and size.

```bash
_cache_cleanup
# Removes entries older than CACHE_MAX_AGE_DAYS
# Removes entries if cache exceeds CACHE_MAX_SIZE_MB
```

#### `_cache_stats()`
Shows cache statistics.

```bash
_cache_stats
# Output:
# Cache Statistics:
#   Files: 42
#   Size: 1.2G
#   Hits: 156
#   Misses: 23
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CACHE_MAX_AGE_DAYS` | Maximum cache age | `30` |
| `CACHE_MAX_SIZE_MB` | Maximum cache size | `5120` (5GB) |
| `_CACHE_ROOT` | Cache directory | `~/.cache/opencode-setup/packages` |
| `_CACHE_INDEX` | Cache index file | `~/.cache/opencode-setup/packages/.cache-index.json` |

## Usage

```bash
# Source the module
source src/lib/helpers.sh
source src/lib/00e-cache-mgr.sh

# Show help
_cache_help

# Initialize cache
_cache_init

# Download with caching
path=$(_cache_download "https://example.com/file.tar.gz")

# Check cache statistics
_cache_stats

# Clean old entries
_cache_cleanup
```

## Cache Structure

```
~/.cache/opencode-setup/packages/
├── .cache-index.json          # Cache index
├── .cache-log                 # Cache hit/miss log
├── a1b2c3d4e5f6g7h8          # Cached file (hash key)
├── i9j0k1l2m3n4o5p6          # Cached file (hash key)
└── ...
```

## Integrity Checks

- SHA256 hash verification
- File size validation
- Timestamp tracking

## See Also

- [core.md](core.md) - Core infrastructure
- [parallel.md](parallel.md) - Parallel execution
- [helpers.sh](../helpers.sh) - Helper functions
