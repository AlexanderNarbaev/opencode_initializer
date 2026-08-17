#!/usr/bin/env bash
# ============================================================================
# ISOLATED Unit Test for 52-context-selector.sh
# Target: src/lib/52-context-selector.sh
# Session: ses_context_selector_test
#
# Tests:
#   (a) Module file + syntax validity
#   (b) config.json — task categories + file_lsp_map validity
#   (c) _select_mcp_for_task() — per-category MCP selection + fallback
#   (d) _select_lsp_for_file() — extension → LSP mapping
#   (e) _optimize_context() — JSON summary + model-router integration
#   (f) Module structure — gates, shebang, function definitions
#
# Isolation: temp HOME + stubbed helpers; module sourced standalone.
# ============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
MODULE="$PROJECT_DIR/src/lib/52-context-selector.sh"
TESTS_PASS=0; TESTS_FAIL=0

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") 2>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $desc" >&2
  fi
}

echo "=== Testing 52-context-selector.sh ==="

# ── (a) Module + syntax ───────────────────────────────────────────────────────
assert "52-context-selector.sh exists" "[ -f '$MODULE' ]"
assert "52-context-selector.sh bash -n clean" "bash -n '$MODULE'"

# ── Stub helpers (module sourced standalone — no helpers.sh/00-core.sh) ───────
section() { :; }; info() { :; }; log() { :; }; warn() { :; }
_step_skip() { return 1; }
_step_done() { :; }
_spin_start() { :; }; _spin_stop() { :; }; _progress() { :; }; _blur() { :; }

TMP=$(mktemp -d /tmp/test_cs.XXXXXX)
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# Isolate HOME so the module writes config into a temp tree
HOME="$TMP/home"
mkdir -p "$HOME"

# Fake model-router profiles — verifies _optimize_context integration
mkdir -p "$HOME/.config/opencode/model-router"
cat > "$HOME/.config/opencode/model-router/task-profiles.json" <<'ROUTER'
{
  "coding": {"model": "fake/coding-model", "small_model": "fake/coding-small", "fallback": ["fake/fallback"]}
}
ROUTER

# ── Source the module (runs its main body against temp HOME) ─────────────────
# shellcheck disable=SC1090
source "$MODULE"
CFG="$HOME/.config/opencode/context-selector/config.json"

# ── (b) config.json validity ─────────────────────────────────────────────────
assert "config.json written" "[ -f '$CFG' ]"
assert "config.json valid JSON" "python3 -c \"import json; json.load(open('$CFG'))\""
for t in coding reasoning fast agentic research testing; do
  assert "has $t category" "python3 -c \"import json; d=json.load(open('$CFG')); assert '$t' in d['task_categories']\""
done
assert "file_lsp_map has .ts" "python3 -c \"import json; d=json.load(open('$CFG')); assert '.ts' in d['file_lsp_map']\""
assert "file_lsp_map has .py" "python3 -c \"import json; d=json.load(open('$CFG')); assert '.py' in d['file_lsp_map']\""
assert "file_lsp_map has .go" "python3 -c \"import json; d=json.load(open('$CFG')); assert '.go' in d['file_lsp_map']\""
assert "defaults has default_task" "python3 -c \"import json; d=json.load(open('$CFG')); assert d['defaults']['default_task']\""

# ── (c) _select_mcp_for_task ─────────────────────────────────────────────────
assert "coding MCP includes codegraph" "echo \"\$(_select_mcp_for_task coding)\" | grep -q codegraph"
assert "coding MCP includes git" "echo \"\$(_select_mcp_for_task coding)\" | grep -q git"
assert "coding MCP includes filesystem" "echo \"\$(_select_mcp_for_task coding)\" | grep -q filesystem"
assert "fast MCP is minimal (filesystem only)" "[ \"\$(_select_mcp_for_task fast)\" = 'filesystem' ]"
assert "reasoning MCP includes memory" "echo \"\$(_select_mcp_for_task reasoning)\" | grep -q memory"
assert "reasoning MCP includes fetch" "echo \"\$(_select_mcp_for_task reasoning)\" | grep -q fetch"
assert "agentic MCP includes orchestrator" "echo \"\$(_select_mcp_for_task agentic)\" | grep -q open-orchestra"
assert "agentic MCP includes browser" "echo \"\$(_select_mcp_for_task agentic)\" | grep -q playwright"
assert "research MCP includes fetch" "echo \"\$(_select_mcp_for_task research)\" | grep -q fetch"
assert "unknown task falls back to default" "echo \"\$(_select_mcp_for_task doesnotexist)\" | grep -q codegraph"

# ── (d) _select_lsp_for_file ─────────────────────────────────────────────────
assert ".ts → typescript-lsp" "echo \"\$(_select_lsp_for_file foo.ts)\" | grep -q typescript-lsp"
assert ".ts → eslint-lsp" "echo \"\$(_select_lsp_for_file foo.ts)\" | grep -q eslint-lsp"
assert ".py → pyright" "echo \"\$(_select_lsp_for_file foo.py)\" | grep -q pyright"
assert ".go → gopls" "echo \"\$(_select_lsp_for_file foo.go)\" | grep -q gopls"
assert "nested path .py → pyright" "echo \"\$(_select_lsp_for_file src/pkg/mod.py)\" | grep -q pyright"
assert ".txt → empty" "[ -z \"\$(_select_lsp_for_file foo.txt)\" ]"
assert "no file → empty" "[ -z \"\$(_select_lsp_for_file)\" ]"

# ── (e) _optimize_context ────────────────────────────────────────────────────
assert "optimize coding is JSON with mcp" "echo \"\$(_optimize_context coding)\" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d[\"mcp\"] and d[\"task\"]==\"coding\"'"
assert "optimize fast is JSON with flash model" "echo \"\$(_optimize_context fast)\" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert \"flash\" in d[\"model\"]'"
assert "optimize coding+file injects file LSP" "echo \"\$(_optimize_context coding foo.py)\" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert \"pyright\" in d[\"lsp\"]'"
assert "optimize pulls model from model-router" "echo \"\$(_optimize_context coding)\" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d[\"model\"]==\"fake/coding-model\"'"
assert "optimize exposes router fallback" "echo \"\$(_optimize_context coding)\" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d[\"fallback\"]==[\"fake/fallback\"]'"
assert "optimize unknown task falls back to default" "echo \"\$(_optimize_context nope)\" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d[\"task\"]==\"coding\"'"

# ── (f) Module structure ─────────────────────────────────────────────────────
assert "has _step_skip gate" "grep -q '_step_skip step_context_selector' '$MODULE'"
assert "has section header" "grep -q 'section.*Context-Aware' '$MODULE'"
assert "defines _select_mcp_for_task" "grep -q '^_select_mcp_for_task()' '$MODULE'"
assert "defines _select_lsp_for_file" "grep -q '^_select_lsp_for_file()' '$MODULE'"
assert "defines _optimize_context" "grep -q '^_optimize_context()' '$MODULE'"
assert "writes config.json" "grep -q 'config.json' '$MODULE'"
assert "writes select.sh CLI" "grep -q 'select.sh' '$MODULE'"
assert "has _step_done gating" "grep -q '_step_done step_context_selector' '$MODULE'"
assert "has shebang" "head -1 '$MODULE' | grep -q '#!/usr/bin/env bash'"
assert "has opt-out flag" "grep -q 'SKIP_CONTEXT_SELECTOR' '$MODULE'"

# ── Report ───────────────────────────────────────────────────────────────────
echo "test_context_selector: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
