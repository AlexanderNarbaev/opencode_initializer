#!/usr/bin/env bash
# test_context_bundle.sh — test 55-context-bundle.sh module
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0; FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

MODULE="$PROJECT_DIR/src/lib/55-context-bundle.sh"
[ -f "$MODULE" ] && pass "55-context-bundle.sh exists" || { fail "55-context-bundle.sh missing"; exit 1; }
bash -n "$MODULE" 2>/dev/null && pass "55-context-bundle.sh syntax OK" || fail "55-context-bundle.sh syntax FAIL"

# Required stubs (mimic other tests' isolated-subshell pattern)
warn()  { :; }; log()  { :; }; info() { :; }; err() { :; }; section() { :; }
_step_skip() { return 1; }; _step_done() { :; }
_spin_start() { :; }; _spin_stop() { :; }

# Subshell test: source the module without actually installing
(
  HOME="$(mktemp -d)"
  export HOME
  # Module exits early via _step_skip in stub — that's fine.
  source "$MODULE" 2>/dev/null
) && pass "55-context-bundle.sh sources in subshell" || fail "55-context-bundle.sh subshell source FAIL"

# Hermetic assertions: a CI checkout has no user install and no rendered
# config, so verify the wiring where it actually lives in the repo — the
# module (install step) and the generator SSOT (18-opencode-json.sh,
# registering both plugins in the default tier since fe04857).
grep -q 'opencode-context' "$MODULE" && pass "opencode-context wired by module" || fail "opencode-context NOT wired by module"
grep -q 'opencode-router' "$MODULE" && pass "opencode-router wired by module" || fail "opencode-router NOT wired by module"

GEN="$PROJECT_DIR/src/lib/18-opencode-json.sh"
[ -f "$GEN" ] && pass "18-opencode-json.sh exists" || fail "18-opencode-json.sh missing"
if [ -f "$GEN" ] && grep -qF '"opencode-context"' "$GEN"; then
  pass "opencode-context registered in generator plugin tier"
else
  fail "opencode-context missing from generator (expected since fe04857)"
fi
if [ -f "$GEN" ] && grep -qF '"opencode-router"' "$GEN"; then
  pass "opencode-router registered in generator plugin tier"
else
  fail "opencode-router missing from generator (expected since fe04857)"
fi

# Test shared bundle.json is written (or at least the function exists)
grep -q '_write_bundle_config' "$MODULE" && pass "_write_bundle_config defined" || fail "_write_bundle_config missing"
grep -q 'bundle.json' "$MODULE" && pass "bundle.json referenced" || fail "bundle.json NOT referenced"

echo
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1