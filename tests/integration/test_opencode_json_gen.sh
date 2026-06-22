#!/usr/bin/env bash
# ============================================================================
# Integration test for 18-opencode-json.sh — opencode.json generation
# Tests: Python config contains all expected sections, lsp_check calls,
#        plugin detection, MCP config structure
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

echo "=== Testing opencode.json generation ==="

JSON_GEN="$PROJECT_DIR/src/lib/18-opencode-json.sh"

# ── Structure checks ────────────────────────────────────────────────────────
assert "18-opencode-json.sh exists" "test -f \"$JSON_GEN\""
assert "Python inline block exists" "grep -q 'python3 << .PYGEN.' \"$JSON_GEN\""
assert "generate_opencode_json function" "grep -q 'generate_opencode_json()' \"$JSON_GEN\""

# ── MCP detection ───────────────────────────────────────────────────────────
EXPECTED_MCPS="context7 filesystem agentic-tools codegraph playwright agent-browser loopsense github postgres gitlab google-maps sequential-thinking memorylayer chrome-devtools git memory fetch time redis brave-search sqlite excalidraw context7-official notion"
for mcp in $EXPECTED_MCPS; do
  assert "MCP detection for $mcp" "grep -qE 'mcps\\[.${mcp}.\\]' \"$JSON_GEN\""
done
assert "Remote MCPs included (sentry)" "grep -qE 'sentry.*remote' \"$JSON_GEN\""
assert "Remote MCPs included (grep)" "grep -qE '\\\"grep\\\".*remote' \"$JSON_GEN\""

# ── LSP detection ───────────────────────────────────────────────────────────
EXPECTED_LSP="gopls rust-analyzer typescript pyright omnisharp yaml marksman taplo lua zls bash dockerfile css html json"
for lsp in $EXPECTED_LSP; do
  assert "LSP detection for $lsp" "grep -qE 'lsp_check.*\\\"$lsp\\\"' \"$JSON_GEN\""
done

# ── Plugin detection ────────────────────────────────────────────────────────
EXPECTED_PLUGINS="opencode-codegraph opencode-dcp opencode-auto-fallback opencode-goal-mode opencode-swarm opencode-vibeguard opencode-daytona opencode-background-agents opencode-scheduler opencode-supermemory opencode-firecrawl opencode-conductor opencode-morph-plugin opencode-zellij-namer opencode-plugin-otel"
for plug in $EXPECTED_PLUGINS; do
  assert "Plugin detection for $plug" "grep -qE '\\\"$plug\\\"' \"$JSON_GEN\""
done

# ── Provider config ─────────────────────────────────────────────────────────
assert "Provider builder exists" "grep -q '_build_providers()' \"$JSON_GEN\""
for prov in deepseek opencode xai mimo moonshot minimax; do
  assert "Provider: $prov" "grep -qE '\\\"$prov\\\"' \"$JSON_GEN\""
done
assert "Provider fallback chains exist" "grep -q 'fallback' \"$JSON_GEN\""

# ── Config structure ────────────────────────────────────────────────────────
for key in model small_model default_agent autoupdate compaction provider tool_output watcher experimental lsp plugin mcp; do
  assert "Config includes $key" "grep -qE '\\\"$key\\\"' \"$JSON_GEN\""
done
assert "Config includes agent section" "grep -qE '\"agent\"' \"$JSON_GEN\""

# ── Cold-start test ─────────────────────────────────────────────────────────
assert "Cold-start verification exists" "grep -q 'cold-start' \"$JSON_GEN\""
assert "Cold-start iterates MCPs" "grep -q 'for mcp_name in' \"$JSON_GEN\""

# ── Valid JSON output marker ────────────────────────────────────────────────
assert "VALID marker exists" "grep -q 'VALID:' \"$JSON_GEN\""

echo
echo "=== test_opencode_json_gen.sh: $TESTS_PASS passed, $TESTS_FAIL failed ==="
[ "$TESTS_FAIL" -eq 0 ] || exit 1
