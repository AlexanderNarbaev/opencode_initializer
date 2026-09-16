#!/usr/bin/env bash
# src/lib/92-harness-tools.sh — Tool registration & execution
# Part of Phase 4: AI-Native Development
# shellcheck disable=SC2034
set -euo pipefail

HARNESS_TOOLS_DIR="${HARNESS_TOOLS_DIR:-$HOME/.config/opencode/harness/tools}"

# ── Tool Registration ────────────────────────────────────────────────────────

# Register a tool
_harness_tool_register() {
  local tool_name="${1:-}"
  local tool_type="${2:-}"
  local tool_description="${3:-}"
  local tool_command="${4:-}"
  
  if [ -z "$tool_name" ]; then
    err "Tool name required"
  fi
  
  mkdir -p "$HARNESS_TOOLS_DIR"
  
  cat > "$HARNESS_TOOLS_DIR/$tool_name.json" <<EOF
{
  "name": "$tool_name",
  "type": "$tool_type",
  "description": "$tool_description",
  "command": "$tool_command",
  "registered_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "enabled": true
}
EOF
  
  log "Tool registered: $tool_name"
}

# List tools
_harness_tool_list() {
  if [ ! -d "$HARNESS_TOOLS_DIR" ]; then
    info "No tools registered"
    return 0
  fi
  
  find "$HARNESS_TOOLS_DIR" -name "*.json" -type f 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      jq -r '"\(.name) (\(.type)) — \(.description)"' "$f" 2>/dev/null
    fi
  done | sort
}

# Execute a tool
_harness_tool_run() {
  local tool_name="${1:-}"
  shift
  local args=("$@")
  
  if [ -z "$tool_name" ]; then
    err "Tool name required"
  fi
  
  local tool_file="$HARNESS_TOOLS_DIR/$tool_name.json"
  
  if [ ! -f "$tool_file" ]; then
    err "Tool not found: $tool_name"
  fi
  
  if command -v jq &>/dev/null; then
    local command
    command=$(jq -r '.command' "$tool_file" 2>/dev/null)
    
    if [ -n "$command" ]; then
      # shellcheck disable=SC2294
      eval "$command" "${args[@]}" 2>&1
    fi
  fi
}

# Enable/disable tool
_harness_tool_toggle() {
  local tool_name="${1:-}"
  local enable="${2:-true}"
  
  if [ -z "$tool_name" ]; then
    err "Tool name required"
  fi
  
  local tool_file="$HARNESS_TOOLS_DIR/$tool_name.json"
  
  if [ ! -f "$tool_file" ]; then
    err "Tool not found: $tool_name"
  fi
  
  if command -v jq &>/dev/null; then
    jq --argjson enabled "$enable" '.enabled = $enabled' \
      "$tool_file" > "$tool_file.tmp"
    mv "$tool_file.tmp" "$tool_file"
  fi
  
  log "Tool $([ "$enable" = "true" ] && echo "enabled" || echo "disabled"): $tool_name"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_harness_tools() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    register) _harness_tool_register "$@" ;;
    list)     _harness_tool_list ;;
    run)      _harness_tool_run "$@" ;;
    enable)   _harness_tool_toggle "$1" true ;;
    disable)  _harness_tool_toggle "$1" false ;;
    help|*)
      cat <<'EOF'
Usage: opencode harness-tools <command> [args]

Commands:
  register <name> <type> <desc> <cmd>  Register a tool
  list                                 List tools
  run <name> [args...]                 Execute a tool
  enable <name>                        Enable tool
  disable <name>                       Disable tool
EOF
      ;;
  esac
}
