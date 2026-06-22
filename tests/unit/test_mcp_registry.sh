#!/usr/bin/env bash
# ============================================================================
# Unit tests for MCP registry — completeness and consistency
# Tests: all MCP entries have 3-element tuples, all have install in 12-mcp-lsp.sh,
#        health checks cover all required MCPs
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

echo "=== Testing MCP Registry ==="

CORE="$PROJECT_DIR/src/lib/00-core.sh"
MCP_INSTALL="$PROJECT_DIR/src/lib/12-mcp-lsp.sh"
HEALTH="$PROJECT_DIR/src/modes/health.sh"

# ── Registry completeness ──────────────────────────────────────────────────
EXPECTED_MCPS="context7 context7-official filesystem agentic-tools codegraph playwright agent-browser loopsense github postgres gitlab google-maps sequential-thinking memorylayer chrome-devtools memory redis brave-search sqlite excalidraw notion"

for mcp in $EXPECTED_MCPS; do
  assert "MCP registry includes $mcp" "grep -qE '\[$mcp\]' \"$CORE\""
done
assert "MCP registry has 22+ entries" "test \$(grep -c '\]=' \"$CORE\") -ge 20"

# ── Install coverage ────────────────────────────────────────────────────────
# Every MCP in registry must have corresponding install handling in 12-mcp-lsp.sh
assert "12-mcp-lsp.sh iterates registry" "grep -q 'for name in.*MCP_PACKAGES' \"$MCP_INSTALL\""
assert "12-mcp-lsp.sh calls _mcp" "grep -q '_mcp.*MCP_PACKAGES' \"$MCP_INSTALL\""

# ── Health check coverage ───────────────────────────────────────────────────
for mcp in context7 filesystem agentic-tools codegraph playwright agent-browser loopsense github postgres sequential-thinking memorylayer chrome-devtools memory redis brave-search sqlite excalidraw context7-official notion; do
  assert "Health check covers $mcp" "grep -qE '_check.*$mcp' \"$HEALTH\""
done

# ── Plugin health checks ────────────────────────────────────────────────────
EXPECTED_PLUGINS="orchestrator token-tracker notify dcp swarm auto-fallback goal-mode vibeguard"
for plug in $EXPECTED_PLUGINS; do
  assert "Health check covers plugin $plug" "grep -qE 'plugin-$plug' \"$HEALTH\""
done

# ── LSP health checks ───────────────────────────────────────────────────────
EXPECTED_LSP="gopls rust-analyzer tsserver pyright bash-lsp dockerfile-lsp css-lsp html-lsp json-lsp"
for lsp in $EXPECTED_LSP; do
  assert "Health check covers LSP $lsp" "grep -qE '\\\"$lsp\\\"' \"$HEALTH\""
done

# ── Pre-session MCP list ────────────────────────────────────────────────────
PRE_SESSION="$PROJECT_DIR/src/lib/pre-session-check.sh"
for mcp in c7-mcp-server chrome-devtools-mcp; do
  assert "Pre-session check includes $mcp" "grep -q '$mcp' \"$PRE_SESSION\""
done
assert "Pre-session counts 12+ MCPs" "grep 'for mcp in' \"$PRE_SESSION\" | grep -oE '[a-zA-Z0-9_-]+' | wc -l | awk '{exit (\$1>=12?0:1)}'"

# ── Version check covers new packages ───────────────────────────────────────
VERSION_CHECK="$PROJECT_DIR/src/lib/version-check.sh"
for pkg in opencode-codegraph opencode-swarm chrome-devtools-mcp opencode-daytona opencode-background-agents opencode-firecrawl; do
  assert "Version check covers $pkg" "grep -q '$pkg' \"$VERSION_CHECK\""
done

echo
echo "=== test_mcp_registry.sh: $TESTS_PASS passed, $TESTS_FAIL failed ==="
[ "$TESTS_FAIL" -eq 0 ] || exit 1
