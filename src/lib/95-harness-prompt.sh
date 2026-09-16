#!/usr/bin/env bash
# src/lib/95-harness-prompt.sh — Prompt construction (SCEI pattern)
# Part of Phase 4: AI-Native Development
# shellcheck disable=SC2034
set -euo pipefail

# ── Prompt Construction ──────────────────────────────────────────────────────

# Build SCEI prompt
_harness_prompt_build_scei() {
  local system="${1:-}"
  local context="${2:-}"
  local examples="${3:-}"
  local input="${4:-}"
  
  cat <<EOF
$system

$context

$examples

$input
EOF
}

# Build hierarchical prompt
_harness_prompt_build_hierarchical() {
  local system="${1:-}"
  local tools="${2:-}"
  local memory="${3:-}"
  local history="${4:-}"
  local input="${5:-}"
  
  cat <<EOF
$system

$tools

$memory

$history

$input
EOF
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_harness_prompt() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    scei)        _harness_prompt_build_scei "$@" ;;
    hierarchical) _harness_prompt_build_hierarchical "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode harness-prompt <command> [args]

Commands:
  scei <system> <context> <examples> <input>           Build SCEI prompt
  hierarchical <system> <tools> <memory> <history> <input>  Build hierarchical prompt
EOF
      ;;
  esac
}
