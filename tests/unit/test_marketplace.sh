#!/usr/bin/env bash
# Unit tests for scripts/marketplace.sh + src/data/marketplaces.json
# Covers: registry validity, list/json output, kind filtering, offline behaviour of help.
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$PROJECT_DIR/scripts/marketplace.sh"
DATA="$PROJECT_DIR/src/data/marketplaces.json"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Test 1: files exist and parse ==="
[ -f "$SCRIPT" ] && pass "marketplace.sh exists" || fail "marketplace.sh missing"
bash -n "$SCRIPT" 2>/dev/null && pass "marketplace.sh syntax" || fail "marketplace.sh syntax"
[ -f "$DATA" ] && pass "marketplaces.json exists" || fail "marketplaces.json missing"
jq empty "$DATA" 2>/dev/null && pass "marketplaces.json is valid JSON" || fail "marketplaces.json invalid"

echo
echo "=== Test 2: registry invariants ==="
count=$(jq -r '.marketplaces | length' "$DATA")
[ "${count:-0}" -ge 5 ] && pass "registry has $count entries (>=5)" || fail "registry too small: ${count:-0}"
missing=$(jq -r '[.marketplaces[] | select((.id|length)==0 or (.url|length)==0 or (.kind|length)==0)] | length' "$DATA")
[ "$missing" -eq 0 ] && pass "every entry has id/url/kind" || fail "$missing entries lack id/url/kind"
kinds=$(jq -r '[.marketplaces[].kind] | unique | join(",")' "$DATA")
for k in plugins mcp skills; do
  case ",$kinds," in *",$k,"*) pass "kind '$k' present" ;; *) fail "kind '$k' missing" ;; esac
done

echo
echo "=== Test 3: list output ==="
out=$(bash "$SCRIPT" list 2>&1)
case "$out" in *"ID"*"KIND"*) pass "list prints a header" ;; *) fail "list header missing" ;; esac
case "$out" in *"opencode-ecosystem"*) pass "list includes opencode-ecosystem" ;; *) fail "list misses opencode-ecosystem" ;; esac
case "$out" in *"install hints:"*) pass "list prints install hints" ;; *) fail "install hints missing" ;; esac

echo
echo "=== Test 4: json + filtering ==="
bash "$SCRIPT" json 2>/dev/null | jq empty 2>/dev/null && pass "json output is valid" || fail "json output invalid"
n_all=$(bash "$SCRIPT" json 2>/dev/null | jq -r '.marketplaces|length')
n_mcp=$(bash "$SCRIPT" json mcp 2>/dev/null | jq -r '.marketplaces|length')
[ "$n_mcp" -gt 0 ] && [ "$n_mcp" -lt "$n_all" ] && pass "kind filter works ($n_mcp of $n_all)" || fail "kind filter broken"

echo
echo "=== Test 5: error handling ==="
bash "$SCRIPT" bogus >/dev/null 2>&1; [ $? -eq 2 ] && pass "unknown command exits 2" || fail "unknown command should exit 2"
bash "$SCRIPT" help 2>&1 | grep -q 'list' && pass "help mentions list" || fail "help output missing"

echo
echo "=========================================="
echo "RESULTS: $PASS pass, $FAIL fail"
echo "=========================================="
[ "$FAIL" -eq 0 ] || exit 1
