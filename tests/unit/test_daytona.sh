#!/usr/bin/env bash
# test_daytona.sh — test 61-daytona.sh module + daytona-env wrapper
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0; FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

MODULE="$PROJECT_DIR/src/lib/61-daytona.sh"
WRAPPER="$PROJECT_DIR/scripts/daytona-env.sh"
[ -f "$MODULE" ]  && pass "61-daytona.sh exists"  || { fail "61-daytona.sh missing"; exit 1; }
[ -f "$WRAPPER" ] && pass "daytona-env.sh exists" || fail "daytona-env.sh missing"

bash -n "$MODULE"  2>/dev/null && pass "61-daytona.sh syntax OK"   || fail "61-daytona.sh syntax FAIL"
bash -n "$WRAPPER" 2>/dev/null && pass "daytona-env.sh syntax OK" || fail "daytona-env.sh syntax FAIL"

# Required stubs (mimic other tests' isolated-subshell pattern)
warn() { :; }; log() { :; }; info() { :; }; err() { :; }; section() { :; }
_step_skip() { return 1; }; _step_done() { :; }
_spin_start() { :; }; _spin_stop() { :; }
_curl() { return 1; }; _sudo() { return 0; }

# Subshell source without installing (network stubbed via _curl returning 1)
(
  HOME="$(mktemp -d)"
  export HOME
  source "$MODULE" 2>/dev/null
) && pass "61-daytona.sh sources in subshell" || fail "61-daytona.sh subshell source FAIL"

# SKIP_DAYTONA=true → early return (isolated)
(
  HOME="$(mktemp -d)"
  SKIP_DAYTONA=true
  export HOME SKIP_DAYTONA
  info() { echo "$*"; }
  out="$(source "$MODULE" 2>&1)"
  echo "$out" | grep -q "SKIP_DAYTONA=true" && exit 0 || exit 1
) && pass "SKIP_DAYTONA=true early-returns" || fail "SKIP_DAYTONA guard not honored"

# Content assertions on the module
grep -q 'step_daytona' "$MODULE"            && pass "step_daytona guard present" || fail "step_daytona guard missing"
grep -q 'SKIP_DAYTONA' "$MODULE"            && pass "SKIP_DAYTONA opt-out present" || fail "SKIP_DAYTONA missing"
grep -q 'releases/latest/download/' "$MODULE" && pass "releases/latest/download URL present" || fail "releases/latest/download URL missing"
grep -q 'daytonaio/cli/daytona' "$MODULE"   && pass "brew tap daytonaio/cli/daytona present" || fail "brew tap missing"
grep -q 'DAYTONA_API_KEY' "$MODULE"         && pass "DAYTONA_API_KEY mention present" || fail "DAYTONA_API_KEY missing"
grep -q 'managed_by' "$MODULE"              && pass "managed_by field present" || fail "managed_by missing"
if grep -qE '(curl|wget)[^#]*get\.daytona\.io' "$MODULE"; then fail "legacy get.daytona.io installer present"; else pass "no legacy get.daytona.io installer"; fi

# Content assertions on the wrapper
for sub in list create status delete prune help; do
  grep -q "$sub" "$WRAPPER" && pass "daytona-env subcommand '$sub' present" || fail "daytona-env subcommand '$sub' missing"
done
grep -q 'DAYTONA_ENVIRONMENTS' "$WRAPPER"   && pass "DAYTONA_ENVIRONMENTS override present" || fail "DAYTONA_ENVIRONMENTS missing"
if grep -q 'declare -A\|typeset -A' "$WRAPPER"; then fail "wrapper uses associative arrays (not bash3.2-safe)"; else pass "wrapper bash3.2-safe (no assoc arrays)"; fi

# Wrapper functional smoke: list against a temp registry via DAYTONA_ENVIRONMENTS
TMP_HOME="$(mktemp -d)"
mkdir -p "$TMP_HOME/.config/opencode/daytona"
cat > "$TMP_HOME/.config/opencode/daytona/environments.json" <<'EOF'
{"version":1,"managed_by":"test","defaults":{"cpu":2,"memory_gb":4,"disk_gb":10,"auto_stop_minutes":15,"target":"us"},"environments":[{"name":"dev-minimal","image":{"snapshot":"debian-slim"},"labels":["dev"]}]}
EOF
out="$(DAYTONA_ENVIRONMENTS="$TMP_HOME/.config/opencode/daytona/environments.json" bash "$WRAPPER" list 2>&1)"
echo "$out" | grep -q "dev-minimal" && pass "daytona-env list renders entries" || fail "daytona-env list failed: $out"

# create without daytona CLI → composes command, warns, non-zero exit
if command -v daytona >/dev/null 2>&1; then
  pass "daytona CLI present (skip warn-path check)"
else
  out="$(DAYTONA_ENVIRONMENTS="$TMP_HOME/.config/opencode/daytona/environments.json" bash "$WRAPPER" create dev-minimal 2>&1 || true)"
  echo "$out" | grep -q "Composed: daytona create" && pass "create composes daytona command" || fail "create did not compose command: $out"
  echo "$out" | grep -q "WARN: daytona CLI not found" && pass "create warns when CLI missing" || fail "create missing warn"
fi

rm -rf "$TMP_HOME"

echo
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
