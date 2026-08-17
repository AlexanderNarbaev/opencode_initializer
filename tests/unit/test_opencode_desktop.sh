#!/usr/bin/env bash
# ============================================================================
# Unit Test for 51-opencode-desktop.sh — OpenCode Desktop (GUI) app
# Session: ses_opencode_desktop_test
# ============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
MOD="$PROJECT_DIR/src/lib/51-opencode-desktop.sh"
TESTS_PASS=0; TESTS_FAIL=0
TESTHOME="$(mktemp -d /tmp/ocd-test.XXXXXX)"

assert() {
  local d="$1" c="$2"
  if (eval "$c") &>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $d" >&2
  fi
}

# Source the module in an isolated subshell (stubbed setup helpers), with a
# fake already-installed binary so Main is a no-op, then run the caller's check.
# Note: `info` emits to stdout (not stubbed) so configure-output checks work.
run_isolated() {
  local d="$1" setup="$2" check="$3"
  if bash -c "
    set -uo pipefail
    log(){ :; }; warn(){ :; }; info(){ echo \"\$*\"; }; err(){ :; }; section(){ :; }
    _progress(){ :; }; _spin_start(){ :; }; _spin_stop(){ :; }
    _step_skip(){ return 1; }; _step_done(){ :; }
    opencode(){ echo '1.17.0'; }
    export HOME='$TESTHOME' ARCH=amd64 PKG_MANAGER=apt DL_CACHE='$TESTHOME/dl'
    unset XDG_CONFIG_HOME
    mkdir -p \"\$HOME/.local/share/opencode-desktop\"
    touch \"\$HOME/.local/share/opencode-desktop/ai.opencode.desktop\"
    chmod +x \"\$HOME/.local/share/opencode-desktop/ai.opencode.desktop\"
    $setup
    source '$MOD'
    $check
  " &>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $d" >&2
  fi
}

echo "=== Testing 51-opencode-desktop.sh ==="

# ── 1. File existence & syntax ───────────────────────────────────────────────
assert "51-opencode-desktop.sh exists" "[ -f '$MOD' ]"
assert "51-opencode-desktop.sh bash -n clean" "bash -n '$MOD'"

# ── 2. Core functions ────────────────────────────────────────────────────────
assert "has _install_opencode_desktop" "grep -q '^_install_opencode_desktop()' '$MOD'"
assert "has _configure_opencode_desktop" "grep -q '^_configure_opencode_desktop()' '$MOD'"
assert "has _check_opencode_desktop" "grep -q '^_check_opencode_desktop()' '$MOD'"
assert "has _install_desktop_appimage" "grep -q '^_install_desktop_appimage()' '$MOD'"
assert "has _desktop_asset_url" "grep -q '^_desktop_asset_url()' '$MOD'"
assert "has _write_desktop_entry" "grep -q '^_write_desktop_entry()' '$MOD'"
assert "has _resolve_desktop_version" "grep -q '^_resolve_desktop_version()' '$MOD'"

# ── 3. Key content markers ───────────────────────────────────────────────────
assert "has SKIP_DESKTOP opt-out" "grep -q 'SKIP_DESKTOP' '$MOD'"
assert "has .deb install path" "grep -q 'dpkg -i' '$MOD'"
assert "has AppImage fallback" "grep -q 'AppImage' '$MOD'"
assert "has Desktop Entry content" "grep -q 'Desktop Entry' '$MOD'"
assert "has version pin" "grep -q 'OCD_PINNED_VER' '$MOD'"

# ── 4. Opt-out & skip paths ──────────────────────────────────────────────────
assert "opt-out SKIP_DESKTOP=true returns 0" "bash -c \"
  log(){ :; }; warn(){ :; }; info(){ :; }; err(){ :; }; section(){ :; }
  _step_skip(){ return 1; }
  export HOME='$TESTHOME' SKIP_DESKTOP=true
  source '$MOD'
\""
assert "skip path (_step_skip=0) returns 0" "bash -c \"
  log(){ :; }; warn(){ :; }; info(){ :; }; err(){ :; }; section(){ :; }
  _step_skip(){ return 0; }
  export HOME='$TESTHOME'
  source '$MOD'
\""

# ── 5. Pure function: asset URL builder ──────────────────────────────────────
run_isolated "deb url correct" "" "[ \"\$(_desktop_asset_url v1.18.18 deb)\" = 'https://github.com/anomalyco/opencode/releases/download/v1.18.18/opencode-desktop-linux-amd64.deb' ]"
run_isolated "rpm url correct" "" "[ \"\$(_desktop_asset_url v1.18.18 rpm)\" = 'https://github.com/anomalyco/opencode/releases/download/v1.18.18/opencode-desktop-linux-x86_64.rpm' ]"
run_isolated "appimage url correct" "" "[ \"\$(_desktop_asset_url v1.18.18 AppImage)\" = 'https://github.com/anomalyco/opencode/releases/download/v1.18.18/opencode-desktop-linux-x86_64.AppImage' ]"
run_isolated "version fallback to pin (curl fails)" "curl(){ return 1; }" "[ \"\$(_resolve_desktop_version)\" = '1.18.18' ]"

# ── 6. Desktop entry writer ──────────────────────────────────────────────────
run_isolated "write_desktop_entry creates .desktop" "" "_write_desktop_entry /tmp/fake-opencode && [ -f \"\$HOME/.local/share/applications/opencode-desktop.desktop\" ] && grep -q 'Exec=/tmp/fake-opencode' \"\$HOME/.local/share/applications/opencode-desktop.desktop\""

# ── 7. Configure: CLI integration + shared config ────────────────────────────
run_isolated "configure reads model from config" "mkdir -p \"\$HOME/.config/opencode\"; printf '{\n  \"model\": \"deepseek/deepseek-v4-pro\"\n}\n' > \"\$HOME/.config/opencode/opencode.json\"" "o=\"\$(_configure_opencode_desktop 2>&1)\"; grep -q 'deepseek/deepseek-v4-pro' <<< \"\$o\""
run_isolated "configure degrades without config" "" "_configure_opencode_desktop"

# ── 8. Main: graceful degradation (no abort on failure) ──────────────────────
assert "Main survives download failure" "bash -c \"
  log(){ :; }; warn(){ :; }; info(){ :; }; err(){ :; }; section(){ :; }
  _progress(){ :; }; _spin_start(){ :; }; _spin_stop(){ :; }
  _step_skip(){ return 1; }; _step_done(){ :; }
  opencode(){ echo '1.17.0'; }
  curl(){ return 1; }; _curl(){ return 1; }; _sudo(){ return 1; }
  export HOME='$TESTHOME' ARCH=amd64 PKG_MANAGER=apt DL_CACHE='$TESTHOME/dl'
  source '$MOD'
\""

echo ""
echo "  PASS: $TESTS_PASS  FAIL: $TESTS_FAIL"
if [ "$TESTS_FAIL" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
fi
echo "  RESULT: PASS"
exit 0
