#!/usr/bin/env bash
# test_context_budget.sh — test scripts/context-budget.py (Wave 3 model-aware monitoring)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0; FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

TOOL="$PROJECT_DIR/scripts/context-budget.py"
[ -f "$TOOL" ] && pass "context-budget.py exists" || { fail "context-budget.py missing"; exit 1; }
[ -x "$TOOL" ] && pass "context-budget.py executable" || fail "context-budget.py not executable"

python3 -m py_compile "$TOOL" 2>/dev/null && pass "py_compile OK" || fail "py_compile FAIL"

# Content assertions (thresholds + robustness markers)
grep -q '0\.77' "$TOOL" && pass "WARN threshold 0.77 mentioned" || fail "0.77 missing"
grep -q '0\.90' "$TOOL" && pass "ACT threshold 0.90 mentioned" || fail "0.90 missing"
if grep -q 'try:' "$TOOL" && grep -q 'except' "$TOOL"; then pass "try/except present"; else fail "try/except missing"; fi
grep -q 'ROUTING_JSON' "$TOOL" && pass "ROUTING_JSON override present" || fail "ROUTING_JSON missing"
grep -q 'cost_table' "$TOOL" && pass "cost_table referenced" || fail "cost_table missing"
for sub in models status check; do
  grep -q "$sub" "$TOOL" && pass "subcommand '$sub' present" || fail "subcommand '$sub' missing"
done

# ── Functional fixture: isolated tmp HOME with crafted sessions ─────────────
TMP_HOME="$(mktemp -d)"
mkdir -p "$TMP_HOME/.local/share/opencode/storage/session"
cat > "$TMP_HOME/.local/share/opencode/storage/session/ses_deepseek.json" <<'EOF'
{"id": "ses_deepseek", "model": {"providerID": "deepseek", "modelID": "deepseek-v4-pro"}, "usage": {"input_tokens": 930000, "output_tokens": 20000, "total_tokens": 950000}}
EOF
cat > "$TMP_HOME/.local/share/opencode/storage/session/ses_mystery.json" <<'EOF'
{"id": "ses_mystery", "model": "mystery-model-1", "usage": {"total_tokens": 50000}}
EOF
cat > "$TMP_HOME/routing.json" <<'EOF'
{"cost_table": {"deepseek/deepseek-v4-pro": {"context": 1000000, "free": true}, "zai/glm-5.2": {"context": 1000000, "free": true}}}
EOF

# status --json: deepseek at 95% → ACT, mystery → UNKNOWN
json_out="$(HOME="$TMP_HOME" ROUTING_JSON="$TMP_HOME/routing.json" python3 "$TOOL" status --json 2>&1)"
echo "$json_out" | python3 -c '
import json, sys
d = json.load(sys.stdin)
sess = d["sessions"]
ds = [s for s in sess if "deepseek" in s["model"].lower()]
assert ds, "no deepseek session"
assert abs(ds[0]["pct"] - 95.0) < 1.0, ds[0]
assert ds[0]["status"] == "ACT", ds[0]
assert ds[0]["limit"] == 1000000, ds[0]
assert ds[0]["used"] == 950000, ds[0]
unknown = [s for s in sess if s["status"] == "UNKNOWN"]
assert unknown, "no unknown session"
assert d["act_count"] == 1, d
' && pass "status --json: pct=95 ACT + UNKNOWN" || fail "status --json assertion FAIL"

# check --strict exits 1 (ACT found)
HOME="$TMP_HOME" ROUTING_JSON="$TMP_HOME/routing.json" python3 "$TOOL" check --strict >/dev/null 2>&1
[ $? -eq 1 ] && pass "check --strict exits 1 on ACT" || fail "check --strict did not exit 1"

# check without --strict always exits 0
HOME="$TMP_HOME" ROUTING_JSON="$TMP_HOME/routing.json" python3 "$TOOL" check >/dev/null 2>&1
[ $? -eq 0 ] && pass "check (no --strict) exits 0" || fail "check (no --strict) did not exit 0"

# models subcommand lists deepseek row
models_out="$(HOME="$TMP_HOME" ROUTING_JSON="$TMP_HOME/routing.json" python3 "$TOOL" models 2>&1)"
echo "$models_out" | grep -q "deepseek/deepseek-v4-pro" && pass "models lists deepseek row" || fail "models missing deepseek row"

# missing session dir → graceful, exit 0 (advisory)
HOME="$TMP_HOME/.nonexistent" ROUTING_JSON="$TMP_HOME/routing.json" python3 "$TOOL" status >/dev/null 2>&1
[ $? -eq 0 ] && pass "missing session dir exits 0 (advisory)" || fail "missing session dir non-zero"

rm -rf "$TMP_HOME"

echo
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
