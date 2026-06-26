#!/usr/bin/env bash
# modes/ci.sh — Lightweight CI/CD headless mode
# Installs: OpenCode CLI + Bun + 3 essential MCPs only
# Use: bash setup.sh --ci
# Non-interactive, zero GUI dependencies
set -euo pipefail

if [ "$MODE" != "ci" ]; then return 0; fi

section "CI/CD Headless Mode — Minimal AI Agent Setup"
log "CI mode: OpenCode CLI + Bun + essential MCPs only"
log "Skipping: ZSH, Docker, Chrome, GUI tools, LLM runtimes, RAG"

TOTAL_STEPS=5

# Only install what CI/CD needs
INTERACTIVE_DO_SYSTEM=false
INTERACTIVE_DO_OPENCODE=true
INTERACTIVE_DO_MCP=true
INTERACTIVE_DO_CHROMADB=false
INTERACTIVE_DO_LLM=false
INTERACTIVE_DO_RAG=false
INTERACTIVE_DO_ZSH=false

# ── Step 1: System essentials ────────────────────────────────────────────
_run_step step_system "System essentials" "$SCRIPT_DIR/src/lib/01-system.sh" || true

# ── Step 2: Node.js (OpenCode depends on Node) ───────────────────────────
INTERACTIVE_DO_NODE=true
_run_step step_node "Node.js" "$SCRIPT_DIR/src/lib/06-node.sh" || true

# ── Step 3: OpenCode CLI + Bun ───────────────────────────────────────────
_run_step step_opencode "OpenCode CLI" "$SCRIPT_DIR/src/lib/11-opencode.sh" || true

# ── Step 4: Essential MCPs only (filesystem, context7) ───────────────────
_info_ci() { info "[CI] $1"; }

CI_MCPS=(
  "@modelcontextprotocol/server-filesystem"
  "@upstash/context7-mcp"
)

if command -v bun &>/dev/null; then
  for pkg in "${CI_MCPS[@]}"; do
    _info_ci "Installing $pkg..."
    bun add -g "$pkg" 2>/dev/null && log "MCP: $pkg" || warn "MCP: $pkg failed (non-fatal)"
  done
fi

# ── Step 5: Minimal opencode.json (CI-optimized) ────────────────────────
_info_ci "Generating minimal opencode.json for CI/CD..."

python3 -c "
import json, os
config = {
    'model': os.environ.get('OPENCODE_MODEL', 'deepseek/deepseek-v4-pro'),
    'small_model': 'deepseek/deepseek-v4-flash',
    'provider': {'deepseek': {}},
    'mcp': {},
    'plugin': [],
}
bun_bin = os.path.expanduser('~/.bun/bin')
if os.path.exists(f'{bun_bin}/mcp-server-filesystem'):
    config['mcp']['filesystem'] = {
        'type': 'local',
        'command': [f'{bun_bin}/mcp-server-filesystem'],
        'enabled': True
    }
if os.path.exists(f'{bun_bin}/c7-mcp-server'):
    config['mcp']['context7'] = {
        'type': 'local',
        'command': [f'{bun_bin}/c7-mcp-server'],
        'enabled': True
    }
out_dir = os.path.expanduser('~/.config/opencode')
os.makedirs(out_dir, exist_ok=True)
with open(f'{out_dir}/opencode.json', 'w') as f:
    json.dump(config, f, indent=2)
print('CI opencode.json generated')
" 2>/dev/null || warn "CI opencode.json generation failed"

log "CI/CD headless setup complete"
log "Run: opencode --non-interactive 'check repo for issues'"
echo ""
echo -e "  ${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "  ${GREEN}║   CI/CD Headless Mode — Ready       ║${NC}"
echo -e "  ${GREEN}║   opencode --non-interactive ...     ║${NC}"
echo -e "  ${GREEN}╚══════════════════════════════════════╝${NC}"
exit 0
