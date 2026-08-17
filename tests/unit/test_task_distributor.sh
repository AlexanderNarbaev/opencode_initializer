#!/usr/bin/env bash
# ============================================================================
# Unit Test for 54-task-distributor.sh
# Target: src/lib/54-task-distributor.sh
#
# Tests:
#   (a) Module file + syntax validity
#   (b) Embedded config.json validity (agents / rules / complexity / keyword map)
#   (c) Agent capability registry — 4 agents with expected fields
#   (d) Distribution rules — 9 task types map to correct agents
#   (e) Complexity tiers — simple/medium/complex + flow + agent
#   (f) Module structure — gates, functions, helper script, shebang
#   (g) Embedded distribute.sh — syntax + end-to-end logic (analyze/agent/split/parallel)
#
# Isolation: mktemp + sed-extracted JSON + sed-extracted helper (no module source)
# ============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
MODULE="$PROJECT_DIR/src/lib/54-task-distributor.sh"

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") 2>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $desc" >&2
  fi
}

echo "=== Testing 54-task-distributor.sh ==="

# ── TMPDIR with extracted artifacts ──────────────────────────────────────────
TMP=$(mktemp -d /tmp/td_test.XXXXXX)
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# Extract embedded config.json (between <<'CONFIG' and CONFIG terminator)
sed -n "/<<'CONFIG'/,/^CONFIG\$/p" "$MODULE" | sed '1d;$d' > "$TMP/config.json"
# Extract embedded distribute.sh (between <<'DISTRIBUTE' and DISTRIBUTE terminator)
sed -n "/<<'DISTRIBUTE'/,/^DISTRIBUTE\$/p" "$MODULE" | sed '1d;$d' > "$TMP/distribute.sh"
chmod +x "$TMP/distribute.sh"

# ── (a) Module file + syntax ─────────────────────────────────────────────────
assert "54-task-distributor.sh exists" "[ -f '$MODULE' ]"
assert "54-task-distributor.sh bash -n clean" "bash -n '$MODULE'"

# ── (b) config.json validity ─────────────────────────────────────────────────
assert "config.json is valid JSON" "python3 -c \"import json; json.load(open('$TMP/config.json'))\""
assert "config.json has version" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d.get('version') == '1.0.0'\""
assert "config.json has architecture" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert 'architecture' in d\""

# ── (c) Agent capability registry — 4 agents ────────────────────────────────
ALL_AGENTS="Commander Planner Worker Reviewer"
for a in $ALL_AGENTS; do
  assert "has agent $a" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert '$a' in d['agents']\""
done
assert "agents have capabilities" "python3 -c \"
import json; d=json.load(open('$TMP/config.json'))
for k in ['Commander','Planner','Worker','Reviewer']:
    assert 'capabilities' in d['agents'][k] and len(d['agents'][k]['capabilities']) >= 1
\""
assert "agents have delegates_to" "python3 -c \"
import json; d=json.load(open('$TMP/config.json'))
for k in ['Commander','Planner','Worker','Reviewer']:
    assert 'delegates_to' in d['agents'][k]
\""
assert "agents have best_for" "python3 -c \"
import json; d=json.load(open('$TMP/config.json'))
for k in ['Commander','Planner','Worker','Reviewer']:
    assert 'best_for' in d['agents'][k] and len(d['agents'][k]['best_for']) >= 1
\""
assert "Commander delegates to Planner" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert 'Planner' in d['agents']['Commander']['delegates_to']\""
assert "Commander delegates to Worker" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert 'Worker' in d['agents']['Commander']['delegates_to']\""
assert "Commander delegates to Reviewer" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert 'Reviewer' in d['agents']['Commander']['delegates_to']\""
assert "Worker delegates to nobody" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d['agents']['Worker']['delegates_to'] == []\""
assert "Planner has research capability" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert 'research' in d['agents']['Planner']['capabilities']\""
assert "Reviewer has verification capability" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert 'verification' in d['agents']['Reviewer']['capabilities']\""

# ── (d) Distribution rules — 9 task types ────────────────────────────────────
ALL_TYPES="coding testing research planning review debug refactor docs orchestration"
for t in $ALL_TYPES; do
  assert "has rule $t" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert '$t' in d['distribution_rules']\""
done
assert "every rule has agent" "python3 -c \"
import json; d=json.load(open('$TMP/config.json'))
for k in ['coding','testing','research','planning','review','debug','refactor','docs','orchestration']:
    assert 'agent' in d['distribution_rules'][k] and d['distribution_rules'][k]['agent']
\""
assert "coding → Worker" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d['distribution_rules']['coding']['agent'] == 'Worker'\""
assert "testing → Worker" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d['distribution_rules']['testing']['agent'] == 'Worker'\""
assert "research → Planner" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d['distribution_rules']['research']['agent'] == 'Planner'\""
assert "planning → Planner" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d['distribution_rules']['planning']['agent'] == 'Planner'\""
assert "review → Reviewer" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d['distribution_rules']['review']['agent'] == 'Reviewer'\""
assert "orchestration → Commander" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d['distribution_rules']['orchestration']['agent'] == 'Commander'\""
assert "testing has tdd skill" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d['distribution_rules']['testing']['skill'] == 'tdd'\""
assert "debug has diagnosing-bugs skill" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d['distribution_rules']['debug']['skill'] == 'diagnosing-bugs'\""

# ── (e) Complexity tiers ─────────────────────────────────────────────────────
for c in simple medium complex; do
  assert "has complexity $c" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert '$c' in d['complexity']\""
done
assert "simple → Worker" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d['complexity']['simple']['agent'] == 'Worker'\""
assert "medium → Planner" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d['complexity']['medium']['agent'] == 'Planner'\""
assert "complex → Commander" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d['complexity']['complex']['agent'] == 'Commander'\""
assert "simple flow is direct" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d['complexity']['simple']['flow'] == 'direct'\""
assert "complex flow is orchestrate" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert d['complexity']['complex']['flow'] == 'orchestrate'\""
assert "complexity has max_minutes" "python3 -c \"
import json; d=json.load(open('$TMP/config.json'))
for k in ['simple','medium','complex']:
    assert 'max_minutes' in d['complexity'][k] and d['complexity'][k]['max_minutes'] > 0
\""
assert "keyword_map has 9 keys" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert len(d['keyword_map']) == 9\""
assert "complexity_signals has 3 tiers" "python3 -c \"import json; d=json.load(open('$TMP/config.json')); assert len(d['complexity_signals']) == 3\""

# ── (f) Module structure — gates, functions, helper ─────────────────────────
assert "has shebang" "head -1 '$MODULE' | grep -q '#!/usr/bin/env bash'"
assert "has _step_skip gate" "grep -q '_step_skip step_task_distributor' '$MODULE'"
assert "has SKIP_TASK_DISTRIBUTOR opt-out" "grep -q 'SKIP_TASK_DISTRIBUTOR' '$MODULE'"
assert "has _step_done gating" "grep -q '_step_done step_task_distributor' '$MODULE'"
assert "defines _analyze_task" "grep -q '^_analyze_task()' '$MODULE'"
assert "defines _select_agent" "grep -q '^_select_agent()' '$MODULE'"
assert "defines _distribute_tasks" "grep -q '^_distribute_tasks()' '$MODULE'"
assert "defines _parallel_execute" "grep -q '^_parallel_execute()' '$MODULE'"
assert "writes config.json" "grep -q 'config.json' '$MODULE'"
assert "generates distribute.sh" "grep -q 'distribute.sh' '$MODULE'"

# ── (g) Embedded distribute.sh — syntax + end-to-end logic ──────────────────
assert "distribute.sh bash -n clean" "bash -n '$TMP/distribute.sh'"

AN="\"$TMP/distribute.sh\" analyze"
assert "analyze 'implement login feature' → coding/simple" "[ \"\$($AN 'implement login feature')\" = 'coding / simple' ]"
assert "analyze 'fix typo in readme' → debug/simple" "[ \"\$($AN 'fix typo in readme')\" = 'debug / simple' ]"
assert "analyze 'debug the failing test' → debug/simple" "[ \"\$($AN 'debug the failing test')\" = 'debug / simple' ]"
assert "analyze 'review the pull request' → review/simple" "[ \"\$($AN 'review the pull request')\" = 'review / simple' ]"
assert "analyze 'orchestrate multi-agent migration' → orchestration/complex" "[ \"\$($AN 'orchestrate multi-agent migration')\" = 'orchestration / complex' ]"
assert "analyze --json emits valid JSON" "[ \"\$($AN 'implement login feature' --json)\" = '{\"task_type\": \"coding\", \"complexity\": \"simple\"}' ]"

AG="\"$TMP/distribute.sh\" agent"
assert "agent 'implement login feature' → Worker" "[ \"\$($AG 'implement login feature')\" = 'Worker' ]"
assert "agent 'research provider APIs' → Planner" "[ \"\$($AG 'research provider APIs')\" = 'Planner' ]"
assert "agent 'review code changes' → Reviewer" "[ \"\$($AG 'review code changes')\" = 'Reviewer' ]"
assert "agent 'orchestrate migration' → Commander" "[ \"\$($AG 'orchestrate migration')\" = 'Commander' ]"

assert "split 'complex task' emits pipeline with verify" "\"$TMP/distribute.sh\" split 'build end-to-end auth system' | grep -q 'verify'"
assert "parallel '3 tasks' emits 3 lanes" "[ \$(\"$TMP/distribute.sh\" parallel 'a' 'b' 'c' | grep -c 'delegate_task') -eq 3 ]"

# ── Report ───────────────────────────────────────────────────────────────────
echo "test_task_distributor: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
