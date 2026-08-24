#!/usr/bin/env bash
# test_skill_audit.sh — test scripts/skill-audit.sh (skills actualization tool)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
AUDIT="$PROJECT_DIR/scripts/skill-audit.sh"

PASS=0; FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

[ -f "$AUDIT" ] && pass "skill-audit.sh exists" || { fail "skill-audit.sh missing"; exit 1; }
[ -x "$AUDIT" ] && pass "skill-audit.sh executable" || fail "skill-audit.sh not executable"

bash -n "$AUDIT" 2>/dev/null && pass "skill-audit.sh syntax OK" || fail "skill-audit.sh syntax FAIL"

# Content assertions (bash 3.2 safety + documented flags)
if grep -q 'declare -A\|typeset -A' "$AUDIT"; then fail "uses associative arrays (not bash3.2-safe)"; else pass "bash3.2-safe (no assoc arrays)"; fi
if grep -q -- '--since' "$AUDIT"; then pass "--since flag documented"; else fail "--since flag missing"; fi
if grep -q -- '--strict' "$AUDIT"; then pass "--strict flag documented"; else fail "--strict flag missing"; fi
if grep -q -- '--json' "$AUDIT"; then pass "--json flag documented"; else fail "--json flag missing"; fi

# ── Functional smoke: isolated fixture (mktemp HOME) ─────────────────────
TMP_HOME="$(mktemp -d)"
mkdir -p "$TMP_HOME/skills/audited" "$TMP_HOME/skills/bloated" "$TMP_HOME/skills/stray"
mkdir -p "$TMP_HOME/auto-skills"

printf -- '---\nname: audited\n---\nA normal skill body.\n' > "$TMP_HOME/skills/audited/SKILL.md"
printf -- '---\nname: stray\n---\nAn unregistered skill body.\n' > "$TMP_HOME/skills/stray/SKILL.md"
awk 'BEGIN{for(i=1;i<=420;i++) print "line", i}' > "$TMP_HOME/skills/bloated/SKILL.md"

cat > "$TMP_HOME/auto-skills/config.json" <<'EOF'
{
  "version": "1.0.0",
  "default_skills": ["audited"],
  "priority": ["audited"],
  "task_triggers": {
    "plan": { "keywords": ["plan"], "skills": ["audited", "bloated", "ghost"] }
  },
  "file_triggers": {}
}
EOF

run_audit() {
  OPENCODE_SKILLS_DIR="$TMP_HOME/skills" \
  AUTO_SKILLS_CONFIG="$TMP_HOME/auto-skills/config.json" \
  OPENCODE_LOG_DIR="$TMP_HOME/nolog" \
  bash "$AUDIT" "$@"
}

# exit 0 (advisory) + summary line with expected counts
out="$(run_audit 2>&1)"
rc=$?
[ "$rc" -eq 0 ] && pass "smoke exits 0" || fail "smoke exit non-zero: $rc"
echo "$out" | grep -q 'SKILLS AUDIT SUMMARY:' && pass "summary line present" || fail "summary line missing"
echo "$out" | grep -q 'broken=1 unregistered=1 oversize=1' && pass "counts broken=1 unregistered=1 oversize=1" || fail "unexpected counts: $(echo "$out" | grep 'SKILLS AUDIT SUMMARY')"

# --json smoke: parses via python3 json.loads
json_out="$(run_audit --json 2>&1)"
echo "$json_out" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["broken"]==1 and d["unregistered"]==1 and d["oversize"]==1' \
  && pass "--json parses + counts correct" || fail "--json parse/counts FAIL"

# --strict smoke: broken=1 -> exit 1
run_audit --strict >/dev/null 2>&1
[ $? -eq 1 ] && pass "--strict exits 1 on broken>0" || fail "--strict did not exit 1"

rm -rf "$TMP_HOME"

echo
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
