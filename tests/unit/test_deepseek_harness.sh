#!/usr/bin/env bash
# ============================================================================
# Unit Test for 49-deepseek-harness.sh — DeepSeek Harness (dsh) agent harness
# Session: ses_deepseek_harness_test
# ============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
A="$PROJECT_DIR/src/lib/49-deepseek-harness.sh"

assert() {
  local d="$1" c="$2"
  if (eval "$c") &>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $d" >&2
  fi
}

# ── 1. File existence & syntax ───────────────────────────────────────────
assert "49-deepseek-harness.sh exists" "[ -f '$A' ]"
assert "49-deepseek-harness.sh syntax clean" "bash -n '$A'"

# ── 2. Core functions ────────────────────────────────────────────────────
assert "has _install_deepseek_harness()" "grep -q '_install_deepseek_harness()' '$A'"
assert "has _configure_deepseek_harness()" "grep -q '_configure_deepseek_harness()' '$A'"
assert "has _deepseek_harness_service()" "grep -q '_deepseek_harness_service()' '$A'"
assert "has _check_deepseek_harness()" "grep -q '_check_deepseek_harness()' '$A'"

# ── 3. Step tracking ─────────────────────────────────────────────────────
assert "has step_deepseek_harness skip check" "grep -q 'step_deepseek_harness' '$A'"
assert "has _step_done step_deepseek_harness" "grep -q '_step_done step_deepseek_harness' '$A'"
assert "has section header" "grep -q 'section.*DeepSeek Harness' '$A'"

# ── 4. Configuration surface (DSH_CONFIG_DIR + DSH_WEB_PORT) ─────────────
# NOTE: the module has no DSH_VERSION constant — the dsh version is resolved
# at runtime via `dsh --version`. The durable config surface is:
#   DSH_CONFIG_DIR (plugin profile dir) and DSH_WEB_PORT (Web UI port).
assert "has DSH_CONFIG_DIR" "grep -q 'DSH_CONFIG_DIR=' '$A'"
assert "DSH_CONFIG_DIR points under ~/.config" "grep -q 'DSH_CONFIG_DIR=.*\.config/deepseek-harness' '$A'"
assert "has DSH_WEB_PORT" "grep -q 'DSH_WEB_PORT=' '$A'"
assert "DSH_WEB_PORT defaults to 3080" "grep -q 'DSH_WEB_PORT:-3080' '$A'"
assert "resolves dsh version at runtime" "grep -q 'dsh --version' '$A'"

# ── 5. Plugin architecture (Cordis) ──────────────────────────────────────
assert "has cordis.yml plugin profile" "grep -q 'cordis.yml' '$A'"
assert "documents everything-is-a-plugin" "grep -q 'everything is a plugin' '$A'"
assert "references Cordis" "grep -q 'Cordis' '$A'"

# ── 6. Install logic ─────────────────────────────────────────────────────
assert "installs via npm install -g" "grep -q 'npm install -g' '$A'"
assert "targets @deepseek-ai/dsh package" "grep -q '@deepseek-ai/dsh' '$A'"
assert "checks Node.js prerequisite" "grep -q 'command -v node' '$A'"
assert "runs dsh web (Web UI)" "grep -q 'dsh web' '$A'"

# ── 7. systemd user service ──────────────────────────────────────────────
assert "has deepseek-harness.service" "grep -q 'deepseek-harness.service' '$A'"
assert "uses systemctl --user" "grep -q 'systemctl --user' '$A'"

# ── 8. Health check ──────────────────────────────────────────────────────
assert "health check curls Web UI" "grep -q 'curl -fsS' '$A'"
assert "health check targets 127.0.0.1" "grep -q '127.0.0.1' '$A'"

# ── 9. Opt-out flag ──────────────────────────────────────────────────────
assert "has SKIP_DEEPSEEK_HARNESS opt-out" "grep -q 'SKIP_DEEPSEEK_HARNESS' '$A'"

# ── 10. Module structure ─────────────────────────────────────────────────
assert "has set -euo pipefail" "grep -q 'set -euo pipefail' '$A'"
assert "has shebang" "head -1 '$A' | grep -q '#!/usr/bin/env bash'"

# ── 11. Sourcing with stubs (no fatal errors, functions defined) ────────
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

STUBS='_step_skip() { return 1; }; _step_done() { return 0; }; section() { :; }; log() { :; }; warn() { :; }; info() { :; }; _progress() { :; }; _spin_start() { :; }; _spin_stop() { :; }; command() { return 1; }'

# Node/dsh absent path: _install_deepseek_harness warns and returns early,
# so no network/install side effects during the test.
SOURCED_RC=0
bash -c "$STUBS; source '$A'" >/dev/null 2>&1 || SOURCED_RC=$?
assert "module sources without fatal errors (exit 0)" "[ $SOURCED_RC -eq 0 ]"

assert "_install_deepseek_harness is a function" "bash -c '$STUBS; source \"$A\" 2>/dev/null; declare -f _install_deepseek_harness >/dev/null 2>&1'"
assert "_configure_deepseek_harness is a function" "bash -c '$STUBS; source \"$A\" 2>/dev/null; declare -f _configure_deepseek_harness >/dev/null 2>&1'"
assert "_deepseek_harness_service is a function" "bash -c '$STUBS; source \"$A\" 2>/dev/null; declare -f _deepseek_harness_service >/dev/null 2>&1'"
assert "_check_deepseek_harness is a function" "bash -c '$STUBS; source \"$A\" 2>/dev/null; declare -f _check_deepseek_harness >/dev/null 2>&1'"

# ── 12. setup.sh references ──────────────────────────────────────────────
S="$PROJECT_DIR/setup.sh"
assert "setup.sh references 49-deepseek-harness.sh" "grep -q '49-deepseek-harness' '$S'"

echo "test_deepseek_harness: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
