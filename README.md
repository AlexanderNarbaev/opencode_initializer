# OpenCode Initializer v1.1.0

<p align="center">
  <b>One-command AI-enhanced development environment setup for WSL2, Linux, and macOS.</b><br>
  <sub>352-line orchestrator · 29 modules · 11 modes · 21 MCPs · 15 plugins · 13 LSPs · 16 providers</sub>
</p>

<p align="center">
  <a href="https://github.com/AlexanderNarbaev/opencode_initializer/actions"><img src="https://img.shields.io/github/actions/workflow/status/AlexanderNarbaev/opencode_initializer/test.yml?branch=main&label=tests" alt="Tests"></a>
  <a href="https://github.com/AlexanderNarbaev/opencode_initializer"><img src="https://img.shields.io/github/stars/AlexanderNarbaev/opencode_initializer?style=social" alt="GitHub stars"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://shellcheck.net"><img src="https://img.shields.io/badge/shellcheck-passing-brightgreen.svg" alt="ShellCheck"></a>
  <a href="https://alexandernarbaev.github.io/opencode_initializer/"><img src="https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/docs.yml/badge.svg" alt="Docs"></a>
</p>

---

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --full
```

One command installs everything: 8 languages, 29 infrastructure modules, 21 MCP servers, 15 OpenCode plugins, 13 LSP servers, 16 AI providers, hardware auto-detection, LiteLLM API gateway, and SearXNG web search.

[Full Documentation](https://alexandernarbaev.github.io/opencode_initializer/)

## Feature Grid

| Category | Count | Details |
|----------|-------|---------|
| Languages | 8 | Java 25, Node.js 24, Python 3.14, Go 1.26, Rust 1.96, .NET 10, Kotlin, Zig |
| Modules | 29 | System, Docker, Chrome, ZSH, 7 languages, OpenCode, MCP/LSP, ChromaDB, LLM, RAG, LiteLLM, SearXNG, providers, dotfiles, Devbox, and more |
| MCP Servers | 21 | GitHub, GitLab, Filesystem, Playwright, Chrome DevTools, Postgres, SQLite, Memory, Excalidraw, Brave Search, Context7, Google Maps, and more |
| LSP Servers | 13 | gopls, rust-analyzer, tsserver, pyright, omnisharp, yaml, marksman, taplo, lua, zls, bash, dockerfile, css/html/json |
| Plugins | 15 | token-tracker, dcp, swarm, goal-mode, vibeguard, orchestrator, auto-fallback, notify, pty, snip, snippets, envsitter-guard, command-inject, ignore |
| AI Providers | 16 | DeepSeek, OpenCode, OpenAI, Anthropic, Google, xAI, Moonshot, MiniMax, MiMo, Groq, Together, Fireworks, Perplexity, Mistral, Cohere, Replicate |
| CLI Modes | 11 | full, reinit, new, health, update, upgrade, interactive, ci, fix-config, fix-zshrc, dry-run |
| Package Managers | 6 | apt, dnf, pacman, apk, zypper, brew |

### v1.1.0 — Ecosystem Expansion

Hardware auto-detection (multi-vendor GPU/NPU), LiteLLM OpenAI-compatible API gateway, SearXNG self-hosted web search with sanitizer proxy, CI/CD headless mode, multimodal support (whisper.cpp, stable-diffusion.cpp, llava), 16 LLM providers with dynamic registration, chezmoi dotfiles manager, Devbox Nix-based environments, ONNX runtime.

## Architecture

```
opencode_initializer/
├── setup.sh                  # Orchestrator (352 lines)
├── dev.sh                    # CLI: dev install|remove|update|health|list|config
├── opencode.json             # Generated OpenCode multi-provider config
├── src/
│   ├── lib/                  # 29 functional modules + 3 infra
│   │   ├── helpers.sh        # _curl, _retry, _npm_install infrastructure
│   │   ├── 00-core.sh        # OS/PKG/ARCH detection, mirrors, progress tracking
│   │   ├── 01-system.sh      # System packages (cross-distro: apt/dnf/pacman/apk/zypper/brew)
│   │   ├── 02-docker.sh      # Docker Engine
│   │   ├── 03-chrome.sh      # Google Chrome + ChromeDriver (WSL2-aware)
│   │   ├── 04-zsh.sh         # Zsh + Oh My Zsh + Powerlevel10k + 14 plugins
│   │   ├── 05-java.sh        # Java 25 (Adoptium) + Zig
│   │   ├── 06-node.sh        # Node.js 24 (n)
│   │   ├── 07-python.sh      # Python 3.14 + uv
│   │   ├── 08-go.sh          # Go 1.26
│   │   ├── 09-rust.sh        # Rust 1.96 (rustup)
│   │   ├── 10-dotnet.sh      # .NET 10
│   │   ├── 11-opencode.sh    # OpenCode CLI 1.17 + Bun 1.3
│   │   ├── 12-mcp-lsp.sh     # 21 MCP + 15 plugins + 13 LSP + Muninn
│   │   ├── 13-chromadb.sh    # ChromaDB vector database + systemd service
│   │   ├── 14-shokunin.sh    # Shokunin + Superpowers + Caveman skills
│   │   ├── 15-security.sh    # Trivy, Qodana
│   │   ├── 16-llm.sh         # Ollama, vLLM, SGLang, Open WebUI, WasmEdge (GPU-aware)
│   │   ├── 17-project.sh     # Project structure (AGENTS.md, WAL, docker-compose)
│   │   ├── 18-opencode-json.sh  # opencode.json generation (Python inline, bun bin paths)
│   │   ├── 19-finalize.sh    # Git config, PATH, .zshrc, auth, verification (36 checks)
│   │   ├── 20-autoupdate.sh  # topgrade + systemd weekly timer + unattended-upgrades + abtop
│   │   ├── 21-rag.sh         # RAG System — Corporate Knowledge Assistant (ETL + proxy + Qdrant + Gemma)
│   │   ├── 22-mise.sh        # mise-en-place universal tool version manager
│   │   ├── 22-webui-service.sh  # Open WebUI systemd user service
│   │   ├── 23-just.sh        # just task runner with default justfile
│   │   ├── 24-websearch.sh   # SearXNG web search + sanitizer proxy
│   │   ├── 25-litellm.sh     # LiteLLM OpenAI-compatible local API gateway
│   │   ├── 26-providers.sh   # 16 LLM provider registry with session switching
│   │   ├── 27-dotfiles.sh    # chezmoi dotfiles manager for team config sharing
│   │   ├── 28-devbox.sh      # Devbox — Nix-based isolated dev environments
│   │   ├── version-check.sh  # Version comparison (8+ tools)
│   │   └── pre-session-check.sh  # Pre-session provider/model validation
│   └── modes/                # 5 mode scripts (+ 6 built-in)
│       ├── ci.sh             # CI/CD headless mode
│       ├── health.sh         # Full diagnostics (65+ checks)
│       ├── fix-zshrc.sh      # .zshrc repair
│       ├── upgrade.sh        # Full system upgrade chain
│       └── interactive.sh    # Component-by-component selection
├── tests/                    # Unit, integration, and E2E test suite (193+ tests)
├── migrations/               # Timestamped, idempotent migrations
├── scripts/                  # Utility scripts (ai-router)
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
| Full | `--full` (default) | Complete bootstrap — 29 steps |
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
  -k "sk-..." \
  --deepseek-key "sk-..." \
  --xai-key "xai-..." \
  --github-token "ghp_..." \
  --gitlab-token "glpat-..."
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
dev install llm         # Add GPU/LLM support later
dev config              # Edit setup configuration
```

## Options

| Flag | Description |
|------|-------------|
| `-k, --api-key <key>` | OpenCode Go API key |
| `--deepseek-key <key>` | DeepSeek API key |
| `--xai-key <key>` | xAI Grok API key |
| `--mimo-key <key>` | Xiaomi MiMo API key |
| `--moonshot-key <key>` | Moonshot API key |
| `--minimax-key <key>` | MiniMax API key |
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
