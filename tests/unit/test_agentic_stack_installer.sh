#!/usr/bin/env bash
# Unit tests for scripts/install-agentic-stack.sh and scripts/check-version-consistency.sh
# Covers: syntax, --check/--dry-run contract (no writes), plan output, failure exit code.
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
INSTALLER="$PROJECT_DIR/scripts/install-agentic-stack.sh"
VERSIONER="$PROJECT_DIR/scripts/check-version-consistency.sh"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Test 1: files exist and parse ==="
[ -f "$INSTALLER" ] && pass "install-agentic-stack.sh exists" || fail "installer missing"
[ -f "$VERSIONER" ] && pass "check-version-consistency.sh exists" || fail "version gate missing"
bash -n "$INSTALLER" 2>/dev/null && pass "installer syntax" || fail "installer syntax"
bash -n "$VERSIONER" 2>/dev/null && pass "version gate syntax" || fail "version gate syntax"

echo
echo "=== Test 2: template is valid JSON and self-consistent ==="
TEMPLATE="$PROJECT_DIR/src/data/opencode.global.template.json"
if [ -f "$TEMPLATE" ]; then
  pass "template exists"
  if jq empty "$TEMPLATE" 2>/dev/null; then pass "template is valid JSON"; else fail "template invalid JSON"; fi
  grep -q '__HOME__' "$TEMPLATE" && pass "template is parameterized (__HOME__)" || fail "template not parameterized"
  mcp_count=$(jq -r '[.mcp | to_entries[] | select(.value.enabled != false)] | length' "$TEMPLATE" 2>/dev/null || echo 0)
  [ "${mcp_count:-0}" -gt 0 ] && pass "template enables $mcp_count MCP server(s)" || fail "template enables no MCP servers"
  plugin_count=$(jq -r '(.plugin // []) | length' "$TEMPLATE" 2>/dev/null || echo 0)
  [ "${plugin_count:-0}" -gt 0 ] && pass "template declares $plugin_count plugin(s)" || fail "template declares no plugins"
else
  fail "template missing"
fi

echo
echo "=== Test 3: version gate agrees with package.json ==="
pkg_version=$(jq -r '.version' "$PROJECT_DIR/package.json")
out=$(bash "$VERSIONER" 2>&1); rc=$?
[ "$rc" -eq 0 ] && pass "version gate exits 0" || fail "version gate failed: $out"
case "$out" in *"$pkg_version"*) pass "version gate reports $pkg_version" ;; *) fail "version gate does not report $pkg_version" ;; esac

echo
echo "=== Test 4: --check never writes (hermetic HOME) ==="
FAKE_HOME="$(mktemp -d)"
before=$(find "$FAKE_HOME" -type f | wc -l)
HOME="$FAKE_HOME" bash "$INSTALLER" --check >/dev/null 2>&1; rc=$?
after=$(find "$FAKE_HOME" -type f | wc -l)
[ "$before" -eq "$after" ] && pass "--check wrote nothing to HOME" || fail "--check created files in HOME"
[ "$rc" -eq 1 ] && pass "--check exits 1 on a bare HOME" || fail "--check expected rc=1 on bare HOME, got $rc"
rm -rf "$FAKE_HOME"

echo
echo "=== Test 5: --dry-run prints a plan and writes nothing ==="
FAKE_HOME2="$(mktemp -d)"
plan_out=$(HOME="$FAKE_HOME2" bash "$INSTALLER" --dry-run 2>&1); rc=$?
[ "$rc" -eq 0 ] && pass "--dry-run exits 0" || fail "--dry-run exited $rc"
[ "$(find "$FAKE_HOME2" -type f | wc -l)" -eq 0 ] && pass "--dry-run wrote nothing to HOME" || fail "--dry-run created files"
case "$plan_out" in *"[plan]"*) pass "--dry-run emits plan lines" ;; *) fail "--dry-run emitted no plan lines" ;; esac
case "$plan_out" in *"bun add -g"*) pass "--dry-run plans bun MCP installs" ;; *) fail "--dry-run plan misses bun installs" ;; esac
case "$plan_out" in *"uv tool install"*) pass "--dry-run plans uv MCP installs" ;; *) fail "--dry-run plan misses uv installs" ;; esac
rm -rf "$FAKE_HOME2"

echo
echo "=========================================="
echo "RESULTS: $PASS pass, $FAIL fail"
echo "=========================================="
[ "$FAIL" -eq 0 ] || exit 1
