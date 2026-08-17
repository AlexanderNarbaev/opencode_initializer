#!/usr/bin/env bash
# src/lib/52-context-selector.sh — Context-Aware MCP/LSP Selector (STEP 52)
# Selects only the MCP/LSP servers relevant to a task, minimizing token/context
# overhead. Integrates with 36-model-router.sh (task-profiles.json) for model
# recommendation. Pairs with 12-mcp-lsp.sh (install) + 18-opencode-json.sh (config).
set -euo pipefail

_step_skip step_context_selector && return 0

# Opt-out flag (matches SKIP_DOTFILES / SKIP_DEVBOX / SKIP_GUI convention)
[ "${SKIP_CONTEXT_SELECTOR:-false}" = "true" ] && { info "Context selector skipped (SKIP_CONTEXT_SELECTOR=true)"; return 0; }

section "Context-Aware MCP/LSP Selector"

# Config paths (overridable via env for isolated tests / alternate locations)
CONTEXT_SELECTOR_DIR="${CONTEXT_SELECTOR_DIR:-$HOME/.config/opencode/context-selector}"
CONTEXT_SELECTOR_CONFIG="${CONTEXT_SELECTOR_CONFIG:-$CONTEXT_SELECTOR_DIR/config.json}"
mkdir -p "$CONTEXT_SELECTOR_DIR"

# ── config.json — task categories → MCP/LSP requirements ─────────────────────
# Each category maps a task type to the minimal set of MCP servers + LSP servers.
# "fast" loads only the minimal MCP (no LSP); "agentic" loads the full suite.
# MCP names match ~/.config/opencode/opencode.json servers + 00-core.sh registry.
#   search        → websearch (SearXNG MCP)
#   browser       → playwright / agent-browser / chrome-devtools
#   orchestrator  → open-orchestra
cat >"$CONTEXT_SELECTOR_CONFIG" <<'SELECTOR_CONFIG'
{
  "version": "1.0.0",
  "description": "Context-aware MCP/LSP selector — loads only the servers relevant to a task to minimize token/context overhead.",
  "task_categories": {
    "coding": {
      "description": "Implementation, refactoring, code writing",
      "mcp": ["codegraph", "git", "filesystem", "context7-official"],
      "lsp": ["typescript-lsp", "eslint-lsp"],
      "model": "deepseek/deepseek-v4-pro",
      "small_model": "deepseek/deepseek-v4-flash"
    },
    "reasoning": {
      "description": "Architecture, planning, complex analysis",
      "mcp": ["fetch", "websearch", "memory", "sequential-thinking"],
      "lsp": [],
      "model": "anthropic/claude-opus-4-8",
      "small_model": "anthropic/claude-sonnet-4-6"
    },
    "fast": {
      "description": "Quick answers, exploration, compaction — minimal context",
      "mcp": ["filesystem"],
      "lsp": [],
      "model": "deepseek/deepseek-v4-flash",
      "small_model": "deepseek/deepseek-v4-flash"
    },
    "agentic": {
      "description": "Autonomous multi-step workflows — full tool access",
      "mcp": ["codegraph", "git", "filesystem", "playwright", "agent-browser", "chrome-devtools", "sequential-thinking", "memorylayer", "memory", "github", "open-orchestra", "context7-official"],
      "lsp": [],
      "model": "deepseek/deepseek-v4-pro",
      "small_model": "deepseek/deepseek-v4-flash"
    },
    "research": {
      "description": "External research, documentation gathering",
      "mcp": ["fetch", "websearch", "playwright", "agent-browser", "context7-official"],
      "lsp": [],
      "model": "deepseek/deepseek-v4-pro",
      "small_model": "deepseek/deepseek-v4-flash"
    },
    "testing": {
      "description": "Test authoring, execution, coverage analysis",
      "mcp": ["filesystem", "git", "codegraph"],
      "lsp": ["typescript-lsp"],
      "model": "deepseek/deepseek-v4-pro",
      "small_model": "deepseek/deepseek-v4-flash"
    }
  },
  "file_lsp_map": {
    ".ts": ["typescript-lsp", "eslint-lsp"],
    ".tsx": ["typescript-lsp", "eslint-lsp"],
    ".js": ["typescript-lsp", "eslint-lsp"],
    ".jsx": ["typescript-lsp", "eslint-lsp"],
    ".mjs": ["typescript-lsp", "eslint-lsp"],
    ".cjs": ["typescript-lsp", "eslint-lsp"],
    ".py": ["pyright"],
    ".go": ["gopls"],
    ".rs": ["rust-analyzer"],
    ".sh": ["bash-language-server"],
    ".bash": ["bash-language-server"],
    ".zsh": ["bash-language-server"],
    ".yaml": ["yaml-language-server"],
    ".yml": ["yaml-language-server"],
    ".json": ["json-lsp"],
    ".toml": ["taplo"],
    ".md": ["marksman"],
    ".markdown": ["marksman"],
    ".lua": ["lua-language-server"],
    ".zig": ["zls"],
    ".cs": ["csharp-ls"],
    "Dockerfile": ["docker-langserver"]
  },
  "defaults": {
    "default_task": "coding",
    "minimal_mcp": ["filesystem"]
  }
}
SELECTOR_CONFIG

log "Config written to $CONTEXT_SELECTOR_CONFIG"

# ── _select_mcp_for_task ──────────────────────────────────────────────────────
# Returns the space-separated list of MCP servers for a task category.
# Usage: _select_mcp_for_task [task]   (default: coding)
# Unknown tasks fall back to defaults.default_task.
_select_mcp_for_task() {
  local task="${1:-coding}"
  local cfg="${CONTEXT_SELECTOR_CONFIG:-$CONTEXT_SELECTOR_DIR/config.json}"
  if [ ! -f "$cfg" ]; then
    warn "context-selector config not found: $cfg"
    return 1
  fi
  python3 -c "
import json, sys
d = json.load(open('$cfg'))
cats = d.get('task_categories', {})
task = '$task'
if task not in cats:
    task = d.get('defaults', {}).get('default_task', 'coding')
if task not in cats:
    sys.exit(0)
print(' '.join(cats[task].get('mcp', [])))
"
}

# ── _select_lsp_for_file ──────────────────────────────────────────────────────
# Returns the space-separated list of LSP servers for a file (by extension).
# Usage: _select_lsp_for_file [file]
_select_lsp_for_file() {
  local file="${1:-}"
  local cfg="${CONTEXT_SELECTOR_CONFIG:-$CONTEXT_SELECTOR_DIR/config.json}"
  if [ ! -f "$cfg" ]; then
    warn "context-selector config not found: $cfg"
    return 1
  fi
  local ext=""
  if [ -n "$file" ]; then
    local base
    base="$(basename "$file")"
    case "$base" in
      Dockerfile|Containerfile|*.dockerfile) ext="Dockerfile" ;;
      *)
        ext="${base##*.}"
        if [ "$ext" = "$base" ]; then ext=""; else ext=".$ext"; fi
        ;;
    esac
  fi
  python3 -c "
import json
d = json.load(open('$cfg'))
mapping = d.get('file_lsp_map', {})
ext = '$ext'
print(' '.join(mapping.get(ext, [])))
"
}

# ── _optimize_context ─────────────────────────────────────────────────────────
# Filters context for a task (+ optional file) and returns a JSON summary:
# task, description, mcp[], lsp[], model, small_model (+ fallback when the
# model-router profiles are present). Integrates with 36-model-router.sh.
# Usage: _optimize_context [task] [file]
_optimize_context() {
  local task="${1:-coding}"
  local file="${2:-}"
  local cfg="${CONTEXT_SELECTOR_CONFIG:-$CONTEXT_SELECTOR_DIR/config.json}"
  local router="${ROUTER_PROFILES:-$HOME/.config/opencode/model-router/task-profiles.json}"
  if [ ! -f "$cfg" ]; then
    warn "context-selector config not found: $cfg"
    return 1
  fi
  python3 -c "
import json, os, sys
d = json.load(open('$cfg'))
cats = d.get('task_categories', {})
mapping = d.get('file_lsp_map', {})
task = '$task'
if task not in cats:
    task = d.get('defaults', {}).get('default_task', 'coding')
cat = cats.get(task, {})
lsp = list(cat.get('lsp', []))
file = '$file'
if file:
    base = os.path.basename(file)
    if base in ('Dockerfile', 'Containerfile') or base.endswith('.dockerfile'):
        ext = 'Dockerfile'
    else:
        ext = os.path.splitext(base)[1]
    if ext in mapping:
        lsp = list(mapping[ext])
result = {
    'task': task,
    'description': cat.get('description', ''),
    'mcp': cat.get('mcp', []),
    'lsp': lsp,
    'model': cat.get('model', ''),
    'small_model': cat.get('small_model', '')
}
if os.path.exists('$router'):
    try:
        rp = json.load(open('$router'))
        if task in rp:
            result['model'] = rp[task].get('model', result['model'])
            result['small_model'] = rp[task].get('small_model', result['small_model'])
            result['fallback'] = rp[task].get('fallback', [])
    except Exception:
        pass
print(json.dumps(result))
"
}

# ── select.sh CLI ─────────────────────────────────────────────────────────────
# Standalone helper: select.sh <task> [file] [--json]
cat >"$CONTEXT_SELECTOR_DIR/select.sh" <<'SELECTOR_CLI'
#!/usr/bin/env bash
# select.sh — Select MCP/LSP servers for a task type
# Usage: select.sh <task-type> [file] [--json]
# Task types: coding, reasoning, fast, agentic, research, testing
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
CFG="$DIR/config.json"
TASK="${1:-coding}"
FILE=""
JSON=0

for a in "${@:2}"; do
  case "$a" in
    --json) JSON=1 ;;
    -h|--help)
      echo "Usage: select.sh <task-type> [file] [--json]"
      echo "Task types: coding, reasoning, fast, agentic, research, testing"
      exit 0
      ;;
    *) [ -z "$FILE" ] && FILE="$a" ;;
  esac
done

[ -f "$CFG" ] || { echo "Error: config.json not found at $CFG" >&2; exit 1; }

if [ "$JSON" = "1" ]; then
  python3 -c "
import json, os, sys
d = json.load(open('$CFG'))
cats = d.get('task_categories', {})
mapping = d.get('file_lsp_map', {})
task = '$TASK'
if task not in cats:
    task = d.get('defaults', {}).get('default_task', 'coding')
if task not in cats:
    print(json.dumps({'error': 'unknown task', 'task': task, 'available': sorted(cats.keys())}))
    sys.exit(1)
cat = cats[task]
lsp = list(cat.get('lsp', []))
file = '$FILE'
if file:
    base = os.path.basename(file)
    ext = 'Dockerfile' if (base in ('Dockerfile', 'Containerfile') or base.endswith('.dockerfile')) else os.path.splitext(base)[1]
    if ext in mapping:
        lsp = list(mapping[ext])
print(json.dumps({'task': task, 'description': cat.get('description', ''), 'mcp': cat.get('mcp', []), 'lsp': lsp, 'model': cat.get('model', ''), 'small_model': cat.get('small_model', '')}, indent=2))
"
else
  python3 -c "
import json, os, sys
d = json.load(open('$CFG'))
cats = d.get('task_categories', {})
mapping = d.get('file_lsp_map', {})
task = '$TASK'
if task not in cats:
    task = d.get('defaults', {}).get('default_task', 'coding')
if task not in cats:
    print(f'Error: unknown task \"{task}\". Available: {\", \".join(sorted(cats.keys()))}')
    sys.exit(1)
cat = cats[task]
lsp = list(cat.get('lsp', []))
file = '$FILE'
if file:
    base = os.path.basename(file)
    ext = 'Dockerfile' if (base in ('Dockerfile', 'Containerfile') or base.endswith('.dockerfile')) else os.path.splitext(base)[1]
    if ext in mapping:
        lsp = list(mapping[ext])
print(f'Task: {task}')
print(f'Description: {cat.get(\"description\", \"\")}')
print(f'MCP: {\" \".join(cat.get(\"mcp\", []))}')
print(f'LSP: {\" \".join(lsp)}')
print(f'Model: {cat.get(\"model\", \"\")}  (small: {cat.get(\"small_model\", \"\")})')
"
fi
SELECTOR_CLI

chmod +x "$CONTEXT_SELECTOR_DIR/select.sh"
log "Selection CLI: $CONTEXT_SELECTOR_DIR/select.sh"

# ── Integrate with opencode.json (mirrors 36-model-router.sh) ────────────────
OC_CONFIG="$HOME/.config/opencode/opencode.json"
if [ -f "$OC_CONFIG" ]; then
  python3 -c "
import json
with open('$OC_CONFIG') as f:
    cfg = json.load(f)
if 'experimental' not in cfg:
    cfg['experimental'] = {}
cfg['experimental']['context_selector_dir'] = '$CONTEXT_SELECTOR_DIR'
with open('$OC_CONFIG', 'w') as f:
    json.dump(cfg, f, indent=2)
print('opencode.json: context_selector_dir added')
" 2>/dev/null && log "opencode.json updated with context_selector_dir" || warn "Failed to update opencode.json"
fi

_step_done step_context_selector
info "Context selector configured. Use: $CONTEXT_SELECTOR_DIR/select.sh <task>"
info "Task types: coding, reasoning, fast, agentic, research, testing"
info "Example: $CONTEXT_SELECTOR_DIR/select.sh coding foo.ts"
