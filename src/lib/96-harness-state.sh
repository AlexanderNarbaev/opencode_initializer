#!/usr/bin/env bash
# src/lib/96-harness-state.sh — State management & checkpoints
# Part of Phase 4: AI-Native Development
# shellcheck disable=SC2034
set -euo pipefail

HARNESS_STATE_DIR="${HARNESS_STATE_DIR:-$HOME/.local/share/opencode/harness/state}"

# ── State Operations ─────────────────────────────────────────────────────────

# Save state
_harness_state_save() {
  local session_id="${1:-}"
  local state_data="${2:-}"
  
  if [ -z "$session_id" ]; then
    err "Session ID required"
  fi
  
  mkdir -p "$HARNESS_STATE_DIR"
  
  cat > "$HARNESS_STATE_DIR/$session_id.json" <<EOF
{
  "session_id": "$session_id",
  "state": "$state_data",
  "saved_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  
  log "State saved: $session_id"
}

# Load state
_harness_state_load() {
  local session_id="${1:-}"
  
  if [ -z "$session_id" ]; then
    err "Session ID required"
  fi
  
  local state_file="$HARNESS_STATE_DIR/$session_id.json"
  
  if [ ! -f "$state_file" ]; then
    echo ""
    return 1
  fi
  
  if command -v jq &>/dev/null; then
    jq -r '.state' "$state_file" 2>/dev/null
  fi
}

# List states
_harness_state_list() {
  if [ ! -d "$HARNESS_STATE_DIR" ]; then
    info "No states"
    return 0
  fi
  
  find "$HARNESS_STATE_DIR" -name "*.json" -type f 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      jq -r '"\(.session_id) — \(.saved_at)"' "$f" 2>/dev/null
    fi
  done | sort
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_harness_state() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    save)   _harness_state_save "$@" ;;
    load)   _harness_state_load "$@" ;;
    list)   _harness_state_list ;;
    help|*)
      cat <<'EOF'
Usage: opencode harness-state <command> [args]

Commands:
  save <session_id> <state>   Save state
  load <session_id>           Load state
  list                        List states
EOF
      ;;
  esac
}
