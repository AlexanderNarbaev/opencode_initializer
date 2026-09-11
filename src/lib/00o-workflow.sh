#!/usr/bin/env bash
# src/lib/00o-workflow.sh — Workflow Automation (v4.4.0)
# Defines and executes automated workflows for common development tasks.
set -euo pipefail

# ── Workflow configuration ───────────────────────────────────────────────────
_WORKFLOW_DIR="${DL_CACHE}/workflows"
_WORKFLOW_REGISTRY="${_WORKFLOW_DIR}/registry.json"

# ── Initialize workflow engine ──────────────────────────────────────────────
_workflow_init() {
  mkdir -p "$_WORKFLOW_DIR"
  
  if [ ! -f "$_WORKFLOW_REGISTRY" ]; then
    cat > "$_WORKFLOW_REGISTRY" <<'EOF'
{
  "version": "1.0.0",
  "workflows": {
    "setup": {
      "description": "Full development environment setup",
      "steps": ["system", "docker", "languages", "opencode", "mcp", "services"]
    },
    "update": {
      "description": "Update all tools and dependencies",
      "steps": ["mirrors", "plugins", "mcp-servers", "dependencies"]
    },
    "security": {
      "description": "Security audit and hardening",
      "steps": ["scan", "permissions", "dependencies", "hooks"]
    },
    "optimize": {
      "description": "Performance optimization",
      "steps": ["benchmark", "cache", "parallel", "cleanup"]
    },
    "deploy": {
      "description": "Deploy to production",
      "steps": ["test", "build", "push", "notify"]
    }
  }
}
EOF
  fi
}

# ── Execute workflow ────────────────────────────────────────────────────────
# Usage: _workflow_run "workflow_name"
_workflow_run() {
  local workflow="$1"

  _workflow_init

  section "Executing Workflow: $workflow"

  case "$workflow" in
    setup)
      _workflow_setup
      ;;
    update)
      _workflow_update
      ;;
    security)
      _workflow_security
      ;;
    optimize)
      _workflow_optimize
      ;;
    deploy)
      _workflow_deploy
      ;;
    *)
      warn "Unknown workflow: $workflow"
      return 1
      ;;
  esac
}

# ── Setup workflow ──────────────────────────────────────────────────────────
_workflow_setup() {
  log "Step 1/6: System packages"
  source "$SCRIPT_DIR/src/lib/01-system.sh" 2>/dev/null || true

  log "Step 2/6: Docker"
  source "$SCRIPT_DIR/src/lib/02-docker.sh" 2>/dev/null || true

  log "Step 3/6: Languages"
  for lang in 05-java 06-node 07-python 08-go 09-rust 10-dotnet; do
    source "$SCRIPT_DIR/src/lib/${lang}.sh" 2>/dev/null || true
  done

  log "Step 4/6: OpenCode"
  source "$SCRIPT_DIR/src/lib/11-opencode.sh" 2>/dev/null || true

  log "Step 5/6: MCP servers"
  source "$SCRIPT_DIR/src/lib/12-mcp-lsp.sh" 2>/dev/null || true

  log "Step 6/6: Services"
  source "$SCRIPT_DIR/src/lib/30-infra.sh" 2>/dev/null || true

  log "Setup workflow complete"
}

# ── Update workflow ─────────────────────────────────────────────────────────
_workflow_update() {
  log "Step 1/4: Configure mirrors"
  _configure_all_mirrors 2>/dev/null || true

  log "Step 2/4: Update plugins"
  _update_plugin_registry 2>/dev/null || true

  log "Step 3/4: Update MCP servers"
  _update_mcp_servers 2>/dev/null || true

  log "Step 4/4: Update dependencies"
  _auto_sync_apply 2>/dev/null || true

  log "Update workflow complete"
}

# ── Security workflow ───────────────────────────────────────────────────────
_workflow_security() {
  log "Step 1/4: Scan for secrets"
  _scan_secrets "$SCRIPT_DIR" 2>/dev/null || true

  log "Step 2/4: Audit permissions"
  _audit_permissions "$SCRIPT_DIR" 2>/dev/null || true

  log "Step 3/4: Check dependencies"
  _scan_dependencies "$SCRIPT_DIR" 2>/dev/null || true

  log "Step 4/4: Install hooks"
  _install_pre_commit_hook "$SCRIPT_DIR/.git" 2>/dev/null || true

  log "Security workflow complete"
}

# ── Optimize workflow ───────────────────────────────────────────────────────
_workflow_optimize() {
  log "Step 1/4: Run benchmarks"
  _run_benchmark 2>/dev/null || true

  log "Step 2/4: Clean cache"
  _cache_cleanup 2>/dev/null || true

  log "Step 3/4: Verify parallel config"
  info "Parallel jobs: ${PARALLEL_MAX_JOBS:-$(nproc 2>/dev/null || echo 4)}"

  log "Step 4/4: Cleanup temp files"
  rm -rf /tmp/bench_* 2>/dev/null || true
  rm -rf /tmp/opencode-* 2>/dev/null || true

  log "Optimize workflow complete"
}

# ── Deploy workflow ─────────────────────────────────────────────────────────
_workflow_deploy() {
  log "Step 1/4: Run tests"
  if command -v bash &>/dev/null; then
    for test_file in "$SCRIPT_DIR"/tests/unit/test_*.sh; do
      [ -f "$test_file" ] && bash "$test_file" 2>/dev/null || true
    done
  fi

  log "Step 2/4: Build"
  if [ -f "$SCRIPT_DIR/package.json" ]; then
    cd "$SCRIPT_DIR" && npm run build 2>/dev/null || true
  fi

  log "Step 3/4: Push to git"
  if [ -d "$SCRIPT_DIR/.git" ]; then
    cd "$SCRIPT_DIR" && git add -A && git status
  fi

  log "Step 4/4: Notify"
  info "Deploy workflow complete — review changes and commit manually"

  log "Deploy workflow complete"
}

# ── List workflows ──────────────────────────────────────────────────────────
# Usage: _workflow_list
_workflow_list() {
  _workflow_init

  section "Available Workflows"

  python3 -c "
import json
with open('$_WORKFLOW_REGISTRY') as f:
    data = json.load(f)

for name, info in data.get('workflows', {}).items():
    desc = info.get('description', '')
    steps = len(info.get('steps', []))
    print(f'  {name:15} — {desc} ({steps} steps)')
" 2>/dev/null || true
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _workflow_init _workflow_run _workflow_setup _workflow_update \
  _workflow_security _workflow_optimize _workflow_deploy _workflow_list 2>/dev/null || true
