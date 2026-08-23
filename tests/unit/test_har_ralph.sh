#!/usr/bin/env bash
# ============================================================================
# Unit tests for `har ralph` — bounded health-convergence loop (Ralph Loop)
# Tests: syntax, function/dispatch presence, version, help, arg parsing,
#        missing-setup guard, and convergence/divergence via a hermetic stub
#        setup.sh (NO real setup.sh --health/--fix-config is ever invoked).
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
HAR="$PROJECT_DIR/scripts/har"
TESTS_PASS=0; TESTS_FAIL=0

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $desc" >&2
  fi
}

TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

# ── Static presence ───────────────────────────────────────────────────────
assert "har ralph: syntax (bash -n)"  "bash -n '$HAR'"
assert "har ralph: function defined"  "grep -q '^har_ralph()' '$HAR'"
assert "har ralph: dispatch case"     "grep -qE '^[[:space:]]*ralph[)]' '$HAR'"

# ── Version ───────────────────────────────────────────────────────────────
ver_out="$(bash "$HAR" version 2>/dev/null)"
assert "har version rc=0 + 1.1.0" '[ "$(bash "$HAR" version >/dev/null 2>&1; echo $?)" = "0" ] && echo "$ver_out" | grep -q "1.1.0"'

# ── Help / arg parsing (non-mutating) ─────────────────────────────────────
help_out="$(bash "$HAR" ralph --help 2>/dev/null)"
assert "ralph --help rc=0"           '[ "$(bash "$HAR" ralph --help >/dev/null 2>&1; echo $?)" = "0" ]'
assert "ralph --help mentions loop"  'echo "$help_out" | grep -q "Bounded health-convergence loop"'
assert "ralph --help mentions --max" 'echo "$help_out" | grep -q -- "--max"'
assert "ralph --help mentions --dry-run" 'echo "$help_out" | grep -q -- "--dry-run"'

# ── Bad option / missing setup ────────────────────────────────────────────
assert "ralph unknown option rc=2" '[ "$(bash "$HAR" ralph --badopt >/dev/null 2>&1; echo $?)" = "2" ]'
missing_out="$(bash "$HAR" ralph --setup /nonexistent/setup.sh 2>&1 || true)"
assert "ralph missing setup rc=2"    '[ "$(bash "$HAR" ralph --setup /nonexistent/setup.sh >/dev/null 2>&1; echo $?)" = "2" ]'
assert "ralph missing setup message" 'echo "$missing_out" | grep -q "setup.sh not found"'

# ── Hermetic convergence via stub setup.sh ────────────────────────────────
# Stub A: always healthy -> converges immediately.
cat > "$TMPDIR/healthy.sh" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  --health) exit 0 ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$TMPDIR/healthy.sh"
assert "ralph: converges on healthy" '[ "$(bash "$HAR" ralph --setup "$TMPDIR/healthy.sh" >/dev/null 2>&1; echo $?)" = "0" ]'

# Stub B: unhealthy first, healthy after first heal round -> converges in 2.
cat > "$TMPDIR/one_fix.sh" <<'EOF'
#!/usr/bin/env bash
cnt_file="$(dirname "$0")/cnt"
case "$1" in
  --health)
    if [ ! -f "$cnt_file" ]; then echo 1 > "$cnt_file"; exit 1; fi
    exit 0 ;;
  --fix-config) : ;;
  --fix-zshrc) : ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$TMPDIR/one_fix.sh"
assert "ralph: converges after heal" '[ "$(bash "$HAR" ralph --max 3 --setup "$TMPDIR/one_fix.sh" >/dev/null 2>&1; echo $?)" = "0" ]'

# Stub C: permanently unhealthy -> dry-run reports would-heal and exits 0.
cat > "$TMPDIR/sick.sh" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  --health) exit 1 ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$TMPDIR/sick.sh"
dry_out="$(bash "$HAR" ralph --max 2 --dry-run --setup "$TMPDIR/sick.sh" 2>&1 || true)"
# Dry-run reports what it WOULD heal but never applies heals, so it cannot
# converge on a permanently-unhealthy stub -> exits 1 with the would-heal hints.
assert "ralph --dry-run rc=1 (no converge)" '[ "$(bash "$HAR" ralph --max 2 --dry-run --setup "$TMPDIR/sick.sh" >/dev/null 2>&1; echo $?)" = "1" ]'
assert "ralph --dry-run reports would-heal" 'echo "$dry_out" | grep -q "would heal"'

# Stub D: permanently unhealthy, no dry-run -> does not converge, rc=1.
assert "ralph: non-convergence rc=1" '[ "$(bash "$HAR" ralph --max 2 --setup "$TMPDIR/sick.sh" >/dev/null 2>&1; echo $?)" = "1" ]'

# ── Summary ──────────────────────────────────────────────────────────────
echo
echo "=== test_har_ralph.sh: $TESTS_PASS passed, $TESTS_FAIL failed ==="
[ "$TESTS_FAIL" -eq 0 ] || exit 1
