#!/usr/bin/env bash
# test_local_memory.sh — test 59-local-memory.sh module
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0; FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

MODULE="$PROJECT_DIR/src/lib/59-local-memory.sh"
[ -f "$MODULE" ] && pass "59-local-memory.sh exists" || { fail "59-local-memory.sh missing"; exit 1; }
bash -n "$MODULE" 2>/dev/null && pass "59-local-memory.sh syntax OK" || fail "59-local-memory.sh syntax FAIL"

# Required stubs (mimic other tests' isolated-subshell pattern)
warn()  { :; }; log()  { :; }; info() { :; }; err() { :; }; section() { :; }
_step_skip() { return 1; }; _step_done() { :; }
_spin_start() { :; }; _spin_stop() { :; }

# Subshell test: source the module without actually installing
(
  HOME="$(mktemp -d)"
  export HOME
  source "$MODULE" 2>/dev/null
) && pass "59-local-memory.sh sources in subshell" || fail "59-local-memory.sh subshell source FAIL"

# Function + references (do NOT assert binary presence — installs are opt-in)
grep -q '_write_memory_config' "$MODULE" && pass "_write_memory_config defined" || fail "_write_memory_config missing"
grep -q 'opencode-mem' "$MODULE" && pass "opencode-mem referenced" || fail "opencode-mem NOT referenced"
grep -q 'LOCAL_MEMORY_ENABLED' "$MODULE" && pass "LOCAL_MEMORY_ENABLED gate present" || fail "LOCAL_MEMORY_ENABLED gate missing"
grep -q 'step_local_memory' "$MODULE" && pass "step_local_memory guard present" || fail "step_local_memory guard missing"

echo
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
