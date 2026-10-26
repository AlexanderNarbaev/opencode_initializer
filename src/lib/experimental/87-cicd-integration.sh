#!/usr/bin/env bash
# src/lib/87-cicd-integration.sh — CI/CD pipeline integration
# Part of Phase 3: Agent Harness
# shellcheck disable=SC2034
set -euo pipefail

CICD_DIR="${CICD_DIR:-$HOME/.config/opencode/cicd}"

# ── CI/CD Operations ─────────────────────────────────────────────────────────

# List CI/CD pipelines
_cicd_list() {
  local cicd_type="${1:-github}"
  
  case "$cicd_type" in
    github)
      if command -v gh &>/dev/null; then
        gh workflow list 2>/dev/null || echo "No GitHub workflows"
      else
        echo "GitHub CLI not available"
      fi
      ;;
    gitlab)
      echo "GitLab CI integration"
      ;;
    *)
      echo "Unknown CI/CD type: $cicd_type"
      ;;
  esac
}

# Trigger a pipeline
_cicd_trigger() {
  local pipeline="${1:-}"
  local branch="${2:-main}"
  local cicd_type="${3:-github}"
  
  if [ -z "$pipeline" ]; then
    err "Pipeline name required"
  fi
  
  info "Triggering pipeline: $pipeline (branch: $branch)"
  
  case "$cicd_type" in
    github)
      if command -v gh &>/dev/null; then
        gh workflow run "$pipeline" --ref "$branch" 2>/dev/null || {
          warn "Failed to trigger GitHub workflow"
          return 1
        }
      else
        warn "GitHub CLI not available"
        return 1
      fi
      ;;
    *)
      warn "Unsupported CI/CD type: $cicd_type"
      return 1
      ;;
  esac
  
  log "Pipeline triggered: $pipeline"
}

# Get pipeline status
_cicd_status() {
  local pipeline="${1:-}"
  local cicd_type="${2:-github}"
  
  if [ -z "$pipeline" ]; then
    err "Pipeline name required"
  fi
  
  case "$cicd_type" in
    github)
      if command -v gh &>/dev/null; then
        gh run list --workflow="$pipeline" --limit=1 2>/dev/null || echo "No runs"
      fi
      ;;
    *)
      echo "Unknown CI/CD type"
      ;;
  esac
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_cicd() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    list)     _cicd_list "$@" ;;
    trigger)  _cicd_trigger "$@" ;;
    status)   _cicd_status "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode cicd <command> [args]

Commands:
  list [type]                          List pipelines (github|gitlab)
  trigger <pipeline> [branch] [type]   Trigger a pipeline
  status <pipeline> [type]             Get pipeline status
EOF
      ;;
  esac
}
