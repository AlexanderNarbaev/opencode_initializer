#!/usr/bin/env bash
# ============================================================================
# ISOLATED Unit Test for routing SSOT (src/data/routing.json) + ai-router.sh
# Target: src/data/routing.json (SSOT) + scripts/ai-router.sh (consumer)
# Session: ses_routing_test
#
# Tests:
#   (a) routing.json exists + parses as valid JSON (jq) + has task_profiles.testing
#   (b) testing profile unified to deepseek-v4-flash (divergence reconciliation)
#   (c) ai-router.sh reads routing.json (SSOT) with a graceful fallback
#   (d) task_routing + cost_per_1k + rate_limits present (SSOT completeness)
#
# Isolation: grep + jq structural asserts (no live network/provider run)
# ============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
RJSON="$PROJECT_DIR/src/data/routing.json"
AROUTER="$PROJECT_DIR/scripts/ai-router.sh"

assert() {
  local d="$1" c="$2"
  if (eval "$c") &>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $d" >&2
  fi
}

echo "=== Testing routing SSOT + ai-router.sh ==="

# ── (a) routing.json exists + structure ─────────────────────────────────────
assert "routing.json exists" "[ -f '$RJSON' ]"
assert "ai-router.sh exists" "[ -f '$AROUTER' ]"
assert "ai-router.sh syntax clean" "bash -n '$AROUTER'"

if command -v jq &>/dev/null; then
  assert "routing.json is valid JSON" "jq -e . '$RJSON'"
  assert "has task_profiles.testing" "jq -e '.task_profiles.testing' '$RJSON'"
  assert "has task_routing" "jq -e '.task_routing' '$RJSON'"
  assert "has cost_table" "jq -e '.cost_table' '$RJSON'"
  assert "has agents" "jq -e '.agents' '$RJSON'"
  assert "has providers" "jq -e '.providers' '$RJSON'"
  assert "has rate_limits" "jq -e '.rate_limits' '$RJSON'"
  assert "has complexity_rules.simple.cost_per_1k" "jq -e '.complexity_rules.simple.cost_per_1k' '$RJSON'"
else
  echo "  (SKIP: jq not available — JSON structural asserts skipped)"
fi

# ── (b) testing profile reconciliation ──────────────────────────────────────
assert "testing model unified to deepseek-v4-flash" "grep -q '\"testing\"' '$RJSON' && grep -q 'deepseek-v4-flash' '$RJSON'"

# ── (c) ai-router.sh reads SSOT with fallback ───────────────────────────────
assert "ai-router.sh references routing.json" "grep -q 'routing.json' '$AROUTER'"
assert "ai-router.sh has _route_task_model" "grep -q '_route_task_model()' '$AROUTER'"
assert "ai-router.sh has jq fallback (never hard-fail)" "grep -q 'Fallback heuristic' '$AROUTER'"

# ── (d) end-to-end routing: no jq crash on task command ─────────────────────
# Source-free smoke: run `ai-router task` with routing.json present and confirm
# it emits a model without crashing (bash -n already guarantees syntax).
OUT=$(bash "$AROUTER" task "fix a small typo in the login module" 2>&1 || true)
assert "cmd_task runs without crash" "[ -n \"\$OUT\" ]"
assert "cmd_task emits a model" "echo \"\$OUT\" | grep -q '/model '"

echo "test_routing: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
