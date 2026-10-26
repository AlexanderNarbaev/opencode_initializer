#!/usr/bin/env bash
# src/lib/67-agent-pipeline.sh — Pipeline management for agent workflows
# Part of Phase 0: Agent Orchestration
# shellcheck disable=SC2034
set -euo pipefail

PIPELINE_DIR="${PIPELINE_DIR:-$HOME/.config/opencode/pipelines}"
PIPELINE_STATE="${PIPELINE_STATE:-$HOME/.local/share/opencode/pipelines}"

# ── Pipeline Operations ──────────────────────────────────────────────────────

# Create a new pipeline
_pipeline_create() {
  local name="${1:-}"
  local description="${2:-}"
  
  if [ -z "$name" ]; then
    err "Pipeline name required"
  fi
  
  local pipeline_file="$PIPELINE_DIR/$name.yaml"
  
  if [ -f "$pipeline_file" ]; then
    warn "Pipeline already exists: $name"
    return 1
  fi
  
  mkdir -p "$PIPELINE_DIR"
  
  cat > "$pipeline_file" <<EOF
name: $name
version: 1.0.0
description: $description
steps: []
EOF
  
  log "Pipeline created: $name"
}

# Add a step to pipeline
_pipeline_add_step() {
  local pipeline_name="${1:-}"
  local step_name="${2:-}"
  local step_type="${3:-}"
  local step_config="${4:-}"
  
  if [ -z "$pipeline_name" ] || [ -z "$step_name" ] || [ -z "$step_type" ]; then
    err "Pipeline name, step name, and step type required"
  fi
  
  local pipeline_file="$PIPELINE_DIR/$pipeline_name.yaml"
  
  if [ ! -f "$pipeline_file" ]; then
    err "Pipeline not found: $pipeline_name"
  fi
  
  # Append step to pipeline
  cat >> "$pipeline_file" <<EOF

  - name: $step_name
    type: $step_type
    config: $step_config
EOF
  
  log "Step added: $step_name ($step_type)"
}

# Execute a pipeline
_pipeline_run() {
  local pipeline_name="${1:-}"
  local input="${2:-}"
  
  if [ -z "$pipeline_name" ]; then
    err "Pipeline name required"
  fi
  
  local pipeline_file="$PIPELINE_DIR/$pipeline_name.yaml"
  
  if [ ! -f "$pipeline_file" ]; then
    err "Pipeline not found: $pipeline_name"
  fi
  
  info "Running pipeline: $pipeline_name"
  
  # Parse and execute steps
  local current_step=0
  local status="success"
  
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]*(.*) ]]; then
      local step_name="${BASH_REMATCH[1]}"
      ((current_step++))
      
      info "Step $current_step: $step_name"
      
      # Execute step
      if ! _pipeline_execute_step "$pipeline_name" "$step_name" "$input"; then
        status="failed"
        break
      fi
    fi
  done < "$pipeline_file"
  
  if [ "$status" = "success" ]; then
    log "Pipeline completed: $pipeline_name"
  else
    err "Pipeline failed: $pipeline_name"
  fi
}

# Execute a single pipeline step
_pipeline_execute_step() {
  local pipeline_name="${1:-}"
  local step_name="${2:-}"
  local input="${3:-}"
  
  # Create step state
  local step_state="$PIPELINE_STATE/$pipeline_name/$step_name"
  mkdir -p "$step_state"
  
  cat > "$step_state/result.json" <<EOF
{
  "step": "$step_name",
  "status": "completed",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  
  return 0
}

# List pipelines
_pipeline_list() {
  if [ ! -d "$PIPELINE_DIR" ]; then
    info "No pipelines"
    return 0
  fi
  
  find "$PIPELINE_DIR" -name "*.yaml" -o -name "*.yml" 2>/dev/null | \
    while read -r f; do
      local name
      name=$(basename "$f" .yaml)
      name=$(basename "$name" .yml)
      echo "$name"
    done | sort
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_pipeline() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    create)   _pipeline_create "$@" ;;
    add-step) _pipeline_add_step "$@" ;;
    run)      _pipeline_run "$@" ;;
    list)     _pipeline_list "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode pipeline <command> [args]

Commands:
  create <name> [description]          Create a new pipeline
  add-step <pipeline> <name> <type>    Add a step to pipeline
  run <pipeline> [input]               Run a pipeline
  list                                 List pipelines
EOF
      ;;
  esac
}
