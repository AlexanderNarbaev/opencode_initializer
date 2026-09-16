#!/usr/bin/env bash
# tests/unit/test_mirrors_sync.sh — Tests for mirrors and auto-sync (v4.1.0)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export SKIP_MIRROR_RESOLVE=true  # skip network mirror resolution while sourcing 00-core.sh
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

_green() { echo -e "\033[0;32m$1\033[0m"; }
_red()   { echo -e "\033[0;31m$1\033[0m"; }

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  if [ "$expected" = "$actual" ]; then
    _green "  ✓ $desc"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ $desc — expected '$expected', got '$actual'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_true() {
  local desc="$1" result="$2"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  if [ "$result" = "0" ]; then
    _green "  ✓ $desc"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ $desc — expected success, got $result"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_file_exists() {
  local desc="$1" file="$2"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  if [ -f "$file" ]; then
    _green "  ✓ $desc"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ $desc — file not found: $file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_contains() {
  local desc="$1" file="$2" pattern="$3"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  if grep -q "$pattern" "$file" 2>/dev/null; then
    _green "  ✓ $desc"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ $desc — pattern not found: $pattern"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "=== test_mirrors_sync.sh ==="

# ── Test 1: Module files exist ──────────────────────────────────────────────
echo "Test 1: Module file structure"
assert_file_exists "00i-mirrors.sh exists" "$SCRIPT_DIR/src/lib/00i-mirrors.sh"
assert_file_exists "00j-auto-sync.sh exists" "$SCRIPT_DIR/src/lib/00j-auto-sync.sh"

# ── Test 2: Mirror functions defined ────────────────────────────────────────
echo "Test 2: Mirror functions"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00i-mirrors.sh"

  assert_true "_detect_region defined" "$(type -t _detect_region &>/dev/null && echo 0 || echo 1)"
  assert_true "_configure_npm_mirror defined" "$(type -t _configure_npm_mirror &>/dev/null && echo 0 || echo 1)"
  assert_true "_configure_pypi_mirror defined" "$(type -t _configure_pypi_mirror &>/dev/null && echo 0 || echo 1)"
  assert_true "_configure_go_mirror defined" "$(type -t _configure_go_mirror &>/dev/null && echo 0 || echo 1)"
  assert_true "_configure_crates_mirror defined" "$(type -t _configure_crates_mirror &>/dev/null && echo 0 || echo 1)"
  assert_true "_configure_docker_mirror defined" "$(type -t _configure_docker_mirror &>/dev/null && echo 0 || echo 1)"
  assert_true "_configure_all_mirrors defined" "$(type -t _configure_all_mirrors &>/dev/null && echo 0 || echo 1)"
  assert_true "_mirror_health_check defined" "$(type -t _mirror_health_check &>/dev/null && echo 0 || echo 1)"
)

# ── Test 3: Region detection ────────────────────────────────────────────────
echo "Test 3: Region detection"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00i-mirrors.sh"

  # Test with Moscow timezone
  region=$(TZ="Europe/Moscow" _detect_region)
  assert_eq "Moscow timezone → ru" "ru" "$region"

  # Test with Shanghai timezone
  region=$(TZ="Asia/Shanghai" _detect_region)
  assert_eq "Shanghai timezone → cn" "cn" "$region"

  # Test with UTC timezone
  region=$(TZ="UTC" _detect_region)
  assert_eq "UTC timezone → global" "global" "$region"
)

# ── Test 4: Auto-sync functions defined ─────────────────────────────────────
echo "Test 4: Auto-sync functions"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00j-auto-sync.sh"

  assert_true "_auto_sync_init defined" "$(type -t _auto_sync_init &>/dev/null && echo 0 || echo 1)"
  assert_true "_auto_sync_check defined" "$(type -t _auto_sync_check &>/dev/null && echo 0 || echo 1)"
  assert_true "_auto_sync_apply defined" "$(type -t _auto_sync_apply &>/dev/null && echo 0 || echo 1)"
  assert_true "_auto_sync_daemon defined" "$(type -t _auto_sync_daemon &>/dev/null && echo 0 || echo 1)"
  assert_true "_update_plugin_registry defined" "$(type -t _update_plugin_registry &>/dev/null && echo 0 || echo 1)"
  assert_true "_update_mcp_servers defined" "$(type -t _update_mcp_servers &>/dev/null && echo 0 || echo 1)"
  assert_true "_full_sync defined" "$(type -t _full_sync &>/dev/null && echo 0 || echo 1)"
)

# ── Test 5: Auto-sync state initialization ──────────────────────────────────
echo "Test 5: Auto-sync state"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00j-auto-sync.sh"

  # Use temp directory
  export DL_CACHE=$(mktemp -d)
  _AUTO_SYNC_STATE="$DL_CACHE/auto-sync-state.json"

  _auto_sync_init
  assert_file_exists "State file created" "$_AUTO_SYNC_STATE"

  # Verify JSON is valid
  if python3 -c "import json; json.load(open('$_AUTO_SYNC_STATE'))" 2>/dev/null; then
    _green "  ✓ State file is valid JSON"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ State file is not valid JSON"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_TOTAL=$((TESTS_TOTAL + 1))

  rm -rf "$DL_CACHE"
)

# ── Test 6: NPM mirror configuration ───────────────────────────────────────
echo "Test 6: NPM mirror"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00i-mirrors.sh"

  # Use temp directory
  export HOME=$(mktemp -d)

  _configure_npm_mirror "ru"

  assert_file_exists ".npmrc created" "$HOME/.npmrc"
  assert_contains ".npmrc has GitVerse mirror" "$HOME/.npmrc" "npm-mirror.gitverse.ru"

  rm -rf "$HOME"
)

# ── Test 7: PyPI mirror configuration ──────────────────────────────────────
echo "Test 7: PyPI mirror"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00i-mirrors.sh"

  # Use temp directory
  export HOME=$(mktemp -d)

  _configure_pypi_mirror "ru"

  assert_file_exists "pip.conf created" "$HOME/.config/pip/pip.conf"
  assert_contains "pip.conf has GitVerse mirror" "$HOME/.config/pip/pip.conf" "pypi-mirror.gitverse.ru"

  rm -rf "$HOME"
)

# ── Test 8: Crates mirror configuration ─────────────────────────────────────
echo "Test 8: Crates mirror"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00i-mirrors.sh"

  # Use temp directory
  export HOME=$(mktemp -d)

  _configure_crates_mirror "ru"

  assert_file_exists "cargo config created" "$HOME/.cargo/config.toml"
  assert_contains "cargo config has GitVerse mirror" "$HOME/.cargo/config.toml" "crates-mirror.gitverse.ru"

  rm -rf "$HOME"
)

# ── Test 9: Go mirror configuration ────────────────────────────────────────
echo "Test 9: Go mirror"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00i-mirrors.sh"

  # Test environment variable
  _configure_go_mirror "ru"
  assert_eq "GOPROXY set" "https://go-mirror.gitverse.ru,direct" "${GOPROXY:-}"
)

# ── Test 10: Docker mirror configuration ────────────────────────────────────
echo "Test 10: Docker mirror"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00i-mirrors.sh"

  # Use temp directory
  export HOME=$(mktemp -d)

  _configure_docker_mirror "ru"

  assert_file_exists "daemon.json created" "$HOME/.config/docker/daemon.json"
  assert_contains "daemon.json has GitVerse mirror" "$HOME/.config/docker/daemon.json" "dh-mirror.gitverse.ru"

  rm -rf "$HOME"
)

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "=== Summary ==="
echo "Total:  $TESTS_TOTAL"
_green "Passed: $TESTS_PASSED"
if [ "$TESTS_FAILED" -gt 0 ]; then
  _red "Failed: $TESTS_FAILED"
  exit 1
else
  echo "Failed: 0"
  exit 0
fi
