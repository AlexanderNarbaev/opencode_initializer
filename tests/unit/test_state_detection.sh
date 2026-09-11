#!/usr/bin/env bash
# ============================================================================
# Unit tests for state-detection helpers added to 00-core.sh:
#   _port_listening_owner, _state_check_binary, _state_check_port,
#   _state_check_file, _state_check_service
# Run: bash tests/unit/test_state_detection.sh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
CORE="$PROJECT_DIR/src/lib/00-core.sh"
INFRA="$PROJECT_DIR/src/lib/30-infra.sh"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== Test 1: helper functions exist in 00-core.sh ==="
for fn in _port_listening_owner _state_check_binary _state_check_port _state_check_file _state_check_service; do
  if grep -qE "^${fn}\(\)" "$CORE"; then pass "$fn defined"
  else fail "$fn missing"; fi
done

echo
echo "=== Test 2: pre-flight block exists in 30-infra.sh ==="
# Look for the signature of the pre-flight block we added
if grep -q "Pre-flight: detect host-port collisions BEFORE compose up" "$INFRA"; then
  pass "pre-flight section header present"
else
  fail "pre-flight section header missing in 30-infra.sh"
fi
if grep -q "_port_listening_owner" "$INFRA"; then
  pass "_port_listening_owner used by 30-infra.sh pre-flight"
else
  fail "_port_listening_owner NOT wired into 30-infra.sh"
fi
if grep -q "_find_free_port" "$INFRA"; then
  pass "_find_free_port used for auto-shift"
else
  fail "_find_free_port NOT used for auto-shift"
fi

echo
echo "=== Test 3: infra.yml template uses QDRANT_GRPC_PORT for qdrant_grpc ==="
# The hardcoded 6334 in the qdrant service must be env-overridable now.
if grep -qE "127\.0\.0\.1:\\\${QDRANT_GRPC_PORT:-6334}" "$INFRA"; then
  pass "infra.yml qdrant uses \${QDRANT_GRPC_PORT:-6334}"
else
  fail "infra.yml qdrant does NOT use \${QDRANT_GRPC_PORT:-6334}"
fi

echo
echo "=== Test 4: dev state subcommand registered in dev.sh ==="
DEV="$PROJECT_DIR/dev.sh"
if grep -q "cmd_state()" "$DEV"; then pass "cmd_state function defined"
else fail "cmd_state function missing"; fi
if grep -qE "^\s*state\) cmd_state " "$DEV"; then pass "state dispatch entry present"
else fail "state dispatch entry missing"; fi
if grep -q 'dev state \[--strict\]' "$DEV"; then pass "state in usage block"
else fail "state not documented in usage"; fi

echo
echo "=== Test 5: runtime behavior of _port_listening_owner ==="
# Use a temp HOME so the test is hermetic
TMPDIR_TEST="$(mktemp -d /tmp/opencode-state-test.XXXXXX)"
HOME_BACKUP="$HOME"
export HOME="$TMPDIR_TEST"
mkdir -p "$HOME/.cache/opencode-setup" "$HOME/.config/opencode-setup"

# shellcheck disable=SC1091
source "$PROJECT_DIR/src/lib/helpers.sh" >/dev/null
# shellcheck disable=SC1091
source "$CORE" >/dev/null
set +e  # state checks return non-zero intentionally

# Free port → empty
out=$(_port_listening_owner 9999)
[ -z "$out" ] && pass "free port 9999 returns empty string" || fail "free port 9999 returned '$out'"

# Bound port (we hope at least one canonical port is bound on the test host;
# if none is, fall back to bound-on-factory-test check below)
if ! _port_is_free 5432 2>/dev/null; then
  out=$(_port_listening_owner 5432)
  [ -n "$out" ] && pass "bound port 5432 returns non-empty: $out" || fail "bound port 5432 returned empty"
else
  echo "  SKIP: no bound port detected on test host (5432 free); skipping bound-port assertion"
fi

# Helper must not crash on bad input
out=$(_port_listening_owner 99999)
[ -z "$out" ] && pass "high free port 99999 returns empty" || fail "high free port 99999 returned '$out'"

set -e
export HOME="$HOME_BACKUP"

echo
echo "=== Test 6: dev state runs end-to-end ==="
# Use the actual dev.sh dispatch. There ARE drift items on a real host
# (the rag-qdrant/rag-redis collisions and stuck opencode containers), so
# --strict must exit non-zero. The unadorned `state` must always exit 0.
# NOTE: temporarily disable -e so non-zero exits from $() don't abort the test.
SCRIPTS_DIR="$PROJECT_DIR"
set +e

# Run with timeout protection (60s should be plenty; default is unbounded)
out_strict="$(timeout 60 bash "$DEV" state --strict 2>&1)"
rc_strict=$?
if [ "$rc_strict" -eq 1 ]; then
  pass "dev state --strict exits 1 when drift present (rc=$rc_strict)"
else
  fail "dev state --strict exited $rc_strict (expected 1 when drift present)"
fi
if printf '%s' "$out_strict" | grep -q "BOUND"; then
  pass "dev state shows port bindings"
else
  fail "dev state output missing BOUND entries"
fi
if printf '%s' "$out_strict" | grep -qE "RUNNING|STOPPED|ABSENT"; then
  pass "dev state shows docker service status"
else
  fail "dev state output missing docker status"
fi

# Unadorned dev state should always exit 0 (informational)
out_plain="$(timeout 60 bash "$DEV" state 2>&1)"
rc_plain=$?
if [ "$rc_plain" -eq 0 ]; then
  pass "dev state (no --strict) exits 0 (informational mode)"
else
  fail "dev state (no --strict) exited $rc_plain (expected 0)"
fi

set -e

echo
echo "=========================================="
echo "RESULTS: $PASS pass, $FAIL fail"
echo "=========================================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
