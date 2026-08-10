#!/usr/bin/env bash
# Unit test: S5.1.1.3 — _set_dns() dry-run guard
# Structural test: verifies DRY_RUN guard exists in 00-core.sh
# v2: dynamic DNS block extraction (no hardcoded line numbers)
set -euo pipefail

PASS=0; FAIL=0

PROJECT_DIR="/home/alexandr-narbaev/Projects/opencode_initializer"
CORE="$PROJECT_DIR/src/lib/00-core.sh"
SETUP_SH="$PROJECT_DIR/setup.sh"

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
if ! grep -q 'rm.*-rf.*\.cache/opencode' "$SETUP_SH"; then
  echo "PASS: setup.sh has no destructive ~/.cache/opencode removal"
  PASS=$((PASS+1))
else
  echo "FAIL: setup.sh still contains rm -rf ~/.cache/opencode"
  FAIL=$((FAIL+1))
fi

# ── Dynamic DNS block extraction ──────────────────────────────────────────
# Find the DNS DRY_RUN guard block by pattern matching instead of hardcoded lines
DRY_DNS_LINE=$(grep -n '\[DRY\] skip WSL2 DNS' "$SETUP_SH" | head -1 | cut -d: -f1)
if [ -z "${DRY_DNS_LINE:-}" ] || [ "$DRY_DNS_LINE" -lt 2 ]; then
  echo "FAIL: cannot locate [DRY] skip WSL2 DNS line in setup.sh"
  FAIL=$((FAIL+1))
  echo "RESULTS: $PASS pass, $FAIL fail"
  exit 1
fi
# The 'if' line is immediately before the info message
DNS_IF_LINE=$((DRY_DNS_LINE - 1))
# Extract from the if line to the next 'fi' (the DNS guard block)
DNS_BLOCK=$(tail -n "+$DNS_IF_LINE" "$SETUP_SH" | awk '/^[[:space:]]*fi[[:space:]]*$/{print; exit} {print}')

# Verify we got a meaningful block (at least 4 lines: if/info/elif/fi)
BLOCK_LINES=$(echo "$DNS_BLOCK" | wc -l)
if [ "${BLOCK_LINES:-0}" -lt 4 ]; then
  echo "FAIL: DNS block extraction returned only $BLOCK_LINES lines (expected >=4)"
  FAIL=$((FAIL+1))
  echo "RESULTS: $PASS pass, $FAIL fail"
  exit 1
fi
echo "INFO: extracted DNS DRY_RUN guard block ($BLOCK_LINES lines, starting at line $DNS_IF_LINE)"

# Test 5: setup.sh WSL2 DNS block has DRY_RUN guard (S1.4.1)
if echo "$DNS_BLOCK" | grep -q 'DRY_RUN' && \
   echo "$DNS_BLOCK" | grep -q 'skip WSL2 DNS'; then
  echo "PASS: setup.sh DNS block has DRY_RUN guard"
  PASS=$((PASS+1))
else
  echo "FAIL: setup.sh DNS block missing DRY_RUN guard"
  FAIL=$((FAIL+1))
fi

# Test 6: DNS block has elif branch (guard + conditional execution)
if echo "$DNS_BLOCK" | grep -q 'elif.*resolv.conf' && \
   echo "$DNS_BLOCK" | grep -q 'sudo tee.*resolv.conf'; then
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
if echo "$DNS_BLOCK" | grep -qE 'info.*\[DRY\].*skip WSL2 DNS'; then
  echo "PASS: DRY_RUN guard uses info() logging function"
  PASS=$((PASS + 1))
else
  echo "FAIL: DRY_RUN guard should use info() for [DRY] message"
  FAIL=$((FAIL + 1))
fi

# Test 9: sudo appears ONLY in elif branch (never on DRY_RUN path)
# Check that the first 2 lines (if + info) don't contain 'sudo'
if echo "$DNS_BLOCK" | grep -q 'elif.*resolv.conf' && \
   ! echo "$DNS_BLOCK" | head -2 | grep -q 'sudo'; then
  echo "PASS: sudo only in elif branch, never on DRY_RUN path"
  PASS=$((PASS + 1))
else
  echo "FAIL: sudo should only appear in elif branch"
  FAIL=$((FAIL + 1))
fi

# Test 10: DRY_RUN guard in setup.sh matches 00-core.sh DRY_RUN pattern
# Both should use: [ "${DRY_RUN:-false}" = "true" ] → info/return pattern
SETUP_DRY_GUARD=$(echo "$DNS_BLOCK" | head -3 | grep -c 'DRY_RUN.*true' 2>/dev/null) || true
SETUP_DRY_SKIP=$(echo "$DNS_BLOCK" | head -3 | grep -ci 'skip WSL2 DNS' 2>/dev/null) || true
if [ "${SETUP_DRY_GUARD:-0}" -ge 1 ] && [ "${SETUP_DRY_SKIP:-0}" -ge 1 ]; then
  echo "PASS: setup.sh DRY_RUN guard + info skip message present"
  PASS=$((PASS + 1))
else
  echo "FAIL: setup.sh DRY_RUN guard or skip message missing (guard=$SETUP_DRY_GUARD skip=$SETUP_DRY_SKIP)"
  FAIL=$((FAIL + 1))
fi

# Test 11: Full DRY_RUN block structure: if → info → elif → sudo → fi
if echo "$DNS_BLOCK" | grep -q 'if.*DRY_RUN' && \
   echo "$DNS_BLOCK" | grep -q 'elif.*resolv.conf' && \
   echo "$DNS_BLOCK" | grep -q 'sudo tee.*resolv.conf' && \
   echo "$DNS_BLOCK" | grep -q '^[[:space:]]*fi[[:space:]]*$'; then
  echo "PASS: complete if/elif/fi structure around DNS fix"
  PASS=$((PASS + 1))
else
  echo "FAIL: incomplete if/elif/fi guard structure"
  FAIL=$((FAIL + 1))
fi

echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
