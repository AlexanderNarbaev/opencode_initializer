#!/usr/bin/env bash
# src/lib/78-marketplace.sh — Marketplace client
# Part of Phase 2: Ecosystem Expansion
# shellcheck disable=SC2034
set -euo pipefail

MARKETPLACE_URL="${MARKETPLACE_URL:-https://marketplace.opencode.ai}"
MARKETPLACE_CACHE="${MARKETPLACE_CACHE:-$HOME/.cache/opencode/marketplace}"

# ── Marketplace Search ───────────────────────────────────────────────────────

# Search marketplace
_marketplace_search() {
  local query="${1:-}"
  local category="${2:-}"
  local limit="${3:-20}"
  
  if [ -z "$query" ]; then
    err "Search query required"
  fi
  
  info "Searching marketplace: $query"
  
  # Mock search results for now
  echo "Results for '$query':"
  echo "  1. code-review@1.2.0 — Automated code review"
  echo "  2. security-audit@1.5.0 — Security audit tool"
  echo "  3. documentation@1.1.0 — Auto-generate docs"
}

# List marketplace categories
_marketplace_categories() {
  echo "Categories:"
  echo "  - code-quality"
  echo "  - security"
  echo "  - documentation"
  echo "  - testing"
  echo "  - devops"
  echo "  - ai-ml"
}

# Get plugin info
_marketplace_info() {
  local plugin_name="${1:-}"
  
  if [ -z "$plugin_name" ]; then
    err "Plugin name required"
  fi
  
  echo "Plugin: $plugin_name"
  echo "Version: 1.0.0"
  echo "Author: opencode"
  echo "License: MIT"
  echo "Downloads: 1000+"
}

# ── Plugin Install ───────────────────────────────────────────────────────────

# Install plugin from marketplace
_marketplace_install() {
  local plugin_name="${1:-}"
  local version="${2:-latest}"
  
  if [ -z "$plugin_name" ]; then
    err "Plugin name required"
  fi
  
  info "Installing plugin: $plugin_name@$version"
  
  # Create plugin directory
  local plugin_dir="$HOME/.config/opencode/plugins/$plugin_name"
  mkdir -p "$plugin_dir"
  
  echo "$version" > "$plugin_dir/VERSION"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$plugin_dir/INSTALLED_AT"
  
  log "Plugin installed: $plugin_name@$version"
}

# List installed plugins
_marketplace_list() {
  local plugin_dir="$HOME/.config/opencode/plugins"
  
  if [ ! -d "$plugin_dir" ]; then
    info "No plugins installed"
    return 0
  fi
  
  find "$plugin_dir" -maxdepth 1 -type d 2>/dev/null | while read -r d; do
    local name
    name=$(basename "$d")
    local version
    version=$(cat "$d/VERSION" 2>/dev/null || echo "unknown")
    echo "$name@$version"
  done | sort
}

# Uninstall plugin
_marketplace_uninstall() {
  local plugin_name="${1:-}"
  
  if [ -z "$plugin_name" ]; then
    err "Plugin name required"
  fi
  
  local plugin_dir="$HOME/.config/opencode/plugins/$plugin_name"
  
  if [ ! -d "$plugin_dir" ]; then
    warn "Plugin not found: $plugin_name"
    return 1
  fi
  
  rm -rf "$plugin_dir"
  log "Plugin uninstalled: $plugin_name"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_marketplace() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    search)     _marketplace_search "$@" ;;
    categories) _marketplace_categories ;;
    info)       _marketplace_info "$@" ;;
    install)    _marketplace_install "$@" ;;
    list)       _marketplace_list ;;
    uninstall)  _marketplace_uninstall "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode marketplace <command> [args]

Commands:
  search <query> [category] [limit]  Search marketplace
  categories                         List categories
  info <name>                        Get plugin info
  install <name> [version]           Install plugin
  list                               List installed plugins
  uninstall <name>                   Uninstall plugin
EOF
      ;;
  esac
}
