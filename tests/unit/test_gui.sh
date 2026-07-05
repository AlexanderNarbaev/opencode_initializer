#!/usr/bin/env bash
# Test GUI server and dashboard
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $desc" >&2; fi
}

S="$PROJECT_DIR/src/gui/server.js"
I="$PROJECT_DIR/src/gui/index.html"

assert "server.js exists" "[ -f '$S' ]"
assert "index.html exists" "[ -f '$I' ]"

# ── API routes ───────────────────────────────────────────────────────────────
assert "server.js has /api/status route" "grep -q '/status' '$S'"
assert "server.js has /api/providers route" "grep -q '/providers' '$S'"
assert "server.js has /api/models route" "grep -q '/models' '$S'"
assert "server.js has /api/mcp route" "grep -q '/mcp' '$S'"
assert "server.js has /api/lsp route" "grep -q '/lsp' '$S'"
assert "server.js has /api/infra route" "grep -q '/infra' '$S'"
assert "server.js has /api/isolated route" "grep -q '/isolated' '$S'"
assert "server.js has /api/backups route" "grep -q '/backups' '$S'"
assert "server.js has /api/logs route" "grep -q '/logs' '$S'"

# ── Server functionality ─────────────────────────────────────────────────────
assert "server.js has http.createServer" "grep -q 'createServer' '$S'"
assert "server.js has readOpencodeConfig" "grep -q 'readOpencodeConfig' '$S'"
assert "server.js has readTaskProfiles" "grep -q 'readTaskProfiles' '$S'"
assert "server.js has checkPort" "grep -q 'checkPort' '$S'"
assert "server.js has checkBin" "grep -q 'checkBin' '$S'"
assert "server.js has PORT config" "grep -q 'GUI_PORT' '$S'"

# ── HTML structure ───────────────────────────────────────────────────────────
assert "index.html has sidebar" "grep -q 'sidebar' '$I'"
assert "index.html has overview section" "grep -q 'overview' '$I'"
assert "index.html has providers section" "grep -q 'providers' '$I'"
assert "index.html has models section" "grep -q 'models' '$I'"
assert "index.html has mcp section" "grep -q 'mcp' '$I'"
assert "index.html has lsp section" "grep -q 'lsp' '$I'"
assert "index.html has infra section" "grep -q 'infra' '$I'"
assert "index.html has isolated section" "grep -q 'isolated' '$I'"
assert "index.html has backup section" "grep -q 'backup' '$I'"
assert "index.html has logs section" "grep -q 'logs' '$I'"
assert "index.html has loadOverview" "grep -q 'loadOverview' '$I'"
assert "index.html has loadProviders" "grep -q 'loadProviders' '$I'"
assert "index.html has loadModels" "grep -q 'loadModels' '$I'"
assert "index.html has toggleIsolated" "grep -q 'toggleIsolated' '$I'"
assert "index.html has createBackup" "grep -q 'createBackup' '$I'"

# ── Node.js syntax ───────────────────────────────────────────────────────────
node --check "$S" 2>/dev/null && assert "server.js passes node --check" "true" || assert "server.js passes node --check" "false"

echo "test_gui: $TESTS_PASS passed, $TESTS_FAIL failed"

[ "$TESTS_FAIL" -eq 0 ] || exit 1
