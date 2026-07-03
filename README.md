# OpenCode Initializer v2.0.0

<p align="center">
  <b>One-command AI-enhanced development environment setup for WSL2, Linux, and macOS.</b><br>
  <sub>373-line orchestrator · 38 modules · 11 modes · 21 MCPs · 15 plugins · 13 LSPs · 24 providers</sub>
</p>

<p align="center">
  <a href="https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/test.yml"><img src="https://img.shields.io/github/actions/workflow/status/AlexanderNarbaev/opencode_initializer/test.yml?branch=main&label=tests" alt="Tests"></a>
  <a href="https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/shellcheck.yml"><img src="https://img.shields.io/github/actions/workflow/status/AlexanderNarbaev/opencode_initializer/shellcheck.yml?branch=main&label=shellcheck" alt="ShellCheck"></a>
  <a href="https://alexandernarbaev.github.io/opencode_initializer/"><img src="https://img.shields.io/github/actions/workflow/status/AlexanderNarbaev/opencode_initializer/docs.yml?branch=main&label=docs" alt="Docs"></a>
  <a href="https://alexandernarbaev.github.io/opencode_initializer/"><img src="https://img.shields.io/badge/docs-online-4051b5.svg" alt="Documentation"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/AlexanderNarbaev/opencode_initializer"><img src="https://img.shields.io/github/stars/AlexanderNarbaev/opencode_initializer?style=social" alt="GitHub stars"></a>
  <a href="https://gitverse.ru/AlexandrNarbaev/opencode_initializer"><img src="https://img.shields.io/badge/gitverse-mirror-8b5cf6.svg" alt="GitVerse Mirror"></a>
</p>

---

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --full
```

One command installs everything: 8 languages, 38 infrastructure modules, 21 MCP servers, 15 OpenCode plugins, 13 LSP servers, 24 AI providers, infrastructure as code (PostgreSQL + Qdrant + Redis + Prometheus + Grafana + MemoryLayer), Cockpit TUI, Isolated Circuit Mode, hardware auto-detection, LiteLLM API gateway, and SearXNG web search.

[Full Documentation](https://alexandernarbaev.github.io/opencode_initializer/)

## Feature Grid

| Category | Count | Details |
|----------|-------|---------|
| Languages | 8 | Java 25, Node.js 24, Python 3.14, Go 1.26, Rust 1.96, .NET 10, Kotlin, Zig |
| Modules | 38 | System, Docker, Chrome, ZSH, 7 languages, OpenCode, MCP/LSP, ChromaDB, LLM, RAG, LiteLLM, SearXNG, providers, dotfiles, Devbox, Infra, Cockpit, Isolated Circuit, Observability, GUI, and more |
| MCP Servers | 21 | GitHub, GitLab, Filesystem, Playwright, Chrome DevTools, Postgres, SQLite, Memory, Excalidraw, Brave Search, Context7, Google Maps, and more |
| LSP Servers | 13 | gopls, rust-analyzer, tsserver, pyright, omnisharp, yaml, marksman, taplo, lua, zls, bash, dockerfile, css/html/json |
| Plugins | 15 | token-tracker, dcp, swarm, goal-mode, vibeguard, orchestrator, auto-fallback, notify, pty, snip, snippets, envsitter-guard, command-inject, ignore |
| AI Providers | 24 | DeepSeek, OpenCode, **z.ai GLM-5.2**, **OpenRouter**, OpenAI, Anthropic Claude 4, Google Gemini, xAI Grok 4, Moonshot Kimi K2, MiniMax, MiMo, **Alibaba Qwen3**, **DeepInfra**, Groq, Together, Fireworks, Perplexity, Mistral, Cohere, Cerebras + 4 local (Ollama, LiteLLM, vLLM, SGLang) |
| CLI Modes | 11 | full, reinit, new, health, update, upgrade, interactive, ci, fix-config, fix-zshrc, dry-run |
| Infrastructure | 6 | PostgreSQL, Qdrant, Redis, Prometheus, Grafana, MemoryLayer |
| Package Managers | 6 | apt, dnf, pacman, apk, zypper, brew |

### v2.0.0 — Infrastructure as Code + Isolated Circuit + z.ai GLM-5.2

- **Infrastructure as Code**: PostgreSQL + Qdrant + Redis + Prometheus + Grafana + MemoryLayer via Docker Compose
- **Cockpit TUI**: 7-tab terminal UI for server management (System, Plugins, GPU/Models, Sessions, Tasks, Logs, Infra)
- **Isolated Circuit Mode**: air-gapped LLM operation with local OpenAI-compatible backends (Ollama, LiteLLM, vLLM, SGLang)
- **z.ai GLM-5.2**: primary provider for RU/CN markets, OpenAI-compatible API, free tier
- **OpenRouter**: aggregator access to 100+ models via single API key
- **Alibaba Qwen3**: native SDK in opencode, 235B flagship model
- **MemoryLayer**: AI memory system with Ollama embed proxy (mxbai-embed-large, 1024-dim)
- **Observability**: Prometheus (:9090) + Grafana (:3001) with auto-provisioning

## Architecture

```
opencode_initializer/
├── setup.sh                  # Orchestrator (373 lines)
├── dev.sh                    # CLI: dev install|remove|update|health|list|config|isolated
├── opencode.json             # Generated OpenCode multi-provider config (24 providers)
├── src/
│   ├── lib/                  # 35 numbered modules + 3 infra
│   │   ├── helpers.sh        # _curl, _retry, _npm_install infrastructure
│   │   ├── 00-core.sh        # OS/PKG/ARCH detection, mirrors, progress, ISOLATED_CIRCUIT
│   │   ├── 01-system.sh      # System packages (cross-distro: apt/dnf/pacman/apk/zypper/brew)
│   │   ├── 02-docker.sh      # Docker Engine
│   │   ├── 03-chrome.sh      # Google Chrome + ChromeDriver (WSL2-aware)
│   │   ├── 04-zsh.sh         # Zsh + Oh My Zsh + Powerlevel10k + 14 plugins
│   │   ├── 05-java.sh        # Java 25 (Adoptium) + Zig
│   │   ├── 06-node.sh        # Node.js 24 (n)
│   │   ├── 07-python.sh      # Python 3.14 + uv
│   │   ├── 08-go.sh          # Go 1.26 (direct download → apt fallback)
│   │   ├── 09-rust.sh        # Rust 1.96 (rustup)
│   │   ├── 10-dotnet.sh      # .NET 10
│   │   ├── 11-opencode.sh    # OpenCode CLI 1.17 + Bun 1.3
│   │   ├── 12-mcp-lsp.sh     # 21 MCP + 15 plugins + 13 LSP + Muninn
│   │   ├── 13-chromadb.sh    # ChromaDB vector database + systemd service
│   │   ├── 14-shokunin.sh    # Shokunin + Superpowers + Caveman skills
│   │   ├── 15-security.sh    # Trivy, Qodana
│   │   ├── 16-llm.sh         # Ollama, vLLM, SGLang, Open WebUI, WasmEdge (GPU-aware)
│   │   ├── 17-project.sh     # Project structure (AGENTS.md, WAL, docker-compose)
│   │   ├── 18-opencode-json.sh  # opencode.json generation (24 providers, ISOLATED_CIRCUIT)
│   │   ├── 19-finalize.sh    # Git config, PATH, .zshrc, auth, verification (36 checks)
│   │   ├── 20-autoupdate.sh  # topgrade + systemd weekly timer + unattended-upgrades + abtop
│   │   ├── 21-rag.sh         # RAG System — Corporate Knowledge Assistant
│   │   ├── 22-webui-service.sh  # Open WebUI systemd user service
│   │   ├── 23-just.sh        # just task runner with default justfile
│   │   ├── 24-websearch.sh   # SearXNG web search + sanitizer proxy
│   │   ├── 25-litellm.sh     # LiteLLM OpenAI-compatible local API gateway
│   │   ├── 26-providers.sh   # 24 LLM provider registry (20 cloud + 4 local)
│   │   ├── 27-dotfiles.sh    # chezmoi dotfiles manager for team config sharing
│   │   ├── 28-devbox.sh      # Devbox — Nix-based isolated dev environments
│   │   ├── 29-mise.sh        # mise-en-place universal tool version manager
│   │   ├── 30-infra.sh       # Infrastructure: PostgreSQL + Qdrant + Redis + Prometheus + Grafana + MemoryLayer
│   │   ├── 31-cockpit.sh     # Cockpit TUI server management daemon (7-tab)
│   │   ├── 32-isolated.sh    # Isolated Circuit Mode — air-gapped LLM
│   │   ├── 34-observability.sh  # Grafana + Prometheus observability stack
│   │   ├── 35-gui.sh         # Web management interface foundation
│   │   ├── version-check.sh  # Version comparison (8+ tools)
│   │   └── pre-session-check.sh  # Pre-session provider/model validation
│   └── modes/                # 5 mode scripts (+ 6 built-in)
│       ├── ci.sh             # CI/CD headless mode
│       ├── health.sh         # Full diagnostics (65+ checks)
│       ├── fix-zshrc.sh      # .zshrc repair
│       ├── upgrade.sh        # Full system upgrade chain
│       └── interactive.sh    # Component-by-component selection
├── tests/                    # Unit (11), integration (5), E2E (4) — 350+ assertions
├── migrations/               # Timestamped, idempotent migrations
├── scripts/                  # Utility scripts (embed-proxy, ai-router, oc-*)
├── docs/                     # MkDocs Material documentation site
├── .github/                  # CI workflows, issue/PR templates
├── CHANGELOG.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
└── LICENSE
```

## Modes

| Mode | Flag | Description |
|------|------|-------------|
| Full | `--full` (default) | Complete bootstrap — all modules |
| Reinit | `--reinit` | Reinstall tools, preserve data |
| New Project | `--new <dir>` | Initialize new project only |
| CI/CD | `--ci` | Headless CI: OpenCode CLI + essential MCPs |
| Health | `--health` | Full diagnostics (65+ checks) |
| Update | `--update` | Update installed tools |
| Upgrade | `--upgrade` | Full system upgrade chain |
| Interactive | `--interactive` | Component-by-component selection |
| Fix Config | `--fix-config` | Regenerate opencode.json |
| Fix ZSH | `--fix-zshrc` | Repair .zshrc |
| Dry Run | `--dry-run` | Preview mode, no changes |

## Installation

### Full Install

```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --full
```

### With API Keys

```bash
bash setup.sh --full \
  --deepseek-key "sk-..." \
  --zai-key "..." \
  --openrouter-key "sk-or-..." \
  --xai-key "xai-..." \
  --github-token "ghp_..." \
  --gitlab-token "glpat-..."
```

### Isolated Circuit Mode (Air-Gapped)

```bash
bash setup.sh --full --isolated          # Use local LLM backends only
dev isolated on                           # Enable after install
dev isolated status                       # Check current state
```

### Interactive

```bash
bash setup.sh --interactive     # Choose what to install
bash setup.sh --dry-run --full  # Preview without changes
```

### Post-Install CLI

```bash
dev health              # Full diagnostics (65+ checks)
dev list                # List installed components
dev update              # Update everything + migrations
dev self-update         # Update the installer itself
dev version-check       # Compare installed vs latest versions
dev isolated status     # Check Isolated Circuit Mode
dev install llm         # Add GPU/LLM support later
dev config              # Edit setup configuration
```

## Options

| Flag | Description |
|------|-------------|
| `-k, --api-key <key>` | OpenCode Go API key |
| `--deepseek-key <key>` | DeepSeek API key |
| `--zai-key <key>` | z.ai GLM API key |
| `--openrouter-key <key>` | OpenRouter API key |
| `--xai-key <key>` | xAI Grok API key |
| `--mimo-key <key>` | Xiaomi MiMo API key |
| `--moonshot-key <key>` | Moonshot Kimi API key |
| `--minimax-key <key>` | MiniMax API key |
| `--alibaba-key <key>` | Alibaba Qwen API key |
| `--deepinfra-key <key>` | DeepInfra API key |
| `--isolated` | Enable Isolated Circuit Mode (local LLM only) |
| `--github-token <token>` | GitHub personal access token |
| `--gitlab-token <token>` | GitLab personal access token |
| `--google-maps-key <key>` | Google Maps API key |
| `-s, --sudo-pass <pass>` | Sudo password (cached) |
| `-p, --project-dir <dir>` | Project directory (default: ~/projects) |
| `-n, --git-name <name>` | Git user name |
| `-e, --git-email <email>` | Git user email |

## Resilience

- **Progress tracking**: `~/.cache/opencode-setup/progress` records completed steps — re-runs are idempotent
- **Retry logic**: All curl downloads use 5 retries with exponential backoff
- **Mirror fallback**: Auto-detects inaccessible services and switches to mirrors (ghproxy.com, npmmirror.com, yandex.ru, goproxy.cn)
- **npm pack cache**: MCP `.tgz` files cached locally, survive npm cache clears
- **Bun binary paths**: Absolute paths to `~/.bun/bin/` — 0.5s cold start vs 5-15s with npx
- **WSL2 optimization**: DNS fix, memory limits, mirrored networking, .wslconfig tuning
- **Dry-run mode**: Preview all changes without executing them
- **Isolated Circuit**: Air-gapped LLM operation with auto-detection of local backends

## Platform Support

| Package Manager | Distributions | Arch |
|----------------|---------------|------|
| apt | Ubuntu, Debian, Mint, Pop!_OS | amd64, arm64 |
| dnf | Fedora, RHEL, CentOS Stream | amd64, arm64 |
| pacman | Arch, Manjaro, EndeavourOS | amd64 |
| apk | Alpine Linux | amd64, arm64 |
| zypper | openSUSE | amd64 |
| brew | macOS, Linuxbrew | amd64, arm64 |

## Security

- All secrets in `~/.config/opencode/secrets.env` (chmod 600)
- `opencode-dcp` + `opencode-vibeguard`: context pruning, PII/secret filtering
- No hardcoded credentials in any source file
- All API keys via CLI arguments only
- ShellCheck CI on every push and PR
- MIT licensed

## Documentation

- [Full Guide](https://alexandernarbaev.github.io/opencode_initializer/) — MkDocs Material site
- [Team Setup Guide](docs/guides/team-setup.md) — onboarding colleagues
- [Architecture](https://alexandernarbaev.github.io/opencode_initializer/architecture/) — C4 diagrams, module reference
- [AGENTS.md](AGENTS.md) — AI agent documentation
- [Contributing Guide](CONTRIBUTING.md)
- [Security Policy](SECURITY.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Changelog](CHANGELOG.md)

## Community

- [GitHub Issues](https://github.com/AlexanderNarbaev/opencode_initializer/issues)
- [GitVerse Mirror](https://gitverse.ru/AlexandrNarbaev/opencode_initializer)

## License

MIT (c) 2025-2026 [Alexander Narbaev](https://github.com/AlexanderNarbaev)
