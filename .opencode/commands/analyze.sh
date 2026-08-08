#!/usr/bin/env bash
# SDD /analyze — cross-check constitution × spec × todo for divergence
set -euo pipefail
PROJECT_DIR="${1:-$(pwd)}"
CONST="$PROJECT_DIR/memory/constitution.md"
SPEC="$PROJECT_DIR/.opencode/spec.md"
TODO="$PROJECT_DIR/.opencode/todo.md"
issues=0
echo "# SDD Analysis Report"
for f in "$CONST" "$SPEC" "$TODO"; do
  if [ -f "$f" ]; then
    echo "  [OK] $(basename "$f") exists"
  else
    echo "  [MISSING] $(basename "$f")"
    issues=$((issues + 1))
  fi
done
if [ -f "$SPEC" ] && [ -f "$TODO" ]; then
  spec_frs=$(grep -oP 'FR-\d+' "$SPEC" 2>/dev/null | sort -u)
  for fr in $spec_frs; do
    if ! grep -q "$fr" "$TODO" 2>/dev/null; then
      echo "  [DIVERGENCE] $fr in spec but not in todo"
      issues=$((issues + 1))
    fi
  done
fi
echo "Total issues: $issues"
exit $issues
