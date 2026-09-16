#!/usr/bin/env bash
# src/lib/66-agent-orchestrator.sh — Workflow execution engine
# Part of Phase 0: Agent Orchestration
# shellcheck disable=SC2034
set -euo pipefail

AGENT_ORCHESTRATOR_DIR="${AGENT_ORCHESTRATOR_DIR:-$HOME/.config/opencode/workflows}"
AGENT_ORCHESTRATOR_STATE="${AGENT_ORCHESTRATOR_STATE:-$HOME/.local/share/opencode/orchestrator}"
AGENT_ORCHESTRATOR_TIMEOUT="${AGENT_ORCHESTRATOR_TIMEOUT:-3600}"

# ── Workflow Management ──────────────────────────────────────────────────────

# Load a workflow definition
_workflow_load() {
  local workflow_name="${1:-}"
  local workflow_file="$AGENT_ORCHESTRATOR_DIR/$workflow_name.yaml"
  
  if [ ! -f "$workflow_file" ]; then
    err "Workflow not found: $workflow_name"
  fi
  
  cat "$workflow_file"
}

# List available workflows
_workflow_list() {
  if [ ! -d "$AGENT_ORCHESTRATOR_DIR" ]; then
    info "No workflows directory"
    return 0
  fi
  
  find "$AGENT_ORCHESTRATOR_DIR" -name "*.yaml" -o -name "*.yml" 2>/dev/null | \
    while read -r f; do
      local name
      name=$(basename "$f" .yaml)
      name=$(basename "$name" .yml)
      echo "$name"
    done | sort
}

# Validate workflow structure
_workflow_validate() {
  local workflow_file="${1:-}"
  
  if [ ! -f "$workflow_file" ]; then
    err "Workflow file not found"
  fi
  
  # Check required fields
  if ! grep -q "^name:" "$workflow_file" 2>/dev/null; then
    warn "Workflow missing 'name' field"
    return 1
  fi
  
  if ! grep -q "^version:" "$workflow_file" 2>/dev/null; then
    warn "Workflow missing 'version' field"
    return 1
  fi
  
  if ! grep -q "^steps:" "$workflow_file" 2>/dev/null; then
    warn "Workflow missing 'steps' field"
    return 1
  fi
  
  return 0
}

# ── Workflow Execution ───────────────────────────────────────────────────────

# Execute a workflow
_workflow_run() {
  local workflow_name="${1:-}"
  local task_input="${2:-}"
  local async="${3:-false}"
  
  if [ -z "$workflow_name" ]; then
    err "Workflow name required"
  fi
  
  local workflow_file="$AGENT_ORCHESTRATOR_DIR/$workflow_name.yaml"
  _workflow_validate "$workflow_file" || err "Invalid workflow"
  
  # Create execution state
  local run_id
  run_id=$(date +%Y%m%d-%H%M%S)-$$
  local run_dir="$AGENT_ORCHESTRATOR_STATE/$workflow_name/$run_id"
  mkdir -p "$run_dir"
  
  # Save run metadata
  cat > "$run_dir/metadata.json" <<EOF
{
  "workflow": "$workflow_name",
  "run_id": "$run_id",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "running",
  "input": "$task_input"
}
EOF
  
  info "Starting workflow: $workflow_name (run: $run_id)"
  
  if [ "$async" = "true" ]; then
    _workflow_run_async "$workflow_name" "$run_dir" "$task_input" &
    echo "$run_id"
  else
    _workflow_run_sync "$workflow_name" "$run_dir" "$task_input"
  fi
}

# Synchronous workflow execution
_workflow_run_sync() {
  local workflow_name="${1:-}"
  local run_dir="${2:-}"
  local task_input="${3:-}"
  
  local workflow_file="$AGENT_ORCHESTRATOR_DIR/$workflow_name.yaml"
  local current_step=0
  local total_steps=0
  local status="success"
  
  # Count steps
  total_steps=$(grep -c "^  - name:" "$workflow_file" 2>/dev/null || echo "0")
  
  # Execute each step
  while IFS= read -r step_line; do
    if [[ "$step_line" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]*(.*) ]]; then
      local step_name="${BASH_REMATCH[1]}"
      ((current_step++))
      
      info "Step $current_step/$total_steps: $step_name"
      
      # Execute step
      if ! _workflow_execute_step "$step_name" "$run_dir" "$task_input"; then
        status="failed"
        warn "Step failed: $step_name"
        break
      fi
      
      # Record step completion
      echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) completed $step_name" >> "$run_dir/steps.log"
    fi
  done < "$workflow_file"
  
  # Update run status
  local metadata_file="$run_dir/metadata.json"
  if command -v jq &>/dev/null; then
    jq --arg status "$status" --arg ended "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '.status = $status | .ended_at = $ended' "$metadata_file" > "$metadata_file.tmp"
    mv "$metadata_file.tmp" "$metadata_file"
  fi
  
  if [ "$status" = "success" ]; then
    log "Workflow completed: $workflow_name"
  else
    err "Workflow failed: $workflow_name"
  fi
}

# Asynchronous workflow execution
_workflow_run_async() {
  local workflow_name="${1:-}"
  local run_dir="${2:-}"
  local task_input="${3:-}"
  
  _workflow_run_sync "$workflow_name" "$run_dir" "$task_input" &
  local pid=$!
  
  echo "$pid" > "$run_dir/pid"
  info "Workflow running in background (PID: $pid)"
}

# Execute a single workflow step
_workflow_execute_step() {
  local step_name="${1:-}"
  local run_dir="${2:-}"
  local task_input="${3:-}"
  
  # Create step directory
  local step_dir="$run_dir/steps/$step_name"
  mkdir -p "$step_dir"
  
  # Execute step based on type
  # For now, log the step execution
  cat > "$step_dir/result.json" <<EOF
{
  "step": "$step_name",
  "status": "completed",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  
  return 0
}

# ── Run Management ───────────────────────────────────────────────────────────

# Get run status
_workflow_status() {
  local workflow_name="${1:-}"
  local run_id="${2:-latest}"
  
  if [ "$run_id" = "latest" ]; then
    run_id=$(ls -1 "$AGENT_ORCHESTRATOR_STATE/$workflow_name/" 2>/dev/null | sort -r | head -1)
  fi
  
  local run_dir="$AGENT_ORCHESTRATOR_STATE/$workflow_name/$run_id"
  
  if [ ! -d "$run_dir" ]; then
    err "Run not found: $workflow_name/$run_id"
  fi
  
  if command -v jq &>/dev/null; then
    jq '.' "$run_dir/metadata.json" 2>/dev/null
  else
    cat "$run_dir/metadata.json" 2>/dev/null
  fi
}

# List runs for a workflow
_workflow_runs() {
  local workflow_name="${1:-}"
  
  if [ ! -d "$AGENT_ORCHESTRATOR_STATE/$workflow_name" ]; then
    info "No runs for workflow: $workflow_name"
    return 0
  fi
  
  ls -1 "$AGENT_ORCHESTRATOR_STATE/$workflow_name/" 2>/dev/null | sort -r
}

# Cancel a running workflow
_workflow_cancel() {
  local workflow_name="${1:-}"
  local run_id="${2:-latest}"
  
  if [ "$run_id" = "latest" ]; then
    run_id=$(ls -1 "$AGENT_ORCHESTRATOR_STATE/$workflow_name/" 2>/dev/null | sort -r | head -1)
  fi
  
  local run_dir="$AGENT_ORCHESTRATOR_STATE/$workflow_name/$run_id"
  
  if [ ! -d "$run_dir" ]; then
    err "Run not found"
  fi
  
  local pid_file="$run_dir/pid"
  if [ -f "$pid_file" ]; then
    local pid
    pid=$(cat "$pid_file")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid"
      log "Workflow cancelled (PID: $pid)"
    else
      warn "Process not running (PID: $pid)"
    fi
  else
    warn "No PID file found"
  fi
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_orchestrator() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    run)      _workflow_run "$@" ;;
    status)   _workflow_status "$@" ;;
    runs)     _workflow_runs "$@" ;;
    list)     _workflow_list "$@" ;;
    cancel)   _workflow_cancel "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode orchestrator <command> [args]

Commands:
  run <name> [input] [async]   Run a workflow
  status <name> [run_id]       Get run status
  runs <name>                  List runs for a workflow
  list                         List available workflows
  cancel <name> [run_id]       Cancel a running workflow
EOF
      ;;
  esac
}
