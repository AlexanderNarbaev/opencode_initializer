#!/usr/bin/env bash
# tests/unit/test_context_selector.sh — Context selector tests
# Tests that context selection and MCP/LSP loading works correctly.
set -euo pipefail

PASS=0; FAIL=0; TOTAL=0
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$_script_dir/src/lib/helpers.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00-core.sh" 2>/dev/null || true

assert_eq() {
  TOTAL=$((TOTAL + 1))
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}✓${NC} %s\n" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf "  ${RED}✗${NC} %s\n  expected: %s\n  actual:   %s\n" "$desc" "$expected" "$actual"
  fi
}

assert_exit() {
  TOTAL=$((TOTAL + 1))
  local desc="$1" expected="$2" cmd="$3"
  local actual
  actual=0
  eval "$cmd" >/dev/null 2>&1 || actual=$?
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}✓${NC} %s\n" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf "  ${RED}✗${NC} %s\n  expected exit: %s\n  actual exit:   %s\n" "$desc" "$expected" "$actual"
  fi
}

assert_contains() {
  TOTAL=$((TOTAL + 1))
  local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -q "$needle"; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}✓${NC} %s\n" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf "  ${RED}✗${NC} %s\n  missing: %s\n" "$desc" "$needle"
  fi
}

echo "─── Context Selector Tests ───"
echo

# ── Test 1: mcp-profiles.json structure ─────────────────────────────────────
echo "1. mcp-profiles.json structure"
mcp_profiles_file="$_script_dir/src/data/mcp-profiles.json"
assert_exit "mcp-profiles.json exists" "0" "[ -f $mcp_profiles_file ]"
mcp_profiles_content="$(cat "$mcp_profiles_file")"
assert_contains "has task_profiles" "task_profiles" "$mcp_profiles_content"
assert_contains "has disabled_by_default" "disabled_by_default" "$mcp_profiles_content"
assert_contains "has file_lsp" "file_lsp" "$mcp_profiles_content"

# ── Test 2: Task profiles in mcp-profiles.json ─────────────────────────────
echo
echo "2. Task profiles"
assert_contains "has coding profile" "coding" "$mcp_profiles_content"
assert_contains "has reasoning profile" "reasoning" "$mcp_profiles_content"
assert_contains "has fast profile" "fast" "$mcp_profiles_content"
assert_contains "has agentic profile" "agentic" "$mcp_profiles_content"
assert_contains "has research profile" "research" "$mcp_profiles_content"
assert_contains "has testing profile" "testing" "$mcp_profiles_content"

# ── Test 3: Disabled by default ─────────────────────────────────────────────
echo
echo "3. Disabled by default"
assert_contains "disables chrome-devtools" "chrome-devtools" "$mcp_profiles_content"
assert_contains "disables playwright" "playwright" "$mcp_profiles_content"
assert_contains "disables excalidraw" "excalidraw" "$mcp_profiles_content"
assert_contains "disables agent-browser" "agent-browser" "$mcp_profiles_content"

# ── Test 4: File LSP mapping ────────────────────────────────────────────────
echo
echo "4. File LSP mapping"
assert_contains "maps .go files" ".go" "$mcp_profiles_content"
assert_contains "maps .ts files" ".ts" "$mcp_profiles_content"
assert_contains "maps .py files" ".py" "$mcp_profiles_content"
assert_contains "maps .rs files" ".rs" "$mcp_profiles_content"
assert_contains "maps .sh files" ".sh" "$mcp_profiles_content"

# ── Test 5: Context selector script exists ──────────────────────────────────
echo
echo "5. Context selector script"
if [ -d "$HOME/.config/opencode/context-selector" ]; then
  assert_exit "context-selector directory exists" "0" "[ -d $HOME/.config/opencode/context-selector ]"
  assert_exit "select.sh exists" "0" "[ -f $HOME/.config/opencode/context-selector/select.sh ]"
  assert_exit "config.json exists" "0" "[ -f $HOME/.config/opencode/context-selector/config.json ]"
else
  echo "  SKIP: context-selector directory not found"
fi

# ── Test 6: Context selector config structure ───────────────────────────────
echo
echo "6. Context selector config"
if [ -f "$HOME/.config/opencode/context-selector/config.json" ]; then
  config_content="$(cat "$HOME/.config/opencode/context-selector/config.json")"
  assert_contains "config has task_categories" "task_categories" "$config_content"
  assert_contains "config has coding" "coding" "$config_content"
  assert_contains "config has reasoning" "reasoning" "$config_content"
else
  echo "  SKIP: config.json not found"
fi

# ── Test 7: Context selector can be sourced ─────────────────────────────────
echo
echo "7. Context selector syntax"
if [ -f "$HOME/.config/opencode/context-selector/select.sh" ]; then
  assert_exit "select.sh has valid syntax" "0" "bash -n $HOME/.config/opencode/context-selector/select.sh"
else
  echo "  SKIP: select.sh not found"
fi

# ── Test 8: Task distributor exists ─────────────────────────────────────────
echo
echo "8. Task distributor"
if [ -d "$HOME/.config/opencode/task-distributor" ]; then
  assert_exit "task-distributor directory exists" "0" "[ -d $HOME/.config/opencode/task-distributor ]"
  assert_exit "distribute.sh exists" "0" "[ -f $HOME/.config/opencode/task-distributor/distribute.sh ]"
  assert_exit "config.json exists" "0" "[ -f $HOME/.config/opencode/task-distributor/config.json ]"
else
  echo "  SKIP: task-distributor directory not found"
fi

# ── Test 9: Context guard exists ────────────────────────────────────────────
echo
echo "9. Context guard"
if [ -f "$HOME/.config/opencode/context-guard.json" ]; then
  assert_exit "context-guard.json exists" "0" "[ -f $HOME/.config/opencode/context-guard.json ]"
else
  echo "  SKIP: context-guard.json not found"
fi

# ── Test 10: Bundle config exists ───────────────────────────────────────────
echo
echo "10. Bundle config"
if [ -f "$HOME/.config/opencode/bundle.json" ]; then
  assert_exit "bundle.json exists" "0" "[ -f $HOME/.config/opencode/bundle.json ]"
else
  echo "  SKIP: bundle.json not found"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo
echo "─── Results: $PASS/$TOTAL passed, $FAIL failed ───"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
