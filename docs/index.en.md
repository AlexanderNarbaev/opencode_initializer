# OpenCode Initializer v2.0.0

[![GitHub stars](https://img.shields.io/github/stars/AlexanderNarbaev/opencode_initializer?style=social)](https://github.com/AlexanderNarbaev/opencode_initializer)
[![License](https://img.shields.io/github/license/AlexanderNarbaev/opencode_initializer)](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/LICENSE)
[![ShellCheck](https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/shellcheck.yml)
[![Docs](https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/docs.yml/badge.svg)](https://alexandernarbaev.github.io/opencode_initializer/)

**Universal Dev Machine Bootstrap** — one command to set up a complete AI-enhanced development environment.

[Install](#quick-install){ .md-button .md-button--primary }
[View on GitHub :fontawesome-brands-github:](https://github.com/AlexanderNarbaev/opencode_initializer){ .md-button }

---

## Quick Stats

| Metric | Value |
|--------|-------|
| Modules | 38 (+ 3 infrastructure) |
| Orchestrator | 373 lines of Bash |
| CLI modes | 11 (full, health, interactive, ci, and more) |
| Languages | 8 |
| MCP servers | 21 |
| LSP servers | 13 |
| OpenCode plugins | 15 |
| AI providers | 24 (20 cloud + 4 local) |
| Infrastructure | 6 services (PostgreSQL, Qdrant, Redis, Prometheus, Grafana, MemoryLayer) |
| Test suite | 350+ assertions |
| Package managers | apt, dnf, pacman, apk, zypper, brew |
| Architectures | amd64, arm64 |

## What is it?

A single script that turns a fresh Linux/WSL2 machine into a production-ready development environment:

- **8 programming languages** — Java 25, Node.js 24, Python 3.14, Go 1.26, Rust 1.96, .NET 10, Kotlin, Zig
- **21 MCP servers** — GitHub, GitLab, Filesystem, Playwright, Chrome DevTools, SQLite, Postgres, Memory, Excalidraw, Brave Search, Context7, Google Maps, and more
- **15 OpenCode plugins** — token-tracker, dcp, swarm, goal-mode, vibeguard, orchestrator, auto-fallback, notify, pty, snip, snippets, envsitter-guard, command-inject, ignore
- **13 LSP servers** — gopls, rust-analyzer, tsserver, pyright, omnisharp, yaml, marksman, taplo, lua, zls, bash, dockerfile, css/html/json
- **Infrastructure as Code** — PostgreSQL, Qdrant, Redis, Prometheus, Grafana, MemoryLayer via Docker Compose
- **Cockpit TUI** — 7-tab terminal UI for server management
- **Isolated Circuit Mode** — air-gapped LLM operation with local backends
- **24 AI providers** — DeepSeek, z.ai GLM-5.2, OpenRouter, OpenAI, Anthropic, Google, xAI, Moonshot, Alibaba Qwen3, and more
- **GPU/LLM** — Ollama, vLLM, SGLang, Open WebUI, WasmEdge (multi-vendor GPU auto-detection)
- **ZSH** — Oh My Zsh + Powerlevel10k with 14 plugins
- **Chrome** — Google Chrome + ChromeDriver (WSL2-optimized)
- **Auto-update** — systemd weekly timer + topgrade

## What's New in v2.0.0

| Feature | Description |
|---------|-------------|
| Infrastructure as Code | PostgreSQL + Qdrant + Redis + Prometheus + Grafana + MemoryLayer via Docker Compose |
| Cockpit TUI | 7-tab terminal UI — System, Plugins, GPU/Models, Sessions, Tasks, Logs, Infra |
| Isolated Circuit Mode | Air-gapped LLM operation with Ollama, LiteLLM, vLLM, SGLang |
| z.ai GLM-5.2 | Primary provider for RU/CN markets, OpenAI-compatible, free tier |
| OpenRouter | Aggregator access to 100+ models via single API key |
| Alibaba Qwen3 | Native SDK, 235B flagship model |
| DeepInfra | Fast inference, competitive pricing |
| MemoryLayer | AI memory system with Ollama embed proxy (mxbai-embed-large) |
| Observability | Prometheus (:9090) + Grafana (:3001) with auto-provisioning |
| 24 providers | 20 cloud + 4 local (was 16 in v1.1.0) |
| 38 modules | Was 29 in v1.1.0 |

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash
```

Or clone and run:

```bash
git clone https://github.com/AlexanderNarbaev/opencode_initializer.git ~/opencode_initializer
cd ~/opencode_initializer && bash setup.sh
```

!!! tip "Review before running"
    Always review scripts before executing them. The entire codebase is open source and documented.

### With API Keys

```bash
bash setup.sh --full \
  --deepseek-key "sk-..." \
  --zai-key "..." \
  --openrouter-key "sk-or-..." \
  --github-token "ghp_..." \
  --gitlab-token "glpat-..." \
  --google-maps-key "..."
```

### Isolated Circuit Mode (Air-Gapped)

```bash
bash setup.sh --full --isolated    # Use local LLM backends only
dev isolated on                     # Enable after install
dev isolated status                 # Check current state
```

## What Gets Installed

| Category | Tools |
|----------|-------|
| **Languages** | Java 25, Node.js 24, Python 3.14 + uv, Go 1.26, Rust 1.96, .NET 10, Kotlin, Zig |
| **Shell** | Zsh 5.8+, Oh My Zsh, Powerlevel10k, 14 plugins |
| **Browser** | Google Chrome, ChromeDriver (WSL2-aware) |
| **Containers** | Docker Engine |
| **Infrastructure** | PostgreSQL, Qdrant, Redis, Prometheus, Grafana, MemoryLayer |
| **AI/ML** | Ollama, vLLM, SGLang, Open WebUI, ChromaDB, WasmEdge, ONNX |
| **API Gateway** | LiteLLM — OpenAI-compatible endpoint for all providers |
| **Web Search** | SearXNG self-hosted search + sanitizer proxy |
| **MCP Servers** | 21 servers for AI-assisted development |
| **LSP Servers** | 13 language servers |
| **Plugins** | 15 OpenCode productivity plugins |
| **Security** | Trivy, Qodana |
| **Utilities** | bat, btm, fd, ripgrep, sd, typos, topgrade, just, mise |
| **Dotfiles** | chezmoi for team config sharing |
| **Dev Environments** | Devbox — Nix-based isolated envs |
| **Cockpit** | 7-tab TUI for server management |

## Supported Platforms

| OS | Status | Package Manager |
|----|--------|----------------|
| Ubuntu 22.04/24.04 | Fully supported | apt |
| Debian 12 | Fully supported | apt |
| Fedora 40+ | Fully supported | dnf |
| Arch Linux | Fully supported | pacman |
| Alpine Linux | Fully supported | apk |
| openSUSE | Fully supported | zypper |
| macOS | Fully supported | brew |
| WSL2 | Optimized (DNS fix, memory limits, .wslconfig) | apt |

## Modes at a Glance

| Mode | Flag | Use Case |
|------|------|----------|
| Full | `--full` | Complete bootstrap (default) |
| Reinit | `--reinit` | Reinstall tools, keep data |
| New Project | `--new <dir>` | Project initialization only |
| CI/CD | `--ci` | Headless pipeline setup |
| Health | `--health` | Full diagnostics (65+ checks) |
| Update | `--update` | Update installed tools |
| Upgrade | `--upgrade` | Full system upgrade chain |
| Interactive | `--interactive` | Pick components individually |
| Fix Config | `--fix-config` | Regenerate opencode.json |
| Fix ZSH | `--fix-zshrc` | Repair shell configuration |
| Dry Run | `--dry-run` | Preview without changes |

## Documentation

- [Getting Started](getting-started/) — beginner-friendly installation guide
- [User Guide](user-guide/) — day-to-day usage
- [Advanced Guide](advanced/) — customization, WSL2, GPU setup
- [Architecture](architecture/) — C4 diagrams, module reference
- [Reference](reference/) — CLI, opencode.json schema, MCP/LSP catalog
- [Contributing](contributing/) — how to help
- [FAQ](faq/) — common questions
- [Team Setup](guides/team-setup/) — onboarding guide for teams

## Community

- :fontawesome-brands-github: [GitHub](https://github.com/AlexanderNarbaev/opencode_initializer)
- :fontawesome-brands-git: [GitVerse Mirror](https://gitverse.ru/AlexandrNarbaev/opencode_initializer)
- [Report a bug](https://github.com/AlexanderNarbaev/opencode_initializer/issues/new?template=bug_report.md)
- [Request a feature](https://github.com/AlexanderNarbaev/opencode_initializer/issues/new?template=feature_request.md)
- [Contributing Guide](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/CONTRIBUTING.md)

## License

MIT — see [LICENSE](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/LICENSE).
