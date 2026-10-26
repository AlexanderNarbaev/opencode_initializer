#!/usr/bin/env bash
# src/lib/99-harness-verify.sh — Verification loops
# Part of Phase 4: AI-Native Development
# shellcheck disable=SC2034
set -euo pipefail

# ── Verification Operations ──────────────────────────────────────────────────

# Verify with tests
_harness_verify_tests() {
  local test_command="${1:-}"
  
  if [ -z "$test_command" ]; then
    err "Test command required"
  fi
  
  info "Running verification tests..."
  
  if eval "$test_command" 2>&1; then
    log "Tests passed"
    return 0
  else
    warn "Tests failed"
    return 1
  fi
}

# Verify with linter
_harness_verify_lint() {
  local lint_command="${1:-}"
  
  if [ -z "$lint_command" ]; then
    err "Lint command required"
  fi
  
  info "Running linter..."
  
  if eval "$lint_command" 2>&1; then
    log "Lint passed"
    return 0
  else
    warn "Lint failed"
    return 1
  fi
}

# Verify with type checker
_harness_verify_types() {
  local type_command="${1:-}"
  
  if [ -z "$type_command" ]; then
    err "Type check command required"
  fi
  
  info "Running type checker..."
  
  if eval "$type_command" 2>&1; then
    log "Type check passed"
    return 0
  else
    warn "Type check failed"
    return 1
  fi
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_harness_verify() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    tests) _harness_verify_tests "$@" ;;
    lint)  _harness_verify_lint "$@" ;;
    types) _harness_verify_types "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode harness-verify <command> [args]

Commands:
  tests <command>   Verify with tests
  lint <command>    Verify with linter
  types <command>   Verify with type checker
EOF
      ;;
  esac
}
