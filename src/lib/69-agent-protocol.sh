#!/usr/bin/env bash
# src/lib/69-agent-protocol.sh — Communication protocol for agents
# Part of Phase 0: Agent Orchestration
# shellcheck disable=SC2034
set -euo pipefail

AGENT_PROTOCOL_DIR="${AGENT_PROTOCOL_DIR:-$HOME/.local/share/opencode/agent-protocol}"
AGENT_PROTOCOL_INBOX="${AGENT_PROTOCOL_DIR}/inbox"
AGENT_PROTOCOL_OUTBOX="${AGENT_PROTOCOL_DIR}/outbox"

# ── Message Operations ───────────────────────────────────────────────────────

# Send a message to an agent
_agent_send() {
  local to_agent="${1:-}"
  local message_type="${2:-}"
  local payload="${3:-}"
  
  if [ -z "$to_agent" ] || [ -z "$message_type" ]; then
    err "Recipient and message type required"
  fi
  
  mkdir -p "$AGENT_PROTOCOL_OUTBOX/$to_agent"
  
  local message_id
  message_id=$(date +%Y%m%d-%H%M%S)-$$
  local message_file="$AGENT_PROTOCOL_OUTBOX/$to_agent/$message_id.json"
  
  cat > "$message_file" <<EOF
{
  "id": "$message_id",
  "from": "orchestrator",
  "to": "$to_agent",
  "type": "$message_type",
  "payload": "$payload",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "pending"
}
EOF
  
  log "Message sent to $to_agent: $message_type"
  echo "$message_id"
}

# Receive messages for an agent
_agent_receive() {
  local agent_name="${1:-}"
  
  if [ -z "$agent_name" ]; then
    err "Agent name required"
  fi
  
  local inbox_dir="$AGENT_PROTOCOL_INBOX/$agent_name"
  
  if [ ! -d "$inbox_dir" ]; then
    return 0
  fi
  
  # List pending messages
  find "$inbox_dir" -name "*.json" -type f 2>/dev/null | sort
}

# Acknowledge a message
_agent_ack() {
  local agent_name="${1:-}"
  local message_id="${2:-}"
  
  if [ -z "$agent_name" ] || [ -z "$message_id" ]; then
    err "Agent name and message ID required"
  fi
  
  local message_file="$AGENT_PROTOCOL_INBOX/$agent_name/$message_id.json"
  
  if [ ! -f "$message_file" ]; then
    warn "Message not found: $message_id"
    return 1
  fi
  
  # Mark as acknowledged
  if command -v jq &>/dev/null; then
    jq '.status = "acknowledged" | .acknowledged_at = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' \
      "$message_file" > "$message_file.tmp"
    mv "$message_file.tmp" "$message_file"
  fi
  
  log "Message acknowledged: $message_id"
}

# ── Protocol Handlers ────────────────────────────────────────────────────────

# Handle task delegation
_protocol_delegate() {
  local to_agent="${1:-}"
  local task="${2:-}"
  local priority="${3:-normal}"
  
  _agent_send "$to_agent" "task_delegate" "{\"task\": \"$task\", \"priority\": \"$priority\"}"
}

# Handle task completion
_protocol_complete() {
  local from_agent="${1:-}"
  local task_id="${2:-}"
  local result="${3:-}"
  
  _agent_send "orchestrator" "task_complete" "{\"agent\": \"$from_agent\", \"task_id\": \"$task_id\", \"result\": \"$result\"}"
}

# Handle status request
_protocol_status_request() {
  local to_agent="${1:-}"
  
  _agent_send "$to_agent" "status_request" "{}"
}

# Handle status response
_protocol_status_response() {
  local from_agent="${1:-}"
  local status="${2:-}"
  
  _agent_send "orchestrator" "status_response" "{\"agent\": \"$from_agent\", \"status\": \"$status\"}"
}

# ── Message Queue ────────────────────────────────────────────────────────────

# List pending messages
_message_queue() {
  local agent_name="${1:-}"
  
  if [ -z "$agent_name" ]; then
    err "Agent name required"
  fi
  
  local inbox_dir="$AGENT_PROTOCOL_INBOX/$agent_name"
  
  if [ ! -d "$inbox_dir" ]; then
    info "No messages for $agent_name"
    return 0
  fi
  
  find "$inbox_dir" -name "*.json" -type f 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      jq -r '"\(.id) \(.type) \(.status)"' "$f" 2>/dev/null
    else
      basename "$f" .json
    fi
  done
}

# Clear processed messages
_message_clear() {
  local agent_name="${1:-}"
  local status="${2:-acknowledged}"
  
  if [ -z "$agent_name" ]; then
    err "Agent name required"
  fi
  
  local inbox_dir="$AGENT_PROTOCOL_INBOX/$agent_name"
  
  if [ ! -d "$inbox_dir" ]; then
    return 0
  fi
  
  find "$inbox_dir" -name "*.json" -type f 2>/dev/null | while read -r f; do
    if command -v jq &>/dev/null; then
      local msg_status
      msg_status=$(jq -r '.status // "pending"' "$f" 2>/dev/null)
      if [ "$msg_status" = "$status" ]; then
        rm -f "$f"
      fi
    fi
  done
  
  log "Cleared $status messages for $agent_name"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_agent_protocol() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    send)       _agent_send "$@" ;;
    receive)    _agent_receive "$@" ;;
    ack)        _agent_ack "$@" ;;
    delegate)   _protocol_delegate "$@" ;;
    complete)   _protocol_complete "$@" ;;
    queue)      _message_queue "$@" ;;
    clear)      _message_clear "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode agent-protocol <command> [args]

Commands:
  send <to> <type> [payload]     Send a message
  receive <agent>                Receive messages
  ack <agent> <message_id>       Acknowledge a message
  delegate <agent> <task>        Delegate a task
  complete <agent> <task_id>     Report task completion
  queue <agent>                  List pending messages
  clear <agent> [status]         Clear processed messages
EOF
      ;;
  esac
}
