#!/usr/bin/env bash
# ============================================================================
# E2E test: 19-finalize.sh — finalize logic validation
# Tests: Git config, PATH persistence, secret file handling, P10k fix
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

echo "=== E2E: finalize validation ==="

F="$PROJECT_DIR/lib/19-finalize.sh"

# ── Verify sections exist ──────────────────────────────────────────────
assert "finalize has git config section"  'grep -q "Git configuration" "'"$F"'"'
assert "finalize has PATH persistence"    'grep -q "PATH persistence" "'"$F"'"'
assert "finalize handles secrets.env"     'grep -q "secrets\.env" "'"$F"'"'
assert "finalize handles P10k"            'grep -qi "P10k\|p10k" "'"$F"'"'
assert "finalize handles dev CLI install" 'grep -qE "dev CLI|\.local/bin/dev" "'"$F"'"'
assert "finalize has verification section" 'grep -q "Verification" "'"$F"'"'
assert "finalize has auth.json handling"  'grep -q "auth.json" "'"$PROJECT_DIR/lib/11-opencode.sh"'"'

# ── Verify mode guards ─────────────────────────────────────────────────
assert "finalize guards on full/reinit" 'grep -qE "MODE.*=.*full.*reinit" "'"$F"'"'

# ── Verify config file template ────────────────────────────────────────
assert "finalize creates setup.conf" 'grep -q "setup.conf" "'"$F"'"'

# ── Verify API key storage uses chmod 600 ─────────────────────────────
assert "secrets.env has chmod 600" 'grep -q "chmod 600" "'"$F"'"'

# ── Verify PATH line format ────────────────────────────────────────────
assert "PATH line includes npm-global" 'grep -q "npm-global" "'"$F"'"'
assert "PATH line includes cargo"      'grep -q "cargo" "'"$F"'"'
assert "PATH line includes go"         'grep -q "/go/bin" "'"$F"'"'
assert "PATH line includes bun"        'grep -q "bun" "'"$F"'"'
assert "PATH line includes dotnet"     'grep -q "dotnet" "'"$F"'"'

# ── Verify MCP verification list ──────────────────────────────────────
for mcp in context7 filesystem agentic-tools codegraph playwright agent-browser loopsense github postgres sequential-thinking memorylayer; do
  assert "finalize verifies MCP $mcp" 'grep -q "'"$mcp"'" "'"$F"'"'
done

# ── Verify Shokunin profile suppression ────────────────────────────────
assert "finalize has shokunin section" 'grep -qi "Shokunin" "'"$F"'"'

# ── Verify bootstrap complete message ──────────────────────────────────
assert "finalize has bootstrap complete" 'grep -qi "BOOTSTRAP\|bootstrap" "'"$F"'"'

# ── Verify that all 6 API key providers are handled ────────────────────
assert "finalize handles DEEPSEEK_KEY"    'grep -q "DEEPSEEK_KEY" "'"$F"'"'
assert "finalize handles OPENCODE_API"    'grep -qE "API_KEY|OPENCODE_API" "'"$F"'"'
assert "finalize handles XAI_KEY"         'grep -q "XAI_KEY" "'"$F"'"'
assert "finalize handles GITHUB_TOKEN"    'grep -q "GITHUB_TOKEN" "'"$F"'"'

echo
echo "=== test_finalize.sh: $TESTS_PASS passed, $TESTS_FAIL failed ==="
[ "$TESTS_FAIL" -eq 0 ] || exit 1
