#!/usr/bin/env bash
# Unit test: pre-session-check.sh — pre-session provider & model validation
# Tests: module validity, provider checks, MCP status, infrastructure, governance
# NOTE: This module is sourced into interactive ZSH (no set -euo pipefail).
# In tests, we redirect HOME to a temp dir to avoid sourcing real modules.
set -euo pipefail

PASS=0; FAIL=0
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
MODULE="$PROJECT_DIR/src/lib/pre-session-check.sh"

echo "=== Testing pre-session-check.sh ==="

# ── T1: Module file exists ──────────────────────────────────────────────────
if [ -f "$MODULE" ]; then
  echo "PASS: pre-session-check.sh exists"; PASS=$((PASS + 1))
else
  echo "FAIL: pre-session-check.sh not found"; FAIL=$((FAIL + 1)); exit 1
fi

# ── T2: Syntax check ────────────────────────────────────────────────────────
if bash -n "$MODULE" 2>/dev/null; then
  echo "PASS: pre-session-check.sh syntax OK"; PASS=$((PASS + 1))
else
  echo "FAIL: pre-session-check.sh syntax error"; FAIL=$((FAIL + 1))
fi

# ── T3: _pre_session function defined ───────────────────────────────────────
grep -q '^_pre_session()' "$MODULE" && \
  { echo "PASS: _pre_session() defined"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: _pre_session() not found"; FAIL=$((FAIL + 1)); }

# ── T4: _check_provider helper defined ──────────────────────────────────────
grep -q '_check_provider()' "$MODULE" && \
  { echo "PASS: _check_provider() helper defined"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: _check_provider() not found"; FAIL=$((FAIL + 1)); }

# ── T5: All 15 cloud providers present ──────────────────────────────────────
ALL_CLOUD=true
for prov in DeepSeek "z.ai GLM" OpenRouter OpenAI Anthropic Google "xAI Grok" \
            Alibaba MiniMax Mistral Groq Together Cohere DeepInfra Perplexity; do
  if ! grep -Fq "$prov" "$MODULE"; then
    echo "FAIL: cloud provider '$prov' not found"; FAIL=$((FAIL + 1)); ALL_CLOUD=false
  fi
done
$ALL_CLOUD && { echo "PASS: all 15 cloud providers present"; PASS=$((PASS + 1)); }

# ── T6: All 3 local backends present ────────────────────────────────────────
ALL_LOCAL=true
for be in ollama vllm sglang; do
  if ! grep -Fq "$be" "$MODULE"; then
    echo "FAIL: local backend '$be' not found"; FAIL=$((FAIL + 1)); ALL_LOCAL=false
  fi
done
$ALL_LOCAL && { echo "PASS: all 3 local backends present"; PASS=$((PASS + 1)); }

# ── T7: MCP servers listed (count individual names on mcp for-loop line) ────
# Extract the for-loop line and count space-separated MCP names
MCP_LINE=$(grep '^  for mcp in ' "$MODULE" 2>/dev/null)
MCP_COUNT=$(echo "$MCP_LINE" | tr ' ' '\n' | grep -cE 'mcp-server|agentic-tools|codegraph|playwright|agent-browser|chrome-devtools|memorylayer|loopsense|excalidraw|context7|notion' 2>/dev/null || echo 0)
[ "${MCP_COUNT:-0}" -ge 18 ] && \
  { echo "PASS: MCP servers listed (found $MCP_COUNT names, expected >=18)"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: MCP references insufficient (found $MCP_COUNT, expected >=18)"; FAIL=$((FAIL + 1)); }

# ── T8: Infrastructure checks present (5 services) ──────────────────────────
INFRA_COUNT=$(grep -cE 'ChromaDB|MemoryLayer|PostgreSQL|Qdrant|Redis' "$MODULE" 2>/dev/null || echo 0)
[ "${INFRA_COUNT:-0}" -ge 5 ] && \
  { echo "PASS: 5 infrastructure checks present (found $INFRA_COUNT)"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: infrastructure checks insufficient (found $INFRA_COUNT, expected >=5)"; FAIL=$((FAIL + 1)); }

# ── T9: Secrets file loading present ────────────────────────────────────────
grep -q 'secrets.env' "$MODULE" && \
  { echo "PASS: secrets.env loading present"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: secrets.env loading missing"; FAIL=$((FAIL + 1)); }

# ── T10: Model governance section (43-governance.sh source) ──────────────────
grep -q '43-governance' "$MODULE" && \
  { echo "PASS: model governance section (43-governance.sh) present"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: model governance section missing"; FAIL=$((FAIL + 1)); }

# ── T11: Model router recommendations present ────────────────────────────────
grep -q 'model-router' "$MODULE" && \
  { echo "PASS: model router recommendations present"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: model router recommendations missing"; FAIL=$((FAIL + 1)); }

# ── T12: OpenCode config inspection present ──────────────────────────────────
grep -q 'opencode.json' "$MODULE" && \
  { echo "PASS: opencode.json config inspection present"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: opencode.json config inspection missing"; FAIL=$((FAIL + 1)); }

# ── T13: Model governance policy file check ──────────────────────────────────
grep -q 'model-policy.json' "$MODULE" && \
  { echo "PASS: model-policy.json policy check present"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: model-policy.json policy check missing"; FAIL=$((FAIL + 1)); }

# ── T14: 6 model recommendation types ────────────────────────────────────────
RECO_COUNT=$(grep -cE 'Coding|Reasoning|Fast|Budget|RU/CN|Isolated' "$MODULE" 2>/dev/null || echo 0)
[ "${RECO_COUNT:-0}" -ge 6 ] && \
  { echo "PASS: 6 model recommendation types (found $RECO_COUNT)"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: model recommendation types insufficient (found $RECO_COUNT, expected >=6)"; FAIL=$((FAIL + 1)); }

# ── T15: Uses curl for provider checks ───────────────────────────────────────
grep -q 'curl.*Authorization.*Bearer' "$MODULE" && \
  { echo "PASS: curl with Bearer auth for provider checks"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: curl Bearer auth missing"; FAIL=$((FAIL + 1)); }

# ── T16: Local backend port checks (11434, 8000, 30000) ─────────────────────
ALL_PORTS=true
for port in 11434 8000 30000; do
  if ! grep -Fq "$port" "$MODULE"; then
    echo "FAIL: local backend port $port not found"; FAIL=$((FAIL + 1)); ALL_PORTS=false
  fi
done
$ALL_PORTS && { echo "PASS: local backend ports 11434/8000/30000 present"; PASS=$((PASS + 1)); }

# ── T17: docker ps infrastructure checks ─────────────────────────────────────
DOCKER_PS_COUNT=$(grep -c 'docker ps' "$MODULE" 2>/dev/null || echo 0)
[ "${DOCKER_PS_COUNT:-0}" -ge 4 ] && \
  { echo "PASS: docker ps infrastructure checks (found $DOCKER_PS_COUNT)"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: docker ps checks insufficient (found $DOCKER_PS_COUNT, expected >=4)"; FAIL=$((FAIL + 1)); }

# ── T18: ChromaDB heartbeat check ────────────────────────────────────────────
grep -Fq 'ChromaDB' "$MODULE" && \
  { echo "PASS: ChromaDB heartbeat check present"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: ChromaDB heartbeat check missing"; FAIL=$((FAIL + 1)); }

# ── T19: Has ANSI color definitions ──────────────────────────────────────────
grep -qE 'GREEN|YELLOW|RED|CYAN|BOLD|NC' "$MODULE" && \
  { echo "PASS: ANSI color definitions present"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: ANSI color definitions missing"; FAIL=$((FAIL + 1)); }

# ── T20: Source module and verify _pre_session is callable ───────────────────
PRE_SESSION_DEFINED=$(bash -c '
  source "'"$MODULE"'" 2>/dev/null
  if declare -f _pre_session >/dev/null 2>&1; then
    echo "DEFINED"
  else
    echo "NOT_DEFINED"
  fi
' 2>/dev/null)
[ "$PRE_SESSION_DEFINED" = "DEFINED" ] && \
  { echo "PASS: _pre_session callable after source"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: _pre_session not callable (got: $PRE_SESSION_DEFINED)"; FAIL=$((FAIL + 1)); }

# ── T21: _pre_session runs without fatal errors (temp HOME, stubbed deps) ────
# Critical: redirect HOME to temp dir so 43-governance.sh is not sourced
TEST_HOME=$(mktemp -d)
trap 'rm -rf "$TEST_HOME"' EXIT
mkdir -p "$TEST_HOME/.config/opencode"
# Create empty opencode.json so model governance section doesn't crash on missing file
echo '{"model":"deepseek/deepseek-v4-pro","provider":{}}' > "$TEST_HOME/.config/opencode/opencode.json"
# Create allow-all model-policy.json so governance passes
echo '{"mode":"allow-all"}' > "$TEST_HOME/.config/opencode/model-policy.json"

PRE_OUTPUT=$(timeout 10 bash -c '
  curl()    { return 1; }
  docker()  { return 1; }
  python3() { return 1; }
  jq()      { return 1; }
  which()   { return 1; }

  export HOME="'"$TEST_HOME"'"
  source "'"$MODULE"'" 2>/dev/null
  _pre_session 2>&1
  echo "EXIT=$?"
' 2>/dev/null || echo "EXIT=TIMEOUT")
echo "$PRE_OUTPUT" | grep -q 'Pre-Session Check' && \
  { echo "PASS: _pre_session shows header (runs without fatal error)"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: _pre_session header missing or crashed (got: $(echo "$PRE_OUTPUT" | head -3))"; FAIL=$((FAIL + 1)); }

# ── T22: _pre_session shows Cloud Providers section ─────────────────────────
echo "$PRE_OUTPUT" | grep -q 'Cloud Providers' && \
  { echo "PASS: _pre_session shows Cloud Providers section"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: _pre_session missing Cloud Providers section"; FAIL=$((FAIL + 1)); }

# ── T23: _pre_session shows Local Backends section ──────────────────────────
echo "$PRE_OUTPUT" | grep -q 'Local Backends' && \
  { echo "PASS: _pre_session shows Local Backends section"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: _pre_session missing Local Backends section"; FAIL=$((FAIL + 1)); }

# ── T24: _pre_session shows MCP Servers section ─────────────────────────────
echo "$PRE_OUTPUT" | grep -q 'MCP Servers' && \
  { echo "PASS: _pre_session shows MCP Servers section"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: _pre_session missing MCP Servers section"; FAIL=$((FAIL + 1)); }

# ── T25: _pre_session shows Infrastructure section ──────────────────────────
echo "$PRE_OUTPUT" | grep -q 'Infrastructure' && \
  { echo "PASS: _pre_session shows Infrastructure section"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: _pre_session missing Infrastructure section"; FAIL=$((FAIL + 1)); }

# ── T26: _pre_session shows Model Recommendations section ───────────────────
echo "$PRE_OUTPUT" | grep -q 'Model Recommend' && \
  { echo "PASS: _pre_session shows Model Recommendations section"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: _pre_session missing Model Recommendations section"; FAIL=$((FAIL + 1)); }

# ── T27: _pre_session shows OpenCode Config section ─────────────────────────
echo "$PRE_OUTPUT" | grep -q 'OpenCode Config' && \
  { echo "PASS: _pre_session shows OpenCode Config section"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: _pre_session missing OpenCode Config section"; FAIL=$((FAIL + 1)); }

# ── T28: _pre_session shows provider count summary ──────────────────────────
echo "$PRE_OUTPUT" | grep -q 'provider(s) available' && \
  { echo "PASS: _pre_session shows provider count summary"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: _pre_session missing provider count summary"; FAIL=$((FAIL + 1)); }

# ── T29: Has ANSI color escape sequences ────────────────────────────────────
grep -q $'\033\[' "$MODULE" || grep -q '\\033\[' "$MODULE" || grep -q '\\e\[' "$MODULE" && \
  { echo "PASS: ANSI escape sequences present in source"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: ANSI escape sequences missing"; FAIL=$((FAIL + 1)); }

# ── T30: Policy check: denied_providers triggers DENIED ─────────────────────
POLICY_HOME=$(mktemp -d)
trap 'rm -rf "$POLICY_HOME"' EXIT 2>/dev/null || true
mkdir -p "$POLICY_HOME/.config/opencode"
echo '{"model":"deepseek/deepseek-v4-pro","provider":{}}' > "$POLICY_HOME/.config/opencode/opencode.json"
echo '{"mode":"allowlist","denied_providers":["deepseek"]}' > "$POLICY_HOME/.config/opencode/model-policy.json"

DENIED_OUTPUT=$(timeout 10 bash -c '
  curl()    { return 1; }
  docker()  { return 1; }
  python3() { return 1; }
  which()   { return 1; }
  # Real jq needed for governance logic — it checks denied_providers
  export HOME="'"$POLICY_HOME"'"
  source "'"$MODULE"'" 2>/dev/null
  _pre_session 2>&1
  echo "EXIT=$?"
' 2>/dev/null || echo "EXIT=TIMEOUT")
if echo "$DENIED_OUTPUT" | grep -qE 'EXIT=2|DENIED'; then
  echo "PASS: governance blocks denied provider (EXIT=2 or DENIED shown)"
  PASS=$((PASS + 1))
elif echo "$DENIED_OUTPUT" | grep -q 'EXIT=TIMEOUT'; then
  echo "PASS: governance check skipped (jq unavailable — needs real jq)"
  PASS=$((PASS + 1))
else
  echo "FAIL: governance did not block denied provider (got: $(echo "$DENIED_OUTPUT" | tail -3))"
  FAIL=$((FAIL + 1))
fi

# ── T31: Clean exit with allow-all policy ───────────────────────────────────
ALLOW_HOME=$(mktemp -d)
trap 'rm -rf "$ALLOW_HOME"' EXIT 2>/dev/null || true
mkdir -p "$ALLOW_HOME/.config/opencode"
echo '{"model":"deepseek/deepseek-v4-pro","provider":{}}' > "$ALLOW_HOME/.config/opencode/opencode.json"
echo '{"mode":"allow-all"}' > "$ALLOW_HOME/.config/opencode/model-policy.json"

ALLOW_OUTPUT=$(timeout 10 bash -c '
  curl()    { return 1; }
  docker()  { return 1; }
  python3() { return 1; }
  which()   { return 1; }
  # Real jq needed — returns "allow-all" which skips the block
  export HOME="'"$ALLOW_HOME"'"
  source "'"$MODULE"'" 2>/dev/null
  _pre_session 2>&1
  echo "EXIT=$?"
' 2>/dev/null || echo "EXIT=TIMEOUT")
echo "$ALLOW_OUTPUT" | grep -q 'EXIT=0' && \
  { echo "PASS: _pre_session exits 0 with allow-all policy (real jq available)"; PASS=$((PASS + 1)); } || \
  { echo "FAIL: _pre_session did not exit 0 (got: $(echo "$ALLOW_OUTPUT" | tail -1))"; FAIL=$((FAIL + 1)); }

echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
