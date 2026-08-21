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

# Test opencode-context and opencode-router binaries exist
command -v opencode-context >/dev/null 2>&1 && pass "opencode-context binary installed" || fail "opencode-context binary missing"
command -v opencode-router  >/dev/null 2>&1 && pass "opencode-router binary installed"  || fail "opencode-router binary missing"

# Test opencode.json does NOT have opencode-context/router in plugin array
# (they hang agent list in current versions — installed as CLI binaries only)
CFG="${XDG_CONFIG_HOME:-$HOME/.config/opencode/opencode.json}"
[ -f "$CFG" ] || CFG="/home/alexandr-narbaev/.config/opencode/opencode.json"
if [ -f "$CFG" ]; then
  if grep -qE '"opencode-context"[\s,]' "$CFG"; then
    fail "opencode-context SHOULD NOT be in plugin[] (hangs agent list)"
  else
    pass "opencode-context correctly absent from plugin[]"
  fi
  if grep -qE '"opencode-router"[\s,]' "$CFG"; then
    fail "opencode-router SHOULD NOT be in plugin[] (hangs agent list)"
  else
    pass "opencode-router correctly absent from plugin[]"
  fi
else
  fail "opencode.json not found"
fi

# Test shared bundle.json is written (or at least the function exists)
grep -q '_write_bundle_config' "$MODULE" && pass "_write_bundle_config defined" || fail "_write_bundle_config missing"
grep -q 'bundle.json' "$MODULE" && pass "bundle.json referenced" || fail "bundle.json NOT referenced"

echo
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1