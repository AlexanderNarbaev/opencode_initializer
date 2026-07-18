# Team Setup Guide

How to onboard an entire team onto an AI-enhanced development environment with one command.

## Prerequisites

- **Linux** (Ubuntu 24.04+, Debian 12+, Fedora, Arch, Alpine, openSUSE) or **WSL2** (Windows 10/11)
- **macOS** also supported via brew backend
- **git** and **curl** pre-installed
- **10 GB+** free disk space
- **Sudo** access (cached during setup)

## Quick Onboarding

Send this command to every team member:

```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --full
```

This single command installs **everything**: 8 programming languages, 21 MCP servers, 15 OpenCode plugins, 13 LSPs, Docker, GPU/LLM runtimes, LiteLLM API gateway, SearXNG web search, ZSH with Powerlevel10k, and the `dev` CLI management tool.

## Common Team Configurations

### Backend Developer (Go + Rust)

```bash
bash setup.sh --full -p ~/projects -n "Your Name" -e "you@company.com"
```

Installs all 8 languages. Team members can skip unused languages with `--interactive`.

### Frontend Developer (TypeScript + Python)

```bash
bash setup.sh --interactive
# Select: Node.js, Python, Chrome, Docker, ZSH
# Deselect: Java, Kotlin, Zig, .NET
```

### Data/ML Engineer (Python + LLM)

```bash
bash setup.sh --full -p ~/ml-projects
# LLM runtimes (Ollama, vLLM, Open WebUI) auto-detect GPU
```

### CI/CD Pipeline (Headless)

```yaml
# .github/workflows/ai-review.yml
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
          opencode --non-interactive "Review this PR for bugs, security issues, and style"
```

CI mode installs only: OpenCode CLI + Bun + essential MCPs (filesystem, context7). No Docker, no ZSH, no GUI tools, no GPU runtimes.

## Adding API Keys

Run setup with team API keys for full AI functionality:

```bash
bash setup.sh --full \
  --deepseek-key "sk-your-deepseek-key" \
  --xai-key "xai-your-grok-key" \
  --github-token "ghp_your-github-token" \
  --gitlab-token "glpat-your-gitlab-token" \
  --google-maps-key "your-google-maps-key"
```

### Supported API Keys

| Flag | Service | Free Tier |
|------|---------|-----------|
| `--deepseek-key` | DeepSeek | Yes (platform.deepseek.com) |
| `-k, --api-key` | OpenCode Go | — |
| `--xai-key` | xAI Grok | — |
| `--mimo-key` | Xiaomi MiMo | — |
| `--moonshot-key` | Moonshot Kimi K2.6 | — |
| `--minimax-key` | MiniMax M3 | — |
| `--github-token` | GitHub (MCP, gh CLI) | Free (classic token, no scopes needed) |
| `--gitlab-token` | GitLab (MCP) | Free (read_api scope) |
| `--google-maps-key` | Google Maps API | Free tier available |

All keys are stored securely in `~/.config/opencode/secrets.env` with `chmod 600` (owner-only read/write).

## Team Dotfiles with chezmoi

v2.0.0 introduces chezmoi for sharing team configuration:

```bash
# After setup, create a team dotfiles repo
chezmoi init --apply git@github.com:your-org/team-dotfiles.git

# Add your personal config
chezmoi add ~/.gitconfig
chezmoi add ~/.config/opencode/secrets.env  # stored encrypted!

# Push for the team
chezmoi cd
git push
```

Team members then apply shared config:

```bash
chezmoi init --apply git@github.com:your-org/team-dotfiles.git
```

## Customizing Per Role

### Linux Server (No GUI)

```bash
bash setup.sh --interactive
# Deselect: Chrome, Open WebUI, Playwright
# Keep: all languages, Docker, ZSH, MCPs
```

### WSL2 with Windows Host

The installer auto-detects WSL2 and applies optimizations:
- DNS fix (8.8.8.8, 1.1.1.1)
- Memory limits (50% of host RAM)
- Mirrored networking mode
- `.wslconfig` generation

```bash
# Full WSL2 install
bash setup.sh --full
```

### macOS

```bash
bash setup.sh --full
# Uses brew backend. GPU features auto-detect Apple Silicon.
```

## Post-Install Verification

Every team member should verify their setup:

```bash
dev health              # 65+ diagnostic checks
dev version-check       # Compare installed vs latest versions
dev list                # List all installed components
```

### What Gets Checked

| Section | Checks | Examples |
|---------|--------|----------|
| System | OS, packages, DNS, mirrors | apt/dnf/pacman working |
| Languages | Java, Node, Python, Go, Rust, .NET, Zig | Version >= minimum |
| Tools | Docker, Chrome, Bun, OpenCode CLI | Binary in PATH |
| Shell | ZSH, Oh My Zsh, plugins, .zshrc | Shell functional |
| MCP | Server binaries, bun paths, config | Cold-start verified |
| LLM | Ollama, vLLM, Open WebUI | GPU detected, service running |
| Security | Secrets permissions, API keys | chmod 600, all tokens present |

## Troubleshooting

### Network unreachable on WSL2

The installer auto-detects WSL2 and applies DNS fixes. If still failing:

```powershell
# In PowerShell (admin):
wsl --shutdown
# Then restart your WSL2 terminal
```

### Sudo password prompts

Cache your sudo password for non-interactive runs:

```bash
bash setup.sh --full -s "your-sudo-password"
```

### Low disk space

Skip heavy components:

```bash
bash setup.sh --interactive
# Deselect: Docker, Chrome, vLLM, RAG, Open WebUI
```

### Docker permission denied

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Provider authentication failures

Verify your keys:

```bash
dev health
# Check the "Security" section for token presence and permissions
```

Regenerate opencode.json after adding new keys:

```bash
bash setup.sh --fix-config --deepseek-key "sk-..."
```

## Installed Components Summary

| Category | Components |
|----------|-----------|
| **Languages** | Java 25, Node.js 24, Python 3.14 + uv, Go 1.26, Rust 1.97.1, .NET 10, Kotlin, Zig |
| **MCP Servers** | 21 — context7, filesystem, github, gitlab, playwright, chrome-devtools, postgres, sqlite, memory, excalidraw, brave-search, google-maps, and more |
| **LSP Servers** | 13 — gopls, rust-analyzer, tsserver, pyright, omnisharp, yaml, marksman, bash, dockerfile, css/html/json, and more |
| **Plugins** | 15 — token-tracker, dcp, swarm, auto-fallback, goal-mode, vibeguard, orchestrator, and more |
| **Infrastructure** | Docker, ChromaDB, LiteLLM, SearXNG, Muninn, Ollama, vLLM, SGLang, Open WebUI |
| **API Gateway** | LiteLLM — OpenAI-compatible endpoint for all 24 providers |
| **Web Search** | SearXNG self-hosted + sanitizer proxy (internal hosts/IP/PII) |
| **Shell** | ZSH + Oh My Zsh + Powerlevel10k + 14 plugins |
| **CLI** | `dev` tool — install, remove, update, health, list, config, version-check |
| **Dotfiles** | chezmoi for team config sharing |
| **Dev Environments** | Devbox — Nix-based isolated environments |
| **Auto-update** | systemd timer (weekly) + topgrade + unattended-upgrades (daily) |

## Next Steps

- Read the [architecture overview](../architecture/) for C4 diagrams and module layout
- Read [AGENTS.md](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/AGENTS.md) for AI agent documentation
- Read the [user guide](../user-guide/) for daily CLI usage
- Report issues on [GitHub](https://github.com/AlexanderNarbaev/opencode_initializer/issues)
