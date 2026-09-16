#!/usr/bin/env bash
# src/lib/91-harness-core.sh — Core orchestration loop (TAO/ReAct)
# Part of Phase 4: AI-Native Development
# shellcheck disable=SC2034
set -euo pipefail

HARNESS_CORE_DIR="${HARNESS_CORE_DIR:-$HOME/.config/opencode/harness}"
HARNESS_CORE_STATE="${HARNESS_CORE_STATE:-$HOME/.local/share/opencode/harness}"

# ── Orchestration Loop ───────────────────────────────────────────────────────

# Initialize harness
_harness_init() {
  mkdir -p "$HARNESS_CORE_DIR" "$HARNESS_CORE_STATE"
  
  cat > "$HARNESS_CORE_DIR/config.json" <<'EOF'
{
  "version": "1.0.0",
  "max_iterations": 50,
  "timeout": 3600,
  "verification": true,
  "guardrails": true
}
EOF
  
  log "Harness initialized"
}

# Run TAO loop (Thought-Action-Observation)
_harness_run() {
  local task="${1:-}"
  local max_iterations="${2:-50}"
  
  if [ -z "$task" ]; then
    err "Task required"
  fi
  
  info "Starting harness: $task"
  
  local iteration=0
  local status="running"
  local result=""
  
  while [ "$iteration" -lt "$max_iterations" ] && [ "$status" = "running" ]; do
    ((iteration++))
    info "Iteration $iteration/$max_iterations"
    
    # Thought phase
    local thought
    thought=$(_harness_think "$task" "$result")
    
    # Action phase
    local action_result
    action_result=$(_harness_act "$thought")
    
    # Observation phase
    local observation
    observation=$(_harness_observe "$action_result")
    
    # Check completion
    if _harness_check_complete "$observation"; then
      status="completed"
      result="$observation"
    else
      result="$observation"
    fi
  done
  
  if [ "$status" = "completed" ]; then
    log "Harness completed: $task"
  else
    warn "Harness reached max iterations"
  fi
  
  echo "$result"
}

# Think phase
_harness_think() {
  local task="${1:-}"
  local context="${2:-}"
  
  # Analyze task and context
  echo "Analyzing: $task"
}

# Act phase
_harness_act() {
  local thought="${1:-}"
  
  # Execute action based on thought
  echo "Executing: $thought"
}

# Observe phase
_harness_observe() {
  local action_result="${1:-}"
  
  # Observe result
  echo "Observed: $action_result"
}

# Check completion
_harness_check_complete() {
  local observation="${1:-}"
  
  # Simple completion check
  if echo "$observation" | grep -qi "completed\|done\|finished"; then
    return 0
  fi
  
  return 1
}

# ── Harness Status ───────────────────────────────────────────────────────────

# Get harness status
_harness_status() {
  if [ ! -f "$HARNESS_CORE_DIR/config.json" ]; then
    echo "Harness not initialized"
    return 1
  fi
  
  if command -v jq &>/dev/null; then
    jq '.' "$HARNESS_CORE_DIR/config.json" 2>/dev/null
  fi
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_harness() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    init)    _harness_init ;;
    run)     _harness_run "$@" ;;
    status)  _harness_status ;;
    help|*)
      cat <<'EOF'
Usage: opencode harness <command> [args]

Commands:
  init                    Initialize harness
  run <task> [max_iter]   Run TAO loop
  status                  Get harness status
EOF
      ;;
  esac
}
