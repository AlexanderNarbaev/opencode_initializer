#!/usr/bin/env bash
# src/lib/90-secrets-manager.sh — Vault/secrets integration
# Part of Phase 3: Agent Harness
# shellcheck disable=SC2034
set -euo pipefail

SECRETS_DIR="${SECRETS_DIR:-$HOME/.config/opencode/secrets}"
SECRETS_VAULT="${SECRETS_VAULT:-$HOME/.config/opencode/vault.json}"

# ── Secrets Operations ───────────────────────────────────────────────────────

# Store a secret
_secrets_store() {
  local key="${1:-}"
  local value="${2:-}"
  local description="${3:-}"
  
  if [ -z "$key" ]; then
    err "Secret key required"
  fi
  
  mkdir -p "$SECRETS_DIR"
  
  # Encrypt value (base64 for now)
  local encrypted
  encrypted=$(echo -n "$value" | base64)
  
  cat > "$SECRETS_DIR/$key.secret" <<EOF
{
  "key": "$key",
  "value": "$encrypted",
  "description": "$description",
  "stored_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  
  log "Secret stored: $key"
}

# Retrieve a secret
_secrets_get() {
  local key="${1:-}"
  
  if [ -z "$key" ]; then
    err "Secret key required"
  fi
  
  local secret_file="$SECRETS_DIR/$key.secret"
  
  if [ ! -f "$secret_file" ]; then
    err "Secret not found: $key"
  fi
  
  if command -v jq &>/dev/null; then
    local encrypted
    encrypted=$(jq -r '.value' "$secret_file" 2>/dev/null)
    echo "$encrypted" | base64 -d
  fi
}

# List secrets
_secrets_list() {
  if [ ! -d "$SECRETS_DIR" ]; then
    info "No secrets"
    return 0
  fi
  
  find "$SECRETS_DIR" -name "*.secret" -type f 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      jq -r '"\(.key) — \(.description // "no description")"' "$f" 2>/dev/null
    fi
  done | sort
}

# Delete a secret
_secrets_delete() {
  local key="${1:-}"
  
  if [ -z "$key" ]; then
    err "Secret key required"
  fi
  
  local secret_file="$SECRETS_DIR/$key.secret"
  
  if [ ! -f "$secret_file" ]; then
    err "Secret not found: $key"
  fi
  
  rm -f "$secret_file"
  log "Secret deleted: $key"
}

# Rotate a secret
_secrets_rotate() {
  local key="${1:-}"
  local new_value="${2:-}"
  
  if [ -z "$key" ] || [ -z "$new_value" ]; then
    err "Secret key and new value required"
  fi
  
  # Get old description
  local secret_file="$SECRETS_DIR/$key.secret"
  local description=""
  
  if [ -f "$secret_file" ] && command -v jq &>/dev/null; then
    description=$(jq -r '.description // ""' "$secret_file" 2>/dev/null)
  fi
  
  # Store new value
  _secrets_store "$key" "$new_value" "$description"
  
  log "Secret rotated: $key"
}

# ── Environment Variables ────────────────────────────────────────────────────

# Export secrets as environment variables
_secrets_export() {
  if [ ! -d "$SECRETS_DIR" ]; then
    return 0
  fi
  
  find "$SECRETS_DIR" -name "*.secret" -type f 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      local key value
      key=$(jq -r '.key' "$f" 2>/dev/null)
      value=$(jq -r '.value' "$f" 2>/dev/null | base64 -d)
      echo "export $key=\"$value\""
    fi
  done
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_secrets() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    store)    _secrets_store "$@" ;;
    get)      _secrets_get "$@" ;;
    list)     _secrets_list ;;
    delete)   _secrets_delete "$@" ;;
    rotate)   _secrets_rotate "$@" ;;
    export)   _secrets_export ;;
    help|*)
      cat <<'EOF'
Usage: opencode secrets <command> [args]

Commands:
  store <key> <value> [description]  Store a secret
  get <key>                          Retrieve a secret
  list                               List secrets
  delete <key>                       Delete a secret
  rotate <key> <new_value>           Rotate a secret
  export                             Export as env vars
EOF
      ;;
  esac
}
