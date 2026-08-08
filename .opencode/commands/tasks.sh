#!/usr/bin/env bash
# SDD /tasks — parse spec.md and todo.md, show status summary
set -euo pipefail
PROJECT_DIR="${1:-$(pwd)}"
SPEC="$PROJECT_DIR/.opencode/spec.md"
TODO="$PROJECT_DIR/.opencode/todo.md"
echo "# Tasks Summary"
if [ -f "$SPEC" ]; then
  fr_count=$(grep -c 'FR-' "$SPEC" 2>/dev/null || echo "0")
  sc_count=$(grep -c 'SC-' "$SPEC" 2>/dev/null || echo "0")
  echo "## From spec.md:"
  echo "  FR requirements: $fr_count"
  echo "  SC scenarios: $sc_count"
else
  echo "## spec.md: NOT FOUND"
fi
if [ -f "$TODO" ]; then
  done_count=$(grep -c '\[x\]' "$TODO" 2>/dev/null || echo "0")
  pending_count=$(grep -c '\- \[ \]' "$TODO" 2>/dev/null || echo "0")
  echo "## From todo.md:"
  echo "  Done: $done_count"
  echo "  Pending: $pending_count"
else
  echo "## todo.md: NOT FOUND"
fi
