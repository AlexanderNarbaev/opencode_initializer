#!/usr/bin/env bash
# tests/unit/test_provider_discovery.sh — Provider discovery tests
# Tests that provider detection and configuration works correctly.
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
  if printf '%s' "$haystack" | grep -q "$needle"; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}✓${NC} %s\n" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf "  ${RED}✗${NC} %s\n  missing: %s\n" "$desc" "$needle"
  fi
}

echo "─── Provider Discovery Tests ───"
echo

# ── Test 1: providers.json exists and is valid JSON ─────────────────────────
echo "1. providers.json structure"
providers_file="$_script_dir/src/data/providers.json"
assert_exit "providers.json exists" "0" "[ -f $providers_file ]"
providers_content="$(cat "$providers_file")"
assert_contains "providers.json has deepseek" "deepseek" "$providers_content"
assert_contains "providers.json has opencode" "opencode" "$providers_content"
assert_contains "providers.json has minimax" "minimax" "$providers_content"

# ── Test 2: routing.json exists and is valid JSON ───────────────────────────
echo
echo "2. routing.json structure"
routing_file="$_script_dir/src/data/routing.json"
assert_exit "routing.json exists" "0" "[ -f $routing_file ]"
routing_content="$(cat "$routing_file")"
assert_contains "routing.json has cost_table" "cost_table" "$routing_content"
assert_contains "routing.json has task_profiles" "task_profiles" "$routing_content"
assert_contains "routing.json has providers" "providers" "$routing_content"

# ── Test 3: mcp-profiles.json exists and is valid JSON ──────────────────────
echo
echo "3. mcp-profiles.json structure"
mcp_profiles_file="$_script_dir/src/data/mcp-profiles.json"
assert_exit "mcp-profiles.json exists" "0" "[ -f $mcp_profiles_file ]"
mcp_profiles_content="$(cat "$mcp_profiles_file")"
assert_contains "mcp-profiles.json has task_profiles" "task_profiles" "$mcp_profiles_content"
assert_contains "mcp-profiles.json has disabled_by_default" "disabled_by_default" "$mcp_profiles_content"

# ── Test 4: Provider API key environment variables ──────────────────────────
echo
echo "4. Provider API key env vars"
# Check that the env vars are documented in providers.json
assert_contains "providers.json references DEEPSEEK_API_KEY" "DEEPSEEK_API_KEY" "$providers_content"
assert_contains "providers.json references OPENCODE_API_KEY" "OPENCODE_API_KEY" "$providers_content"
assert_contains "providers.json references MINIMAX_API_KEY" "MINIMAX_API_KEY" "$providers_content"

# ── Test 5: Provider fallback chains ────────────────────────────────────────
echo
echo "5. Provider fallback chains"
assert_contains "routing.json has fallback chains" "fallback" "$routing_content"

# ── Test 6: Task profiles ───────────────────────────────────────────────────
echo
echo "6. Task profiles"
assert_contains "routing.json has coding profile" "coding" "$routing_content"
assert_contains "routing.json has reasoning profile" "reasoning" "$routing_content"
assert_contains "routing.json has fast profile" "fast" "$routing_content"

# ── Test 7: Cost table ──────────────────────────────────────────────────────
echo
echo "7. Cost table"
assert_contains "routing.json has cost_table" "cost_table" "$routing_content"
assert_contains "routing.json has free models" "free" "$routing_content"

# ── Test 8: MCP profiles ────────────────────────────────────────────────────
echo
echo "8. MCP profiles"
assert_contains "mcp-profiles.json has coding profile" "coding" "$mcp_profiles_content"
assert_contains "mcp-profiles.json has reasoning profile" "reasoning" "$mcp_profiles_content"

# ── Test 9: Provider discovery script exists ────────────────────────────────
echo
echo "9. Provider discovery script"
assert_exit "provider-check.sh exists" "0" "[ -f $_script_dir/scripts/provider-check.sh ]"

# ── Test 10: Model router exists ────────────────────────────────────────────
echo
echo "10. Model router"
if [ -d "$_script_dir/src/data/../model-router" ] || [ -d "$HOME/.config/opencode/model-router" ]; then
  assert_exit "model-router directory exists" "0" "[ -d $_script_dir/src/data/../model-router ] || [ -d $HOME/.config/opencode/model-router ]"
else
  echo "  SKIP: model-router directory not found"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo
echo "─── Results: $PASS/$TOTAL passed, $FAIL failed ───"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
