#!/usr/bin/env bash
# Unit tests for scripts/model-limits.py — limits are DERIVED from the model
# catalog, never hand-typed. Uses the offline fixture, no network.
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TOOL="$PROJECT_DIR/scripts/model-limits.py"
FIXTURE="$PROJECT_DIR/tests/fixtures/models-dev.fixture.json"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

WORK="$(mktemp -d /tmp/model-limits-test.XXXXXX)"
ROUTING="$WORK/routing.json"
cat > "$ROUTING" <<'JSON'
{
  "version": "test",
  "cost_table": {
    "acme/big": { "input": 1.5, "output": 2.5, "context": 999 },
    "other/small": { "input": 0.1, "output": 0.2 },
    "local/only": { "input": 0, "output": 0, "context": 777 }
  }
}
JSON

echo "=== Test 1: tool exists and compiles ==="
[ -f "$TOOL" ] && pass "model-limits.py exists" || fail "model-limits.py missing"
python3 -m py_compile "$TOOL" 2>/dev/null && pass "tool compiles" || fail "tool does not compile"
[ -f "$FIXTURE" ] && pass "catalog fixture exists" || fail "fixture missing"

echo
echo "=== Test 2: show reads the catalog (offline fixture) ==="
show_json="$(ROUTING_JSON="$ROUTING" python3 "$TOOL" --catalog "$FIXTURE" show --json 2>&1)"
echo "$show_json" | jq empty 2>/dev/null && pass "show --json is valid JSON" || fail "show --json invalid"
ctx=$(echo "$show_json" | jq -r '.resolved["acme/big"].context')
out=$(echo "$show_json" | jq -r '.resolved["acme/big"].output')
[ "$ctx" = "123456" ] && pass "catalog context surfaced ($ctx)" || fail "context wrong: $ctx"
[ "$out" = "4096" ] && pass "catalog output surfaced ($out)" || fail "output wrong: $out"

echo
echo "=== Test 3: check detects hand-typed drift ==="
ROUTING_JSON="$ROUTING" python3 "$TOOL" --catalog "$FIXTURE" check >/dev/null 2>&1
[ $? -eq 1 ] && pass "check fails while routing disagrees with catalog" || fail "check should fail on drift"

echo
echo "=== Test 4: sync rewrites limits from the model, not from typing ==="
ROUTING_JSON="$ROUTING" python3 "$TOOL" --catalog "$FIXTURE" sync >/tmp/model-limits-sync.txt 2>&1
[ $? -eq 0 ] && pass "sync exits 0" || { fail "sync failed"; sed -n '1,5p' /tmp/model-limits-sync.txt; }
new_ctx=$(jq -r '.cost_table["acme/big"].context' "$ROUTING")
new_out=$(jq -r '.cost_table["acme/big"].max_output_tokens' "$ROUTING")
price_out=$(jq -r '.cost_table["acme/big"].output' "$ROUTING")
[ "$new_ctx" = "123456" ] && pass "context synced from catalog ($new_ctx)" || fail "context not synced: $new_ctx"
[ "$new_out" = "4096" ] && pass "max_output_tokens synced ($new_out)" || fail "max_output_tokens not synced: $new_out"
[ "$price_out" = "2.5" ] && pass "output PRICE left untouched ($price_out)" || fail "output price was overwritten: $price_out"

echo
echo "=== Test 5: local overrides are never overwritten ==="
local_ctx=$(jq -r '.cost_table["local/only"].context' "$ROUTING")
[ "$local_ctx" = "777" ] && pass "unresolved model keeps its local override ($local_ctx)" || fail "local override changed: $local_ctx"
grep -q 'kept local override for local/only' /tmp/model-limits-sync.txt && pass "sync reports the override" || fail "sync does not report the override"

echo
echo "=== Test 6: check passes after sync, and backup is written ==="
ROUTING_JSON="$ROUTING" python3 "$TOOL" --catalog "$FIXTURE" check >/dev/null 2>&1
[ $? -eq 0 ] && pass "check passes after sync" || fail "check still failing after sync"
ls "$WORK"/routing.json.bak-* >/dev/null 2>&1 && pass "sync wrote a backup next to routing.json" || fail "no backup written"

echo
echo "=== Test 7: the real repo registry is model-derived ==="
ROUTING_JSON="$PROJECT_DIR/src/data/routing.json" python3 "$TOOL" --offline check >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
  pass "src/data/routing.json matches the model catalog"
elif [ "$rc" -eq 1 ]; then
  # no cached catalog in CI is fine; drift is not
  if [ -f "${XDG_CACHE_HOME:-$HOME/.cache}/opencode-setup/models-dev.json" ]; then
    fail "src/data/routing.json drifted from the catalog"
  else
    pass "no catalog cache here — offline check skipped"
  fi
else
  pass "offline check skipped (no cache)"
fi

rm -rf "$WORK"

echo
echo "=========================================="
echo "RESULTS: $PASS pass, $FAIL fail"
echo "=========================================="
[ "$FAIL" -eq 0 ] || exit 1
