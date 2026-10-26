#!/usr/bin/env bash
# Unit tests for the deployable agentic-stack services:
#   deploy/agentic-stack/docker-compose.yml + scripts/stack.sh
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
COMPOSE_DIR="$PROJECT_DIR/deploy/agentic-stack"
COMPOSE="$COMPOSE_DIR/docker-compose.yml"
STACK="$PROJECT_DIR/scripts/stack.sh"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Test 1: files exist and parse ==="
[ -f "$COMPOSE" ] && pass "docker-compose.yml exists" || fail "compose file missing"
[ -f "$COMPOSE_DIR/README.md" ] && pass "README exists" || fail "README missing"
[ -f "$COMPOSE_DIR/.env.example" ] && pass ".env.example exists" || fail ".env.example missing"
[ -f "$STACK" ] && pass "scripts/stack.sh exists" || fail "stack.sh missing"
bash -n "$STACK" 2>/dev/null && pass "stack.sh syntax" || fail "stack.sh syntax"
python3 - "$COMPOSE" <<'PY' && pass "compose YAML parses" || fail "compose YAML invalid"
import sys, yaml
yaml.safe_load(open(sys.argv[1]))
PY

echo
echo "=== Test 2: required services present ==="
for svc in qdrant postgres redis memorylayer; do
  python3 - "$COMPOSE" "$svc" <<'PY' && pass "service: $svc" || fail "service missing: $svc"
import sys, yaml
d = yaml.safe_load(open(sys.argv[1]))
sys.exit(0 if sys.argv[2] in (d.get("services") or {}) else 1)
PY
done

echo
echo "=== Test 3: loopback-only publishing, no privileged containers ==="
if grep -qE '^\s*-\s*"[0-9]+:' "$COMPOSE"; then
  fail "a port is published on all interfaces"
else
  pass "no port is published on all interfaces"
fi
grep -q '127.0.0.1:' "$COMPOSE" && pass "ports bound to 127.0.0.1" || fail "no loopback binding found"
if grep -q 'privileged:\s*true' "$COMPOSE"; then fail "privileged container declared"; else pass "no privileged container"; fi
grep -q 'no-new-privileges' "$COMPOSE" && pass "no-new-privileges set" || fail "no-new-privileges missing"
grep -q 'resources:' "$COMPOSE" && pass "resource limits declared" || fail "no resource limits"

echo
echo "=== Test 4: stack.sh contract ==="
help_out="$(bash "$STACK" --help 2>&1)"
for cmd in status check up down logs env; do
  case "$help_out" in *"$cmd"*) pass "help documents '$cmd'" ;; *) fail "help misses '$cmd'" ;; esac
done
bash "$STACK" bogus >/dev/null 2>&1
[ $? -eq 2 ] && pass "unknown command exits 2" || fail "unknown command should exit 2"

echo
echo "=== Test 5: env output matches the MCP wiring ==="
env_out="$(bash "$STACK" env 2>&1)"
case "$env_out" in *"QDRANT_URL=http://127.0.0.1:6333"*) pass "env exposes QDRANT_URL" ;; *) fail "QDRANT_URL missing" ;; esac
case "$env_out" in *"postgresql://opencode:opencode@127.0.0.1:5432/opencode"*) pass "env exposes POSTGRES_URL" ;; *) fail "POSTGRES_URL missing" ;; esac
template="$PROJECT_DIR/src/data/opencode.global.template.json"
jq -e '.mcp.qdrant.environment.QDRANT_URL == "http://127.0.0.1:6333"' "$template" >/dev/null 2>&1 \
  && pass "template qdrant MCP points at the stack" || fail "template qdrant MCP not wired"
jq -e '.mcp.postgres.command[] | select(test("5432"))' "$template" >/dev/null 2>&1 \
  && pass "template postgres MCP points at the stack" || fail "template postgres MCP not wired"
jq -e '.mcp.codegraph' "$template" >/dev/null 2>&1 \
  && pass "template ships the codegraph MCP" || fail "template misses codegraph MCP"

echo
echo "=== Test 6: LSP servers are declared with absolute commands ==="
n_lsp=$(jq -r '.lsp | length' "$template")
[ "${n_lsp:-0}" -ge 10 ] && pass "template declares $n_lsp LSP servers" || fail "only ${n_lsp:-0} LSP servers"
all_abs=$(jq -r '[.lsp[].command[0] | startswith("__HOME__")] | all' "$template")
[ "$all_abs" = "true" ] && pass "every LSP command is absolute (__HOME__-prefixed)" || fail "relative LSP command found"
jq -e '.lsp.typescript.extensions | index(".ts")' "$template" >/dev/null && pass "typescript LSP covers .ts" || fail "typescript extensions missing"

echo
echo "=========================================="
echo "RESULTS: $PASS pass, $FAIL fail"
echo "=========================================="
[ "$FAIL" -eq 0 ] || exit 1
