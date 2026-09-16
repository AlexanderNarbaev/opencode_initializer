#!/usr/bin/env bash
# src/lib/112-cache-manager.sh — Cache management
# Part of Phase 6: Production Hardening
# shellcheck disable=SC2034
set -euo pipefail

CACHE_DIR="${CACHE_DIR:-$HOME/.cache/opencode}"

# ── Cache Operations ─────────────────────────────────────────────────────────

# Clear cache
_cache_clear() {
  local cache_type="${1:-all}"
  
  case "$cache_type" in
    all)
      rm -rf "${CACHE_DIR:?}"/*
      log "All cache cleared"
      ;;
    skills)
      rm -rf "$CACHE_DIR/skills"
      log "Skills cache cleared"
      ;;
    marketplace)
      rm -rf "$CACHE_DIR/marketplace"
      log "Marketplace cache cleared"
      ;;
    *)
      warn "Unknown cache type: $cache_type"
      ;;
  esac
}

# Get cache size
_cache_size() {
  local cache_type="${1:-all}"
  
  local target="$CACHE_DIR"
  if [ "$cache_type" != "all" ]; then
    target="$CACHE_DIR/$cache_type"
  fi
  
  if [ ! -d "$target" ]; then
    echo "0B"
    return
  fi
  
  du -sh "$target" 2>/dev/null | cut -f1
}

# List cache contents
_cache_list() {
  if [ ! -d "$CACHE_DIR" ]; then
    info "No cache"
    return 0
  fi
  
  find "$CACHE_DIR" -maxdepth 1 -type d 2>/dev/null | while read -r d; do
    local name
    name=$(basename "$d")
    local size
    size=$(du -sh "$d" 2>/dev/null | cut -f1)
    echo "$name: $size"
  done | sort
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_cache() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    clear) _cache_clear "$@" ;;
    size)  _cache_size "$@" ;;
    list)  _cache_list ;;
    help|*)
      cat <<'EOF'
Usage: opencode cache <command> [args]

Commands:
  clear [type]   Clear cache (all|skills|marketplace)
  size [type]    Get cache size
  list           List cache contents
EOF
      ;;
  esac
}
