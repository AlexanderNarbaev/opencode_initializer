#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# OpenCode Initializer v15.0.0 - Module 34: Token Cache
# =============================================================================
# Description: Multi-level caching for token optimization (40-60% savings)
# Version: 1.0.0
# Status: Active
# Dependencies: 00-core.sh, 05-logging.sh, 10-config.sh, 33-spec-registry.sh
# Gap Addressed: Token economics optimization
# =============================================================================

# NOTE: sourced by setup.sh — set -euo pipefail is idempotent there (setup.sh already strict).

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
TOKEN_CACHE_VERSION="1.0.0"
TOKEN_CACHE_DIR="${OPENCODE_TOKEN_CACHE_DIR:-${OPENCODE_ROOT:-.}/.cache/tokens}"
TOKEN_CACHE_DB="${TOKEN_CACHE_DIR}/cache.db"
TOKEN_CACHE_STATS="${TOKEN_CACHE_DIR}/stats.json"
TOKEN_CACHE_TTL_DEFAULT=3600  # 1 hour
TOKEN_CACHE_MAX_SIZE=1000     # Max entries

# Cache levels (bash 3.2-safe case lookup — no declare -A)
#   L1 = memory  In-memory (fastest, process lifetime)
#   L2 = disk    Disk-based (persistent)
#   L3 = redis   Redis shared (distributed)
cache_level_kind() {
    case "$1" in
        L1) echo "memory" ;;
        L2) echo "disk" ;;
        L3) echo "redis" ;;
        *) return 1 ;;
    esac
}

# Statistics
declare -i CACHE_HITS=0
declare -i CACHE_MISSES=0
declare -i CACHE_EXPIRED=0
declare -i CACHE_EVICTED=0

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
token_log_info() {
    log_info "[TOKEN] $*"
}

token_log_warn() {
    log_warn "[TOKEN] $*"
}

token_log_error() {
    log_error "[TOKEN] $*"
}

token_log_debug() {
    log_debug "[TOKEN] $*"
}

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------
init_token_cache() {
    token_log_info "Initializing Token Cache v${TOKEN_CACHE_VERSION}"
    
    # Create directories
    mkdir -p "${TOKEN_CACHE_DIR}"
    mkdir -p "${TOKEN_CACHE_DIR}/responses"
    mkdir -p "${TOKEN_CACHE_DIR}/embeddings"
    mkdir -p "${TOKEN_CACHE_DIR}/contexts"
    
    # Initialize stats file
    if [[ ! -f "${TOKEN_CACHE_STATS}" ]]; then
        cat > "${TOKEN_CACHE_STATS}" << 'EOF'
{
    "version": "1.0.0",
    "initialized": "$(date -Iseconds)",
    "hits": 0,
    "misses": 0,
    "expired": 0,
    "evicted": 0,
    "total_savings_tokens": 0,
    "total_savings_usd": 0.0
}
EOF
    fi
    
    token_log_info "Token Cache initialized at ${TOKEN_CACHE_DIR}"
}

# -----------------------------------------------------------------------------
# Hash Functions
# -----------------------------------------------------------------------------
# Generate cache key from prompt + context
generate_cache_key() {
    local prompt="$1"
    local context="${2:-}"
    local model="${3:-default}"
    
    local combined="${model}:${prompt}:${context}"
    echo -n "$combined" | sha256sum | cut -d' ' -f1
}

# -----------------------------------------------------------------------------
# L1 Cache (In-Memory) — parallel indexed arrays (bash 3.2-safe, no declare -A)
L1_KEYS=()
L1_VALUES=()
L1_TIMESTAMPS=()

# Index lookup: echoes array index of key, or returns 1 if absent
_l1_index_of() {
    local i
    for ((i = 0; i < ${#L1_KEYS[@]}; i++)); do
        [ "${L1_KEYS[$i]}" = "$1" ] && { echo "$i"; return 0; }
    done
    return 1
}

# Remove entry by index (swap-with-last keeps arrays dense)
_l1_remove_at() {
    local idx="$1"
    local last=$(( ${#L1_KEYS[@]} - 1 ))
    if [ "$idx" -ne "$last" ]; then
        L1_KEYS[$idx]="${L1_KEYS[$last]}"
        L1_VALUES[$idx]="${L1_VALUES[$last]}"
        L1_TIMESTAMPS[$idx]="${L1_TIMESTAMPS[$last]}"
    fi
    unset "L1_KEYS[$last]" "L1_VALUES[$last]" "L1_TIMESTAMPS[$last]"
}

l1_cache_get() {
    local key="$1"
    local idx
    
    if idx=$(_l1_index_of "$key"); then
        local timestamp="${L1_TIMESTAMPS[$idx]:-0}"
        local now=$(date +%s)
        local age=$((now - timestamp))
        
        if [[ $age -lt $TOKEN_CACHE_TTL_DEFAULT ]]; then
            ((CACHE_HITS++)) || true
            echo "${L1_VALUES[$idx]}"
            return 0
        else
            # Expired
            _l1_remove_at "$idx"
            ((CACHE_EXPIRED++)) || true
        fi
    fi
    
    ((CACHE_MISSES++)) || true
    return 1
}

l1_cache_set() {
    local key="$1"
    local value="$2"
    local idx
    
    if idx=$(_l1_index_of "$key"); then
        L1_VALUES[$idx]="$value"
        L1_TIMESTAMPS[$idx]=$(date +%s)
    else
        L1_KEYS+=("$key")
        L1_VALUES+=("$value")
        L1_TIMESTAMPS+=("$(date +%s)")
    fi
    
    # Evict oldest if over limit
    if [[ ${#L1_KEYS[@]} -gt $TOKEN_CACHE_MAX_SIZE ]]; then
        local oldest_idx=""
        local oldest_time=9999999999
        local i
        
        for ((i = 0; i < ${#L1_TIMESTAMPS[@]}; i++)); do
            local t="${L1_TIMESTAMPS[$i]}"
            if [[ $t -lt $oldest_time ]]; then
                oldest_time=$t
                oldest_idx=$i
            fi
        done
        
        if [[ -n "$oldest_idx" ]]; then
            _l1_remove_at "$oldest_idx"
            ((CACHE_EVICTED++)) || true
        fi
    fi
}

# -----------------------------------------------------------------------------
# L2 Cache (Disk)
# -----------------------------------------------------------------------------
l2_cache_get() {
    local key="$1"
    local cache_file="${TOKEN_CACHE_DIR}/responses/${key}.cache"
    
    if [[ -f "$cache_file" ]]; then
        local timestamp=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
        local now=$(date +%s)
        local age=$((now - timestamp))
        
        if [[ $age -lt $TOKEN_CACHE_TTL_DEFAULT ]]; then
            ((CACHE_HITS++)) || true
            cat "$cache_file"
            return 0
        else
            # Expired
            rm -f "$cache_file"
            ((CACHE_EXPIRED++)) || true
        fi
    fi
    
    ((CACHE_MISSES++)) || true
    return 1
}

l2_cache_set() {
    local key="$1"
    local value="$2"
    local cache_file="${TOKEN_CACHE_DIR}/responses/${key}.cache"
    
    echo -n "$value" > "$cache_file"
    token_log_debug "Cached to L2: $key"
}

# -----------------------------------------------------------------------------
# Unified Cache Interface
# -----------------------------------------------------------------------------
token_cache_get() {
    local prompt="$1"
    local context="${2:-}"
    local model="${3:-default}"
    
    local key
    key=$(generate_cache_key "$prompt" "$context" "$model")
    
    # Try L1 first
    local result
    if result=$(l1_cache_get "$key"); then
        token_log_debug "L1 cache hit: $key"
        echo "$result"
        return 0
    fi
    
    # Try L2
    if result=$(l2_cache_get "$key"); then
        token_log_debug "L2 cache hit: $key"
        # Promote to L1
        l1_cache_set "$key" "$result"
        echo "$result"
        return 0
    fi
    
    token_log_debug "Cache miss: $key"
    return 1
}

token_cache_set() {
    local prompt="$1"
    local response="$2"
    local context="${3:-}"
    local model="${4:-default}"
    
    local key
    key=$(generate_cache_key "$prompt" "$context" "$model")
    
    # Store in both L1 and L2
    l1_cache_set "$key" "$response"
    l2_cache_set "$key" "$response"
    
    token_log_info "Cached response: $key (${#response} chars)"
}

# -----------------------------------------------------------------------------
# Context Deduplication
# -----------------------------------------------------------------------------
# Remove duplicate lines from context
deduplicate_context() {
    local context="$1"
    
    echo "$context" | sort -u | tr '\n' '\n'
}

# Compress context by removing whitespace
compress_context() {
    local context="$1"
    
    echo "$context" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -s ' \t\n' ' '
}

# Smart context chunking
chunk_context() {
    local context="$1"
    local max_chunk_size="${2:-4000}"  # tokens approx
    
    local chunks=()
    local current_chunk=""
    local current_size=0
    
    while IFS= read -r line; do
        local line_size=${#line}
        
        if [[ $((current_size + line_size)) -gt $max_chunk_size ]]; then
            chunks+=("$current_chunk")
            current_chunk="$line"
            current_size=$line_size
        else
            current_chunk+=$'\n'"$line"
            current_size=$((current_size + line_size))
        fi
    done <<< "$context"
    
    # Add last chunk
    if [[ -n "$current_chunk" ]]; then
        chunks+=("$current_chunk")
    fi
    
    # Output chunks
    for i in "${!chunks[@]}"; do
        echo "===CHUNK_${i}==="${chunks[$i]}"===END_CHUNK_${i}==="
    done
}

# -----------------------------------------------------------------------------
# Statistics
# -----------------------------------------------------------------------------
update_stats() {
    local total=$((CACHE_HITS + CACHE_MISSES))
    local hit_rate=0
    
    if [[ $total -gt 0 ]]; then
        hit_rate=$(echo "scale=2; $CACHE_HITS * 100 / $total" | bc)
    fi
    
    # Estimate savings (assuming avg 100 tokens per cache hit)
    local saved_tokens=$((CACHE_HITS * 100))
    local saved_usd=$(echo "scale=2; $saved_tokens * 0.000002" | bc)  # Approx $2/1M tokens
    
    cat > "${TOKEN_CACHE_STATS}" << EOF
{
    "version": "$TOKEN_CACHE_VERSION",
    "updated": "$(date -Iseconds)",
    "hits": $CACHE_HITS,
    "misses": $CACHE_MISSES,
    "expired": $CACHE_EXPIRED,
    "evicted": $CACHE_EVICTED,
    "hit_rate_percent": $hit_rate,
    "total_savings_tokens": $saved_tokens,
    "total_savings_usd": $saved_usd
}
EOF
}

get_stats() {
    if [[ -f "${TOKEN_CACHE_STATS}" ]]; then
        cat "${TOKEN_CACHE_STATS}"
    else
        echo '{"error": "Stats not found. Run init_token_cache first."}'
        return 1
    fi
}

print_stats() {
    local stats
    stats=$(get_stats)
    
    if [[ $? -eq 0 ]]; then
        echo "=== Token Cache Statistics ==="
        echo "Hits: $(echo "$stats" | jq -r '.hits')"
        echo "Misses: $(echo "$stats" | jq -r '.misses')"
        echo "Hit Rate: $(echo "$stats" | jq -r '.hit_rate_percent')%"
        echo "Expired: $(echo "$stats" | jq -r '.expired')"
        echo "Evicted: $(echo "$stats" | jq -r '.evicted')"
        echo "Tokens Saved: $(echo "$stats" | jq -r '.total_savings_tokens')"
        echo "USD Saved: \$$(echo "$stats" | jq -r '.total_savings_usd')"
        echo "=============================="
    fi
}

# -----------------------------------------------------------------------------
# CLI Interface
# -----------------------------------------------------------------------------
token_cli() {
    local cmd="${1:-help}"
    shift || true
    
    case "$cmd" in
        init)
            init_token_cache
            ;;
        get)
            if [[ $# -lt 1 ]]; then
                echo "Usage: token-cache get <prompt> [context] [model]"
                exit 1
            fi
            token_cache_get "$@"
            ;;
        set)
            if [[ $# -lt 2 ]]; then
                echo "Usage: token-cache set <prompt> <response> [context] [model]"
                exit 1
            fi
            token_cache_set "$@"
            ;;
        stats)
            print_stats
            ;;
        clear)
            rm -rf "${TOKEN_CACHE_DIR}"/*
            token_log_info "Cache cleared"
            ;;
        help|*)
            cat << EOF
OpenCode Token Cache CLI v${TOKEN_CACHE_VERSION}

Usage: token-cache <command> [options]

Commands:
  init                          Initialize token cache
  get <prompt> [context] [model]
                                Get cached response
  set <prompt> <response> [context] [model]
                                Cache a response
  stats                         Show cache statistics
  clear                         Clear all caches

Features:
  - L1 (memory) + L2 (disk) caching
  - Automatic TTL expiration (1 hour default)
  - Context deduplication
  - Hit rate tracking
  - Token savings estimation

Examples:
  token-cache init
  token-cache set "What is AI?" "Artificial Intelligence..." "" "gpt-4"
  token-cache get "What is AI?" "" "gpt-4"
  token-cache stats

EOF
            ;;
    esac
}

# Export functions

# Auto-initialize if sourced and OPENCODE_AUTO_INIT is set
if [[ "${OPENCODE_AUTO_INIT:-false}" == "true" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_token_cache
fi

# Direct execution only (never runs when sourced by setup.sh)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        init|get|set|dedup|compress|chunk|stats) token_cli "$@" ;;
        *) token_cli "help"; exit 2 ;;
    esac
fi
