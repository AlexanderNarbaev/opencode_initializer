#!/usr/bin/env bash
# test_context_guard.sh — test 57-context-guard.sh module
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0; FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

MODULE="$PROJECT_DIR/src/lib/57-context-guard.sh"
[ -f "$MODULE" ] && pass "57-context-guard.sh exists" || { fail "57-context-guard.sh missing"; exit 1; }
bash -n "$MODULE" 2>/dev/null && pass "57-context-guard.sh syntax OK" || fail "57-context-guard.sh syntax FAIL"

# Required stubs (mimic other tests' isolated-subshell pattern)
warn()  { :; }; log()  { :; }; info() { :; }; err() { :; }; section() { :; }
_step_skip() { return 1; }; _step_done() { :; }
_spin_start() { :; }; _spin_stop() { :; }

# Subshell test: source the module without actually installing
(
  HOME="$(mktemp -d)"
  export HOME
  source "$MODULE" 2>/dev/null
) && pass "57-context-guard.sh sources in subshell" || fail "57-context-guard.sh subshell source FAIL"

# Test the config writer + referenced artifacts are present
grep -q '_write_context_guard_config' "$MODULE" && pass "_write_context_guard_config defined" || fail "_write_context_guard_config missing"
grep -q 'context-guard.json' "$MODULE" && pass "context-guard.json referenced" || fail "context-guard.json NOT referenced"
grep -q '@skybluejacket/opencode-context-compress' "$MODULE" && pass "@skybluejacket/opencode-context-compress referenced" || fail "@skybluejacket/opencode-context-compress NOT referenced"
grep -q 'opencode-context-guard' "$MODULE" && pass "opencode-context-guard referenced" || fail "opencode-context-guard NOT referenced"
grep -q 'opencode-context-watch' "$MODULE" && pass "opencode-context-watch referenced" || fail "opencode-context-watch NOT referenced"
grep -q 'step_context_guard' "$MODULE" && pass "step_context_guard guard present" || fail "step_context_guard guard NOT present"

echo
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
