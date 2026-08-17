#!/usr/bin/env bash
# test_caching.sh — test 56-caching.sh module
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0; FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

MODULE="$PROJECT_DIR/src/lib/56-caching.sh"
[ -f "$MODULE" ] && pass "56-caching.sh exists" || { fail "56-caching.sh missing"; exit 1; }
bash -n "$MODULE" 2>/dev/null && pass "56-caching.sh syntax OK" || fail "56-caching.sh syntax FAIL"

# Required stubs (mimic other tests' isolated-subshell pattern)
warn()  { :; }; log()  { :; }; info() { :; }; err() { :; }; section() { :; }
_step_skip() { return 1; }; _step_done() { :; }
_spin_start() { :; }; _spin_stop() { :; }
# Stub npm so the subshell-source does not trigger real `npm install -g`.
npm() { :; }

# Subshell test: source the module without actually installing
(
  HOME="$(mktemp -d)"
  export HOME
  # Module proceeds past the _step_skip guard (stub returns 1) and past the
  # SKIP_CACHING opt-out (unset); install/check helpers no-op via npm stub.
  source "$MODULE" 2>/dev/null
) && pass "56-caching.sh sources in subshell" || fail "56-caching.sh subshell source FAIL"

# Test module references each of the 5 cache packages
grep -q 'opencode-cache-injector' "$MODULE" && pass "opencode-cache-injector referenced" || fail "opencode-cache-injector NOT referenced"
grep -q 'opencode-cache-switch'    "$MODULE" && pass "opencode-cache-switch referenced"    || fail "opencode-cache-switch NOT referenced"
grep -q 'opencode-cache-ttl'       "$MODULE" && pass "opencode-cache-ttl referenced"       || fail "opencode-cache-ttl NOT referenced"
grep -q '@vikrant82/opencode-cache-keepalive' "$MODULE" && pass "opencode-cache-keepalive referenced" || fail "opencode-cache-keepalive NOT referenced"
grep -q 'opencode-cache-hit'       "$MODULE" && pass "opencode-cache-hit referenced"       || fail "opencode-cache-hit NOT referenced"

# Test the two required functions are defined
grep -q '_configure_cache()'        "$MODULE" && pass "_configure_cache defined"        || fail "_configure_cache missing"
grep -q '_register_cache_plugins()' "$MODULE" && pass "_register_cache_plugins defined" || fail "_register_cache_plugins missing"

# Test module references routing.json (cost_table validation source)
grep -q 'routing.json' "$MODULE" && pass "routing.json referenced" || fail "routing.json NOT referenced"

echo
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
