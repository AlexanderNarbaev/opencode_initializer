#!/usr/bin/env bash
# src/lib/89-security-policies.sh — OPA/Rego policy enforcement
# Part of Phase 3: Agent Harness
# shellcheck disable=SC2034
set -euo pipefail

SECURITY_POLICIES_DIR="${SECURITY_POLICIES_DIR:-$HOME/.config/opencode/security-policies}"

# ── Policy Operations ────────────────────────────────────────────────────────

# Create a security policy
_security_policy_create() {
  local name="${1:-}"
  local description="${2:-}"
  local rules="${3:-}"
  
  if [ -z "$name" ]; then
    err "Policy name required"
  fi
  
  mkdir -p "$SECURITY_POLICIES_DIR"
  
  cat > "$SECURITY_POLICIES_DIR/$name.json" <<EOF
{
  "name": "$name",
  "description": "$description",
  "rules": "$rules",
  "enabled": true,
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  
  log "Security policy created: $name"
}

# List security policies
_security_policy_list() {
  if [ ! -d "$SECURITY_POLICIES_DIR" ]; then
    info "No security policies"
    return 0
  fi
  
  find "$SECURITY_POLICIES_DIR" -name "*.json" -type f 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      jq -r '"\(.name) — \(.description) [\(if .enabled then "enabled" else "disabled" end)]"' "$f" 2>/dev/null
    fi
  done | sort
}

# Check policy compliance
_security_policy_check() {
  local action="${1:-}"
  local resource="${2:-}"
  
  if [ ! -d "$SECURITY_POLICIES_DIR" ]; then
    return 0
  fi
  
  local allowed=true
  
  find "$SECURITY_POLICIES_DIR" -name "*.json" -type f 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      local enabled
      enabled=$(jq -r '.enabled // true' "$f" 2>/dev/null)
      
      if [ "$enabled" = "true" ]; then
        local rules
        rules=$(jq -r '.rules // ""' "$f" 2>/dev/null)
        
        # Simple rule matching
        if echo "$rules" | grep -qi "block.*$action"; then
          warn "Action blocked by policy: $(jq -r '.name' "$f")"
          allowed=false
        fi
      fi
    fi
  done
  
  if [ "$allowed" = "false" ]; then
    return 1
  fi
  
  return 0
}

# Enable/disable policy
_security_policy_toggle() {
  local name="${1:-}"
  local enable="${2:-true}"
  
  if [ -z "$name" ]; then
    err "Policy name required"
  fi
  
  local policy_file="$SECURITY_POLICIES_DIR/$name.json"
  
  if [ ! -f "$policy_file" ]; then
    err "Policy not found: $name"
  fi
  
  if command -v jq &>/dev/null; then
    jq --argjson enabled "$enable" '.enabled = $enabled' \
      "$policy_file" > "$policy_file.tmp"
    mv "$policy_file.tmp" "$policy_file"
  fi
  
  log "Policy $([ "$enable" = "true" ] && echo "enabled" || echo "disabled"): $name"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_security_policy() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    create)  _security_policy_create "$@" ;;
    list)    _security_policy_list ;;
    check)   _security_policy_check "$@" ;;
    enable)  _security_policy_toggle "$1" true ;;
    disable) _security_policy_toggle "$1" false ;;
    help|*)
      cat <<'EOF'
Usage: opencode security-policy <command> [args]

Commands:
  create <name> [description] [rules]  Create policy
  list                                 List policies
  check <action> [resource]            Check policy compliance
  enable <name>                        Enable policy
  disable <name>                       Disable policy
EOF
      ;;
  esac
}
