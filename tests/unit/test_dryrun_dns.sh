#!/usr/bin/env bash
# Unit test: S5.1.1.3 — _set_dns() dry-run guard
# Structural test: verifies DRY_RUN guard exists in 00-core.sh
set -euo pipefail

PASS=0; FAIL=0

PROJECT_DIR="/home/alexandr-narbaev/Projects/opencode_initializer"
CORE="$PROJECT_DIR/src/lib/00-core.sh"

echo "=== Testing _set_dns() dry-run guard ==="

# Test 1: Source file exists
if [ -f "$CORE" ]; then
  echo "PASS: 00-core.sh exists"
  PASS=$((PASS+1))
else
  echo "FAIL: 00-core.sh not found"
  FAIL=$((FAIL+1))
  exit 1
fi

# Test 2: _set_dns function has DRY_RUN guard (any line between function start and first real command)
# Pattern: DRY_RUN check before sudo calls
if awk '/^_set_dns\(\)/,/^}/' "$CORE" | grep -q 'DRY_RUN'; then
  echo "PASS: _set_dns() has DRY_RUN guard"
  PASS=$((PASS+1))
else
  echo "FAIL: _set_dns() missing DRY_RUN guard"
  FAIL=$((FAIL+1))
fi

# Test 3: The guard returns/skips before sudo
if awk '/^_set_dns\(\)/,/^}/' "$CORE" | grep -qE 'DRY_RUN.*return 0'; then
  echo "PASS: DRY_RUN guard returns before sudo"
  PASS=$((PASS+1))
else
  echo "FAIL: DRY_RUN guard should return 0 to skip sudo"
  FAIL=$((FAIL+1))
fi

# Test 4: No rm -rf ~/.cache/opencode in setup.sh (S5.1.1.4)
if ! grep -q 'rm.*-rf.*\.cache/opencode' "$PROJECT_DIR/setup.sh"; then
  echo "PASS: setup.sh has no destructive ~/.cache/opencode removal"
  PASS=$((PASS+1))
else
  echo "FAIL: setup.sh still contains rm -rf ~/.cache/opencode"
  FAIL=$((FAIL+1))
fi

echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
