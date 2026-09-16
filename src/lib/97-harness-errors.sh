#!/usr/bin/env bash
# src/lib/97-harness-errors.sh — Error handling (4 types)
# Part of Phase 4: AI-Native Development
# shellcheck disable=SC2034
set -euo pipefail

# ── Error Classification ─────────────────────────────────────────────────────

# Classify error type
_harness_error_classify() {
  local error="${1:-}"
  
  # Transient errors (retry)
  if echo "$error" | grep -qi "timeout\|rate.limit\|connection\|temporary"; then
    echo "transient"
    return 0
  fi
  
  # LLM-recoverable errors
  if echo "$error" | grep -qi "invalid\|malformed\|parse\|format"; then
    echo "recoverable"
    return 0
  fi
  
  # User-fixable errors
  if echo "$error" | grep -qi "permission\|auth\|credential\|access"; then
    echo "user_fixable"
    return 0
  fi
  
  # Unexpected errors
  echo "unexpected"
  return 0
}

# Handle error based on type
_harness_error_handle() {
  local error_type="${1:-}"
  local error_message="${2:-}"
  local retry_count="${3:-0}"
  local max_retries="${4:-3}"
  
  case "$error_type" in
    transient)
      if [ "$retry_count" -lt "$max_retries" ]; then
        warn "Transient error, retrying ($retry_count/$max_retries): $error_message"
        return 1  # Signal retry
      else
        err "Max retries exceeded: $error_message"
      fi
      ;;
    recoverable)
      warn "Recoverable error: $error_message"
      return 0  # Continue with degraded result
      ;;
    user_fixable)
      err "User action required: $error_message"
      ;;
    unexpected)
      err "Unexpected error: $error_message"
      ;;
  esac
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_harness_errors() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    classify) _harness_error_classify "$@" ;;
    handle)   _harness_error_handle "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode harness-errors <command> [args]

Commands:
  classify <error>                    Classify error type
  handle <type> <message> [retries]   Handle error
EOF
      ;;
  esac
}
