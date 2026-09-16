#!/usr/bin/env bash
# src/lib/85-automation.sh — Task automation engine
# Part of Phase 3: Agent Harness
# shellcheck disable=SC2034
set -euo pipefail

AUTOMATION_DIR="${AUTOMATION_DIR:-$HOME/.config/opencode/automations}"
AUTOMATION_LOG="${AUTOMATION_DIR}/log.jsonl"

# ── Automation Management ────────────────────────────────────────────────────

# Create an automation
_automation_create() {
  local name="${1:-}"
  local trigger="${2:-}"
  local action="${3:-}"
  local schedule="${4:-}"
  
  if [ -z "$name" ]; then
    err "Automation name required"
  fi
  
  mkdir -p "$AUTOMATION_DIR"
  
  cat > "$AUTOMATION_DIR/$name.yaml" <<EOF
name: $name
trigger: $trigger
action: $action
schedule: $schedule
enabled: true
created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
  
  log "Automation created: $name"
}

# List automations
_automation_list() {
  if [ ! -d "$AUTOMATION_DIR" ]; then
    info "No automations"
    return 0
  fi
  
  find "$AUTOMATION_DIR" -name "*.yaml" -type f 2>/dev/null | while read -r f; do
    local name
    name=$(basename "$f" .yaml)
    local trigger
    trigger=$(grep "^trigger:" "$f" 2>/dev/null | sed 's/trigger: *//')
    echo "$name — trigger: $trigger"
  done | sort
}

# Run an automation
_automation_run() {
  local name="${1:-}"
  
  if [ -z "$name" ]; then
    err "Automation name required"
  fi
  
  local automation_file="$AUTOMATION_DIR/$name.yaml"
  
  if [ ! -f "$automation_file" ]; then
    err "Automation not found: $name"
  fi
  
  info "Running automation: $name"
  
  # Log execution
  echo "{\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"automation\": \"$name\", \"status\": \"started\"}" \
    >> "$AUTOMATION_LOG"
  
  # Execute action
  local action
  action=$(grep "^action:" "$automation_file" 2>/dev/null | sed 's/action: *//')
  
  if [ -n "$action" ]; then
    eval "$action" 2>&1 || true
  fi
  
  # Log completion
  echo "{\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"automation\": \"$name\", \"status\": \"completed\"}" \
    >> "$AUTOMATION_LOG"
  
  log "Automation completed: $name"
}

# Enable/disable automation
_automation_toggle() {
  local name="${1:-}"
  local enable="${2:-true}"
  
  if [ -z "$name" ]; then
    err "Automation name required"
  fi
  
  local automation_file="$AUTOMATION_DIR/$name.yaml"
  
  if [ ! -f "$automation_file" ]; then
    err "Automation not found: $name"
  fi
  
  if [ "$enable" = "true" ]; then
    sed -i 's/enabled: false/enabled: true/' "$automation_file"
    log "Automation enabled: $name"
  else
    sed -i 's/enabled: true/enabled: false/' "$automation_file"
    log "Automation disabled: $name"
  fi
}

# Delete automation
_automation_delete() {
  local name="${1:-}"
  
  if [ -z "$name" ]; then
    err "Automation name required"
  fi
  
  local automation_file="$AUTOMATION_DIR/$name.yaml"
  
  if [ ! -f "$automation_file" ]; then
    err "Automation not found: $name"
  fi
  
  rm -f "$automation_file"
  log "Automation deleted: $name"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_automation() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    create)  _automation_create "$@" ;;
    list)    _automation_list ;;
    run)     _automation_run "$@" ;;
    enable)  _automation_toggle "$1" true ;;
    disable) _automation_toggle "$1" false ;;
    delete)  _automation_delete "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode automation <command> [args]

Commands:
  create <name> <trigger> <action> [schedule]  Create automation
  list                                         List automations
  run <name>                                   Run automation
  enable <name>                                Enable automation
  disable <name>                               Disable automation
  delete <name>                                Delete automation
EOF
      ;;
  esac
}
