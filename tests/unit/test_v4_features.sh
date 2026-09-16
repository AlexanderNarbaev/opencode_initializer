#!/usr/bin/env bash
# tests/unit/test_v4_features.sh — Tests for v4.0.0 features (APM + Multi-agent)
set -euo pipefail
export SKIP_MIRROR_RESOLVE=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
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

echo "=== test_v4_features.sh ==="

# ── Test 1: Module files exist ──────────────────────────────────────────────
echo "Test 1: Module file structure"
assert_file_exists "00g-apm-integration.sh exists" "$SCRIPT_DIR/src/lib/00g-apm-integration.sh"
assert_file_exists "00h-multi-agent.sh exists" "$SCRIPT_DIR/src/lib/00h-multi-agent.sh"

# ── Test 2: APM integration functions ───────────────────────────────────────
echo "Test 2: APM integration functions"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00f-apm.sh"
  source "$SCRIPT_DIR/src/lib/00g-apm-integration.sh"

  assert_true "_apm_generate_policy defined" "$(type -t _apm_generate_policy &>/dev/null && echo 0 || echo 1)"
  assert_true "_apm_install_package defined" "$(type -t _apm_install_package &>/dev/null && echo 0 || echo 1)"
  assert_true "_apm_update_package defined" "$(type -t _apm_update_package &>/dev/null && echo 0 || echo 1)"
  assert_true "_apm_uninstall_package defined" "$(type -t _apm_uninstall_package &>/dev/null && echo 0 || echo 1)"
)

# ── Test 3: APM policy generation ───────────────────────────────────────────
echo "Test 3: APM policy generation"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00f-apm.sh"
  source "$SCRIPT_DIR/src/lib/00g-apm-integration.sh"

  tmp_policy=$(mktemp)
  _apm_generate_policy "$tmp_policy"

  assert_file_exists "Policy file created" "$tmp_policy"
  assert_contains "Policy has schema_version" "$tmp_policy" "schema_version:"
  assert_contains "Policy has install section" "$tmp_policy" "install:"
  assert_contains "Policy has security section" "$tmp_policy" "security:"

  rm -f "$tmp_policy"
)

# ── Test 4: Multi-agent functions ───────────────────────────────────────────
echo "Test 4: Multi-agent functions"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00h-multi-agent.sh"

  assert_true "_generate_copilot_instructions defined" "$(type -t _generate_copilot_instructions &>/dev/null && echo 0 || echo 1)"
  assert_true "_generate_claude_settings defined" "$(type -t _generate_claude_settings &>/dev/null && echo 0 || echo 1)"
  assert_true "_generate_cursor_settings defined" "$(type -t _generate_cursor_settings &>/dev/null && echo 0 || echo 1)"
  assert_true "_generate_vscode_settings defined" "$(type -t _generate_vscode_settings &>/dev/null && echo 0 || echo 1)"
  assert_true "_generate_all_targets defined" "$(type -t _generate_all_targets &>/dev/null && echo 0 || echo 1)"
)

# ── Test 5: Copilot instructions generation ─────────────────────────────────
echo "Test 5: Copilot instructions"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00h-multi-agent.sh"

  tmp_dir=$(mktemp -d)
  _generate_copilot_instructions "$tmp_dir"

  assert_file_exists "Copilot instructions created" "$tmp_dir/.github/copilot-instructions.md"
  assert_contains "Has project overview" "$tmp_dir/.github/copilot-instructions.md" "Project Overview"
  assert_contains "Has code style" "$tmp_dir/.github/copilot-instructions.md" "Code Style"
  assert_contains "Has architecture" "$tmp_dir/.github/copilot-instructions.md" "Architecture"

  rm -rf "$tmp_dir"
)

# ── Test 6: Claude settings generation ──────────────────────────────────────
echo "Test 6: Claude settings"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00h-multi-agent.sh"

  tmp_dir=$(mktemp -d)
  _generate_claude_settings "$tmp_dir"

  assert_file_exists "Claude settings created" "$tmp_dir/.claude/settings.json"

  # Verify JSON is valid
  if python3 -c "import json; json.load(open('$tmp_dir/.claude/settings.json'))" 2>/dev/null; then
    _green "  ✓ Claude settings is valid JSON"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ Claude settings is not valid JSON"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_TOTAL=$((TESTS_TOTAL + 1))

  rm -rf "$tmp_dir"
)

# ── Test 7: Cursor settings generation ──────────────────────────────────────
echo "Test 7: Cursor settings"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00h-multi-agent.sh"

  tmp_dir=$(mktemp -d)
  _generate_cursor_settings "$tmp_dir"

  assert_file_exists "Cursor settings created" "$tmp_dir/.cursor/settings.json"

  # Verify JSON is valid
  if python3 -c "import json; json.load(open('$tmp_dir/.cursor/settings.json'))" 2>/dev/null; then
    _green "  ✓ Cursor settings is valid JSON"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ Cursor settings is not valid JSON"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_TOTAL=$((TESTS_TOTAL + 1))

  rm -rf "$tmp_dir"
)

# ── Test 8: VS Code settings generation ─────────────────────────────────────
echo "Test 8: VS Code settings"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00h-multi-agent.sh"

  tmp_dir=$(mktemp -d)
  _generate_vscode_settings "$tmp_dir"

  assert_file_exists "VS Code settings created" "$tmp_dir/.vscode/settings.json"

  # Verify JSON is valid
  if python3 -c "import json; json.load(open('$tmp_dir/.vscode/settings.json'))" 2>/dev/null; then
    _green "  ✓ VS Code settings is valid JSON"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ VS Code settings is not valid JSON"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_TOTAL=$((TESTS_TOTAL + 1))

  rm -rf "$tmp_dir"
)

# ── Test 9: Generate all targets ────────────────────────────────────────────
echo "Test 9: Generate all targets"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00h-multi-agent.sh"

  tmp_dir=$(mktemp -d)
  _generate_all_targets "$tmp_dir"

  assert_file_exists "Copilot instructions" "$tmp_dir/.github/copilot-instructions.md"
  assert_file_exists "Claude settings" "$tmp_dir/.claude/settings.json"
  assert_file_exists "Cursor settings" "$tmp_dir/.cursor/settings.json"
  assert_file_exists "VS Code settings" "$tmp_dir/.vscode/settings.json"

  rm -rf "$tmp_dir"
)

# ── Test 10: APM policy content validation ──────────────────────────────────
echo "Test 10: APM policy content"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00f-apm.sh"
  source "$SCRIPT_DIR/src/lib/00g-apm-integration.sh"

  tmp_policy=$(mktemp)
  _apm_generate_policy "$tmp_policy"

  assert_contains "Has pre_checks" "$tmp_policy" "pre_checks:"
  assert_contains "Has bash_version check" "$tmp_policy" "bash_version"
  assert_contains "Has disk_space check" "$tmp_policy" "disk_space"
  assert_contains "Has post_actions" "$tmp_policy" "post_actions:"
  assert_contains "Has update policy" "$tmp_policy" "update:"
  assert_contains "Has allowed_sources" "$tmp_policy" "allowed_sources:"

  rm -f "$tmp_policy"
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
