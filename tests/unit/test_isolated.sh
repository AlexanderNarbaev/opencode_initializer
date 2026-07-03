#!/usr/bin/env bash
# Test 32-isolated.sh module
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $desc" >&2; fi
}

# ── Test 1: Isolated Circuit detection ───────────────────────────────────────
C="$PROJECT_DIR/src/lib/32-isolated.sh"
assert "32-isolated.sh exists" "[ -f '$C' ]"
assert "32-isolated.sh syntax valid" "bash -n '$C'"
assert "has ISOLATED_CIRCUIT variable" "grep -q 'ISOLATED_CIRCUIT' '$C'"
assert "has Ollama backend" "grep -q 'ollama' '$C'"
assert "has LiteLLM backend" "grep -q 'litellm' '$C'"
assert "has vLLM backend" "grep -q 'vllm' '$C'"
assert "has SGLang backend" "grep -q 'sglang' '$C'"
assert "has port 11434" "grep -q '11434' '$C'"
assert "has port 4000" "grep -q '4000' '$C'"
assert "has port 8000" "grep -q '8000' '$C'"
assert "has port 30000" "grep -q '30000' '$C'"
assert "has /v1/models endpoint" "grep -q '/v1/models' '$C'"
assert "has true/false normalization" "grep -q 'true.*false' '$C'"
assert "has default off" "grep -q 'ISOLATED_CIRCUIT.*false' '$C'"

# ── Test 2: Isolated Circuit in providers ────────────────────────────────────
P="$PROJECT_DIR/src/lib/26-providers.sh"
assert "26-providers.sh has ISOLATED_CIRCUIT check" "grep -q 'ISOLATED_CIRCUIT' '$P'"
assert "26-providers.sh has local-only mode" "grep -q 'local providers only' '$P'"

# ── Test 3: Isolated Circuit in opencode-json ────────────────────────────────
J="$PROJECT_DIR/src/lib/18-opencode-json.sh"
assert "18-opencode-json.sh has ISOLATED_CIRCUIT" "grep -q 'ISOLATED_CIRCUIT' '$J'"
assert "18-opencode-json.sh has isolated branch" "grep -q 'isolated' '$J'"
assert "18-opencode-json.sh has local backends" "grep -q 'local_backends' '$J'"

# ── Test 4: dev.sh isolated command ──────────────────────────────────────────
D="$PROJECT_DIR/dev.sh"
assert "dev.sh has isolated command" "grep -q 'isolated' '$D'"
assert "dev.sh has isolated on" "grep -q 'isolated.*on' '$D'"
assert "dev.sh has isolated off" "grep -q 'isolated.*off' '$D'"
assert "dev.sh has isolated status" "grep -q 'isolated.*status' '$D'"

# ── Test 5: Cockpit TUI indicator ───────────────────────────────────────────
G="$PROJECT_DIR/src/cockpit/main.go"
assert "cockpit has ISOLATED indicator" "grep -qi 'isolated' '$G'"

echo "test_isolated: $TESTS_PASS passed, $TESTS_FAIL failed"
