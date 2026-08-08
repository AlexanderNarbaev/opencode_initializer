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

# Test 5: setup.sh WSL2 DNS block has DRY_RUN guard (S1.4.1)
SETUP_SH="$PROJECT_DIR/setup.sh"
# The DNS block (lines ~391-397) must have DRY_RUN check before sudo
if sed -n '391,400p' "$SETUP_SH" | grep -q 'DRY_RUN' && \
   sed -n '391,400p' "$SETUP_SH" | grep -q 'skip WSL2 DNS'; then
  echo "PASS: setup.sh DNS block has DRY_RUN guard"
  PASS=$((PASS+1))
else
  echo "FAIL: setup.sh DNS block missing DRY_RUN guard"
  FAIL=$((FAIL+1))
fi

# Test 6: DNS block has elif branch (guard + conditional execution)
if sed -n '391,400p' "$SETUP_SH" | grep -q 'elif.*resolv.conf' && \
   sed -n '391,400p' "$SETUP_SH" | grep -q 'sudo tee.*resolv.conf'; then
  echo "PASS: DNS block has elif guard + sudo tee in conditional branch"
  PASS=$((PASS+1))
else
  echo "FAIL: DNS block missing elif guard or sudo tee"
  FAIL=$((FAIL+1))
fi

# Test 7: setup.sh DNS block references [DRY] in skip message
if grep -q '\[DRY\] skip WSL2 DNS' "$SETUP_SH"; then
  echo "PASS: DNS dry-run skip message uses [DRY] prefix"
  PASS=$((PASS + 1))
else
  echo "FAIL: DNS dry-run skip missing [DRY] prefix"
  FAIL=$((FAIL + 1))
fi

# ── S1.4.2: Extended assertions ───────────────────────────────────────────
echo "=== Extended DRY_RUN guard checks (S1.4.2) ==="

# Test 8: The DRY_RUN guard uses 'info' (not 'echo' or bare message)
# This ensures the message goes through the standard logging channel
if sed -n '391,400p' "$SETUP_SH" | grep -qE 'info.*\[DRY\].*skip WSL2 DNS'; then
  echo "PASS: DRY_RUN guard uses info() logging function"
  PASS=$((PASS + 1))
else
  echo "FAIL: DRY_RUN guard should use info() for [DRY] message"
  FAIL=$((FAIL + 1))
fi

# Test 9: sudo appears ONLY in elif branch (never on DRY_RUN path)
# Extract the if/elif/fi block, verify sudo only in elif
dns_block=$(sed -n '391,400p' "$SETUP_SH")
if echo "$dns_block" | grep -q 'elif.*resolv.conf' && \
   ! echo "$dns_block" | head -2 | grep -q 'sudo'; then
  echo "PASS: sudo only in elif branch, never on DRY_RUN path"
  PASS=$((PASS + 1))
else
  echo "FAIL: sudo should only appear in elif branch"
  FAIL=$((FAIL + 1))
fi

# Test 10: DRY_RUN guard in setup.sh matches 00-core.sh DRY_RUN pattern
# Both should use: [ "${DRY_RUN:-false}" = "true" ] → info/return pattern
SETUP_DRY_GUARD=$(sed -n '391,393p' "$SETUP_SH" | grep -c 'DRY_RUN.*true' 2>/dev/null) || true
SETUP_DRY_SKIP=$(sed -n '391,393p' "$SETUP_SH" | grep -ci 'skip WSL2 DNS' 2>/dev/null) || true
if [ "${SETUP_DRY_GUARD:-0}" -ge 1 ] && [ "${SETUP_DRY_SKIP:-0}" -ge 1 ]; then
  echo "PASS: setup.sh DRY_RUN guard + info skip message present"
  PASS=$((PASS + 1))
else
  echo "FAIL: setup.sh DRY_RUN guard or skip message missing (guard=$SETUP_DRY_GUARD skip=$SETUP_DRY_SKIP)"
  FAIL=$((FAIL + 1))
fi

# Test 11: Full DRY_RUN block structure: if → info → elif → sudo → fi
if sed -n '391,400p' "$SETUP_SH" | grep -q 'if.*DRY_RUN' && \
   sed -n '391,400p' "$SETUP_SH" | grep -q 'elif.*resolv.conf' && \
   sed -n '391,400p' "$SETUP_SH" | grep -q 'sudo tee.*resolv.conf' && \
   sed -n '391,400p' "$SETUP_SH" | grep -q '^fi$'; then
  echo "PASS: complete if/elif/fi structure around DNS fix"
  PASS=$((PASS + 1))
else
  echo "FAIL: incomplete if/elif/fi guard structure"
  FAIL=$((FAIL + 1))
fi

echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
