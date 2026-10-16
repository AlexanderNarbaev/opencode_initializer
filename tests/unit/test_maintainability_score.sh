#!/usr/bin/env bash
# test_maintainability_score.sh — Module 45 (Maintainability Score)
#
# Regression coverage for the v16.1.0 crash: unsanitized `bc` output ("3.00",
# ".25") and `grep -c ... || echo 0` ("0\n0") were fed straight into $(( )) and
# [ -gt ], producing
#     line 120: 3.00: arithmetic syntax error
#     line 190: 0\n0 : arithmetic syntax error in expression
#     MAINTAINABILITY SCORE: /100     (empty variable reached the banner)
# with exit code 3 even though the module "worked".
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../test_lib.sh"

MODULE="$PROJECT_DIR/src/lib/45-maintainability-score.sh"
FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT

# Keep every write inside the fixture.
export MAINTAINABILITY_CACHE="$FIXTURE/cache"
export MAINTAINABILITY_CONFIG="$FIXTURE/maintainability.toml"

# ── File present and syntactically valid ─────────────────────────────────────
assert "45-maintainability-score.sh exists" "[ -f '$MODULE' ]"
assert "45-maintainability-score.sh syntax OK" "bash -n '$MODULE'"

# ── bash 3.2 compatibility (repo rule: no declare -A, no grep -P) ────────────
assert "no declare -A in module" \
  "! grep -v '^[[:space:]]*#' '$MODULE' | grep -q 'declare -A'"
assert "no grep -P in module" "! grep -q 'grep -P' '$MODULE'"

# Source the module once for the sanitizer / metric probes.
# The module ships its own `set -euo pipefail`; restore the harness policy
# afterwards so the deliberate non-zero probes below do not abort the run.
# shellcheck source=/dev/null
source "$MODULE" >/dev/null 2>&1
set +e

# ── Numeric sanitizers ───────────────────────────────────────────────────────
assert "_maint_int strips bc decimals (3.00 -> 3)"  "[ \"\$(_maint_int '3.00')\" = '3' ]"
assert "_maint_int strips bc decimals (26.00 -> 26)" "[ \"\$(_maint_int '26.00')\" = '26' ]"
assert "_maint_int survives grep -c '0\\n0'"        "[ \"\$(_maint_int \"\$(printf '0\\n0')\")\" = '0' ]"
assert "_maint_int handles empty string"            "[ \"\$(_maint_int '')\" = '0' ]"
assert "_maint_int handles garbage"                 "[ \"\$(_maint_int 'abc')\" = '0' ]"
assert "_maint_ratio_pct 7/20 -> 35"                "[ \"\$(_maint_ratio_pct 7 20)\" = '35' ]"
assert "_maint_ratio_pct 0/0 -> 0"                  "[ \"\$(_maint_ratio_pct 0 0)\" = '0' ]"
assert "_maint_clamp 140 -> 100"                    "[ \"\$(_maint_clamp 140 0 100)\" = '100' ]"
assert "_maint_clamp 5 -> 0"                        "[ \"\$(_maint_clamp 5 0 100)\" = '5' ]"

# ── Build a synthetic project fixture ────────────────────────────────────────
mkdir -p "$FIXTURE/proj/src/lib" "$FIXTURE/proj/tests/unit" \
         "$FIXTURE/proj/tests/integration" "$FIXTURE/proj/tests/e2e" \
         "$FIXTURE/proj/docs/adr" "$FIXTURE/proj/specs/catalog" \
         "$FIXTURE/proj/discipline/registry"
cat > "$FIXTURE/proj/src/lib/a.sh" <<'EOF'
foo() {
  echo foo
}
bar() {
  echo bar
}
EOF
cp "$FIXTURE/proj/src/lib/a.sh" "$FIXTURE/proj/src/lib/b.sh"
for n in 1 2 3; do echo "#!/usr/bin/env bash" > "$FIXTURE/proj/tests/unit/test_x$n.sh"; done
echo "x" > "$FIXTURE/proj/tests/integration/i1.sh"
echo "x" > "$FIXTURE/proj/tests/e2e/e1.sh"
echo "# README" > "$FIXTURE/proj/README.md"
echo "# ADR" > "$FIXTURE/proj/docs/adr/001-x.md"
echo "# spec" > "$FIXTURE/proj/specs/catalog/spec.md"
echo 'spec://feat/demo' > "$FIXTURE/proj/src/lib/a.sh.ref"
cat "$FIXTURE/proj/src/lib/a.sh.ref" >> "$FIXTURE/proj/src/lib/b.sh"
# 6 debt entries, ALL resolved -> 0 open. This is the exact input that used to
# yield the literal "0\n0" from `grep -c '"status": "open"' ... || echo 0`.
for i in 1 2 3 4 5 6; do
  echo "{\"id\":\"D-$i\",\"status\":\"resolved\"}" >> "$FIXTURE/proj/discipline/registry/debt.jsonl"
done

PROJ="$FIXTURE/proj"

# ── Each metric emits a bare integer on stdout (logs go to stderr) ───────────
for metric in calculate_test_coverage calculate_documentation_score \
              calculate_complexity_score calculate_debt_ratio_score \
              calculate_spec_citation_score; do
  out="$($metric "$PROJ" 2>/dev/null | tail -1)"
  assert "$metric returns an integer" "printf '%s' '$out' | grep -qE '^[0-9]+$'"
  assert "$metric stays within 0..100" "[ '$out' -ge 0 ] && [ '$out' -le 100 ]"
done

# ── Debt registry with zero open entries (the '0\\n0' regression) ────────────
debt_score="$(calculate_debt_ratio_score "$PROJ" 2>/dev/null | tail -1)"
assert "debt score with 0/6 open entries is numeric" "printf '%s' '$debt_score' | grep -qE '^[0-9]+$'"
assert "debt score with 0/6 open entries equals 100" "[ '$debt_score' = '100' ]"

# ── calculate_maintainability_score: numeric banner, exit 0 on success ────────
banner="$(calculate_maintainability_score "$PROJ" text 2>/dev/null)"
rc=$?
# Strip ANSI colour codes and keep a single line for the assertions below.
banner_plain="$(printf '%s' "$banner" | sed -e 's/\x1b\[[0-9;]*m//g')"
score="$(printf '%s\n' "$banner_plain" | grep -oE 'MAINTAINABILITY SCORE: [0-9]+' | head -1 | grep -oE '[0-9]+')"

assert "calculate_maintainability_score exits 0"    "[ '$rc' -eq 0 ]"
assert "banner prints MAINTAINABILITY SCORE: N/100" "printf '%s\n' \"\$banner_plain\" | grep -qE 'MAINTAINABILITY SCORE: [0-9]+/100'"
assert "banner never prints an empty score"        "! printf '%s\n' \"\$banner_plain\" | grep -q 'SCORE: /100'"
assert "banner prints a STATUS band"               "printf '%s\n' \"\$banner_plain\" | grep -qE 'STATUS: (EXCELLENT|GOOD|NEEDS IMPROVEMENT|CRITICAL)'"
assert "score was extracted"                       "printf '%s' \"\$score\" | grep -qE '^[0-9]+$'"
assert "score is inside 0..100"                    "[ '$score' -ge 0 ] && [ '$score' -le 100 ]"

# No arithmetic / comparison errors anywhere on stderr.
err_out="$(calculate_maintainability_score "$PROJ" text 2>&1 >/dev/null)"
assert "no arithmetic syntax error"        "! printf '%s' \"\$err_out\" | grep -qi 'arithmetic syntax error'"
assert "no integer-expression diagnostic" "! printf '%s' \"\$err_out\" | grep -qi 'integer expression expected'"

# A well-covered fixture must not be scored as CRITICAL.
assert "fixture project is not CRITICAL" "! printf '%s\n' \"\$banner_plain\" | grep -q 'STATUS: CRITICAL'"

# ── JSON output is machine-readable ──────────────────────────────────────────
json="$(calculate_maintainability_score "$PROJ" json 2>/dev/null)"
if command -v jq >/dev/null 2>&1; then
  assert "json output parses with jq" "printf '%s' \"\$json\" | jq -e . >/dev/null 2>&1"
  assert "overall_score is a number" "printf '%s' \"\$json\" | jq -e '.overall_score | type == \"number\"' >/dev/null 2>&1"
  assert "all metrics present" "printf '%s' \"\$json\" | jq -e '.metrics | has(\"test_coverage\") and has(\"documentation\") and has(\"complexity\") and has(\"debt_ratio\") and has(\"spec_citations\")' >/dev/null 2>&1"
  json_score="$(printf '%s' "$json" | jq -r '.overall_score')"
  assert "overall_score is inside 0..100" "[ '$json_score' -ge 0 ] && [ '$json_score' -le 100 ]"
fi

# ── Empty project (no src/, no tests/) still yields a number ────────────────
mkdir -p "$FIXTURE/empty"
empty_banner="$(calculate_maintainability_score "$FIXTURE/empty" text 2>/dev/null | sed -e 's/\x1b\[[0-9;]*m//g')"
assert "empty project banner has a number" "printf '%s' \"\$empty_banner\" | grep -qE 'MAINTAINABILITY SCORE: [0-9]+/100'"

# ── Genuine failures return non-zero, not the legacy band codes ─────────────
calculate_maintainability_score "$FIXTURE/does-not-exist" text >/dev/null 2>&1
assert "missing project root returns 1" "[ $? -eq 1 ]"
MAINTAINABILITY_CACHE="/proc/cannot-create/x" calculate_maintainability_score "$PROJ" text >/dev/null 2>&1
assert "unwritable cache returns 1" "[ $? -eq 1 ]"

# ── strict mode still exposes the legacy band exit codes ───────────────────
calculate_maintainability_score "$PROJ" text 1 >/dev/null 2>&1
strict_rc=$?
assert "strict mode returns a band code 0..3" "[ '$strict_rc' -ge 0 ] && [ '$strict_rc' -le 3 ]"

# ── Dashboard and CI gate ────────────────────────────────────────────────────
dash="$(render_maintainability_dashboard "$PROJ" 2>/dev/null | sed -e 's/\x1b\[[0-9;]*m//g')"
assert "dashboard prints an overall score" "printf '%s' \"\$dash\" | grep -qE 'Overall Score: [0-9]+/100'"
assert "dashboard does not abort on empty fields" "! printf '%s' \"\$dash\" | grep -q 'Overall Score: /100'"

maintainability_ci_gate "$PROJ" 1 >/dev/null 2>&1
assert "ci gate passes at threshold 1" "[ $? -eq 0 ]"
maintainability_ci_gate "$PROJ" 100 >/dev/null 2>&1
assert "ci gate fails at unreachable threshold" "[ $? -eq 1 ]"

# ── CLI entry point ──────────────────────────────────────────────────────────
assert "CLI calculate exits 0" "bash '$MODULE' calculate '$PROJ' text >/dev/null 2>&1"
assert "CLI help exits 0"     "bash '$MODULE' help >/dev/null 2>&1"

cleanup_test