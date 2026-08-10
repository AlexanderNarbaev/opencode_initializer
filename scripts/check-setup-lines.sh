#!/usr/bin/env bash
# Pre-commit check: ensure setup.sh line count matches README claim
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ACTUAL=$(wc -l < "$SCRIPT_DIR/setup.sh")
CLAIMED=$(grep -oE '[0-9]+-line orchestrator' "$SCRIPT_DIR/README.md" | head -1 | cut -d- -f1)

if [ "$ACTUAL" != "$CLAIMED" ]; then
  echo "ERROR: setup.sh is $ACTUAL lines but README claims $CLAIMED-line orchestrator"
  echo "Fix: update README.md to say ${ACTUAL}-line orchestrator"
  exit 1
fi
echo "OK: setup.sh=$ACTUAL, README=$CLAIMED"
