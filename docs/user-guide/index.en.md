# User Guide

Day-to-day usage of your OpenCode Initializer-powered development environment.

## Daily Workflow

```mermaid
flowchart LR
    A[Open Terminal] --> B[Check Health]
    B --> C[Write Code]
    C --> D[AI Assist]
    D --> E[Test & Deploy]
    E --> F[Weekly Update]
```

## The `dev` CLI

Your main management tool after installation. Available as `~/opencode_initializer/dev.sh`.

### Health Check

Run this first thing to verify your environment:

```bash
dev health
```

Output covers 5 sections:
1. **System** — OS, kernel, package manager, disk space
2. **Shell** — ZSH, plugins, Oh My Zsh version
3. **Languages** — Java, Node, Python, Go, Rust, .NET, Zig
4. **Tools** — Docker, Chrome, OpenCode, Bun
5. **AI/LLM** — MCP servers, Ollama, ChromaDB

### Version Check

```bash
dev version-check
```

Compares installed versions against latest from:
- GitHub Releases (Go, Zig, Bun)
- API endpoints (Node, Python)
- Package registries (Rust, .NET)

### Update Tools

```bash
# Update dev tools only
dev update

# Full system update (all packages)
dev autoupdate
```

## Working with AI

### Basic Code Generation

```bash
opencode "Create a Python Flask API with /health and /users endpoints"
```

### Code Review

```bash
opencode "Review the file src/main.go for security issues"
```

### Project Understanding

OpenCode reads your `AGENTS.md` and `opencode.json` for context:

```bash
opencode "Explain the architecture of this project"
```

## Managing Projects

### Create a New Project

```bash
bash setup.sh --new ~/my-new-project
```

This creates:
```
~/my-new-project/
├── AGENTS.md         # AI agent instructions
├── opencode.json     # AI config
├── docker-compose.yml
├── .gitignore
└── agents/           # Custom AI subagents
```

### Existing Project Integration

Just add an `AGENTS.md` to any project directory. OpenCode will pick it up automatically.

## MCP Servers

### List Active MCP Servers

```bash
cat ~/opencode_initializer/opencode.json | grep -A 3 '"mcpServers"'
```

### Add a Custom MCP Server

Edit `opencode.json` and add:

```json
{
  "mcpServers": {
    "my-server": {
      "type": "local",
      "command": ["node", "/path/to/server.js"]
    }
  }
}
```

### Troubleshoot MCP

```bash
# Check if Bun is installed
which bun

# Check MCP npm cache
ls ~/.cache/opencode-setup/mcp-cache/

# Reinstall MCP servers
bash setup.sh --reinit
```

## Docker

```bash
# Start Docker (if not auto-started)
sudo systemctl start docker

# Run a container
docker run hello-world

# Check Docker in health report
dev health
```

## Chrome (WSL2)

```bash
# Launch Chrome
chrome-open

# Launch with specific URL
chrome-open https://github.com
```

## LLM / GPU

### Check GPU

```bash
nvidia-smi
```

### Manage Ollama

```bash
# Start Ollama
systemctl --user start ollama

# List installed models
ollama list

# Pull a model
ollama pull llama3.2

# Test
ollama run llama3.2 "Hello!"
```

### Open WebUI

Access at `http://localhost:3000` after starting:

```bash
# Start Open WebUI (requires Ollama running)
systemctl --user start open-webui
```

## Logs

All installation output is logged:

```bash
ls -lt ~/.cache/opencode-setup/setup-*.log | head -1
```

View the latest log:

```bash
tail -100 ~/.cache/opencode-setup/setup-*.log
```

## Tips & Tricks

### Aliases

The installer adds useful aliases to your `.zshrc`:

```bash
alias dev='~/opencode_initializer/dev.sh'
alias chrome-open='google-chrome-stable --no-sandbox'
```

### Keyboard Shortcuts (ZSH with plugins)

| Shortcut | Action |
|----------|--------|
| `Ctrl+T` | Fuzzy file search (fzf) |
| `Ctrl+R` | Fuzzy history search |
| `Alt+C` | Fuzzy directory jump |
| `Tab` | Smart autocomplete (zsh-autosuggestions) |

### Performance Tips

1. **Close unused containers**: `docker system prune`
2. **Limit Ollama models**: Only pull what you use
3. **Clean npm cache**: `npm cache clean --force`
4. **Check disk**: `dev health` includes disk usage

### Backup Your Config

```bash
# Backup entire config
tar -czf opencode-backup-$(date +%Y%m%d).tar.gz \
  ~/.config/opencode-setup/ \
  ~/.config/opencode/ \
  ~/opencode_initializer/opencode.json
```

---

**See also:**
- [MCP, LSP & Plugins Reference](../reference/mcp-lsp-plugins/) — full catalogue of all servers
- [Advanced Guide](../advanced/) — WSL2, GPU, customization
- [FAQ](../faq/) — common issues and solutions
- [Architecture](../architecture/) — C4 diagrams and module reference
