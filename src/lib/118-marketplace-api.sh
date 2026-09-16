#!/usr/bin/env bash
# src/lib/118-marketplace-api.sh — Marketplace API
# Part of Phase 4: Advanced Features
# shellcheck disable=SC2034
set -euo pipefail

MARKETPLACE_API="${MARKETPLACE_API:-https://marketplace.opencode.ai/api/v1}"

# ── Marketplace API Operations ───────────────────────────────────────────────

# Search plugins
_marketplace_api_search() {
  local query="${1:-}"
  local limit="${2:-20}"
  
  if [ -z "$query" ]; then
    err "Search query required"
  fi
  
  info "Searching marketplace: $query"
  
  if command -v curl &>/dev/null; then
    curl -sS "$MARKETPLACE_API/search?q=$query&limit=$limit" 2>/dev/null || {
      warn "Failed to search marketplace"
      return 1
    }
  fi
}

# Get plugin info
_marketplace_api_info() {
  local plugin_name="${1:-}"
  
  if [ -z "$plugin_name" ]; then
    err "Plugin name required"
  fi
  
  if command -v curl &>/dev/null; then
    curl -sS "$MARKETPLACE_API/plugins/$plugin_name" 2>/dev/null || {
      warn "Failed to get plugin info"
      return 1
    }
  fi
}

# Install plugin
_marketplace_api_install() {
  local plugin_name="${1:-}"
  local version="${2:-latest}"
  
  if [ -z "$plugin_name" ]; then
    err "Plugin name required"
  fi
  
  info "Installing plugin: $plugin_name@$version"
  
  # Download plugin
  local download_url="$MARKETPLACE_API/plugins/$plugin_name/download?version=$version"
  
  if command -v curl &>/dev/null; then
    local plugin_dir="$HOME/.config/opencode/plugins/$plugin_name"
    mkdir -p "$plugin_dir"
    
    curl -sS "$download_url" | tar xz -C "$plugin_dir" 2>/dev/null || {
      warn "Failed to download plugin"
      return 1
    }
    
    echo "$version" > "$plugin_dir/VERSION"
    log "Plugin installed: $plugin_name@$version"
  fi
}

# Publish plugin
_marketplace_api_publish() {
  local plugin_dir="${1:-.}"
  
  if [ ! -f "$plugin_dir/manifest.json" ]; then
    err "No manifest.json found in $plugin_dir"
  fi
  
  info "Publishing plugin from $plugin_dir"
  
  # Create archive
  local archive="/tmp/opencode-plugin-$(date +%s).tar.gz"
  tar czf "$archive" -C "$plugin_dir" . 2>/dev/null || {
    err "Failed to create archive"
  }
  
  # Upload to marketplace
  if command -v curl &>/dev/null; then
    curl -sS -X POST \
      -F "plugin=@$archive" \
      "$MARKETPLACE_API/publish" 2>/dev/null || {
      rm -f "$archive"
      err "Failed to publish plugin"
    }
  fi
  
  rm -f "$archive"
  log "Plugin published"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_marketplace_api() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    search)  _marketplace_api_search "$@" ;;
    info)    _marketplace_api_info "$@" ;;
    install) _marketplace_api_install "$@" ;;
    publish) _marketplace_api_publish "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode marketplace-api <command> [args]

Commands:
  search <query> [limit]         Search plugins
  info <name>                    Get plugin info
  install <name> [version]       Install plugin
  publish [dir]                  Publish plugin
EOF
      ;;
  esac
}
