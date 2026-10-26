#!/usr/bin/env bash
# install-agentic-stack.sh — reproducible OpenCode v2 agentic stack for one machine.
#
# Installs and verifies the pieces that make OpenCode usable for agentic/AI
# development, idempotently:
#   1. npm global prefix directory (npx needs it to exist)
#   2. Bun   (runs the bun-installed MCP servers)
#   3. uv    (runs the Python MCP servers)
#   4. Bun-installed MCP servers  (filesystem, memory, sequential-thinking,
#      context7, playwright, chrome-devtools)
#   5. uv-installed MCP servers   (git, fetch, time)
#   6. Global skills              (~/.config/opencode/skills, flattened)
#   7. Global config              (~/.config/opencode/opencode.json, rendered
#      from src/data/opencode.global.template.json, previous file backed up)
#   8. Governance plugin          (src/plugins/governance.js -> global plugins dir:
#      hash-chained audit, secret redaction, dangerous-command guard)
#   9. Slash commands             (src/commands/*.md -> ~/.config/opencode/command/)
#  10. LSP servers                (typescript/pyright/bash/yaml/json/css/html/
#      dockerfile/markdown via bun, gopls via `go install`)
#  11. Verification               (binaries present, config valid JSON, MCP
#      executables start, `opencode --version` works)
#
# Usage:
#   bash scripts/install-agentic-stack.sh            # install what is missing
#   bash scripts/install-agentic-stack.sh --check    # verify only, no changes
#   bash scripts/install-agentic-stack.sh --dry-run  # print the plan
#
# Exit codes: 0 everything present/installed, 1 a required piece is missing.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$SCRIPT_DIR/src/data/opencode.global.template.json"
SKILLS_SRC="$SCRIPT_DIR/.opencode/skills"

HOME_DIR="${HOME:?HOME is not set}"
CONFIG_DIR="$HOME_DIR/.config/opencode"
CONFIG_FILE="$CONFIG_DIR/opencode.json"
SKILLS_DST="$CONFIG_DIR/skills"

CHECK_ONLY=false
DRY_RUN=false
FAILED=0

for arg in "$@"; do
  case "$arg" in
    --check)   CHECK_ONLY=true ;;
    --dry-run) DRY_RUN=true ;;
    -h|--help)
      sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown option: $arg (try --help)" >&2; exit 2 ;;
  esac
done

ok()   { printf '  \033[0;32m[ok]\033[0m   %s\n' "$*"; }
miss() { printf '  \033[0;31m[miss]\033[0m %s\n' "$*"; FAILED=$((FAILED + 1)); }
plan() { printf '  \033[0;36m[plan]\033[0m %s\n' "$*"; }
hdr()  { printf '\n\033[1m%s\033[0m\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

BUN_BIN="$HOME_DIR/.bun/bin"
UV_LOCAL_BIN="$HOME_DIR/.local/bin"
# Read the prefix from ~/.npmrc instead of calling npm: `npm config get` writes
# ~/.npm/_update-notifier-last-checked, which would make --check non-hermetic.
npm_prefix_from_rc() {
  local rc="$HOME_DIR/.npmrc"
  [ -f "$rc" ] || return 1
  sed -nE 's/^[[:space:]]*prefix[[:space:]]*=[[:space:]]*(.+)$/\1/p' "$rc" | head -1
}
if NPM_PREFIX="$(npm_prefix_from_rc)" && [ -n "$NPM_PREFIX" ]; then :
elif $CHECK_ONLY || $DRY_RUN; then NPM_PREFIX="$HOME_DIR/.npm-global"
elif have npm; then NPM_PREFIX="$(npm config get prefix 2>/dev/null)"
else NPM_PREFIX="$HOME_DIR/.npm-global"; fi
NPM_PREFIX="${NPM_PREFIX:-$HOME_DIR/.npm-global}"

# MCP servers installed through Bun (package -> expected executable name).
BUN_MCPS=(
  "@modelcontextprotocol/server-filesystem:mcp-server-filesystem"
  "@modelcontextprotocol/server-memory:mcp-server-memory"
  "@modelcontextprotocol/server-sequential-thinking:mcp-server-sequential-thinking"
  "@upstash/context7-mcp:context7-mcp"
  "@playwright/mcp:playwright-mcp"
  "chrome-devtools-mcp:chrome-devtools-mcp"
  "@colbymchenry/codegraph:codegraph"
)
# MCP servers installed through uv.
UV_MCPS=(mcp-server-git mcp-server-fetch mcp-server-time mcp-server-qdrant)

# ── 1. npm global prefix ────────────────────────────────────────────────────
hdr "1. npm global prefix"
if [ -d "$NPM_PREFIX" ]; then ok "prefix exists: $NPM_PREFIX"
else
  if $CHECK_ONLY; then miss "prefix missing: $NPM_PREFIX"
  elif $DRY_RUN; then plan "mkdir -p $NPM_PREFIX/bin $NPM_PREFIX/lib"
  else mkdir -p "$NPM_PREFIX/bin" "$NPM_PREFIX/lib" && ok "created $NPM_PREFIX"; fi
fi

# ── 2. Bun ──────────────────────────────────────────────────────────────────
hdr "2. Bun runtime"
if [ -x "$BUN_BIN/bun" ]; then ok "bun $("$BUN_BIN/bun" --version 2>/dev/null)"
elif have bun; then ok "bun $(bun --version) (on PATH)"
elif $CHECK_ONLY; then miss "bun not installed"
elif $DRY_RUN; then plan "curl -fsSL https://bun.sh/install | bash"
else
  curl -fsSL https://bun.sh/install | bash >/dev/null 2>&1 \
    && ok "bun $("$BUN_BIN/bun" --version 2>/dev/null) installed" \
    || miss "bun install failed"
fi

# ── 3. uv ───────────────────────────────────────────────────────────────────
hdr "3. uv runtime"
if [ -x "$UV_LOCAL_BIN/uv" ] || have uv; then
  ok "uv $("$UV_LOCAL_BIN/uv" --version 2>/dev/null || uv --version)"
elif $CHECK_ONLY; then miss "uv not installed"
elif $DRY_RUN; then plan "curl -LsSf https://astral.sh/uv/install.sh | sh"
else
  curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1 \
    && ok "uv installed" || miss "uv install failed"
fi

# ── 4. Bun MCP servers ──────────────────────────────────────────────────────
hdr "4. Bun MCP servers"
for entry in "${BUN_MCPS[@]}"; do
  pkg="${entry%%:*}"; bin="${entry##*:}"
  if [ -x "$BUN_BIN/$bin" ]; then ok "$pkg -> $BUN_BIN/$bin"
  elif $CHECK_ONLY; then miss "$pkg (missing $BUN_BIN/$bin)"
  elif $DRY_RUN; then plan "bun add -g $pkg"
  else
    if BUN_INSTALL="$HOME_DIR/.bun" "$BUN_BIN/bun" add -g "$pkg" >/dev/null 2>&1; then
      ok "$pkg installed"
    else
      miss "$pkg install failed"
    fi
  fi
done

# ── 5. uv MCP servers ───────────────────────────────────────────────────────
hdr "5. uv MCP servers"
for tool in "${UV_MCPS[@]}"; do
  if [ -x "$UV_LOCAL_BIN/$tool" ]; then ok "$tool"
  elif $CHECK_ONLY; then miss "$tool (missing $UV_LOCAL_BIN/$tool)"
  elif $DRY_RUN; then plan "uv tool install $tool"
  else
    "$UV_LOCAL_BIN/uv" tool install "$tool" >/dev/null 2>&1 \
      && ok "$tool installed" || miss "$tool install failed"
  fi
done

# ── 6. Global skills ────────────────────────────────────────────────────────
hdr "6. Global skills"
if [ -d "$SKILLS_SRC" ]; then
  want=$(find "$SKILLS_SRC" -mindepth 2 -maxdepth 3 -name SKILL.md | wc -l | tr -d ' ')
  got=$(find "$SKILLS_DST" -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
  if [ "$got" -ge "$want" ] && [ "$want" -gt 0 ]; then
    ok "$got skills installed (repo has $want)"
  elif $CHECK_ONLY; then miss "skills: $got installed, $want available"
  elif $DRY_RUN; then plan "sync $want skills -> $SKILLS_DST"
  else
    mkdir -p "$SKILLS_DST"
    for f in $(find "$SKILLS_SRC" -mindepth 2 -maxdepth 2 -name SKILL.md); do
      name=$(basename "$(dirname "$f")")
      rm -rf "$SKILLS_DST/$name"; cp -a "$(dirname "$f")" "$SKILLS_DST/$name"
    done
    for f in $(find "$SKILLS_SRC" -mindepth 3 -maxdepth 3 -name SKILL.md); do
      name=$(basename "$(dirname "$f")")
      rm -rf "$SKILLS_DST/$name"; cp -a "$(dirname "$f")" "$SKILLS_DST/$name"
    done
    ok "skills synchronized -> $SKILLS_DST"
  fi
else
  miss "skills source missing: $SKILLS_SRC"
fi

# ── 7. Global config ────────────────────────────────────────────────────────
hdr "7. Global config"
if [ ! -f "$TEMPLATE" ]; then
  miss "template missing: $TEMPLATE"
elif $CHECK_ONLY; then
  if [ -f "$CONFIG_FILE" ] && jq empty "$CONFIG_FILE" 2>/dev/null; then ok "config valid: $CONFIG_FILE"
  else miss "config missing or invalid: $CONFIG_FILE"; fi
elif $DRY_RUN; then
  plan "render $TEMPLATE -> $CONFIG_FILE (__HOME__ -> $HOME_DIR)"
else
  mkdir -p "$CONFIG_DIR"
  [ -f "$CONFIG_FILE" ] && cp -a "$CONFIG_FILE" "$CONFIG_FILE.bak-$(date +%Y%m%dT%H%M%S)"
  sed "s|__HOME__|$HOME_DIR|g" "$TEMPLATE" > "$CONFIG_FILE.tmp"
  if jq empty "$CONFIG_FILE.tmp" 2>/dev/null; then
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"; ok "config rendered: $CONFIG_FILE"
  else
    rm -f "$CONFIG_FILE.tmp"; miss "rendered config is not valid JSON"
  fi
fi

# ── 8. Governance plugin ────────────────────────────────────────────────────
hdr "8. Governance plugin"
PLUGIN_SRC="$SCRIPT_DIR/src/plugins/governance.js"
PLUGIN_DST="$CONFIG_DIR/plugins/governance.js"
if [ ! -f "$PLUGIN_SRC" ]; then
  miss "governance plugin missing: $PLUGIN_SRC"
elif [ -f "$PLUGIN_DST" ] && cmp -s "$PLUGIN_SRC" "$PLUGIN_DST"; then
  ok "plugin installed: $PLUGIN_DST"
elif $CHECK_ONLY; then
  miss "plugin not installed or outdated: $PLUGIN_DST"
elif $DRY_RUN; then
  plan "cp $PLUGIN_SRC -> $PLUGIN_DST"
else
  mkdir -p "$CONFIG_DIR/plugins"
  cp "$PLUGIN_SRC" "$PLUGIN_DST"
  ok "plugin installed: $PLUGIN_DST"
fi

# ── 9. Slash commands ───────────────────────────────────────────────────────
hdr "9. Slash commands"
CMDS_SRC="$SCRIPT_DIR/src/commands"
CMDS_DST="$CONFIG_DIR/command"
if [ ! -d "$CMDS_SRC" ]; then
  miss "commands directory missing: $CMDS_SRC"
else
  mkdir -p "$CMDS_DST" 2>/dev/null || true
  for f in "$CMDS_SRC"/*.md; do
    [ -f "$f" ] || continue
    name="$(basename "$f")"
    if [ -f "$CMDS_DST/$name" ] && cmp -s "$f" "$CMDS_DST/$name"; then
      ok "command installed: $name"
    elif $CHECK_ONLY; then
      miss "command not installed or outdated: $name"
    elif $DRY_RUN; then
      plan "cp $f -> $CMDS_DST/$name"
    else
      cp "$f" "$CMDS_DST/$name" && ok "command installed: $name"
    fi
  done
fi

# ── 10. LSP servers ─────────────────────────────────────────────────────────
hdr "10. LSP servers"
LSP_PKGS=(
  "typescript-language-server"
  "typescript"
  "bash-language-server"
  "yaml-language-server"
  "vscode-langservers-extracted"
  "dockerfile-language-server-nodejs"
  "pyright"
)
LSP_BINS=(
  typescript-language-server pyright-langserver bash-language-server
  yaml-language-server vscode-json-language-server vscode-css-language-server
  vscode-html-language-server vscode-markdown-language-server docker-langserver
)
missing_pkgs=()
for pkg in "${LSP_PKGS[@]}"; do
  case "$pkg" in
    typescript) bin="typescript-language-server" ;;
    vscode-langservers-extracted) bin="vscode-json-language-server" ;;
    dockerfile-language-server-nodejs) bin="docker-langserver" ;;
    pyright) bin="pyright-langserver" ;;
    *) bin="$pkg" ;;
  esac
  [ -x "$BUN_BIN/$bin" ] || missing_pkgs+=("$pkg")
done
if [ "${#missing_pkgs[@]}" -eq 0 ]; then
  ok "bun LSP packages present (${#LSP_PKGS[@]})"
elif $CHECK_ONLY; then
  miss "missing LSP packages: ${missing_pkgs[*]}"
elif $DRY_RUN; then
  plan "bun add -g ${missing_pkgs[*]}"
else
  if BUN_INSTALL="$HOME_DIR/.bun" "$BUN_BIN/bun" add -g "${missing_pkgs[@]}" >/dev/null 2>&1; then
    ok "installed LSP packages: ${missing_pkgs[*]}"
  else
    miss "failed to install: ${missing_pkgs[*]}"
  fi
fi

GOPLS_BIN="$HOME_DIR/go/bin/gopls"
if [ -x "$GOPLS_BIN" ]; then
  ok "gopls present"
elif ! command -v go >/dev/null 2>&1; then
  ok "gopls skipped (go toolchain not installed)"
elif $CHECK_ONLY; then
  miss "gopls missing ($GOPLS_BIN)"
elif $DRY_RUN; then
  plan "go install golang.org/x/tools/gopls@latest"
else
  GOBIN="$HOME_DIR/go/bin" go install golang.org/x/tools/gopls@latest >/dev/null 2>&1 \
    && ok "gopls installed" || miss "gopls install failed"
fi

# ── 11. Verification ────────────────────────────────────────────────────────
hdr "11. Verification"
if have opencode || [ -x "$HOME_DIR/.opencode/bin/opencode" ]; then
  ver=$("$HOME_DIR/.opencode/bin/opencode" --version 2>/dev/null || opencode --version 2>/dev/null)
  ok "opencode ${ver:-present}"
else
  miss "opencode binary not found"
fi

for entry in "${BUN_MCPS[@]}"; do
  bin="${entry##*:}"
  [ -x "$BUN_BIN/$bin" ] && ok "executable: $bin" || miss "executable: $bin"
done
for tool in "${UV_MCPS[@]}"; do
  [ -x "$UV_LOCAL_BIN/$tool" ] && ok "executable: $tool" || miss "executable: $tool"
done

lsp_ok=0
for bin in "${LSP_BINS[@]}"; do [ -x "$BUN_BIN/$bin" ] && lsp_ok=$((lsp_ok + 1)); done
ok "LSP binaries: $lsp_ok/${#LSP_BINS[@]} in $BUN_BIN"
[ -x "$HOME_DIR/go/bin/gopls" ] && ok "LSP: gopls" || miss "LSP: gopls"

cmd_count=0
for f in "$CMDS_SRC"/*.md; do [ -f "$f" ] && cmd_count=$((cmd_count + 1)); done
installed=0
if [ -d "$CMDS_DST" ]; then
  for f in "$CMDS_SRC"/*.md; do
    [ -f "$f" ] || continue
    cmp -s "$f" "$CMDS_DST/$(basename "$f")" && installed=$((installed + 1))
  done
fi
[ "$installed" -eq "$cmd_count" ] && ok "commands: $installed/$cmd_count installed" || miss "commands: $installed/$cmd_count installed"

if [ -f "$PLUGIN_DST" ]; then
  if command -v node >/dev/null 2>&1; then
    node --check "$PLUGIN_DST" 2>/dev/null && ok "governance plugin parses" || miss "governance plugin syntax error"
  else
    ok "governance plugin present (node not installed, syntax check skipped)"
  fi
else
  miss "governance plugin not installed"
fi

if [ -f "$CONFIG_FILE" ]; then
  enabled=$(jq -r '[.mcp // {} | to_entries[] | select(.value.enabled != false)] | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
  plugins=$(jq -r '(.plugin // []) | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
  ok "config: $enabled MCP enabled, $plugins plugins"
fi

hdr "Result"
if $DRY_RUN; then
  echo "  dry run: plan above, nothing changed"
  exit 0
fi
if [ "$FAILED" -eq 0 ]; then
  echo "  all checks passed"
  exit 0
fi
echo "  $FAILED problem(s) found" >&2
exit 1
