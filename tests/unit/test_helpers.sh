#!/usr/bin/env bash
# ============================================================================
# Unit tests for helpers.sh and 00-core.sh functions
# Tests: _curl, _retry, _npm_install, _step_skip, _step_done, _pkg_install,
#        _pkg_update, log, warn, err, info, section, _sudo, _dry, _spin, _gate
# Approach: source only helpers.sh (fast), validate 00-core.sh via grep.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
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

TMPDIR=$(mktemp -d /tmp/test_helpers.XXXXXX)
cleanup_test() { rm -rf "$TMPDIR"; }
trap cleanup_test EXIT

export HOME="$TMPDIR/home"
mkdir -p "$HOME/.cache/opencode-setup" "$HOME/.config/opencode" "$HOME/.local/bin"

echo "=== Testing helper functions ==="

# ── Source helpers.sh only (not 00-core to avoid network calls) ──────
source "$PROJECT_DIR/lib/helpers.sh"
trap cleanup_test EXIT

DL_CACHE="$HOME/.cache/opencode-setup"
MCP_CACHE="$DL_CACHE/mcp-offline"
mkdir -p "$MCP_CACHE"
SECRETS_FILE="$HOME/.config/opencode/secrets.env"

# ── Function existence ──────────────────────────────────────────────────
for fn in log warn err info section cleanup _curl _retry _npm_install _sudo; do
  assert "$fn function exists" "type $fn &>/dev/null"
done

# ── Environment setup ───────────────────────────────────────────────────
assert "SCRIPT_DIR is set"             "[ -n '$SCRIPT_DIR' ]"
assert "DL_CACHE exists as dir"        "[ -d '$DL_CACHE' ]"
assert "MCP_CACHE exists as dir"       "[ -d '$MCP_CACHE' ]"

# ── log/warn/info output ────────────────────────────────────────────────
assert "log outputs to stdout"    "log 't1' 2>/dev/null | grep -q 't1'"
assert "warn outputs to stderr"   "warn 't2' 2>&1 1>/dev/null | grep -q 't2'"
assert "info outputs to stdout"   "info 't3' 2>/dev/null | grep -q 't3'"
assert "section outputs to stdout" "section 't4' 2>/dev/null | grep -q 't4'"

# ── _retry function ─────────────────────────────────────────────────────
assert "_retry succeeds on true" "_retry 1 'test' true 2>/dev/null"

# ── _curl caching behavior ──────────────────────────────────────────────
if command -v curl &>/dev/null; then
  TMP_OUT="$TMPDIR/curl_test_output"
  _curl "https://httpbin.org/get" "$TMP_OUT" 2>/dev/null || true
  CACHE_KEY=$(echo "https://httpbin.org/get" | md5sum | awk '{print $1}')
  CACHE_FILE="$DL_CACHE/${CACHE_KEY}.dl"
  if [ -f "$CACHE_FILE" ]; then
    assert "_curl creates cache file" "true"
  else
    assert "_curl creates cache file" "false"
  fi
  rm -f "$TMP_OUT"
else
  assert "_curl skip (no curl)" "true"
fi

# ── _npm_install exists ─────────────────────────────────────────────────
assert "_npm_install is defined" "type _npm_install &>/dev/null"

# ── Verify helpers.sh source structure ──────────────────────────────────
H="$PROJECT_DIR/lib/helpers.sh"
assert "helpers.sh defines GREEN"    'grep -q "GREEN=" "'"$H"'"'
assert "helpers.sh defines cleanup"  'grep -q "cleanup()" "'"$H"'"'
assert "helpers.sh defines _curl"    'grep -q "_curl()" "'"$H"'"'
assert "helpers.sh defines _retry"   'grep -q "_retry()" "'"$H"'"'
assert "helpers.sh defines _npm_install" 'grep -q "_npm_install()" "'"$H"'"'
assert "helpers.sh has SCRIPT_DIR"   'grep -q "SCRIPT_DIR=" "'"$H"'"'
assert "helpers.sh has DL_CACHE"     'grep -q "DL_CACHE=" "'"$H"'"'

# ── Verify 00-core.sh structure (without sourcing) ──────────────────────
C="$PROJECT_DIR/lib/00-core.sh"
assert "00-core.sh has version"      'grep -q "SCRIPT_VERSION" "'"$C"'"'
assert "00-core.sh has ARCH"         'grep -q "ARCH=" "'"$C"'"'
assert "00-core.sh has PKG_MANAGER"  'grep -q "PKG_MANAGER" "'"$C"'"'
assert "00-core.sh has _pkg_install" 'grep -q "_pkg_install()" "'"$C"'"'
assert "00-core.sh has _pkg_update"  'grep -q "_pkg_update()" "'"$C"'"'
assert "00-core.sh has _mirror_url"  'grep -q "_mirror_url()" "'"$C"'"'
assert "00-core.sh has _step_skip"   'grep -q "_step_skip()" "'"$C"'"'
assert "00-core.sh has _step_done"   'grep -q "_step_done()" "'"$C"'"'
assert "00-core.sh has _spin"        'grep -q "_spin()" "'"$C"'"'
assert "00-core.sh has _gate"        'grep -q "_gate()" "'"$C"'"'
assert "00-core.sh has _dry"         'grep -q "_dry()" "'"$C"'"'
assert "00-core.sh has MCP_PACKAGES" 'grep -q "MCP_PACKAGES=" "'"$C"'"'
assert "00-core.sh has v34.0"        'grep -q "v34.0" "'"$C"'"'

# ── Verify MCP registry contents ────────────────────────────────────────
for mcp in context7 filesystem agentic-tools codegraph playwright agent-browser loopsense github postgres gitlab google-maps sequential-thinking memorylayer; do
  assert "MCP registry includes $mcp" 'grep -F "['"$mcp"']" "'"$C"'"'
done

# ── Verify mirror URL variables defined ─────────────────────────────────
for mirror in GITHUB_MIRROR NPM_REGISTRY PYPI_MIRROR DOCKER_MIRROR GO_MIRROR RUSTUP_MIRROR ZIG_MIRROR JAVA_MIRROR; do
  assert "$mirror in source" 'grep -q "'"$mirror"'" "'"$C"'"'
done

# ── Summary ─────────────────────────────────────────────────────────────
echo
echo "=== test_helpers.sh: $TESTS_PASS passed, $TESTS_FAIL failed ==="
[ "$TESTS_FAIL" -eq 0 ] || exit 1
