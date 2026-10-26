#!/usr/bin/env bash
# src/lib/93-harness-memory.sh — Memory hierarchy (WAL, files, vectors)
# Part of Phase 4: AI-Native Development
# shellcheck disable=SC2034
set -euo pipefail

HARNESS_MEMORY_DIR="${HARNESS_MEMORY_DIR:-$HOME/.local/share/opencode/harness/memory}"

# ── Memory Operations ────────────────────────────────────────────────────────

# Store in memory
_harness_memory_store() {
  local level="${1:-}"
  local key="${2:-}"
  local data="${3:-}"
  
  if [ -z "$level" ] || [ -z "$key" ]; then
    err "Memory level and key required"
  fi
  
  local memory_dir="$HARNESS_MEMORY_DIR/$level"
  mkdir -p "$memory_dir"
  
  cat > "$memory_dir/$key.json" <<EOF
{
  "level": "$level",
  "key": "$key",
  "data": "$data",
  "stored_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# Retrieve from memory
_harness_memory_retrieve() {
  local level="${1:-}"
  local key="${2:-}"
  
  if [ -z "$level" ] || [ -z "$key" ]; then
    err "Memory level and key required"
  fi
  
  local memory_file="$HARNESS_MEMORY_DIR/$level/$key.json"
  
  if [ ! -f "$memory_file" ]; then
    echo ""
    return 1
  fi
  
  if command -v jq &>/dev/null; then
    jq -r '.data' "$memory_file" 2>/dev/null
  fi
}

# Search memory
_harness_memory_search() {
  local query="${1:-}"
  local level="${2:-}"
  
  if [ -z "$query" ]; then
    err "Search query required"
  fi
  
  local search_dir="$HARNESS_MEMORY_DIR"
  if [ -n "$level" ]; then
    search_dir="$HARNESS_MEMORY_DIR/$level"
  fi
  
  if [ ! -d "$search_dir" ]; then
    return 0
  fi
  
  grep -rl "$query" "$search_dir/" 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      jq -r '"\(.level)/\(.key)"' "$f" 2>/dev/null
    fi
  done
}

# ── Memory Levels ────────────────────────────────────────────────────────────

# List memory levels
_harness_memory_levels() {
  if [ ! -d "$HARNESS_MEMORY_DIR" ]; then
    return 0
  fi
  
  find "$HARNESS_MEMORY_DIR" -maxdepth 1 -type d 2>/dev/null | while read -r d; do
    local level
    level=$(basename "$d")
    if [ "$level" != "$(basename "$HARNESS_MEMORY_DIR")" ]; then
      echo "$level"
    fi
  done | sort
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_harness_memory() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    store)    _harness_memory_store "$@" ;;
    retrieve) _harness_memory_retrieve "$@" ;;
    search)   _harness_memory_search "$@" ;;
    levels)   _harness_memory_levels ;;
    help|*)
      cat <<'EOF'
Usage: opencode harness-memory <command> [args]

Commands:
  store <level> <key> <data>   Store in memory
  retrieve <level> <key>       Retrieve from memory
  search <query> [level]       Search memory
  levels                       List memory levels
EOF
      ;;
  esac
}
