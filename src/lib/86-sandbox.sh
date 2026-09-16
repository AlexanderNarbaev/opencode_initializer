#!/usr/bin/env bash
# src/lib/86-sandbox.sh — Agent isolation (Docker, MicroVM)
# Part of Phase 3: Agent Harness
# shellcheck disable=SC2034
set -euo pipefail

SANDBOX_DIR="${SANDBOX_DIR:-$HOME/.config/opencode/sandbox}"
SANDBOX_POLICIES="${SANDBOX_DIR}/policies.json"

# ── Sandbox Management ───────────────────────────────────────────────────────

# Create a sandbox
_sandbox_create() {
  local name="${1:-}"
  local isolation="${2:-docker}"
  local policy="${3:-default}"
  
  if [ -z "$name" ]; then
    err "Sandbox name required"
  fi
  
  mkdir -p "$SANDBOX_DIR"
  
  cat > "$SANDBOX_DIR/$name.json" <<EOF
{
  "name": "$name",
  "isolation": "$isolation",
  "policy": "$policy",
  "status": "created",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "resources": {
    "cpu": "2",
    "memory": "4Gi",
    "timeout": "30m"
  },
  "network": {
    "outbound": false,
    "allowed_domains": []
  },
  "filesystem": {
    "readonly": ["/etc", "/usr"],
    "writable": ["/tmp", "/workspace"]
  }
}
EOF
  
  log "Sandbox created: $name ($isolation)"
}

# List sandboxes
_sandbox_list() {
  if [ ! -d "$SANDBOX_DIR" ]; then
    info "No sandboxes"
    return 0
  fi
  
  find "$SANDBOX_DIR" -name "*.json" -type f 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      jq -r '"\(.name) (\(.isolation)) — \(.status)"' "$f" 2>/dev/null
    fi
  done | sort
}

# Start sandbox
_sandbox_start() {
  local name="${1:-}"
  
  if [ -z "$name" ]; then
    err "Sandbox name required"
  fi
  
  local sandbox_file="$SANDBOX_DIR/$name.json"
  
  if [ ! -f "$sandbox_file" ]; then
    err "Sandbox not found: $name"
  fi
  
  # Update status
  if command -v jq &>/dev/null; then
    jq '.status = "running" | .started_at = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' \
      "$sandbox_file" > "$sandbox_file.tmp"
    mv "$sandbox_file.tmp" "$sandbox_file"
  fi
  
  log "Sandbox started: $name"
}

# Stop sandbox
_sandbox_stop() {
  local name="${1:-}"
  
  if [ -z "$name" ]; then
    err "Sandbox name required"
  fi
  
  local sandbox_file="$SANDBOX_DIR/$name.json"
  
  if [ ! -f "$sandbox_file" ]; then
    err "Sandbox not found: $name"
  fi
  
  # Update status
  if command -v jq &>/dev/null; then
    jq '.status = "stopped" | .stopped_at = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' \
      "$sandbox_file" > "$sandbox_file.tmp"
    mv "$sandbox_file.tmp" "$sandbox_file"
  fi
  
  log "Sandbox stopped: $name"
}

# Delete sandbox
_sandbox_delete() {
  local name="${1:-}"
  
  if [ -z "$name" ]; then
    err "Sandbox name required"
  fi
  
  local sandbox_file="$SANDBOX_DIR/$name.json"
  
  if [ ! -f "$sandbox_file" ]; then
    err "Sandbox not found: $name"
  fi
  
  rm -f "$sandbox_file"
  log "Sandbox deleted: $name"
}

# Get sandbox info
_sandbox_info() {
  local name="${1:-}"
  
  if [ -z "$name" ]; then
    err "Sandbox name required"
  fi
  
  local sandbox_file="$SANDBOX_DIR/$name.json"
  
  if [ ! -f "$sandbox_file" ]; then
    err "Sandbox not found: $name"
  fi
  
  if command -v jq &>/dev/null; then
    jq '.' "$sandbox_file" 2>/dev/null
  fi
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_sandbox() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    create)  _sandbox_create "$@" ;;
    list)    _sandbox_list ;;
    start)   _sandbox_start "$@" ;;
    stop)    _sandbox_stop "$@" ;;
    delete)  _sandbox_delete "$@" ;;
    info)    _sandbox_info "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode sandbox <command> [args]

Commands:
  create <name> [isolation] [policy]  Create sandbox (docker|microvm)
  list                                List sandboxes
  start <name>                        Start sandbox
  stop <name>                         Stop sandbox
  delete <name>                       Delete sandbox
  info <name>                         Get sandbox info
EOF
      ;;
  esac
}
