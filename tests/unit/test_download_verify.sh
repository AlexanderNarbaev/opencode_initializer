#!/usr/bin/env bash
# Unit test: S5.1.2.x — _download_verify() supply-chain hardening
# Verifies: no curl|sh patterns, _download_verify exists, bash syntax
set -euo pipefail

PASS=0; FAIL=0
PROJECT_DIR="/home/alexandr-narbaev/Projects/opencode_initializer"

echo "=== Testing M5.1.2: Supply-Chain Hardening ==="

# Test 1: helpers.sh contains _download_verify function
if grep -q '^_download_verify()' "$PROJECT_DIR/src/lib/helpers.sh"; then
  echo "PASS: _download_verify() defined in helpers.sh"
  PASS=$((PASS+1))
else
  echo "FAIL: _download_verify() not found in helpers.sh"
  FAIL=$((FAIL+1))
fi

# Test 2: No curl|sh execution patterns in supply-chain files
for f in 29-mise.sh 28-devbox.sh 14-shokunin.sh; do
  # Count lines with curl piping to shell (exclude comment lines starting with #)
  count=$(grep -n 'curl.*|.*sh\|curl.*|.*bash' "$PROJECT_DIR/src/lib/$f" 2>/dev/null | grep -v '^[0-9]*:[[:space:]]*#' | wc -l) || count=0
  if [ "${count:-0}" -eq 0 ]; then
    echo "PASS: $f — no curl|sh execution"
    PASS=$((PASS+1))
  else
    echo "FAIL: $f — has $count curl|sh execution pattern(s)"
    FAIL=$((FAIL+1))
  fi
done

# Test 3: 16-llm.sh WasmEdge uses _download_verify
if grep -q '_download_verify.*WasmEdge' "$PROJECT_DIR/src/lib/16-llm.sh"; then
  echo "PASS: 16-llm.sh WasmEdge uses _download_verify"
  PASS=$((PASS+1))
else
  echo "FAIL: 16-llm.sh WasmEdge still uses curl|sh"
  FAIL=$((FAIL+1))
fi

# Test 4: 04-zsh.sh Oh My Zsh uses _download_verify
if grep -q '_download_verify.*OMZ' "$PROJECT_DIR/src/lib/04-zsh.sh"; then
  echo "PASS: 04-zsh.sh uses _download_verify for OMZ"
  PASS=$((PASS+1))
else
  echo "FAIL: 04-zsh.sh still uses curl|sh for OMZ"
  FAIL=$((FAIL+1))
fi

# Test 5: All modified files pass bash -n
for f in helpers.sh 29-mise.sh 28-devbox.sh 16-llm.sh 14-shokunin.sh 04-zsh.sh; do
  if bash -n "$PROJECT_DIR/src/lib/$f" 2>/dev/null; then
    PASS=$((PASS+1))
  else
    echo "FAIL: $f — syntax error"
    FAIL=$((FAIL+1))
  fi
done

echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
