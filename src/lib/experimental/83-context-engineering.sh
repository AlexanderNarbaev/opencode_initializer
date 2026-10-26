#!/usr/bin/env bash
# src/lib/83-context-engineering.sh — Context optimization & engineering
# Part of Phase 3: Agent Harness
# shellcheck disable=SC2034
set -euo pipefail

CONTEXT_ENG_DIR="${CONTEXT_ENG_DIR:-$HOME/.config/opencode/context-engineering}"
CONTEXT_ENG_BUDGET="${CONTEXT_ENG_BUDGET:-100000}"

# ── Context Optimization ─────────────────────────────────────────────────────

# Optimize context for token budget
_context_optimize() {
  local input_file="${1:-}"
  local budget="${2:-$CONTEXT_ENG_BUDGET}"
  local strategy="${3:-compress}"
  
  if [ -z "$input_file" ]; then
    err "Input file required"
  fi
  
  if [ ! -f "$input_file" ]; then
    err "File not found: $input_file"
  fi
  
  local content
  content=$(cat "$input_file")
  local content_length=${#content}
  
  info "Context optimization: $content_length chars, budget: $budget tokens"
  
  if [ "$content_length" -le "$budget" ]; then
    echo "$content"
    return 0
  fi
  
  case "$strategy" in
    compress)
      _context_compress "$content" "$budget"
      ;;
    truncate)
      _context_truncate "$content" "$budget"
      ;;
    summarize)
      _context_summarize "$content" "$budget"
      ;;
    *)
      err "Unknown strategy: $strategy"
      ;;
  esac
}

# Compress context (remove redundancy)
_context_compress() {
  local content="${1:-}"
  local budget="${2:-100000}"
  
  # Remove duplicate lines
  local compressed
  compressed=$(echo "$content" | awk '!seen[$0]++')
  
  # Remove empty lines
  compressed=$(echo "$compressed" | sed '/^$/d')
  
  # Truncate if still over budget
  if [ ${#compressed} -gt "$budget" ]; then
    compressed=$(echo "$compressed" | head -c "$budget")
  fi
  
  echo "$compressed"
}

# Truncate context (keep beginning and end)
_context_truncate() {
  local content="${1:-}"
  local budget="${2:-100000}"
  
  local half=$((budget / 2))
  local beginning
  beginning=$(echo "$content" | head -c "$half")
  local ending
  ending=$(echo "$content" | tail -c "$half")
  
  echo "$beginning"
  echo "... [truncated] ..."
  echo "$ending"
}

# Summarize context (placeholder)
_context_summarize() {
  local content="${1:-}"
  local budget="${2:-100000}"
  
  # For now, just compress
  _context_compress "$content" "$budget"
}

# ── SCEI Pattern ─────────────────────────────────────────────────────────────

# Build SCEI prompt
_context_build_scei() {
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

# ── Context Analysis ─────────────────────────────────────────────────────────

# Analyze context usage
_context_analyze() {
  local input_file="${1:-}"
  
  if [ -z "$input_file" ] || [ ! -f "$input_file" ]; then
    err "Input file required"
  fi
  
  local content
  content=$(cat "$input_file")
  local chars=${#content}
  local lines
  lines=$(wc -l < "$input_file")
  local words
  words=$(wc -w < "$input_file")
  
  # Estimate tokens (rough: 1 token ≈ 4 chars)
  local tokens=$((chars / 4))
  
  echo "Context Analysis:"
  echo "  Characters: $chars"
  echo "  Lines: $lines"
  echo "  Words: $words"
  echo "  Estimated tokens: $tokens"
  echo "  Budget: $CONTEXT_ENG_BUDGET"
  
  if [ "$tokens" -gt "$CONTEXT_ENG_BUDGET" ]; then
    echo "  Status: OVER BUDGET"
  else
    echo "  Status: within budget"
  fi
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_context_engineering() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    optimize) _context_optimize "$@" ;;
    scei)     _context_build_scei "$@" ;;
    analyze)  _context_analyze "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode context-engineering <command> [args]

Commands:
  optimize <file> [budget] [strategy]  Optimize context (compress|truncate|summarize)
  scei <system> <context> <examples> <input>  Build SCEI prompt
  analyze <file>                       Analyze context usage
EOF
      ;;
  esac
}
