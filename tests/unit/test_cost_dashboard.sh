#!/usr/bin/env bash
# test_cost_dashboard.sh — test the unified cost/cache observability dashboard
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0; FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

METRICS="$PROJECT_DIR/scripts/oc-metrics.py"
AUTOUPDATE="$PROJECT_DIR/src/lib/20-autoupdate.sh"
TUI="$PROJECT_DIR/scripts/oc-tui.sh"

# 1. Metrics exporter exists
[ -f "$METRICS" ] && pass "oc-metrics.py exists" || { fail "oc-metrics.py missing"; exit 1; }

# 2. Metrics exporter is valid Python
python3 -c "import ast; ast.parse(open('$METRICS').read())" 2>/dev/null \
  && pass "oc-metrics.py is valid Python" || fail "oc-metrics.py syntax FAIL"

# 3. Cost + cache metrics emitted
grep -q 'opencode_cache_hit_rate' "$METRICS" \
  && pass "opencode_cache_hit_rate metric present" || fail "opencode_cache_hit_rate missing"
grep -q 'opencode_model_cost_per_1m' "$METRICS" \
  && pass "opencode_model_cost_per_1m metric present" || fail "opencode_model_cost_per_1m missing"

# 4. Price SSOT feed in autoupdate
grep -q 'token-costs' "$AUTOUPDATE" \
  && pass "token-costs in 20-autoupdate.sh" || fail "token-costs missing from 20-autoupdate.sh"
bash -n "$AUTOUPDATE" 2>/dev/null && pass "20-autoupdate.sh syntax OK" || fail "20-autoupdate.sh syntax FAIL"

# 5. TUI cost view
grep -qi 'cost' "$TUI" \
  && pass "oc-tui.sh has cost view" || fail "oc-tui.sh missing cost view"

echo
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
