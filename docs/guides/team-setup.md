# Team Setup Guide — opencode_initializer

How to onboard colleagues onto an AI-enhanced development environment in one command.

## Prerequisites

- **Linux** (Ubuntu 24.04+, Debian 12+, Fedora, Arch, Alpine, openSUSE) or **WSL2** (Windows 10/11)
- **git** and **curl** installed
- **10GB+** free disk space
- **Sudo** access

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --full
```

This installs everything: 8 programming languages, 21 MCP servers, 15 plugins, 13 LSPs, Docker, GPU/LLM runtimes, and ZSH with Powerlevel10k.

## Adding API Keys

Run setup with your API keys for full AI functionality:

```bash
bash setup.sh --full \
  --deepseek-key "sk-your-deepseek-key" \
  --github-token "ghp_your-github-token" \
  --gitlab-token "glpat-your-gitlab-token"
```

Supported API keys:
- `--deepseek-key` — DeepSeek (free tier available at platform.deepseek.com)
- `-k, --api-key` — OpenCode Go proxy
- `--xai-key` — xAI Grok
- `--github-token` — GitHub personal access token (for MCP, gh CLI)
- `--gitlab-token` — GitLab personal access token
- `--google-maps-key` — Google Maps API key
- `--mimo-key` — Xiaomi MiMo
- `--moonshot-key` — Moonshot Kimi K2.6
- `--minimax-key` — MiniMax M3

API keys are stored in `~/.config/opencode/secrets.env` with `chmod 600`.

## Customizing the Install

### Skip components (interactive mode)

```bash
bash setup.sh --interactive
```

Select which components to install via a menu. Useful for:
- Skipping languages you don't use
- Skipping GPU/LLM runtimes on CPU-only machines
- Skipping Chrome on servers

### Install only what you need

```bash
bash setup.sh --full -p ~/my-project    # Custom project directory
bash setup.sh --full --dry-run          # Preview without changes
bash setup.sh --reinit                  # Reinstall tools, keep data
```

### Post-install: add components later

```bash
dev install llm       # Add GPU/LLM support
dev install docker    # Add Docker
dev remove java       # Remove Java
```

## CI/CD Mode (GitHub Actions)

Use `--ci` mode in your GitHub Actions workflows for lightweight AI agent setup:

```yaml
name: AI Code Review
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup OpenCode CI
        run: |
          curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --ci
      - name: AI Review
        env:
          DEEPSEEK_API_KEY: ${{ secrets.DEEPSEEK_API_KEY }}
        run: |
          opencode --non-interactive "Review this PR for bugs, security issues, and style problems"
```

CI mode installs only: OpenCode CLI + Bun + essential MCPs (filesystem, context7). No Docker, no ZSH, no GUI tools, no GPU runtimes.

## Common Issues

### "Network unreachable" on WSL2
The installer auto-detects WSL2 and applies DNS fixes (8.8.8.8, 1.1.1.1). If still failing:
```powershell
# In PowerShell (admin):
wsl --shutdown
# Then restart your WSL2 terminal
```

### "Sudo password" prompt
The installer caches your sudo password. If you prefer non-interactive:
```bash
bash setup.sh --full -s "your-sudo-password"
```

### Low disk space
Skip heavy components:
```bash
bash setup.sh --full --interactive
# Deselect: Docker, Chrome, vLLM, RAG
```

### "Permission denied" for Docker
Add yourself to the docker group:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Post-install verification
```bash
dev health              # 65+ diagnostic checks
dev version-check       # Compare installed vs latest versions
dev list                # List all installed components
```

## What's Installed

| Category | Components |
|----------|-----------|
| Languages | Java 25, Node.js 24, Python 3.14, Go 1.26, Rust 1.96, .NET 10, Kotlin, Zig |
| MCP Servers | 21 (context7, filesystem, github, gitlab, playwright, chrome-devtools, postgres, sqlite, memory, excalidraw, brave-search, google-maps, and more) |
| LSP Servers | 13 (gopls, rust-analyzer, tsserver, pyright, omnisharp, yaml, marksman, bash, dockerfile, css/html/json, and more) |
| Plugins | 15+ (token-tracker, dcp, swarm, auto-fallback, goal-mode, vibeguard, orchestrator, and more) |
| Infrastructure | Docker, ChromaDB, LiteLLM, SearXNG, Ollama, vLLM, SGLang, Open WebUI |
| Shell | ZSH + Oh My Zsh + Powerlevel10k + 18 plugins |
| CLI | `dev` tool (install, remove, update, health, list, config, version-check) |

## Next Steps

- Read the [full guide](../guide.md) for detailed feature reference
- Read [AGENTS.md](../../AGENTS.md) for AI agent documentation
- Report issues on [GitHub](https://github.com/AlexanderNarbaev/opencode_initializer/issues)
