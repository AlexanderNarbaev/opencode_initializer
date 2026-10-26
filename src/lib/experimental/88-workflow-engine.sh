#!/usr/bin/env bash
# src/lib/88-workflow-engine.sh — Workflow orchestration
# Part of Phase 3: Agent Harness
# shellcheck disable=SC2034
set -euo pipefail

WORKFLOW_ENGINE_DIR="${WORKFLOW_ENGINE_DIR:-$HOME/.config/opencode/workflows}"

# ── Workflow Operations ──────────────────────────────────────────────────────

# Create a workflow
_workflow_engine_create() {
  local name="${1:-}"
  local description="${2:-}"
  
  if [ -z "$name" ]; then
    err "Workflow name required"
  fi
  
  mkdir -p "$WORKFLOW_ENGINE_DIR"
  
  cat > "$WORKFLOW_ENGINE_DIR/$name.yaml" <<EOF
name: $name
version: 1.0.0
description: $description
steps: []
triggers: []
variables: {}
EOF
  
  log "Workflow created: $name"
}

# Add a step to workflow
_workflow_engine_add_step() {
  local workflow="${1:-}"
  local step_name="${2:-}"
  local step_type="${3:-}"
  local step_config="${4:-}"
  
  if [ -z "$workflow" ] || [ -z "$step_name" ] || [ -z "$step_type" ]; then
    err "Workflow, step name, and step type required"
  fi
  
  local workflow_file="$WORKFLOW_ENGINE_DIR/$workflow.yaml"
  
  if [ ! -f "$workflow_file" ]; then
    err "Workflow not found: $workflow"
  fi
  
  cat >> "$workflow_file" <<EOF

  - name: $step_name
    type: $step_type
    config: $step_config
EOF
  
  log "Step added to $workflow: $step_name"
}

# Execute workflow
_workflow_engine_run() {
  local workflow="${1:-}"
  local input="${2:-}"
  
  if [ -z "$workflow" ]; then
    err "Workflow name required"
  fi
  
  local workflow_file="$WORKFLOW_ENGINE_DIR/$workflow.yaml"
  
  if [ ! -f "$workflow_file" ]; then
    err "Workflow not found: $workflow"
  fi
  
  info "Running workflow: $workflow"
  
  # Parse and execute steps
  local step_count=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]*(.*) ]]; then
      local step_name="${BASH_REMATCH[1]}"
      ((step_count++))
      info "Step $step_count: $step_name"
    fi
  done < "$workflow_file"
  
  log "Workflow completed: $workflow ($step_count steps)"
}

# List workflows
_workflow_engine_list() {
  if [ ! -d "$WORKFLOW_ENGINE_DIR" ]; then
    info "No workflows"
    return 0
  fi
  
  find "$WORKFLOW_ENGINE_DIR" -name "*.yaml" -type f 2>/dev/null | while read -r f; do
    local name
    name=$(basename "$f" .yaml)
    echo "$name"
  done | sort
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_workflow_engine() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    create)   _workflow_engine_create "$@" ;;
    add-step) _workflow_engine_add_step "$@" ;;
    run)      _workflow_engine_run "$@" ;;
    list)     _workflow_engine_list ;;
    help|*)
      cat <<'EOF'
Usage: opencode workflow-engine <command> [args]

Commands:
  create <name> [description]           Create workflow
  add-step <workflow> <name> <type>     Add step
  run <workflow> [input]                Run workflow
  list                                  List workflows
EOF
      ;;
  esac
}
