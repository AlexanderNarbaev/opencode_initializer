#!/usr/bin/env bash
# ============================================================================
# ISOLATED Unit Test for 36-model-router.sh
# Target: src/lib/36-model-router.sh (218 lines)
# Session: ses_model_router_test
#
# Tests:
#   (a) Module file + syntax validity
#   (b) All 8 task profiles present + field completeness
#   (c) Profile-specific model assignments
#   (d) Cost table — free tiers, context windows, local models
#   (e) Team preferences structure
#   (f) Module structure — gates, outputs, recommend.sh
#
# Isolation: mktemp + sed-extracted JSON (no module source needed)
# ============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
ROUTER="$PROJECT_DIR/src/lib/36-model-router.sh"

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") 2>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $desc" >&2
  fi
}

echo "=== Testing 36-model-router.sh ==="

# ── TMPDIR with extracted JSON ───────────────────────────────────────────────
TMP=$(mktemp -d /tmp/test_router.XXXXXX)
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# Extract embedded JSON heredocs (match: "cat >... <<'EOF'" pattern)
sed -n "/cat.*task-profiles.json/,/^PROFILES$/p" "$ROUTER" | sed '1d;$d' > "$TMP/profiles.json"
sed -n "/cat.*cost-table.json/,/^COSTS$/p" "$ROUTER" | sed '1d;$d' > "$TMP/costs.json"
sed -n "/cat.*team-prefs.json/,/^TEAM$/p" "$ROUTER" | sed '1d;$d' > "$TMP/team-prefs.json"

# ── (a) Module file + syntax ─────────────────────────────────────────────────
assert "36-model-router.sh exists" "[ -f '$ROUTER' ]"
assert "36-model-router.sh bash -n clean" "bash -n '$ROUTER'"

# ── JSON validity ────────────────────────────────────────────────────────────
assert "profiles.json is valid JSON" "python3 -c \"import json; json.load(open('$TMP/profiles.json'))\""
assert "costs.json is valid JSON" "python3 -c \"import json; json.load(open('$TMP/costs.json'))\""
assert "team-prefs.json is valid JSON" "python3 -c \"import json; json.load(open('$TMP/team-prefs.json'))\""

# ── (b) All 8 profiles present ───────────────────────────────────────────────
ALL_PROFILES="coding reasoning fast agentic budget vision isolated ru_cn"
for p in $ALL_PROFILES; do
  assert "has $p profile" "python3 -c \"import json; d=json.load(open('$TMP/profiles.json')); assert '$p' in d\""
done

# ── (b) Every profile has required fields (aggregate check) ──────────────────
assert "all profiles have model" "python3 -c \"
import json; d=json.load(open('$TMP/profiles.json'))
for k in ['coding','reasoning','fast','agentic','budget','vision','isolated','ru_cn']:
    assert 'model' in d[k] and d[k]['model'], f'{k}: missing model'
\""
assert "all profiles have small_model" "python3 -c \"
import json; d=json.load(open('$TMP/profiles.json'))
for k in ['coding','reasoning','fast','agentic','budget','vision','isolated','ru_cn']:
    assert 'small_model' in d[k] and d[k]['small_model'], f'{k}: missing small_model'
\""
assert "all profiles have fallback (>=1)" "python3 -c \"
import json; d=json.load(open('$TMP/profiles.json'))
for k in ['coding','reasoning','fast','agentic','budget','vision','isolated','ru_cn']:
    assert 'fallback' in d[k] and len(d[k]['fallback']) >= 1, f'{k}: missing/broken fallback'
\""
assert "all profiles have description" "python3 -c \"
import json; d=json.load(open('$TMP/profiles.json'))
for k in ['coding','reasoning','fast','agentic','budget','vision','isolated','ru_cn']:
    assert 'description' in d[k] and d[k]['description'], f'{k}: missing description'
\""
assert "all profiles have rationale" "python3 -c \"
import json; d=json.load(open('$TMP/profiles.json'))
for k in ['coding','reasoning','fast','agentic','budget','vision','isolated','ru_cn']:
    assert 'rationale' in d[k] and d[k]['rationale'], f'{k}: missing rationale'
\""

# ── (c) Profile-specific model assignments ───────────────────────────────────
assert "coding model is deepseek-v4-pro" "python3 -c \"import json; d=json.load(open('$TMP/profiles.json')); assert d['coding']['model'] == 'deepseek/deepseek-v4-pro'\""
assert "fast model is deepseek-v4-flash" "python3 -c \"import json; d=json.load(open('$TMP/profiles.json')); assert d['fast']['model'] == 'deepseek/deepseek-v4-flash'\""
assert "reasoning model contains claude-opus" "python3 -c \"import json; d=json.load(open('$TMP/profiles.json')); assert 'claude-opus' in d['reasoning']['model']\""
assert "budget model is z.ai glm-5.2" "python3 -c \"import json; d=json.load(open('$TMP/profiles.json')); assert d['budget']['model'] == 'zai/glm-5.2'\""
assert "isolated model is ollama local" "python3 -c \"import json; d=json.load(open('$TMP/profiles.json')); assert d['isolated']['model'].startswith('ollama/')\""
assert "ru_cn model is glm-5.2" "python3 -c \"import json; d=json.load(open('$TMP/profiles.json')); assert d['ru_cn']['model'] == 'zai/glm-5.2'\""
assert "vision model contains gemini" "python3 -c \"import json; d=json.load(open('$TMP/profiles.json')); assert 'gemini' in d['vision']['model']\""
assert "agentic model is deepseek-v4-pro" "python3 -c \"import json; d=json.load(open('$TMP/profiles.json')); assert d['agentic']['model'] == 'deepseek/deepseek-v4-pro'\""

# ── Fallback chain checks ────────────────────────────────────────────────────
assert "coding fallback has zai" "python3 -c \"import json; d=json.load(open('$TMP/profiles.json')); assert any('zai' in f for f in d['coding']['fallback'])\""
assert "budget fallback length >= 2" "python3 -c \"import json; d=json.load(open('$TMP/profiles.json')); assert len(d['budget']['fallback']) >= 2\""
assert "isolated fallback is all ollama" "python3 -c \"import json; d=json.load(open('$TMP/profiles.json')); assert all(f.startswith('ollama/') for f in d['isolated']['fallback'])\""
assert "ru_cn fallback has deepseek" "python3 -c \"import json; d=json.load(open('$TMP/profiles.json')); assert any('deepseek' in f for f in d['ru_cn']['fallback'])\""

# ── (d) Cost table — free tier validation ────────────────────────────────────
assert "deepseek-v4-pro is free (input=0 output=0)" "python3 -c \"
import json; d=json.load(open('$TMP/costs.json'))
m=d['deepseek/deepseek-v4-pro']
assert m['free'] == True and m['input'] == 0.0 and m['output'] == 0.0
\""
assert "gemini-3.5-flash is NOT free" "python3 -c \"
import json; d=json.load(open('$TMP/costs.json'))
assert d['google/gemini-3.5-flash']['free'] == False
\""
assert "all free models have input=0 output=0" "python3 -c \"
import json; d=json.load(open('$TMP/costs.json'))
for k,v in d.items():
    if v.get('free'):
        assert v['input'] == 0.0 and v['output'] == 0.0, f'{k}: free but has cost'
\""

# ── (d) Cost table — context windows ─────────────────────────────────────────
assert "deepseek-v4-pro has 1M context" "python3 -c \"import json; d=json.load(open('$TMP/costs.json')); assert d['deepseek/deepseek-v4-pro']['context'] == 1000000\""
assert "openai gpt-5.5 has >=1M context" "python3 -c \"import json; d=json.load(open('$TMP/costs.json')); assert d['openai/gpt-5.5']['context'] >= 1000000\""
assert "ollama local models have 131072 context" "python3 -c \"import json; d=json.load(open('$TMP/costs.json')); assert d['ollama/qwen3:32b']['context'] == 131072\""

# ── (d) Cost table — local models ────────────────────────────────────────────
assert "ollama/qwen3:32b is local" "python3 -c \"import json; d=json.load(open('$TMP/costs.json')); assert d['ollama/qwen3:32b'].get('local') == True\""
assert "ollama/qwen3:14b is local" "python3 -c \"import json; d=json.load(open('$TMP/costs.json')); assert d['ollama/qwen3:14b'].get('local') == True\""
assert "cost table has >=14 models" "python3 -c \"import json; d=json.load(open('$TMP/costs.json')); assert len(d) >= 14, f'got {len(d)}'\""

# ── (d) Free tier count ──────────────────────────────────────────────────────
assert ">=8 models have free tier" "python3 -c \"
import json; d=json.load(open('$TMP/costs.json'))
free=[k for k,v in d.items() if v.get('free')]
assert len(free) >= 8, f'only {len(free)} free models'
\""

# ── (e) Team preferences ─────────────────────────────────────────────────────
assert "team-prefs has overrides key" "python3 -c \"import json; d=json.load(open('$TMP/team-prefs.json')); assert 'overrides' in d\""
assert "team-prefs has defaults key" "python3 -c \"import json; d=json.load(open('$TMP/team-prefs.json')); assert 'defaults' in d\""
assert "team-prefs preferred_provider is deepseek" "python3 -c \"import json; d=json.load(open('$TMP/team-prefs.json')); assert d['defaults']['preferred_provider'] == 'deepseek'\""
assert "team-prefs has fallback_strategy" "python3 -c \"import json; d=json.load(open('$TMP/team-prefs.json')); assert 'fallback_strategy' in d['defaults']\""

# ── (f) Module structure — gates and outputs ─────────────────────────────────
assert "has _step_skip gate" "grep -q '_step_skip step_model_router' '$ROUTER'"
assert "has section header" "grep -q 'section.*Model Routing' '$ROUTER'"
assert "writes task-profiles.json" "grep -q 'task-profiles.json' '$ROUTER'"
assert "writes cost-table.json" "grep -q 'cost-table.json' '$ROUTER'"
assert "writes team-prefs.json" "grep -q 'team-prefs.json' '$ROUTER'"
assert "generates recommend.sh" "grep -q 'recommend.sh' '$ROUTER'"
assert "has _step_done gating" "grep -q '_step_done step_model_router' '$ROUTER'"
assert "has shebang" "head -1 '$ROUTER' | grep -q '#!/usr/bin/env bash'"

# ── Report ───────────────────────────────────────────────────────────────────
echo "test_model_router: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
