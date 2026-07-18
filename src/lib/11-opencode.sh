#!/usr/bin/env bash
# lib/11-opencode.sh — OpenCode CLI 1.17 + Bun 1.3.14 + auth.json (STEP 8)
# Requires: MODE, OPENCODE_VER, DEEPSEEK_KEY, API_KEY, XAI_KEY, etc.
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_OPENCODE"; then
  section "OpenCode CLI"
  if ! command -v opencode &>/dev/null; then
    info "Installing OpenCode CLI ($OPENCODE_VER)..."
    if timeout 120 npm install -g "opencode-ai@${OPENCODE_VER}" --prefer-offline 2>/dev/null; then
      log "OpenCode $(opencode --version 2>/dev/null || echo 'installed')"
    elif _curl "https://opencode.ai/install" /tmp/opencode-install.sh 2>/dev/null; then
      timeout 60 bash /tmp/opencode-install.sh 2>/dev/null && log "OpenCode installed (curl)" || warn "opencode install script failed"
      rm -f /tmp/opencode-install.sh
    else
      warn "OpenCode install failed — install manually: npm install -g opencode-ai@latest"
    fi
  else
    log "OpenCode $(opencode --version 2>/dev/null) already installed"
  fi
  _step_done step_opencode

  # Write API keys to auth.json for immediate use (before secrets.env is sourced)
  AUTH_FILE="$HOME/.local/share/opencode/auth.json"
  mkdir -p "$(dirname "$AUTH_FILE")"
  python3 -c "
import json, os
auth = {}
if os.path.exists('$AUTH_FILE'):
    try:
        with open('$AUTH_FILE') as f:
            auth = json.load(f)
    except: pass
dk = '${DEEPSEEK_KEY:-}'
ak = '${API_KEY:-}'
xk = '${XAI_KEY:-}'
mk = '${MIMO_KEY:-}'
msk = '${MOONSHOT_KEY:-}'
mmk = '${MINIMAX_KEY:-}'
ghk = '${GITHUB_TOKEN:-}'
glk = '${GITLAB_TOKEN:-}'
gmk = '${GOOGLE_MAPS_KEY:-}'
if dk:
    auth['deepseek'] = {'type': 'api', 'key': dk}
if ak:
    auth['opencode'] = {'type': 'api', 'key': ak}
if xk:
    auth['xai'] = {'type': 'api', 'key': xk}
if mk:
    auth['mimo'] = {'type': 'api', 'key': mk}
if msk:
    auth['moonshot'] = {'type': 'api', 'key': msk}
if mmk:
    auth['minimax'] = {'type': 'api', 'key': mmk}
if ghk:
    auth['github'] = {'type': 'api', 'key': ghk}
if glk:
    auth['gitlab'] = {'type': 'api', 'key': glk}
if gmk:
    auth['google-maps'] = {'type': 'api', 'key': gmk}
if dk or ak or xk or mk or msk or mmk or ghk or glk or gmk:
    with open('$AUTH_FILE', 'w') as f:
        json.dump(auth, f, indent=2)
" 2>/dev/null || true
  [ -f "$AUTH_FILE" ] && chmod 600 "$AUTH_FILE" 2>/dev/null || true

  if ! command -v bun &>/dev/null; then
    if command -v unzip &>/dev/null || sudo apt-get install -y unzip &>/dev/null; then
      BUN_SCRIPT=$(mktemp /tmp/bun-install.XXXXXX.sh)
      if _curl "https://bun.sh/install" "$BUN_SCRIPT" 2>/dev/null; then
        bash "$BUN_SCRIPT" && export PATH="$HOME/.bun/bin:$PATH" && log "Bun installed" || warn "Bun install failed"
        rm -f "$BUN_SCRIPT"
      else
        warn "Bun download failed — install manually: curl -fsSL https://bun.sh/install | bash"
      fi
    else
      warn "Bun install failed (unzip unavailable)"
    fi
  else
    log "Bun already installed"
  fi

  # Install interaction mode wrappers (TUI/JSON/RPC/SDK)
  if [ -d "$SCRIPT_DIR/scripts" ]; then
    for script in oc-tui oc-json oc-sdk oc-rpc; do
      src_tgt=""
      if [ -f "$SCRIPT_DIR/scripts/${script}.sh" ]; then
        src_tgt="$SCRIPT_DIR/scripts/${script}.sh"
      elif [ -f "$SCRIPT_DIR/scripts/${script}.py" ]; then
        src_tgt="$SCRIPT_DIR/scripts/${script}.py"
      fi
      if [ -n "$src_tgt" ]; then
        cp "$src_tgt" "$HOME/.local/bin/${script}" 2>/dev/null || true
        chmod +x "$HOME/.local/bin/${script}" 2>/dev/null || true
      fi
    done
    log "Interaction mode wrappers installed (~/.local/bin/oc-*)"
  fi
fi
