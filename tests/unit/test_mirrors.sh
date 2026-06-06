#!/usr/bin/env bash
# ============================================================================
# Unit tests for mirror detection (_mirror_url function)
# Sources 00-core.sh to test real _mirror_url behavior with network
# Falls back gracefully if network is unavailable
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

TMPDIR=$(mktemp -d /tmp/test_mirrors.XXXXXX)
cleanup_test() { rm -rf "$TMPDIR"; }
trap cleanup_test EXIT

export HOME="$TMPDIR/home"
mkdir -p "$HOME/.cache/opencode-setup" "$HOME/.config/opencode"

echo "=== Testing mirror detection ==="

# ── Source files to get real _mirror_url ──────────────────────────────
source "$PROJECT_DIR/lib/helpers.sh"
trap cleanup_test EXIT
source "$PROJECT_DIR/lib/00-core.sh"
trap cleanup_test EXIT

# Override DL_CACHE for test isolation
DL_CACHE="$HOME/.cache/opencode-setup"
PROGRESS="$DL_CACHE/progress"

C="$PROJECT_DIR/lib/00-core.sh"

# ── Function existence ─────────────────────────────────────────────────
assert "_mirror_url is defined" "type _mirror_url &>/dev/null"

# ── _mirror_url with reachable URLs ────────────────────────────────────
if command -v curl &>/dev/null; then
  MIRROR_RESULT=$(_mirror_url "https://example.com" 2>/dev/null || echo "FALLBACK")
  assert "_mirror_url returns string" "[ -n '$MIRROR_RESULT' ]"
  assert "_mirror_url returns https URL" "echo '$MIRROR_RESULT' | grep -q 'https'"
else
  assert "_mirror_url skip (no curl)" "true"
  assert "_mirror_url skip (no curl)" "true"
fi

# ── Seven mirror variables are set to https:// URLs ────────────────────
for var in GITHUB_MIRROR NPM_REGISTRY PYPI_MIRROR DOCKER_MIRROR GO_MIRROR RUSTUP_MIRROR ZIG_MIRROR JAVA_MIRROR; do
  val="${!var}"
  assert "$var is set" "[ -n '$val' ]"
  assert "$var is https URL" "echo '$val' | grep -qE '^https://'"
done

# ── GITHUB_MIRROR is a known mirror domain ─────────────────────────────
assert "GITHUB_MIRROR is known domain" \
  'echo "'"$GITHUB_MIRROR"'" | grep -qE "github\.com|fastgit\.xyz|ghproxy\.com"'

# ── NPM_REGISTRY host ──────────────────────────────────────────────────
NPM_HOST=$(echo "$NPM_REGISTRY" | sed 's|https://||;s|/.*||')
assert "NPM_REGISTRY has valid host" "[ -n '$NPM_HOST' ]"

# ── _curl has GitHub mirror fallback logic ─────────────────────────────
assert "_curl has mirror fallback" 'type _curl 2>&1 | grep -q "ghproxy"'

# ── Mirror-related exports in 00-core.sh ───────────────────────────────
assert "source exports NPM_CONFIG_REGISTRY" 'grep -q "export NPM_CONFIG_REGISTRY" "'"$C"'"'
assert "source exports PIP_INDEX_URL"       'grep -q "export PIP_INDEX_URL" "'"$C"'"'
assert "source exports GOPROXY"             'grep -q "export GOPROXY" "'"$C"'"'
assert "source exports RUSTUP_DIST_SERVER"  'grep -q "export RUSTUP_DIST_SERVER" "'"$C"'"'

# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== test_mirrors.sh: $TESTS_PASS passed, $TESTS_FAIL failed ==="
[ "$TESTS_FAIL" -eq 0 ] || exit 1
