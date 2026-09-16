#!/usr/bin/env bash
# src/lib/100-harness-subagents.sh — Subagent orchestration
# Part of Phase 4: AI-Native Development
# shellcheck disable=SC2034
set -euo pipefail

HARNESS_SUBAGENTS_DIR="${HARNESS_SUBAGENTS_DIR:-$HOME/.local/share/opencode/harness/subagents}"

# ── Subagent Operations ──────────────────────────────────────────────────────

# Create a subagent
_harness_subagent_create() {
  local name="${1:-}"
  local type="${2:-}"
  local task="${3:-}"
  
  if [ -z "$name" ]; then
    err "Subagent name required"
  fi
  
  mkdir -p "$HARNESS_SUBAGENTS_DIR"
  
  cat > "$HARNESS_SUBAGENTS_DIR/$name.json" <<EOF
{
  "name": "$name",
  "type": "$type",
  "task": "$task",
  "status": "created",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  
  log "Subagent created: $name ($type)"
}

# List subagents
_harness_subagent_list() {
  if [ ! -d "$HARNESS_SUBAGENTS_DIR" ]; then
    info "No subagents"
    return 0
  fi
  
  find "$HARNESS_SUBAGENTS_DIR" -name "*.json" -type f 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      jq -r '"\(.name) (\(.type)) — \(.status)"' "$f" 2>/dev/null
    fi
  done | sort
}

# Get subagent status
_harness_subagent_status() {
  local name="${1:-}"
  
  if [ -z "$name" ]; then
    err "Subagent name required"
  fi
  
  local subagent_file="$HARNESS_SUBAGENTS_DIR/$name.json"
  
  if [ ! -f "$subagent_file" ]; then
    err "Subagent not found: $name"
  fi
  
  if command -v jq &>/dev/null; then
    jq '.' "$subagent_file" 2>/dev/null
  fi
}

# Update subagent status
_harness_subagent_update() {
  local name="${1:-}"
  local status="${2:-}"
  local result="${3:-}"
  
  if [ -z "$name" ]; then
    err "Subagent name required"
  fi
  
  local subagent_file="$HARNESS_SUBAGENTS_DIR/$name.json"
  
  if [ ! -f "$subagent_file" ]; then
    err "Subagent not found: $name"
  fi
  
  if command -v jq &>/dev/null; then
    jq --arg status "$status" --arg result "$result" \
      '.status = $status | .result = $result | .updated_at = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' \
      "$subagent_file" > "$subagent_file.tmp"
    mv "$subagent_file.tmp" "$subagent_file"
  fi
  
  log "Subagent updated: $name → $status"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_harness_subagents() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    create) _harness_subagent_create "$@" ;;
    list)   _harness_subagent_list ;;
    status) _harness_subagent_status "$@" ;;
    update) _harness_subagent_update "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode harness-subagents <command> [args]

Commands:
  create <name> <type> <task>   Create subagent
  list                          List subagents
  status <name>                 Get subagent status
  update <name> <status>        Update subagent status
EOF
      ;;
  esac
}
