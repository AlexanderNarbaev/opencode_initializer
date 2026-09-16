#!/usr/bin/env bash
# src/lib/79-plugin-manager.sh — Plugin lifecycle management
# Part of Phase 2: Ecosystem Expansion
# shellcheck disable=SC2034
set -euo pipefail

PLUGIN_DIR="${PLUGIN_DIR:-$HOME/.config/opencode/plugins}"

# ── Plugin Operations ────────────────────────────────────────────────────────

# Enable a plugin
_plugin_enable() {
  local plugin_name="${1:-}"
  
  if [ -z "$plugin_name" ]; then
    err "Plugin name required"
  fi
  
  local plugin_path="$PLUGIN_DIR/$plugin_name"
  
  if [ ! -d "$plugin_path" ]; then
    err "Plugin not found: $plugin_name"
  fi
  
  touch "$plugin_path/ENABLED"
  log "Plugin enabled: $plugin_name"
}

# Disable a plugin
_plugin_disable() {
  local plugin_name="${1:-}"
  
  if [ -z "$plugin_name" ]; then
    err "Plugin name required"
  fi
  
  local plugin_path="$PLUGIN_DIR/$plugin_name"
  
  if [ ! -d "$plugin_path" ]; then
    err "Plugin not found: $plugin_name"
  fi
  
  rm -f "$plugin_path/ENABLED"
  log "Plugin disabled: $plugin_name"
}

# Check if plugin is enabled
_plugin_is_enabled() {
  local plugin_name="${1:-}"
  
  if [ -z "$plugin_name" ]; then
    err "Plugin name required"
  fi
  
  [ -f "$PLUGIN_DIR/$plugin_name/ENABLED" ]
}

# List enabled plugins
_plugin_list_enabled() {
  if [ ! -d "$PLUGIN_DIR" ]; then
    return 0
  fi
  
  find "$PLUGIN_DIR" -name "ENABLED" -type f 2>/dev/null | while read -r f; do
    basename "$(dirname "$f")"
  done | sort
}

# ── Plugin Configuration ─────────────────────────────────────────────────────

# Set plugin config
_plugin_config_set() {
  local plugin_name="${1:-}"
  local key="${2:-}"
  local value="${3:-}"
  
  if [ -z "$plugin_name" ] || [ -z "$key" ]; then
    err "Plugin name and key required"
  fi
  
  local config_file="$PLUGIN_DIR/$plugin_name/config.json"
  mkdir -p "$PLUGIN_DIR/$plugin_name"
  
  if [ ! -f "$config_file" ]; then
    echo '{}' > "$config_file"
  fi
  
  if command -v jq &>/dev/null; then
    jq --arg key "$key" --arg value "$value" \
      '.[$key] = $value' "$config_file" > "$config_file.tmp"
    mv "$config_file.tmp" "$config_file"
  fi
  
  log "Config set: $plugin_name.$key = $value"
}

# Get plugin config
_plugin_config_get() {
  local plugin_name="${1:-}"
  local key="${2:-}"
  
  if [ -z "$plugin_name" ]; then
    err "Plugin name required"
  fi
  
  local config_file="$PLUGIN_DIR/$plugin_name/config.json"
  
  if [ ! -f "$config_file" ]; then
    echo ""
    return 1
  fi
  
  if [ -n "$key" ]; then
    if command -v jq &>/dev/null; then
      jq -r --arg key "$key" '.[$key] // ""' "$config_file" 2>/dev/null
    fi
  else
    cat "$config_file" 2>/dev/null
  fi
}

# ── Plugin Info ──────────────────────────────────────────────────────────────

# Get plugin info
_plugin_info() {
  local plugin_name="${1:-}"
  
  if [ -z "$plugin_name" ]; then
    err "Plugin name required"
  fi
  
  local plugin_path="$PLUGIN_DIR/$plugin_name"
  
  if [ ! -d "$plugin_path" ]; then
    err "Plugin not found: $plugin_name"
  fi
  
  echo "Plugin: $plugin_name"
  echo "Version: $(cat "$plugin_path/VERSION" 2>/dev/null || echo 'unknown')"
  echo "Enabled: $(_plugin_is_enabled "$plugin_name" && echo 'yes' || echo 'no')"
  echo "Installed: $(cat "$plugin_path/INSTALLED_AT" 2>/dev/null || echo 'unknown')"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_plugin() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    enable)    _plugin_enable "$@" ;;
    disable)   _plugin_disable "$@" ;;
    enabled)   _plugin_list_enabled ;;
    config-set) _plugin_config_set "$@" ;;
    config-get) _plugin_config_get "$@" ;;
    info)      _plugin_info "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode plugin <command> [args]

Commands:
  enable <name>                 Enable a plugin
  disable <name>                Disable a plugin
  enabled                       List enabled plugins
  config-set <name> <key> <val> Set plugin config
  config-get <name> [key]       Get plugin config
  info <name>                   Get plugin info
EOF
      ;;
  esac
}
