#!/usr/bin/env bash
# src/lib/102-pla-extract.sh — Extraction layer
# Part of Phase 5: Ecosystem Integration
# shellcheck disable=SC2034
set -euo pipefail

# ── Extraction Operations ────────────────────────────────────────────────────

# Extract data from file
_pla_extract_file() {
  local file="${1:-}"
  local pattern="${2:-}"
  
  if [ -z "$file" ] || [ ! -f "$file" ]; then
    err "File required"
  fi
  
  if [ -n "$pattern" ]; then
    grep -E "$pattern" "$file" 2>/dev/null
  else
    cat "$file"
  fi
}

# Extract structured data
_pla_extract_structured() {
  local file="${1:-}"
  local format="${2:-json}"
  
  if [ -z "$file" ] || [ ! -f "$file" ]; then
    err "File required"
  fi
  
  case "$format" in
    json)
      if command -v jq &>/dev/null; then
        jq '.' "$file" 2>/dev/null
      fi
      ;;
    yaml)
      if command -v yq &>/dev/null; then
        yq '.' "$file" 2>/dev/null
      fi
      ;;
    csv)
      cat "$file" 2>/dev/null
      ;;
    *)
      cat "$file" 2>/dev/null
      ;;
  esac
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_pla_extract() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    file)       _pla_extract_file "$@" ;;
    structured) _pla_extract_structured "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode pla-extract <command> [args]

Commands:
  file <file> [pattern]           Extract from file
  structured <file> [format]      Extract structured data (json|yaml|csv)
EOF
      ;;
  esac
}
