#!/usr/bin/env bash
# tests/unit/test_modes.sh — Mode-specific tests for src/modes/*.sh
# Tests that each mode script exists, has valid syntax, and produces expected output.
set -euo pipefail

PASS=0; FAIL=0; TOTAL=0
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$_script_dir/src/lib/helpers.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00-core.sh" 2>/dev/null || true

assert_eq() {
  TOTAL=$((TOTAL + 1))
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}✓${NC} %s\n" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf "  ${RED}✗${NC} %s\n  expected: %s\n  actual:   %s\n" "$desc" "$expected" "$actual"
  fi
}

assert_exit() {
  TOTAL=$((TOTAL + 1))
  local desc="$1" expected="$2" cmd="$3"
  local actual
  actual=0
  eval "$cmd" >/dev/null 2>&1 || actual=$?
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}✓${NC} %s\n" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf "  ${RED}✗${NC} %s\n  expected exit: %s\n  actual exit:   %s\n" "$desc" "$expected" "$actual"
  fi
}

assert_contains() {
  TOTAL=$((TOTAL + 1))
  local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -q "$needle"; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}✓${NC} %s\n" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf "  ${RED}✗${NC} %s\n  missing: %s\n" "$desc" "$needle"
  fi
}

echo "─── Mode Script Tests ───"
echo

# ── Test 1: All mode scripts exist ──────────────────────────────────────────
echo "1. Mode scripts exist"
for mode in health ci interactive upgrade fix-zshrc new; do
  assert_exit "src/modes/$mode.sh exists" "0" "[ -f $_script_dir/src/modes/$mode.sh ]"
done

# ── Test 2: All mode scripts have valid bash syntax ─────────────────────────
echo
echo "2. Mode scripts have valid syntax"
for mode in health ci interactive upgrade fix-zshrc new; do
  assert_exit "bash -n src/modes/$mode.sh" "0" "bash -n $_script_dir/src/modes/$mode.sh"
done

# ── Test 3: health.sh structure ─────────────────────────────────────────────
echo
echo "3. health.sh structure"
health_content="$(cat "$_script_dir/src/modes/health.sh")"
assert_contains "health.sh has section function" "section" "$health_content"
assert_contains "health.sh has _check function" "_check" "$health_content"
assert_contains "health.sh checks Docker" "Docker" "$health_content"
assert_contains "health.sh checks Node.js" "Node.js" "$health_content"
assert_contains "health.sh checks Python" "Python" "$health_content"
assert_contains "health.sh checks MCP Servers" "MCP Servers" "$health_content"
assert_contains "health.sh checks LSP Servers" "LSP Servers" "$health_content"
assert_contains "health.sh checks Services" "Services" "$health_content"
assert_contains "health.sh checks Config" "Config" "$health_content"
assert_contains "health.sh has PASS/FAIL counters" "PASS=" "$health_content"
assert_contains "health.sh exits cleanly" "exit 0" "$health_content"

# ── Test 4: ci.sh structure ─────────────────────────────────────────────────
echo
echo "4. ci.sh structure"
ci_content="$(cat "$_script_dir/src/modes/ci.sh")"
assert_contains "ci.sh checks MODE" "MODE" "$ci_content"
assert_contains "ci.sh has non-interactive logic" "CI" "$ci_content"
assert_contains "ci.sh has TOTAL_STEPS" "TOTAL_STEPS" "$ci_content"
assert_contains "ci.sh generates opencode.json" "opencode.json" "$ci_content"

# ── Test 5: interactive.sh structure ────────────────────────────────────────
echo
echo "5. interactive.sh structure"
interactive_content="$(cat "$_script_dir/src/modes/interactive.sh")"
assert_contains "interactive.sh has read/prompt" "read" "$interactive_content"
assert_contains "interactive.sh has section" "section" "$interactive_content"

# ── Test 6: upgrade.sh structure ────────────────────────────────────────────
echo
echo "6. upgrade.sh structure"
upgrade_content="$(cat "$_script_dir/src/modes/upgrade.sh")"
assert_contains "upgrade.sh has section" "section" "$upgrade_content"
assert_contains "upgrade.sh has git pull" "git" "$upgrade_content"

# ── Test 7: fix-zshrc.sh structure ──────────────────────────────────────────
echo
echo "7. fix-zshrc.sh structure"
fix_zshrc_content="$(cat "$_script_dir/src/modes/fix-zshrc.sh")"
assert_contains "fix-zshrc.sh checks .zshrc" ".zshrc" "$fix_zshrc_content"
assert_contains "fix-zshrc.sh has Python repair" "python3" "$fix_zshrc_content"
assert_contains "fix-zshrc.sh fixes P10k" "P10k" "$fix_zshrc_content"

# ── Test 8: new.sh structure ────────────────────────────────────────────────
echo
echo "8. new.sh structure"
new_content="$(cat "$_script_dir/src/modes/new.sh")"
assert_contains "new.sh has section" "section" "$new_content"

# ── Test 9: health.sh can be sourced (syntax check) ────────────────────────
echo
echo "9. health.sh syntax valid"
assert_exit "bash -n health.sh" "0" "bash -n $_script_dir/src/modes/health.sh"

# ── Test 10: ci.sh syntax valid ────────────────────────────────────────────
echo
echo "10. ci.sh syntax valid"
assert_exit "bash -n ci.sh" "0" "bash -n $_script_dir/src/modes/ci.sh"

# ── Summary ─────────────────────────────────────────────────────────────────
echo
echo "─── Results: $PASS/$TOTAL passed, $FAIL failed ───"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
