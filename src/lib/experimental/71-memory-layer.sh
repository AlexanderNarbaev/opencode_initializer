#!/usr/bin/env bash
# src/lib/71-memory-layer.sh — Memory persistence and management
# Part of Phase 0: Agent Orchestration
# shellcheck disable=SC2034
set -euo pipefail

MEMORY_LAYER_DIR="${MEMORY_LAYER_DIR:-$HOME/.local/share/opencode/memory}"
MEMORY_LAYER_WAL="${MEMORY_LAYER_DIR}/wal"
MEMORY_LAYER_LONG_TERM="${MEMORY_LAYER_DIR}/long-term"
MEMORY_LAYER_SHORT_TERM="${MEMORY_LAYER_DIR}/short-term"

# ── Memory Operations ────────────────────────────────────────────────────────

# Store a memory
_memory_store() {
  local memory_type="${1:-}"
  local memory_key="${2:-}"
  local memory_data="${3:-}"
  local importance="${4:-5}"
  
  if [ -z "$memory_type" ] || [ -z "$memory_key" ]; then
    err "Memory type and key required"
  fi
  
  local memory_dir="$MEMORY_LAYER_DIR/$memory_type"
  mkdir -p "$memory_dir"
  
  local memory_file="$memory_dir/$memory_key.json"
  
  cat > "$memory_file" <<EOF
{
  "type": "$memory_type",
  "key": "$memory_key",
  "data": "$memory_data",
  "importance": $importance,
  "stored_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "access_count": 0,
  "last_accessed": null
}
EOF
  
  log "Memory stored: $memory_type/$memory_key"
}

# Retrieve a memory
_memory_retrieve() {
  local memory_type="${1:-}"
  local memory_key="${2:-}"
  
  if [ -z "$memory_type" ] || [ -z "$memory_key" ]; then
    err "Memory type and key required"
  fi
  
  local memory_file="$MEMORY_LAYER_DIR/$memory_type/$memory_key.json"
  
  if [ ! -f "$memory_file" ]; then
    echo ""
    return 1
  fi
  
  # Update access count
  if command -v jq &>/dev/null; then
    jq '.access_count += 1 | .last_accessed = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' \
      "$memory_file" > "$memory_file.tmp"
    mv "$memory_file.tmp" "$memory_file"
    
    jq -r '.data' "$memory_file" 2>/dev/null
  else
    cat "$memory_file" 2>/dev/null
  fi
}

# Search memories
_memory_search() {
  local query="${1:-}"
  local memory_type="${2:-}"
  local limit="${3:-10}"
  
  if [ -z "$query" ]; then
    err "Search query required"
  fi
  
  local search_dir="$MEMORY_LAYER_DIR"
  if [ -n "$memory_type" ]; then
    search_dir="$MEMORY_LAYER_DIR/$memory_type"
  fi
  
  if [ ! -d "$search_dir" ]; then
    return 0
  fi
  
  # Search in memory files
  grep -rl "$query" "$search_dir/" 2>/dev/null | head -n "$limit" | while read -r f; do
    if command -v jq &>/dev/null; then
      jq -r '"\(.type)/\(.key) (importance: \(.importance))"' "$f" 2>/dev/null
    else
      echo "$f"
    fi
  done
}

# ── WAL (Write-Ahead Log) ────────────────────────────────────────────────────

# Write to WAL
_wal_write() {
  local operation="${1:-}"
  local data="${2:-}"
  
  mkdir -p "$MEMORY_LAYER_WAL"
  
  local wal_file="$MEMORY_LAYER_WAL/wal.jsonl"
  
  echo "{\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"operation\": \"$operation\", \"data\": \"$data\"}" \
    >> "$wal_file"
}

# Read WAL
_wal_read() {
  local limit="${1:-100}"
  
  local wal_file="$MEMORY_LAYER_WAL/wal.jsonl"
  
  if [ ! -f "$wal_file" ]; then
    return 0
  fi
  
  tail -n "$limit" "$wal_file" 2>/dev/null
}

# Replay WAL
_wal_replay() {
  local wal_file="$MEMORY_LAYER_WAL/wal.jsonl"
  
  if [ ! -f "$wal_file" ]; then
    info "No WAL to replay"
    return 0
  fi
  
  info "Replaying WAL..."
  
  while IFS= read -r line; do
    if command -v jq &>/dev/null; then
      local operation data
      operation=$(echo "$line" | jq -r '.operation // ""' 2>/dev/null)
      data=$(echo "$line" | jq -r '.data // ""' 2>/dev/null)
      
      case "$operation" in
        store)
          # Replay store operation
          info "Replaying: store $data"
          ;;
        *)
          ;;
      esac
    fi
  done < "$wal_file"
  
  log "WAL replay complete"
}

# Checkpoint WAL
_wal_checkpoint() {
  local wal_file="$MEMORY_LAYER_WAL/wal.jsonl"
  
  if [ ! -f "$wal_file" ]; then
    return 0
  fi
  
  # Archive current WAL
  local archive="$MEMORY_LAYER_WAL/wal-$(date +%Y%m%d-%H%M%S).jsonl"
  mv "$wal_file" "$archive"
  
  # Compress archive
  if command -v gzip &>/dev/null; then
    gzip "$archive"
  fi
  
  log "WAL checkpoint created"
}

# ── Memory Statistics ────────────────────────────────────────────────────────

# Get memory statistics
_memory_stats() {
  local memory_type="${1:-}"
  
  local search_dir="$MEMORY_LAYER_DIR"
  if [ -n "$memory_type" ]; then
    search_dir="$MEMORY_LAYER_DIR/$memory_type"
  fi
  
  if [ ! -d "$search_dir" ]; then
    info "No memory data"
    return 0
  fi
  
  local total_files=0 total_size=0
  
  while IFS= read -r f; do
    ((total_files++))
    local size
    size=$(stat -c %s "$f" 2>/dev/null || echo "0")
    total_size=$((total_size + size))
  done < <(find "$search_dir" -name "*.json" -type f 2>/dev/null)
  
  echo "Memory Statistics:"
  echo "  Files: $total_files"
  echo "  Size: $total_size bytes"
}

# List memory types
_memory_types() {
  if [ ! -d "$MEMORY_LAYER_DIR" ]; then
    return 0
  fi
  
  find "$MEMORY_LAYER_DIR" -maxdepth 1 -type d 2>/dev/null | while read -r d; do
    local type
    type=$(basename "$d")
    if [ "$type" != "$(basename "$MEMORY_LAYER_DIR")" ]; then
      echo "$type"
    fi
  done | sort
}

# ── Cleanup ──────────────────────────────────────────────────────────────────

# Clean old memories
_memory_cleanup() {
  local max_age="${1:-604800}"  # 7 days default
  local min_importance="${2:-3}"
  
  info "Cleaning old memories (max_age: ${max_age}s, min_importance: $min_importance)"
  
  local cleaned=0
  local now
  now=$(date +%s)
  
  find "$MEMORY_LAYER_DIR" -name "*.json" -type f 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      local stored_at importance
      stored_at=$(jq -r '.stored_at // ""' "$f" 2>/dev/null)
      importance=$(jq -r '.importance // 5' "$f" 2>/dev/null)
      
      if [ -n "$stored_at" ] && [ "$importance" -lt "$min_importance" ]; then
        local stored_ts
        stored_ts=$(date -d "$stored_at" +%s 2>/dev/null || echo "0")
        local age=$((now - stored_ts))
        
        if [ "$age" -gt "$max_age" ]; then
          rm -f "$f"
          ((cleaned++))
        fi
      fi
    fi
  done
  
  log "Cleaned $cleaned old memories"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_memory() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    store)      _memory_store "$@" ;;
    retrieve)   _memory_retrieve "$@" ;;
    search)     _memory_search "$@" ;;
    wal-write)  _wal_write "$@" ;;
    wal-read)   _wal_read "$@" ;;
    wal-replay) _wal_replay "$@" ;;
    checkpoint) _wal_checkpoint "$@" ;;
    stats)      _memory_stats "$@" ;;
    types)      _memory_types "$@" ;;
    cleanup)    _memory_cleanup "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode memory <command> [args]

Commands:
  store <type> <key> <data> [importance]  Store a memory
  retrieve <type> <key>                   Retrieve a memory
  search <query> [type] [limit]           Search memories
  wal-write <operation> <data>            Write to WAL
  wal-read [limit]                        Read WAL
  wal-replay                              Replay WAL
  checkpoint                              Checkpoint WAL
  stats [type]                            Get memory statistics
  types                                   List memory types
  cleanup [max_age] [min_importance]      Clean old memories
EOF
      ;;
  esac
}
