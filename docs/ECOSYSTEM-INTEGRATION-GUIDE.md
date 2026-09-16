# OpenCode Personal Home Station — Ecosystem Integration Guide

## Overview

This guide covers the integration of agent frameworks, MCP servers, LSP services, and development tools for maximum efficiency on a personal home station.

## Agent Frameworks

### CrewAI (Multi-Agent Orchestration)
- **Purpose**: Orchestrate teams of AI agents with role-based collaboration
- **Use Case**: Complex tasks requiring multiple specialized agents
- **Installation**: `uv tool install crewai` or `pipx install crewai`
- **License**: MIT (open-source)

### LangGraph (Stateful Agents)
- **Purpose**: Build long-running, stateful agents with durable execution
- **Use Case**: Workflows that need persistence and human-in-the-loop
- **Installation**: `pip install langgraph`
- **License**: MIT (open-source)

### Microsoft Agent Framework
- **Purpose**: Enterprise-grade multi-agent orchestration
- **Use Case**: Production deployments with A2A and MCP support
- **Status**: Successor to AutoGen (which is now in maintenance mode)
- **License**: MIT (open-source)

## MCP Servers

### Reference Servers (from Model Context Protocol)
| Server | Purpose | Installation |
|--------|---------|--------------|
| `@modelcontextprotocol/server-memory` | Knowledge graph-based memory | `npm install -g` |
| `@modelcontextprotocol/server-filesystem` | Secure file operations | `npm install -g` |
| `@modelcontextprotocol/server-sequentialthinking` | Dynamic problem-solving | `npm install -g` |
| `@modelcontextprotocol/server-github` | GitHub API integration | `npm install -g` |
| `@modelcontextprotocol/server-gitlab` | GitLab API integration | `npm install -g` |
| `@modelcontextprotocol/server-postgres` | PostgreSQL database access | `npm install -g` |
| `@modelcontextprotocol/server-redis` | Redis key-value store | `npm install -g` |
| `@modelcontextprotocol/server-slack` | Slack messaging | `npm install -g` |
| `@brave/brave-search-mcp-server` | Web search | `npm install -g` |
| `@modelcontextprotocol/server-puppeteer` | Browser automation | `npm install -g` |

### Community Servers
| Server | Purpose | Installation |
|--------|---------|--------------|
| `@upstash/context7-mcp` | Context7 documentation | `npm install -g` |
| `@notionhq/notion-mcp-server` | Notion integration | `npm install -g` |
| `mcp-server-git` | Git operations | `uvx mcp-server-git` |
| `mcp-server-fetch` | Web fetching | `uvx mcp-server-fetch` |
| `mcp-server-time` | Time/timezone | `uvx mcp-server-time` |
| `mcp-server-sqlite` | SQLite database | `uvx mcp-server-sqlite` |
| `excalidraw-architect-mcp` | Diagram generation | `uvx excalidraw-architect-mcp` |

## LSP Servers

### Core Languages
| Server | Language | Installation |
|--------|----------|--------------|
| `typescript-language-server` | TypeScript/JavaScript | `npm install -g` |
| `pyright` | Python | `npm install -g` |
| `gopls` | Go | `go install golang.org/x/tools/gopls@latest` |
| `rust-analyzer` | Rust | `rustup component add rust-analyzer` |
| `bash-language-server` | Bash | `npm install -g` |
| `yaml-language-server` | YAML | `npm install -g` |
| `vscode-json-languageserver` | JSON | `npm install -g` |
| `dockerfile-language-server-nodejs` | Docker | `npm install -g` |
| `marksman` | Markdown | Binary download |
| `lua-language-server` | Lua | Binary download |
| `zls` | Zig | Binary download |

## Development Tools

### Task Runners
- **Taskfile**: `npm install -g @task/cli`
- **Just**: `npm install -g just`

### Documentation
- **MkDocs**: `uv pip install mkdocs-material`
- **Hugo**: `go install github.com/gohugoio/hugo@latest`

### Static Analysis
- **ShellCheck**: System package
- **Hadolint**: Dockerfile linter
- **yamllint**: YAML linter

## Configuration

### OpenCode Configuration
```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/projects"]
    },
    "sequentialthinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequentialthinking"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "<YOUR_TOKEN>"
      }
    }
  }
}
```

### LSP Configuration
```json
{
  "lsp": {
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"]
    },
    "python": {
      "command": "pyright-langserver",
      "args": ["--stdio"]
    },
    "go": {
      "command": "gopls",
      "args": ["serve"]
    }
  }
}
```

## Best Practices

### Token Economy
1. Use compact prompts
2. Reuse context across operations
3. Batch similar operations
4. Skip redundant checks

### Performance
1. Enable parallel execution
2. Use caching aggressively
3. Lazy-load heavy resources
4. Background updates

### Security
1. Verify checksums
2. Scan for vulnerabilities
3. Use sandboxed execution
4. Backup before changes

## Troubleshooting

### Common Issues
1. **MCP server not found**: Check PATH and npm global installation
2. **LSP server not starting**: Verify language runtime is installed
3. **Agent framework errors**: Check API keys and dependencies

### Debug Mode
```bash
# Enable debug logging
export OPENCODE_DEBUG=1
export OPENCODE_LOG_LEVEL=debug

# Run with verbose output
opencode --verbose
```

## Resources

- [Model Context Protocol](https://modelcontextprotocol.io/)
- [CrewAI Documentation](https://docs.crewai.com/)
- [LangGraph Documentation](https://docs.langchain.com/oss/python/langgraph/overview)
- [Microsoft Agent Framework](https://github.com/microsoft/agent-framework)
- [MCP Registry](https://registry.modelcontextprotocol.io/)

