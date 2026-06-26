# MCP, LSP & Plugin Reference

Complete reference of all AI infrastructure configured by OpenCode Initializer.

## MCP Servers (21 local + 4 remote)

MCP (Model Context Protocol) servers extend OpenCode with external tools and data sources.

### Local Servers

| Server | Package | Category | Description |
|--------|---------|----------|-------------|
| **filesystem** | `@modelcontextprotocol/server-filesystem` | Core | File system operations — read, write, list, search |
| **git** | `mcp-server-git` | Core | Git operations — log, diff, branch, commit |
| **github** | `@modelcontextprotocol/server-github` | Platform | GitHub API — repos, issues, PRs, search |
| **gitlab** | `mcp-server-gitlab` | Platform | GitLab API mirror of GitHub server |
| **memory** | `@modelcontextprotocol/server-memory` | AI | Knowledge graph with persistent memory |
| **sequential-thinking** | `@modelcontextprotocol/server-sequential-thinking` | AI | Chain-of-thought reasoning breakdown |
| **memorylayer** | `@scitrera/memorylayer-mcp-server` | AI | Advanced memory with session persistence |
| **fetch** | `mcp-server-fetch` | Network | HTTP requests, web content retrieval |
| **time** | `mcp-server-time` | Utility | Timezone conversion, current time |
| **sqlite** | `mcp-server-sqlite` | Data | SQLite database query and management |
| **postgres** | `@modelcontextprotocol/server-postgres` | Data | PostgreSQL database access (requires token) |
| **redis** | `@modelcontextprotocol/server-redis` | Data | Redis key-value store operations |
| **playwright** | `@playwright/mcp` | Browser | Full browser automation (Chromium) |
| **agent-browser** | `agent-browser-mcp-server` | Browser | Lightweight browser control for web tasks |
| **chrome-devtools** | `chrome-devtools-mcp` | Browser | Chrome DevTools Protocol access |
| **brave-search** | `brave-search-mcp` | Search | Web search via Brave Search API |
| **context7** | `context7-mcp` | Search | Code documentation search |
| **context7-official** | `@upstash/context7-mcp` | Search | Official Context7 library documentation |
| **agentic-tools** | `@pimzino/agentic-tools-mcp` | Agent | Task management, project planning |
| **codegraph** | `codegraph-mcp` | Analysis | Code dependency and call graph analysis |
| **loopsense** | `@loopsense/mcp` | Analysis | Code quality and best practices |

### Remote Servers

| Server | Package | Category | Description |
|--------|---------|----------|-------------|
| **sentry** | `@sentry/mcp` | Monitoring | Error tracking and performance monitoring |
| **grep** | `grep-mcp` | Utility | Content search across codebase |
| **excalidraw** | `excalidraw-mcp` | Design | Architecture diagrams and technical drawings |
| **google-maps** | `mcp-server-google-maps` | Location | Google Maps geocoding and routing |

### Enabling/Disabling MCP Servers

MCP servers are defined in `opencode.json` under `mcpServers`. Each server can be:

```json
{
  "mcpServers": {
    "filesystem": {
      "type": "local",
      "command": ["/home/user/.bun/bin/mcp-server-filesystem", "/path/to/project"],
      "enabled": true
    }
  }
}
```

Platform-specific servers (GitHub, GitLab, Postgres, Google Maps) are **conditionally enabled** — only if the corresponding API key is provided via `--github-token`, `--gitlab-token`, etc.

### Cold Start Performance

Most MCP servers use **absolute Bun binary paths** (`~/.bun/bin/mcp-server-*`) instead of `npx -y`. This means:

- 0.5s cold start vs 5-15s with npx
- No network required after install
- Survives npm cache clears

## LSP Servers (13)

LSP (Language Server Protocol) servers provide intelligent code analysis for OpenCode.

| Server | Language | Features |
|--------|----------|----------|
| **gopls** | Go | Autocomplete, jump-to-def, refactor, diagnostics |
| **rust-analyzer** | Rust | Full IDE experience, borrow checker integration |
| **tsserver** | TypeScript/JavaScript | Type checking, autocomplete, quick fixes |
| **pyright** | Python | Static type checking, autocomplete, diagnostics |
| **omnisharp** | C# / .NET | Full C# language support |
| **yaml-ls** | YAML | Schema validation, autocomplete, formatting |
| **marksman** | Markdown | Link validation, TOC generation, autocomplete |
| **taplo** | TOML | Formatting, validation, autocomplete |
| **lua-ls** | Lua | Autocomplete, diagnostics, annotations |
| **zls** | Zig | Full Zig language support |
| **bash-ls** | Bash/Shell | Shell script analysis, diagnostics |
| **dockerfile-ls** | Dockerfile | Syntax highlighting, validation, autocomplete |
| **css/html/json** | Web | CSS/HTML/JSON language support |

### Architecture-dependent LSPs

| Server | amd64 | arm64 |
|--------|-------|-------|
| gopls | :white_check_mark: | :white_check_mark: |
| rust-analyzer | :white_check_mark: | :white_check_mark: |
| omnisharp | :white_check_mark: x64 | :white_check_mark: arm64 |
| zls | :white_check_mark: x86_64 | :white_check_mark: aarch64 |

The installer auto-detects CPU architecture and downloads the correct binary.

## Plugins (15)

OpenCode plugins extend the assistant's capabilities.

| Plugin | Description |
|--------|-------------|
| **token-tracker** | Track token usage per session |
| **dcp** | Damage Control Protocol — prevent harmful actions |
| **swarm** | Multi-agent coordination |
| **goal-mode** | Structured goal-driven development |
| **vibeguard** | Quality gate before completion |
| **orchestrator** | Task orchestration and delegation |
| **auto-fallback** | Automatic provider fallback |
| **notify** | Desktop notifications |
| **pty** | Terminal emulation |
| **snip** | Code snippet management |
| **snippets** | Reusable code templates |
| **envsitter-guard** | Environment variable protection |
| **command-inject** | Command injection for subagents |
| **ignore** | Pattern-based file ignoring |
| **gitlab** | GitLab integration |

## Configuration Reference

### MCP Server Command Formats

```json
// Local server (bun binary — fast cold start)
{
  "type": "local",
  "command": ["/home/user/.bun/bin/mcp-server-filesystem", "/project"]
}

// Local server (npx fallback — when bun binary missing)
{
  "type": "local",
  "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "/project"]
}

// Remote server (HTTP)
{
  "type": "remote",
  "url": "https://mcp.example.com/sse"
}
```

### Plugin Format

```json
{
  "plugin": [
    ["token-tracker@latest"],
    ["dcp@v2.0.0"],
    ["swarm@latest"]
  ]
}
```

### Adding Custom MCP/LSP/Plugin

1. **MCP Server**: Add to `opencode.json` -> `mcpServers`
2. **LSP Server**: Add to `opencode.json` -> `lsp`
3. **Plugin**: Add to `opencode.json` -> `plugin` array

For system-wide installation, modify `src/lib/12-mcp-lsp.sh` and run `bash setup.sh --reinit`.

---

**See also:**
- [Architecture](../architecture/) — C4 diagrams and module layout
- [Reference](../reference/) — CLI reference and opencode.json schema
- [User Guide](../user-guide/) — daily usage of MCP and LSP
- [Advanced Guide](../advanced/) — custom MCP/LSP configuration
