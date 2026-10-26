#!/usr/bin/env bash
# src/lib/104-pla-verify.sh — Verification layer
# Part of Phase 5: Ecosystem Integration
# shellcheck disable=SC2034
set -euo pipefail

# ── Verification Operations ──────────────────────────────────────────────────

# Verify output format
_pla_verify_format() {
  local data="${1:-}"
  local format="${2:-json}"
  
  case "$format" in
    json)
      if echo "$data" | jq '.' &>/dev/null; then
        echo "Valid JSON"
        return 0
      else
        echo "Invalid JSON"
        return 1
      fi
      ;;
    yaml)
      if echo "$data" | yq '.' &>/dev/null; then
        echo "Valid YAML"
        return 0
      else
        echo "Invalid YAML"
        return 1
      fi
      ;;
    *)
      echo "Unknown format: $format"
      return 1
      ;;
  esac
}

# Verify completeness
_pla_verify_complete() {
  local data="${1:-}"
  local required_fields="${2:-}"
  
  if [ -z "$required_fields" ]; then
    echo "No required fields specified"
    return 0
  fi
  
  local missing=0
  for field in $required_fields; do
    if ! echo "$data" | grep -qi "$field"; then
      echo "Missing field: $field"
      ((missing++))
    fi
  done
  
  if [ "$missing" -eq 0 ]; then
    echo "All required fields present"
    return 0
  else
    echo "$missing fields missing"
    return 1
  fi
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_pla_verify() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    format)   _pla_verify_format "$@" ;;
    complete) _pla_verify_complete "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode pla-verify <command> [args]

Commands:
  format <data> <format>              Verify output format
  complete <data> <required_fields>   Verify completeness
EOF
      ;;
  esac
}
