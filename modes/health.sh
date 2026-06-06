#!/usr/bin/env bash
# modes/health.sh — health check mode (36 checks, 5 sections)
# Sources: lib/helpers.sh, lib/00-core.sh must be sourced before
set -euo pipefail

echo -e "${GREEN}=== OpenCode Environment Health Check ===${NC}"
PASS=0; FAIL=0
_check() { if eval "$2" &>/dev/null; then echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS+1)); else echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL+1)); fi; }

section "Core CLI"
_check "Docker"         "docker --version"
_check "Java"           "java -version 2>&1 | head -1"
_check "Go"             "go version"
_check "Rust"           "rustc --version"
_check ".NET"           "dotnet --version"
_check "Kotlin"         "kotlin -version 2>/dev/null || echo 'not installed'"
_check "Zig"            "zig version 2>/dev/null || echo 'not installed'"
_check "Node.js"        "node --version"
_check "Python 3.14"    "python3.14 --version"
_check "uv"             "uv --version"
_check "bun"            "bun --version"
_check "OpenCode"       "opencode --version"
_check "Gradle"         "gradle --version 2>&1 | head -2"
_check "Maven"          "mvn --version 2>&1 | head -1"
_check "jbang"          "jbang --version"
_check "Git"            "git --version"
_check "zsh"            "zsh --version"
_check "Chrome"         "google-chrome-stable --version 2>/dev/null | head -1"
_check "ripgrep"        "rg --version"
_check "fzf"            "fzf --version"
_check "eza"            "eza --version"
_check "bat"            "bat --version"
_check "fd"             "fdfind --version"

section "MCP Servers"
_check "context7"       "which c7-mcp-server"
_check "filesystem"     "npm list -g @modelcontextprotocol/server-filesystem &>/dev/null"
_check "agentic-tools"  "npm list -g @pimzino/agentic-tools-mcp &>/dev/null"
_check "codegraph"      "which codegraph"
_check "playwright"     "npm list -g @playwright/mcp &>/dev/null"
_check "agent-browser"  "npm list -g agent-browser-mcp-server &>/dev/null || which agent-browser-mcp-server"
_check "loopsense"      "npm list -g @loopsense/mcp &>/dev/null"
_check "github"         "npm list -g @modelcontextprotocol/server-github &>/dev/null"
_check "postgres"       "npm list -g @modelcontextprotocol/server-postgres &>/dev/null"
_check "seq-thinking"   "npm list -g @modelcontextprotocol/server-sequential-thinking &>/dev/null"
_check "memorylayer"    "npm list -g @scitrera/memorylayer-mcp-server &>/dev/null"
_check "plugin-codegraph" "npm list -g opencode-codegraph &>/dev/null"
_check "plugin-orchestra" "npm list -g open-orchestra &>/dev/null"

section "LSP Servers"
_check "gopls"          "which gopls"
_check "rust-analyzer"  "which rust-analyzer"
_check "tsserver"       "which typescript-language-server"
_check "pyright"        "which pyright-langserver"

section "Services"
_check "Muninn skills"      "[ -f ~/.config/opencode/skills/memory-read/SKILL.md ]"
_check "ChromaDB server"    "curl -sf http://127.0.0.1:8000/api/v2/heartbeat &>/dev/null"
_check "ONNX model cached"  "[ -f ~/.cache/chroma/onnx_models/all-MiniLM-L6-v2/onnx/model.onnx ]"

section "Config"
_check "opencode.json"      "[ -f ~/.config/opencode/opencode.json ]"
_check "MCPs registered"    "python3 -c \"import json; c=json.load(open('$HOME/.config/opencode/opencode.json')); m=len(c.get('mcp',{})); exit(0 if m>2 else 1)\" 2>/dev/null"
_check "AGENTS.md"          "[ -f \"${PROJECT_DIR:-$HOME/projects}/AGENTS.md\" ]"
_check "GLOBAL_WAL.md"      "[ -f \"${PROJECT_DIR:-$HOME/projects}/wal/GLOBAL_WAL.md\" ]"
_check "No stale scout"     "[ ! -f \"${PROJECT_DIR:-$HOME/projects}/.opencode/agents/scout.md\" ] && [ ! -f \"$HOME/.config/opencode/agents/scout.md\" ]"

echo; log "Health: $PASS passed, $FAIL failed"
exit 0
