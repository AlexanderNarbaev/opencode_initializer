#!/usr/bin/env bash
# modes/ci.sh — Lightweight CI/CD headless mode
# Installs: OpenCode CLI + Bun + 3 essential MCPs only
# Use: bash setup.sh --ci
# Non-interactive, zero GUI dependencies
set -euo pipefail

if [ "$MODE" != "ci" ]; then return 0; fi

section "CI/CD Headless Mode — Minimal AI Agent Setup"
if [ "${DRY_RUN:-false}" = "true" ]; then
  log "dry-run mode active — preview only, no changes will be made"
fi
log "CI mode: OpenCode CLI + Bun + essential MCPs only"
log "Skipping: ZSH, Docker, Chrome, GUI tools, LLM runtimes, RAG"

export TOTAL_STEPS=5

# Only install what CI/CD needs
export INTERACTIVE_DO_SYSTEM=false
export INTERACTIVE_DO_OPENCODE=true
export INTERACTIVE_DO_MCP=true
export INTERACTIVE_DO_CHROMADB=false
export INTERACTIVE_DO_LLM=false
export INTERACTIVE_DO_RAG=false
export INTERACTIVE_DO_ZSH=false

# ── Step 1: System essentials ────────────────────────────────────────────
_run_step step_system "System essentials" "$SCRIPT_DIR/src/lib/01-system.sh" || true

# ── Step 2: Node.js (OpenCode depends on Node) ───────────────────────────
export INTERACTIVE_DO_NODE=true
_run_step step_node "Node.js" "$SCRIPT_DIR/src/lib/06-node.sh" || true

# ── Step 3: OpenCode CLI + Bun ───────────────────────────────────────────
_run_step step_opencode "OpenCode CLI" "$SCRIPT_DIR/src/lib/11-opencode.sh" || true

# ── Step 4: Essential MCPs only (filesystem, context7) ───────────────────
_info_ci() { info "[CI] $1"; }

CI_MCPS=(
  "@modelcontextprotocol/server-filesystem"
  "@upstash/context7-mcp"
)

if [ "${DRY_RUN:-false}" = "true" ]; then
  for pkg in "${CI_MCPS[@]}"; do
    _info_ci "[DRY] would add MCP package: $pkg"
  done
elif command -v bun &>/dev/null; then
  for pkg in "${CI_MCPS[@]}"; do
    _info_ci "Installing $pkg..."
    bun add -g "$pkg" 2>/dev/null && log "MCP: $pkg" || warn "MCP: $pkg failed (non-fatal)"
  done
fi

# ── Step 5: Minimal opencode.json (CI-optimized) ────────────────────────
if [ "${DRY_RUN:-false}" = "true" ]; then
  _info_ci "[DRY] would generate minimal opencode.json for CI/CD (skipped)"
  log "CI/CD headless dry-run complete — no changes made"
  exit 0
fi
# Never clobber an existing full config with the minimal CI one (data-loss guard).
_ci_cfg="${HOME}/.config/opencode/opencode.json"
if [ -f "$_ci_cfg" ] && grep -qE '"(permission|lsp|agent)"[[:space:]]*:' "$_ci_cfg"; then
  _info_ci "Existing full opencode.json detected — keeping it (CI minimal config not written)"
  log "CI/CD headless setup complete"
  exit 0
fi
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
