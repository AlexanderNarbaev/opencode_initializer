#!/usr/bin/env bash
# src/lib/81-integrations.sh — Integration framework
# Part of Phase 2: Ecosystem Expansion
# shellcheck disable=SC2034
set -euo pipefail

INTEGRATIONS_DIR="${INTEGRATIONS_DIR:-$HOME/.config/opencode/integrations}"

# ── Integration Registry ─────────────────────────────────────────────────────

# Register an integration
_integration_register() {
  local name="${1:-}"
  local type="${2:-}"
  local endpoint="${3:-}"
  local credentials="${4:-}"
  
  if [ -z "$name" ] || [ -z "$type" ]; then
    err "Integration name and type required"
  fi
  
  mkdir -p "$INTEGRATIONS_DIR"
  
  cat > "$INTEGRATIONS_DIR/$name.json" <<EOF
{
  "name": "$name",
  "type": "$type",
  "endpoint": "$endpoint",
  "credentials": "$credentials",
  "registered_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "active"
}
EOF
  
  log "Integration registered: $name ($type)"
}

# List integrations
_integration_list() {
  if [ ! -d "$INTEGRATIONS_DIR" ]; then
    info "No integrations"
    return 0
  fi
  
  find "$INTEGRATIONS_DIR" -name "*.json" -type f 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      jq -r '"\(.name) (\(.type)) — \(.status)"' "$f" 2>/dev/null
    fi
  done | sort
}

# Get integration info
_integration_info() {
  local name="${1:-}"
  
  if [ -z "$name" ]; then
    err "Integration name required"
  fi
  
  local config_file="$INTEGRATIONS_DIR/$name.json"
  
  if [ ! -f "$config_file" ]; then
    err "Integration not found: $name"
  fi
  
  if command -v jq &>/dev/null; then
    jq '.' "$config_file" 2>/dev/null
  fi
}

# Remove integration
_integration_remove() {
  local name="${1:-}"
  
  if [ -z "$name" ]; then
    err "Integration name required"
  fi
  
  local config_file="$INTEGRATIONS_DIR/$name.json"
  
  if [ ! -f "$config_file" ]; then
    err "Integration not found: $name"
  fi
  
  rm -f "$config_file"
  log "Integration removed: $name"
}

# ── Predefined Integrations ──────────────────────────────────────────────────

# Setup GitHub integration
_integration_github() {
  local token="${1:-}"
  
  if [ -z "$token" ]; then
    err "GitHub token required"
  fi
  
  _integration_register "github" "scm" "https://api.github.com" "$token"
  log "GitHub integration configured"
}

# Setup GitLab integration
_integration_gitlab() {
  local token="${1:-}"
  local url="${2:-https://gitlab.com}"
  
  if [ -z "$token" ]; then
    err "GitLab token required"
  fi
  
  _integration_register "gitlab" "scm" "$url" "$token"
  log "GitLab integration configured"
}

# Setup Slack integration
_integration_slack() {
  local webhook="${1:-}"
  
  if [ -z "$webhook" ]; then
    err "Slack webhook required"
  fi
  
  _integration_register "slack" "notification" "$webhook" ""
  log "Slack integration configured"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_integration() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    register) _integration_register "$@" ;;
    list)     _integration_list ;;
    info)     _integration_info "$@" ;;
    remove)   _integration_remove "$@" ;;
    github)   _integration_github "$@" ;;
    gitlab)   _integration_gitlab "$@" ;;
    slack)    _integration_slack "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode integration <command> [args]

Commands:
  register <name> <type> [endpoint] [credentials]  Register integration
  list                                              List integrations
  info <name>                                       Get integration info
  remove <name>                                     Remove integration
  github <token>                                    Setup GitHub
  gitlab <token> [url]                              Setup GitLab
  slack <webhook>                                   Setup Slack
EOF
      ;;
  esac
}
