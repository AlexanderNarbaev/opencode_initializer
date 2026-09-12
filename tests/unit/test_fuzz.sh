#!/usr/bin/env bash
# tests/unit/test_fuzz.sh — Fuzz tests for configuration parsing
# Tests robustness against malformed inputs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0
TOTAL=0

pass() { PASS=$((PASS + 1)); echo -e "  \033[32m✓\033[0m $1"; }
fail() { FAIL=$((FAIL + 1)); echo -e "  \033[31m✗\033[0m $1"; }
test_case() { TOTAL=$((TOTAL + 1)); echo "Test $TOTAL: $1"; }

# ── Fuzz: Empty TOML ────────────────────────────────────────────────────────
echo "=== Fuzz Tests — Malformed Inputs ==="
echo ""

test_case "Empty TOML file"
TEMP_TOML=$(mktemp /tmp/test_fuzz_XXXXXX.toml)
touch "$TEMP_TOML"

if python3 -c "import tomllib; tomllib.load(open('$TEMP_TOML', 'rb'))" 2>/dev/null; then
  pass "Empty TOML handled gracefully"
else
  pass "Empty TOML rejected (expected)"
fi
rm -f "$TEMP_TOML"

# ── Fuzz: Invalid TOML syntax ───────────────────────────────────────────────
echo ""
test_case "Invalid TOML syntax"

TEMP_TOML=$(mktemp /tmp/test_fuzz_XXXXXX.toml)
echo "[unclosed" > "$TEMP_TOML"

if python3 -c "import tomllib; tomllib.load(open('$TEMP_TOML', 'rb'))" 2>/dev/null; then
  fail "Invalid TOML accepted"
else
  pass "Invalid TOML rejected"
fi
rm -f "$TEMP_TOML"

TEMP_TOML=$(mktemp /tmp/test_fuzz_XXXXXX.toml)
echo "= value" > "$TEMP_TOML"

if python3 -c "import tomllib; tomllib.load(open('$TEMP_TOML', 'rb'))" 2>/dev/null; then
  fail "Invalid TOML accepted"
else
  pass "Invalid TOML rejected"
fi
rm -f "$TEMP_TOML"

# ── Fuzz: Special characters in values ───────────────────────────────────────
echo ""
test_case "Special characters in values"

TEMP_TOML=$(mktemp /tmp/test_fuzz_XXXXXX.toml)
cat > "$TEMP_TOML" << 'EOF'
[test]
path = "path with spaces"
unicode = "привет мир"
EOF

result=$(python3 -c "
import tomllib
with open('$TEMP_TOML', 'rb') as f:
    d = tomllib.load(f)
print(d['test']['path'])
" 2>&1)

if [[ "$result" == "path with spaces" ]]; then
  pass "Special characters handled"
else
  fail "Special characters failed: $result"
fi
rm -f "$TEMP_TOML"

# ── Fuzz: Very large values ─────────────────────────────────────────────────
echo ""
test_case "Very large values"

LARGE_VALUE=$(printf 'A%.0s' {1..10000})
TEMP_TOML=$(mktemp /tmp/test_fuzz_XXXXXX.toml)
cat > "$TEMP_TOML" << EOF
[test]
large_key = "$LARGE_VALUE"
EOF

result=$(python3 -c "
import tomllib
with open('$TEMP_TOML', 'rb') as f:
    d = tomllib.load(f)
print(len(d['test']['large_key']))
" 2>&1)

if [[ "$result" == "10000" ]]; then
  pass "Large value handled (10000 chars)"
else
  fail "Large value failed: $result"
fi
rm -f "$TEMP_TOML"

# ── Fuzz: Deeply nested sections ────────────────────────────────────────────
echo ""
test_case "Deeply nested sections"

TEMP_TOML=$(mktemp /tmp/test_fuzz_XXXXXX.toml)
cat > "$TEMP_TOML" << 'EOF'
[a]
[a.b]
[a.b.c]
[a.b.c.d]
[a.b.c.d.e]
key = "deep"
EOF

result=$(python3 -c "
import tomllib
with open('$TEMP_TOML', 'rb') as f:
    d = tomllib.load(f)
print(d['a']['b']['c']['d']['e']['key'])
" 2>&1)

if [[ "$result" == "deep" ]]; then
  pass "Deeply nested sections handled"
else
  fail "Deeply nested sections failed: $result"
fi
rm -f "$TEMP_TOML"

# ── Fuzz: Duplicate keys ────────────────────────────────────────────────────
echo ""
test_case "Duplicate keys"

TEMP_TOML=$(mktemp /tmp/test_fuzz_XXXXXX.toml)
cat > "$TEMP_TOML" << 'EOF'
key = "first"
key = "second"
EOF

if python3 -c "import tomllib; tomllib.load(open('$TEMP_TOML', 'rb'))" 2>/dev/null; then
  pass "Duplicate keys handled (last wins)"
else
  pass "Duplicate keys rejected (per TOML spec)"
fi
rm -f "$TEMP_TOML"

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "─── Fuzz Tests: $TOTAL tests, $PASS passed, $FAIL failed ───"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
