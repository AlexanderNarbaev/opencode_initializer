#!/usr/bin/env bash
# Unit tests for the shipped OpenCode v2 slash commands (src/commands/*.md).
# Frontmatter must be valid, the agent must be a primary agent, and the template
# must be non-empty. Also guards against re-shipping commands that call tools
# which do not exist in v2 (the old /devcontainer, /workspaces, /worktree).
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
CMDS="$PROJECT_DIR/src/commands"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Test 1: directory and count ==="
[ -d "$CMDS" ] && pass "src/commands exists" || fail "src/commands missing"
count=$(ls "$CMDS"/*.md 2>/dev/null | wc -l | tr -d ' ')
[ "${count:-0}" -ge 4 ] && pass "$count command(s) shipped" || fail "expected >=4 commands, got ${count:-0}"

echo
echo "=== Test 2: per-command structure ==="
for f in "$CMDS"/*.md; do
  name=$(basename "$f")
  # YAML frontmatter: opening --- line 1, closing --- present, description key inside
  if [ "$(head -1 "$f")" = "---" ] && grep -q '^description:' "$f" && grep -q '^---$' "$f"; then
    pass "$name has frontmatter with description"
  else
    fail "$name frontmatter invalid"
  fi
  agent=$(sed -n 's/^agent:[[:space:]]*//p' "$f" | head -1)
  case "${agent:-build}" in
    build|plan) pass "$name uses a primary agent (${agent:-build})" ;;
    *) fail "$name uses unsupported agent '$agent'" ;;
  esac
  # body = everything after the closing frontmatter delimiter
  body=$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$f")
  [ -n "$(echo "$body" | tr -d '[:space:]')" ] && pass "$name has a non-empty template" || fail "$name template is empty"
done

echo
echo "=== Test 3: no commands for non-existent v2 tools ==="
for banned in devcontainer workspaces worktree; do
  if grep -rqi "$banned" "$CMDS" 2>/dev/null; then
    fail "command references '$banned' (tool does not exist in v2)"
  else
    pass "no command depends on '$banned'"
  fi
done

echo
echo "=== Test 4: installer ships the commands ==="
INSTALLER="$PROJECT_DIR/scripts/install-agentic-stack.sh"
grep -q 'Slash commands' "$INSTALLER" && pass "installer has a commands step" || fail "installer lacks a commands step"
grep -q 'CMDS_SRC' "$INSTALLER" && pass "installer copies src/commands" || fail "installer does not copy src/commands"

echo
echo "=== Test 5: expected command set ==="
for c in plan review test commit; do
  [ -f "$CMDS/$c.md" ] && pass "/$c present" || fail "/$c missing"
done

echo
echo "=========================================="
echo "RESULTS: $PASS pass, $FAIL fail"
echo "=========================================="
[ "$FAIL" -eq 0 ] || exit 1
