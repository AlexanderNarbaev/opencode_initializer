#!/usr/bin/env bash
# ============================================================================
# Unit tests for 00-core.sh — core infrastructure
# Tests: OS validation, arch detection, pkg manager detection,
#        progress tracking, interactive gate, dry-run mode
# Approach: source helpers.sh only, then validate 00-core.sh structure.
# We don't source 00-core.sh here to avoid slow _mirror_url network calls.
# The _mirror_url function is tested separately in test_mirrors.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
TESTS_PASS=0; TESTS_FAIL=0

# Use eval-friendly condition construction
assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $desc" >&2
  fi
}

TMPDIR=$(mktemp -d /tmp/test_core.XXXXXX)
cleanup_test() { rm -rf "$TMPDIR"; }
trap cleanup_test EXIT

export HOME="$TMPDIR/home"
mkdir -p "$HOME/.cache/opencode-setup" "$HOME/.config/opencode" "$HOME/.local/bin"

source "$PROJECT_DIR/lib/helpers.sh"
trap cleanup_test EXIT

C="$PROJECT_DIR/lib/00-core.sh"

echo "=== Testing 00-core.sh infrastructure ==="

# ── File structure checks ────────────────────────────────────────────────
assert "00-core.sh has shebang"           'head -1 "'"$C"'" | grep -q "#!/usr/bin/env bash"'
assert "00-core.sh has set -euo pipefail" 'grep -q "set -euo pipefail" "'"$C"'"'

# ── Version ──────────────────────────────────────────────────────────────
assert "SCRIPT_VERSION is v34.0" 'grep -qE "SCRIPT_VERSION.*v34\.0" "'"$C"'"'

# ── OS validation ────────────────────────────────────────────────────────
assert "OS validation exists"       'grep -q "/etc/os-release" "'"$C"'"'
assert "Ubuntu/Debian check exists" 'grep -qE "ubuntu\|debian" "'"$C"'"'

# ── Architecture detection ───────────────────────────────────────────────
assert "ARCH detection (uname -m)"  'grep -q "ARCH=\$(uname" "'"$C"'"'
assert "amd64 case"                 'grep -q "amd64)" "'"$C"'"'
assert "arm64 case"                 'grep -q "arm64)" "'"$C"'"'
assert "GO_ARCH logic"              'grep -q "GO_ARCH" "'"$C"'"'

# ── Package manager detection ────────────────────────────────────────────
assert "PKG_MANAGER detection" 'grep -q "PKG_MANAGER" "'"$C"'"'
for pm in apt dnf pacman apk zypper brew; do
  assert "Package manager: $pm" 'grep -qE "command -v '"$pm"'" "'"$C"'" || grep -q "\"'"$pm"'\"" "'"$C"'"'
done

# ── _pkg_install function ────────────────────────────────────────────────
assert "_pkg_install defined" 'grep -q "_pkg_install()" "'"$C"'"'
assert "_pkg_update defined"  'grep -q "_pkg_update()" "'"$C"'"'
assert "_pkg_list defined"    'grep -q "_pkg_list()" "'"$C"'"'
assert "_pkg_list includes git" 'grep -q "git" "'"$C"'"'

# ── _mirror_url function ─────────────────────────────────────────────────
assert "_mirror_url defined"      'grep -q "_mirror_url()" "'"$C"'"'
assert "_mirror_url has --resolve" 'grep -q "\-\-resolve" "'"$C"'"'

# ── Mirror variables ────────────────────────────────────────────────────
for mirror in GITHUB_MIRROR NPM_REGISTRY PYPI_MIRROR DOCKER_MIRROR GO_MIRROR RUSTUP_MIRROR ZIG_MIRROR JAVA_MIRROR; do
  assert "$mirror defined" 'grep -q "'"$mirror"'" "'"$C"'"'
done

# ── Progress tracking ────────────────────────────────────────────────────
assert "PROGRESS variable"  'grep -q "PROGRESS=" "'"$C"'"'
assert "_step_skip defined" 'grep -q "_step_skip()" "'"$C"'"'
assert "_step_done defined" 'grep -q "_step_done()" "'"$C"'"'

# ── _spin function ───────────────────────────────────────────────────────
assert "_spin defined" 'grep -q "_spin()" "'"$C"'"'

# ── MCP registry ────────────────────────────────────────────────────────
assert "MCP_PACKAGES declared" 'grep -q "MCP_PACKAGES=" "'"$C"'"'
for mcp in context7 filesystem agentic-tools codegraph playwright agent-browser loopsense github postgres gitlab google-maps sequential-thinking memorylayer; do
  assert "MCP registry includes $mcp" 'grep -F "['"$mcp"']" "'"$C"'"'
done
assert "MCP registry has 10+ entries" 'test $(grep -c "\]=" "'"$C"'") -ge 10'

# ── Interactive gate ─────────────────────────────────────────────────────
assert "_gate defined" 'grep -q "_gate()" "'"$C"'"'

# ── Dry-run mode ────────────────────────────────────────────────────────
assert "_dry defined"   'grep -q "_dry()" "'"$C"'"'
assert "DRY_RUN check"  'grep -q "DRY_RUN" "'"$C"'"'

# ── PATH exports ────────────────────────────────────────────────────────
assert "NPM_GLOBAL defined" 'grep -q "NPM_GLOBAL=" "'"$C"'"'
assert "N_PREFIX defined"   'grep -q "N_PREFIX=" "'"$C"'"'
assert "CORE_PATH defined"  'grep -q "CORE_PATH=" "'"$C"'"'
assert "PATH exported"       'grep -q "export PATH" "'"$C"'"'

# ── Env exports ──────────────────────────────────────────────────────────
assert "NPM_CONFIG_REGISTRY export" 'grep -q "export NPM_CONFIG_REGISTRY" "'"$C"'"'
assert "PIP_INDEX_URL export"       'grep -q "export PIP_INDEX_URL" "'"$C"'"'
assert "GOPROXY export"             'grep -q "export GOPROXY" "'"$C"'"'
assert "RUSTUP_DIST_SERVER export"  'grep -q "export RUSTUP_DIST_SERVER" "'"$C"'"'

# ── _set_dns / _install_ca_certs ────────────────────────────────────────
assert "_set_dns defined"          'grep -q "_set_dns()" "'"$C"'"'
assert "_install_ca_certs defined" 'grep -q "_install_ca_certs()" "'"$C"'"'

# ── Summary ──────────────────────────────────────────────────────────────
echo
echo "=== test_core.sh: $TESTS_PASS passed, $TESTS_FAIL failed ==="
[ "$TESTS_FAIL" -eq 0 ] || exit 1
