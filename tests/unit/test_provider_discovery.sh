#!/usr/bin/env bash
# test_provider_discovery.sh — test 58-provider-discovery.sh module
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0; FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

MODULE="$PROJECT_DIR/src/lib/58-provider-discovery.sh"
[ -f "$MODULE" ] && pass "58-provider-discovery.sh exists" || { fail "58-provider-discovery.sh missing"; exit 1; }
bash -n "$MODULE" 2>/dev/null && pass "58-provider-discovery.sh syntax OK" || fail "58-provider-discovery.sh syntax FAIL"

# Required stubs (mimic other tests' isolated-subshell pattern)
warn()  { :; }; log()  { :; }; info() { :; }; err() { :; }; section() { :; }
_step_skip() { return 1; }; _step_done() { :; }
_spin_start() { :; }; _spin_stop() { :; }

# Subshell test: source the module against a throwaway HOME (no real opencode.json)
(
  HOME="$(mktemp -d)"
  export HOME
  unset XDG_CONFIG_HOME
  source "$MODULE" 2>/dev/null
) && pass "58-provider-discovery.sh sources in subshell" || fail "58-provider-discovery.sh subshell source FAIL"

# Module references both packages and the opm binary
grep -q 'opencode-models-discovery' "$MODULE" && pass "opencode-models-discovery referenced" || fail "opencode-models-discovery NOT referenced"
grep -q 'opencode-provider-manager' "$MODULE" && pass "opencode-provider-manager referenced" || fail "opencode-provider-manager NOT referenced"
grep -q 'opm' "$MODULE" && pass "opm referenced" || fail "opm NOT referenced"

# Register + guard functions defined
grep -q '_register_provider_discovery_plugins' "$MODULE" && pass "_register_provider_discovery_plugins defined" || fail "_register_provider_discovery_plugins missing"
grep -q 'step_provider_discovery' "$MODULE" && pass "step_provider_discovery guard present" || fail "step_provider_discovery guard missing"

echo
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
