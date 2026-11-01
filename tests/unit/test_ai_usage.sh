#!/usr/bin/env bash
# Unit tests for scripts/ai-usage.py — hermetic fixtures, no network.
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$PROJECT_DIR/scripts/ai-usage.py"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/routing.json" <<'JSON'
{
  "cost_policy": {"monthly_budgets": {"currency": "USD", "deepseek": 10.0}},
  "cost_table": {
    "xiaomi-token-plan-sgp/mimo-v2.6-pro": {"input": 0, "output": 0, "prepaid": true},
    "minimax-coding-plan/MiniMax-M3": {"input": 0, "output": 0, "prepaid": true}
  }
}
JSON

now_ms() { date +%s%3N; }
NOW="$(now_ms)"
cat > "$TMP/tokens.jsonl" <<JSON
{"type":"tokens","provider":"xiaomi-token-plan-sgp","model":"mimo-v2.6-pro","input":1000,"output":100,"cost":0.5,"_ts":$NOW}
{"type":"tokens","provider":"deepseek","model":"deepseek-flash","input":2000,"output":200,"cost":2.0,"_ts":$NOW}
{"type":"tokens","provider":"opencode","model":"big-pickle","input":500,"output":50,"cost":1.0,"_ts":$NOW}
JSON

cat > "$TMP/over.jsonl" <<JSON
{"type":"tokens","provider":"deepseek","model":"deepseek-flash","input":1,"output":1,"cost":12.0,"_ts":$NOW}
JSON

echo "=== Test 1: script exists, compiles, and is executable by python ==="
[ -f "$SCRIPT" ] && pass "ai-usage.py exists" || fail "ai-usage.py missing"
python3 -m py_compile "$SCRIPT" 2>/dev/null && pass "python compiles" || fail "python compile failed"

echo
echo "=== Test 2: JSON report separates billable spend from prepaid value ==="
out="$(python3 "$SCRIPT" --log "$TMP/tokens.jsonl" --routing "$TMP/routing.json" --days 30 --json 2>/dev/null)"; rc=$?
[ "$rc" -eq 0 ] && pass "exits 0 under budget" || fail "exited $rc under budget"
echo "$out" > "$TMP/report.json"
python3 - "$TMP/report.json" <<'PY' && pass "billable=3.0 prepaid=0.5 deepseek=2.0" || fail "aggregation mismatch"
import json, sys
r = json.load(open(sys.argv[1]))
assert r["billable_cost"] == 3.0, r["billable_cost"]
assert r["prepaid_value"] == 0.5, r["prepaid_value"]
assert r["deepseek"]["spent"] == 2.0, r["deepseek"]["spent"]
assert r["deepseek"]["over_budget"] is False
assert r["providers"]["xiaomi-token-plan-sgp"]["prepaid"] is True
assert r["providers"]["deepseek"]["prepaid"] is False
PY

echo
echo "=== Test 3: over-budget DeepSeek exits 1 and flags the budget ==="
out="$(python3 "$SCRIPT" --log "$TMP/over.jsonl" --routing "$TMP/routing.json" --days 30 --json 2>/dev/null)"; rc=$?
[ "$rc" -eq 1 ] && pass "exits 1 when DeepSeek exceeds budget" || fail "exited $rc instead of 1"
echo "$out" | python3 -c "import json,sys; r=json.load(sys.stdin); assert r['deepseek']['over_budget'] is True" \
  && pass "over_budget flag set" || fail "over_budget flag missing"

echo
echo "=== Test 4: window filtering and missing log ==="
OLD=$((NOW - 40 * 86400 * 1000))
cat > "$TMP/old.jsonl" <<JSON
{"type":"tokens","provider":"deepseek","model":"deepseek-flash","input":1,"output":1,"cost":5.0,"_ts":$OLD}
JSON
out="$(python3 "$SCRIPT" --log "$TMP/old.jsonl" --routing "$TMP/routing.json" --days 7 --json 2>/dev/null)"
echo "$out" | python3 -c "import json,sys; r=json.load(sys.stdin); assert r['deepseek']['spent'] == 0.0" \
  && pass "records older than the window are ignored" || fail "window filter failed"
python3 "$SCRIPT" --log "$TMP/does-not-exist.jsonl" --routing "$TMP/routing.json" >/dev/null 2>&1 \
  && pass "missing log exits 0 with no data" || fail "missing log is not tolerated"

echo
echo "=== Test 5: human table mentions prepaid and billable lines ==="
out="$(python3 "$SCRIPT" --log "$TMP/tokens.jsonl" --routing "$TMP/routing.json" --days 30 2>&1)"
grep -q 'Billable spend: \$3.0000' <<< "$out" && pass "table reports billable spend" || fail "billable line missing"
grep -q 'Plan value covered: \$0.5000' <<< "$out" && pass "table reports prepaid value" || fail "prepaid line missing"
grep -q 'DeepSeek (pay-as-you-go): \$2.0000 / \$10.00' <<< "$out" && pass "table reports DeepSeek budget" || fail "budget line missing"

echo
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
