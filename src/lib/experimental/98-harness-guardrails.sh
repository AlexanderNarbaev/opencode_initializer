#!/usr/bin/env bash
# src/lib/98-harness-guardrails.sh — Input/output/tool guardrails
# Part of Phase 4: AI-Native Development
# shellcheck disable=SC2034
set -euo pipefail

HARNESS_GUARDRAILS_DIR="${HARNESS_GUARDRAILS_DIR:-$HOME/.config/opencode/harness/guardrails}"

# ── Guardrail Operations ─────────────────────────────────────────────────────

# Check input guardrail
_harness_guardrail_input() {
  local input="${1:-}"
  local rules="${2:-}"
  
  # Check for dangerous patterns
  if echo "$input" | grep -qi "rm -rf\|sudo\|eval\|exec"; then
    warn "Input guardrail triggered: dangerous pattern"
    return 1
  fi
  
  # Check for secrets
  if echo "$input" | grep -qi "password\|secret\|token\|key"; then
    warn "Input guardrail triggered: potential secret"
    return 1
  fi
  
  return 0
}

# Check output guardrail
_harness_guardrail_output() {
  local output="${1:-}"
  
  # Check for errors in output
  if echo "$output" | grep -qi "error\|exception\|failed"; then
    warn "Output guardrail triggered: error detected"
    return 1
  fi
  
  return 0
}

# Check tool guardrail
_harness_guardrail_tool() {
  local tool_name="${1:-}"
  local tool_args="${2:-}"
  
  # Check for dangerous tools
  local dangerous_tools=("rm" "mkfs" "dd" "format")
  for dangerous in "${dangerous_tools[@]}"; do
    if [ "$tool_name" = "$dangerous" ]; then
      warn "Tool guardrail triggered: dangerous tool"
      return 1
    fi
  done
  
  return 0
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_harness_guardrails() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    input)  _harness_guardrail_input "$@" ;;
    output) _harness_guardrail_output "$@" ;;
    tool)   _harness_guardrail_tool "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode harness-guardrails <command> [args]

Commands:
  input <input> [rules]     Check input guardrail
  output <output>           Check output guardrail
  tool <name> [args]        Check tool guardrail
EOF
      ;;
  esac
}
