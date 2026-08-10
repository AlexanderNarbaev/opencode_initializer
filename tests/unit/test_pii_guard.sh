#!/usr/bin/env bash
# Unit test: 45-pii-guard.sh — PII detection, redaction, gate
set -euo pipefail

PASS=0; FAIL=0
PROJECT_DIR="/home/alexandr-narbaev/Projects/opencode_initializer"
PII_MODULE="$PROJECT_DIR/src/lib/45-pii-guard.sh"

echo "=== Testing 45-pii-guard.sh ==="

# Test 1: Module file exists and is syntactically valid
if [ -f "$PII_MODULE" ]; then
  echo "PASS: 45-pii-guard.sh exists"
  PASS=$((PASS+1))
else
  echo "FAIL: 45-pii-guard.sh not found"
  FAIL=$((FAIL+1))
  exit 1
fi

if bash -n "$PII_MODULE" 2>/dev/null; then
  echo "PASS: 45-pii-guard.sh syntax OK"
  PASS=$((PASS+1))
else
  echo "FAIL: 45-pii-guard.sh syntax error"
  FAIL=$((FAIL+1))
fi

# Source the module in a subshell to avoid polluting the test environment
run_pii_test() {
  (
    # Minimal stubs for dependencies (helpers.sh functions)
    warn() { echo "[WARN] $*" >&2; }
    log()  { echo "[LOG] $*" >&2; }
    info() { echo "[INFO] $*" >&2; }
    
    source "$PII_MODULE"
    "$@"
  )
}

# ── PII Scan Tests ──────────────────────────────────────────────────────────

# Test 3: _pii_scan detects email
SCAN_EMAIL=$(run_pii_test _pii_scan "contact user@example.com for info")
if [ "${SCAN_EMAIL:-0}" -ge 1 ]; then
  echo "PASS: _pii_scan detects email (found=$SCAN_EMAIL)"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_scan missed email"
  FAIL=$((FAIL+1))
fi

# Test 4: _pii_scan detects Russian phone (+7)
SCAN_PHONE=$(run_pii_test _pii_scan "call +79161234567 today")
if [ "${SCAN_PHONE:-0}" -ge 1 ]; then
  echo "PASS: _pii_scan detects +7 phone (found=$SCAN_PHONE)"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_scan missed +7 phone"
  FAIL=$((FAIL+1))
fi

# Test 5: _pii_scan detects Russian phone (8-prefix)
SCAN_PHONE8=$(run_pii_test _pii_scan "call 89161234567 today")
if [ "${SCAN_PHONE8:-0}" -ge 1 ]; then
  echo "PASS: _pii_scan detects 8-prefix phone (found=$SCAN_PHONE8)"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_scan missed 8-prefix phone"
  FAIL=$((FAIL+1))
fi

# Test 6: _pii_scan detects INN (10-digit)
SCAN_INN10=$(run_pii_test _pii_scan "INN: 7707083893 is valid")
if [ "${SCAN_INN10:-0}" -ge 1 ]; then
  echo "PASS: _pii_scan detects 10-digit INN (found=$SCAN_INN10)"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_scan missed 10-digit INN"
  FAIL=$((FAIL+1))
fi

# Test 7: _pii_scan detects INN (12-digit)
SCAN_INN12=$(run_pii_test _pii_scan "INN: 500100732259 is valid")
if [ "${SCAN_INN12:-0}" -ge 1 ]; then
  echo "PASS: _pii_scan detects 12-digit INN (found=$SCAN_INN12)"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_scan missed 12-digit INN"
  FAIL=$((FAIL+1))
fi

# Test 8: _pii_scan detects credit card
SCAN_CC=$(run_pii_test _pii_scan "card: 4111-1111-1111-1111")
if [ "${SCAN_CC:-0}" -ge 1 ]; then
  echo "PASS: _pii_scan detects credit card (found=$SCAN_CC)"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_scan missed credit card"
  FAIL=$((FAIL+1))
fi

# Test 9: _pii_scan detects API key (sk- prefix)
SCAN_API=$(run_pii_test _pii_scan "key: sk-abcdefghijklmnopqrstuvwxyz123456")
if [ "${SCAN_API:-0}" -ge 1 ]; then
  echo "PASS: _pii_scan detects API key (found=$SCAN_API)"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_scan missed API key"
  FAIL=$((FAIL+1))
fi

# Test 10: _pii_scan detects IP address
SCAN_IP=$(run_pii_test _pii_scan "host: 192.168.1.1 is internal")
if [ "${SCAN_IP:-0}" -ge 1 ]; then
  echo "PASS: _pii_scan detects IP address (found=$SCAN_IP)"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_scan missed IP address"
  FAIL=$((FAIL+1))
fi

# Test 11: _pii_scan returns 0 for clean text
SCAN_CLEAN=$(run_pii_test _pii_scan "this is clean text with no personal data")
if [ "${SCAN_CLEAN:-1}" -eq 0 ]; then
  echo "PASS: _pii_scan returns 0 for clean text"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_scan found PII in clean text (found=$SCAN_CLEAN)"
  FAIL=$((FAIL+1))
fi

# ── PII Redact Tests ────────────────────────────────────────────────────────

# Test 12: _pii_redact replaces email with mask
REDACT_EMAIL=$(run_pii_test _pii_redact "email: user@example.com")
if echo "$REDACT_EMAIL" | grep -q '\[REDACTED\]' && ! echo "$REDACT_EMAIL" | grep -q 'user@example.com'; then
  echo "PASS: _pii_redact masks email"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_redact did not mask email (got: $REDACT_EMAIL)"
  FAIL=$((FAIL+1))
fi

# Test 13: _pii_redact replaces phone with mask
REDACT_PHONE=$(run_pii_test _pii_redact "call +79161234567")
if echo "$REDACT_PHONE" | grep -q '\[REDACTED\]' && ! echo "$REDACT_PHONE" | grep -q '+79161234567'; then
  echo "PASS: _pii_redact masks phone"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_redact did not mask phone (got: $REDACT_PHONE)"
  FAIL=$((FAIL+1))
fi

# Test 14: _pii_redact preserves non-PII text
REDACT_CLEAN=$(run_pii_test _pii_redact "hello world")
if echo "$REDACT_CLEAN" | grep -q 'hello world' && ! echo "$REDACT_CLEAN" | grep -q '\[REDACTED\]'; then
  echo "PASS: _pii_redact preserves clean text"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_redact corrupted clean text (got: $REDACT_CLEAN)"
  FAIL=$((FAIL+1))
fi

# Test 15: PII registry has at least 8 patterns
PII_COUNT=$(run_pii_test 'echo ${#PII_NAMES[@]}')
if [ "${PII_COUNT:-0}" -ge 8 ]; then
  echo "PASS: PII registry has $PII_COUNT patterns (>=8)"
  PASS=$((PASS+1))
else
  echo "FAIL: PII registry has only $PII_COUNT patterns (<8)"
  FAIL=$((FAIL+1))
fi

# Test 16: _pii_scan detects SNILS
SCAN_SNILS=$(run_pii_test _pii_scan "SNILS: 123-456-789 01")
if [ "${SCAN_SNILS:-0}" -ge 1 ]; then
  echo "PASS: _pii_scan detects SNILS (found=$SCAN_SNILS)"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_scan missed SNILS"
  FAIL=$((FAIL+1))
fi

# Test 17: _pii_scan detects Russian passport
SCAN_PASSPORT=$(run_pii_test _pii_scan "passport: 45 07 123456")
if [ "${SCAN_PASSPORT:-0}" -ge 1 ]; then
  echo "PASS: _pii_scan detects Russian passport (found=$SCAN_PASSPORT)"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_scan missed Russian passport"
  FAIL=$((FAIL+1))
fi

# Test 18: _pii_scan detects multiple PII types in one string
SCAN_MULTI=$(run_pii_test _pii_scan "user@test.com, +79161234567, 4111111111111111")
if [ "${SCAN_MULTI:-0}" -ge 3 ]; then
  echo "PASS: _pii_scan detects multiple PII types (found=$SCAN_MULTI)"
  PASS=$((PASS+1))
else
  echo "FAIL: _pii_scan missed multiple PII (found=$SCAN_MULTI, expected >=3)"
  FAIL=$((FAIL+1))
fi

echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
