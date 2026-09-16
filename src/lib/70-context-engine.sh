#!/usr/bin/env bash
# src/lib/70-context-engine.sh — Context management and optimization
# Part of Phase 0: Agent Orchestration
# shellcheck disable=SC2034
set -euo pipefail

CONTEXT_ENGINE_DIR="${CONTEXT_ENGINE_DIR:-$HOME/.local/share/opencode/context}"
CONTEXT_ENGINE_CACHE="${CONTEXT_ENGINE_DIR}/cache"
CONTEXT_ENGINE_MAX_TOKENS="${CONTEXT_ENGINE_MAX_TOKENS:-100000}"

# ── Context Operations ───────────────────────────────────────────────────────

# Store context
_context_store() {
  local context_type="${1:-}"
  local context_key="${2:-}"
  local context_data="${3:-}"
  
  if [ -z "$context_type" ] || [ -z "$context_key" ]; then
    err "Context type and key required"
  fi
  
  local context_dir="$CONTEXT_ENGINE_DIR/$context_type"
  mkdir -p "$context_dir"
  
  local context_file="$context_dir/$context_key.json"
  
  cat > "$context_file" <<EOF
{
  "type": "$context_type",
  "key": "$context_key",
  "data": "$context_data",
  "stored_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "access_count": 0
}
EOF
  
  log "Context stored: $context_type/$context_key"
}

# Retrieve context
_context_retrieve() {
  local context_type="${1:-}"
  local context_key="${2:-}"
  
  if [ -z "$context_type" ] || [ -z "$context_key" ]; then
    err "Context type and key required"
  fi
  
  local context_file="$CONTEXT_ENGINE_DIR/$context_type/$context_key.json"
  
  if [ ! -f "$context_file" ]; then
    echo ""
    return 1
  fi
  
  # Update access count
  if command -v jq &>/dev/null; then
    jq '.access_count += 1 | .last_accessed = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' \
      "$context_file" > "$context_file.tmp"
    mv "$context_file.tmp" "$context_file"
    
    jq -r '.data' "$context_file" 2>/dev/null
  else
    cat "$context_file" 2>/dev/null
  fi
}

# Search context
_context_search() {
  local query="${1:-}"
  local context_type="${2:-}"
  
  if [ -z "$query" ]; then
    err "Search query required"
  fi
  
  local search_dir="$CONTEXT_ENGINE_DIR"
  if [ -n "$context_type" ]; then
    search_dir="$CONTEXT_ENGINE_DIR/$context_type"
  fi
  
  if [ ! -d "$search_dir" ]; then
    return 0
  fi
  
  # Search in context files
  grep -rl "$query" "$search_dir/" 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      jq -r '"\(.type)/\(.key): \(.data | tostring | .[0:100])..."' "$f" 2>/dev/null
    else
      echo "$f"
    fi
  done
}

# ── Context Compaction ───────────────────────────────────────────────────────

# Compact context (summarize old entries)
_context_compact() {
  local context_type="${1:-}"
  local max_age="${2:-86400}"  # 24 hours default
  
  if [ -z "$context_type" ]; then
    err "Context type required"
  fi
  
  local context_dir="$CONTEXT_ENGINE_DIR/$context_type"
  
  if [ ! -d "$context_dir" ]; then
    return 0
  fi
  
  local compacted=0
  local now
  now=$(date +%s)
  
  find "$context_dir" -name "*.json" -type f 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      local stored_at
      stored_at=$(jq -r '.stored_at // ""' "$f" 2>/dev/null)
      
      if [ -n "$stored_at" ]; then
        local stored_ts
        stored_ts=$(date -d "$stored_at" +%s 2>/dev/null || echo "0")
        local age=$((now - stored_ts))
        
        if [ "$age" -gt "$max_age" ]; then
          # Compact: keep only essential data
          jq '{type, key, data: (.data | tostring | .[0:200]), compacted_at: "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' \
            "$f" > "$f.tmp"
          mv "$f.tmp" "$f"
          ((compacted++))
        fi
      fi
    fi
  done
  
  log "Compacted $compacted context entries"
}

# ── Context Statistics ───────────────────────────────────────────────────────

# Get context statistics
_context_stats() {
  local context_type="${1:-}"
  
  local search_dir="$CONTEXT_ENGINE_DIR"
  if [ -n "$context_type" ]; then
    search_dir="$CONTEXT_ENGINE_DIR/$context_type"
  fi
  
  if [ ! -d "$search_dir" ]; then
    info "No context data"
    return 0
  fi
  
  local total_files=0 total_size=0
  
  while IFS= read -r f; do
    ((total_files++))
    local size
    size=$(stat -c %s "$f" 2>/dev/null || echo "0")
    total_size=$((total_size + size))
  done < <(find "$search_dir" -name "*.json" -type f 2>/dev/null)
  
  echo "Context Statistics:"
  echo "  Files: $total_files"
  echo "  Size: $total_size bytes"
}

# List context types
_context_types() {
  if [ ! -d "$CONTEXT_ENGINE_DIR" ]; then
    return 0
  fi
  
  find "$CONTEXT_ENGINE_DIR" -maxdepth 1 -type d 2>/dev/null | while read -r d; do
    local type
    type=$(basename "$d")
    if [ "$type" != "$(basename "$CONTEXT_ENGINE_DIR")" ]; then
      echo "$type"
    fi
  done | sort
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_context() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    store)    _context_store "$@" ;;
    retrieve) _context_retrieve "$@" ;;
    search)   _context_search "$@" ;;
    compact)  _context_compact "$@" ;;
    stats)    _context_stats "$@" ;;
    types)    _context_types "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode context <command> [args]

Commands:
  store <type> <key> <data>   Store context
  retrieve <type> <key>       Retrieve context
  search <query> [type]       Search context
  compact <type> [max_age]    Compact old entries
  stats [type]                Get context statistics
  types                       List context types
EOF
      ;;
  esac
}
