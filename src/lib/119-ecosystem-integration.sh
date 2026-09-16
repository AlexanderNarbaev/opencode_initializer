#!/usr/bin/env bash
# src/lib/119-ecosystem-integration.sh — Ecosystem Integration Module (v15.2.0)
# Integrates agent frameworks, MCP servers, and development tools
set -euo pipefail
# See docs/ECOSYSTEM-INTEGRATION-GUIDE.md for integration details

# ═══════════════════════════════════════════════════════════════════════════════
# Agent Framework Integration
# ═══════════════════════════════════════════════════════════════════════════════

# Install CrewAI for multi-agent orchestration
_install_crewai() {
    section "Installing CrewAI"
    if command -v uv &>/dev/null; then
        uv tool install crewai 2>/dev/null && log "CrewAI installed" || warn "CrewAI install failed"
    elif command -v pipx &>/dev/null; then
        pipx install crewai 2>/dev/null && log "CrewAI installed" || warn "CrewAI install failed"
    else
        warn "Neither uv nor pipx found, skipping CrewAI"
    fi
}

# Install LangGraph for stateful agents
_install_langgraph() {
    section "Installing LangGraph"
    if command -v uv &>/dev/null; then
        uv pip install langgraph 2>/dev/null && log "LangGraph installed" || warn "LangGraph install failed"
    elif command -v pip3 &>/dev/null; then
        pip3 install langgraph 2>/dev/null && log "LangGraph installed" || warn "LangGraph install failed"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# MCP Server Integration
# ═══════════════════════════════════════════════════════════════════════════════

# Install additional MCP servers
_install_mcp_servers() {
    section "Installing Additional MCP Servers"

    # Memory server (knowledge graph)
    npm install -g @modelcontextprotocol/server-memory@latest 2>/dev/null && log "MCP: memory" || warn "MCP memory failed"

    # Filesystem server
    npm install -g @modelcontextprotocol/server-filesystem@latest 2>/dev/null && log "MCP: filesystem" || warn "MCP filesystem failed"

    # Sequential thinking server
    npm install -g @modelcontextprotocol/server-sequentialthinking@latest 2>/dev/null && log "MCP: sequentialthinking" || warn "MCP sequentialthinking failed"

    # GitHub server
    npm install -g @modelcontextprotocol/server-github@latest 2>/dev/null && log "MCP: github" || warn "MCP github failed"

    # GitLab server
    npm install -g @modelcontextprotocol/server-gitlab@latest 2>/dev/null && log "MCP: gitlab" || warn "MCP gitlab failed"

    # PostgreSQL server
    npm install -g @modelcontextprotocol/server-postgres@latest 2>/dev/null && log "MCP: postgres" || warn "MCP postgres failed"

    # Redis server
    npm install -g @modelcontextprotocol/server-redis@latest 2>/dev/null && log "MCP: redis" || warn "MCP redis failed"

    # Slack server
    npm install -g @modelcontextprotocol/server-slack@latest 2>/dev/null && log "MCP: slack" || warn "MCP slack failed"

    # Brave Search server
    npm install -g @brave/brave-search-mcp-server@latest 2>/dev/null && log "MCP: brave-search" || warn "MCP brave-search failed"

    # Puppeteer server
    npm install -g @modelcontextprotocol/server-puppeteer@latest 2>/dev/null && log "MCP: puppeteer" || warn "MCP puppeteer failed"

    log "Additional MCP servers installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# LSP Server Integration
# ═══════════════════════════════════════════════════════════════════════════════

# Install additional LSP servers
_install_lsp_servers() {
    section "Installing Additional LSP Servers"

    # TypeScript/JavaScript
    npm install -g typescript-language-server@latest 2>/dev/null && log "LSP: typescript" || warn "LSP typescript failed"

    # Python
    npm install -g pyright@latest 2>/dev/null && log "LSP: pyright" || warn "LSP pyright failed"

    # YAML
    npm install -g yaml-language-server@latest 2>/dev/null && log "LSP: yaml" || warn "LSP yaml failed"

    # JSON
    npm install -g vscode-json-languageserver@latest 2>/dev/null && log "LSP: json" || warn "LSP json failed"

    # Bash
    npm install -g bash-language-server@latest 2>/dev/null && log "LSP: bash" || warn "LSP bash failed"

    # Docker
    npm install -g dockerfile-language-server-nodejs@latest 2>/dev/null && log "LSP: docker" || warn "LSP docker failed"

    # HTML/CSS
    npm install -g vscode-langservers-extracted@latest 2>/dev/null && log "LSP: html/css" || warn "LSP html/css failed"

    # Go (if Go is installed)
    if command -v go &>/dev/null; then
        go install golang.org/x/tools/gopls@latest 2>/dev/null && log "LSP: gopls" || warn "LSP gopls failed"
    fi

    # Rust (if rustup is installed)
    if command -v rustup &>/dev/null; then
        rustup component add rust-analyzer 2>/dev/null && log "LSP: rust-analyzer" || warn "LSP rust-analyzer failed"
    fi

    # Zig (if Zig is installed)
    if command -v zig &>/dev/null; then
        npm install -g zls@latest 2>/dev/null && log "LSP: zls" || warn "LSP zls failed"
    fi

    log "Additional LSP servers installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Development Tools Integration
# ═══════════════════════════════════════════════════════════════════════════════

# Install development tools
_install_dev_tools() {
    section "Installing Development Tools"

    # Taskfile (task runner)
    npm install -g @task/cli@latest 2>/dev/null && log "Taskfile installed" || warn "Taskfile failed"

    # Just (command runner)
    npm install -g just@latest 2>/dev/null && log "Just installed" || warn "Just failed"

    # MkDocs (documentation)
    if command -v uv &>/dev/null; then
        uv pip install mkdocs-material 2>/dev/null && log "MkDocs installed" || warn "MkDocs failed"
    fi

    # Hugo (static site generator)
    if command -v go &>/dev/null; then
        go install github.com/gohugoio/hugo@latest 2>/dev/null && log "Hugo installed" || warn "Hugo failed"
    fi

    log "Development tools installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main Integration Function
# ═══════════════════════════════════════════════════════════════════════════════

# Install all ecosystem components
_ecosystem_install() {
    section "Ecosystem Integration"

    _install_crewai
    _install_langgraph
    _install_mcp_servers
    _install_lsp_servers
    _install_dev_tools

    section "Ecosystem Integration Complete"
    log "All ecosystem components installed"
}

# Show ecosystem status
_ecosystem_status() {
    section "Ecosystem Status"

    echo "Agent Frameworks:"
    command -v crewai &>/dev/null && echo "  ✓ CrewAI" || echo "  ✗ CrewAI"
    python3 -c "import langgraph" 2>/dev/null && echo "  ✓ LangGraph" || echo "  ✗ LangGraph"

    echo ""
    echo "MCP Servers:"
    command -v @modelcontextprotocol/server-memory &>/dev/null && echo "  ✓ Memory" || echo "  ✗ Memory"
    command -v @modelcontextprotocol/server-filesystem &>/dev/null && echo "  ✓ Filesystem" || echo "  ✗ Filesystem"
    command -v @modelcontextprotocol/server-sequentialthinking &>/dev/null && echo "  ✓ Sequential Thinking" || echo "  ✗ Sequential Thinking"

    echo ""
    echo "LSP Servers:"
    command -v typescript-language-server &>/dev/null && echo "  ✓ TypeScript" || echo "  ✗ TypeScript"
    command -v pyright &>/dev/null && echo "  ✓ Pyright" || echo "  ✗ Pyright"
    command -v gopls &>/dev/null && echo "  ✓ Go" || echo "  ✗ Go"
    command -v rust-analyzer &>/dev/null && echo "  ✓ Rust" || echo "  ✗ Rust"
}

# Export functions
export -f _ecosystem_install _ecosystem_status 2>/dev/null || true

