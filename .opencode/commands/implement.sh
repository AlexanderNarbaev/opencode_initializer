#!/usr/bin/env bash
# SDD /implement — find first pending task and show it
set -euo pipefail
PROJECT_DIR="${1:-$(pwd)}"
TODO="$PROJECT_DIR/.opencode/todo.md"
echo "# Next Task to Implement"
if [ -f "$TODO" ]; then
  next=$(grep -m1 '\- \[ \]' "$TODO" 2>/dev/null || true)
  if [ -n "$next" ]; then
    echo "$next"
  else
    echo "All tasks complete!"
  fi
else
  echo "todo.md not found — run /tasks first"
fi
