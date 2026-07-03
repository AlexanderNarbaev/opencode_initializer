#!/usr/bin/env bash
# Test scripts/embed-proxy.py — Ollama embedding proxy for MemoryLayer
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $desc" >&2; fi
}

P="$PROJECT_DIR/scripts/embed-proxy.py"
assert "embed-proxy.py exists" "[ -f '$P' ]"
assert "embed-proxy.py syntax valid" "python3 -m py_compile '$P'"

# ── Content checks ───────────────────────────────────────────────────────────
assert "has Flask/FastAPI import" "grep -qE 'flask|fastapi|http.server|aiohttp' '$P'"
assert "has Ollama URL" "grep -qi 'ollama' '$P'"
assert "has embed endpoint" "grep -q 'embed' '$P'"
assert "has mxbai model" "grep -q 'mxbai' '$P'"
assert "has /v1/embeddings endpoint" "grep -q 'v1/embeddings' '$P'"

# ── systemd service ──────────────────────────────────────────────────────────
S="$PROJECT_DIR/scripts/opencode-embed-proxy.service"
assert "systemd service exists" "[ -f '$S' ]"
assert "service has ExecStart" "grep -q 'ExecStart' '$S'"
assert "service has embed-proxy.py" "grep -q 'embed-proxy.py' '$S'"
assert "service has Restart" "grep -q 'Restart' '$S'"

echo "test_embed_proxy: $TESTS_PASS passed, $TESTS_FAIL failed"
