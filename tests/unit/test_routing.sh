#!/usr/bin/env bash
# ============================================================================
# ISOLATED Unit Test for SSOT routing table (routing.json)
# Target: src/data/routing.json + src/lib/36-model-router.sh + scripts/ai-router.sh
# Session: ses_test_routing
#
# Tests:
#   (a) routing.json parses + has required top-level keys
#   (b) testing profile exists (was missing in 36-model-router.sh pre-SSOT)
#   (c) testing reconciliation (ai-router.json said xai/grok-4.3; swarm said
#       gpt-5-nano; SSOT settles deepseek-v4-flash)
#   (d) both bash readers derive from routing.json
#   (e) ai-router.sh filters "_"-prefixed meta keys from .providers
# ============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
ROUTING="$PROJECT_DIR/src/data/routing.json"
MODEL_ROUTER="$PROJECT_DIR/src/lib/36-model-router.sh"
AI_ROUTER="$PROJECT_DIR/scripts/ai-router.sh"

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") 2>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $desc" >&2
  fi
}

echo "=== Testing routing SSOT ==="

# ── (a) File + JSON validity ─────────────────────────────────────────────────
assert "routing.json exists" "[ -f '$ROUTING' ]"
assert "routing.json parses" "python3 -c \"import json; json.load(open('$ROUTING'))\""
assert "routing.json has complexity_rules" "python3 -c \"import json; d=json.load(open('$ROUTING')); assert 'complexity_rules' in d\""
assert "routing.json has task_routing" "python3 -c \"import json; d=json.load(open('$ROUTING')); assert 'task_routing' in d\""
assert "routing.json has task_profiles" "python3 -c \"import json; d=json.load(open('$ROUTING')); assert 'task_profiles' in d\""
assert "routing.json has agents" "python3 -c \"import json; d=json.load(open('$ROUTING')); assert 'agents' in d\""
assert "routing.json has rate_limits" "python3 -c \"import json; d=json.load(open('$ROUTING')); assert 'rate_limits' in d\""

# ── (b) testing profile present + field-complete ─────────────────────────────
assert "testing profile exists" "python3 -c \"import json; d=json.load(open('$ROUTING')); assert 'testing' in d['task_profiles']\""
assert "testing profile has model" "python3 -c \"import json; d=json.load(open('$ROUTING')); assert d['task_profiles']['testing']['model']\""
assert "testing profile has fallback" "python3 -c \"import json; d=json.load(open('$ROUTING')); assert len(d['task_profiles']['testing']['fallback']) >= 1\""

# ── (c) testing reconciliation: settled on deepseek-v4-flash ─────────────────
assert "task_routing.testing is deepseek-v4-flash" "python3 -c \"import json; d=json.load(open('$ROUTING')); assert d['task_routing']['testing']['model'] == 'deepseek-v4-flash'\""
assert "testing profile model is deepseek-v4-flash" "python3 -c \"import json; d=json.load(open('$ROUTING')); assert d['task_profiles']['testing']['model'] == 'deepseek/deepseek-v4-flash'\""
assert "testing profile rationale notes reconciliation" "python3 -c \"import json; d=json.load(open('$ROUTING')); assert 'grok-4.3' in d['task_profiles']['testing']['rationale'] and 'gpt-5-nano' in d['task_profiles']['testing']['rationale']\""

# ── (d) both readers derive from routing.json ────────────────────────────────
assert "36-model-router.sh references routing.json" "grep -q 'routing.json' '$MODEL_ROUTER'"
assert "36-model-router.sh has _routing_extract" "grep -q '_routing_extract' '$MODEL_ROUTER'"
assert "36-model-router.sh has SSOT fallback heredoc" "grep -q 'PROFILES' '$MODEL_ROUTER'"
assert "36-model-router.sh fallback has testing profile" "grep -q '\"testing\"' '$MODEL_ROUTER'"
assert "ai-router.sh references routing.json" "grep -q 'routing.json' '$AI_ROUTER'"
assert "ai-router.sh has reconciliation note" "grep -qi 'grok-4.3' '$AI_ROUTER' && grep -qi 'gpt-5-nano' '$AI_ROUTER'"

# ── (e) ai-router.sh filters "_"-prefixed meta keys ─────────────────────────
assert "ai-router.sh filters _comment meta keys" "grep -q 'startswith(\"_\")' '$AI_ROUTER'"

# ── Syntax validity of both readers ──────────────────────────────────────────
assert "36-model-router.sh bash -n clean" "bash -n '$MODEL_ROUTER'"
assert "ai-router.sh bash -n clean" "bash -n '$AI_ROUTER'"

echo "test_routing: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
