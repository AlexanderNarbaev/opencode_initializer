# OpenCode Initializer · Universal Dev Machine Bootstrap

<p align="center">
  <b>One-command AI-enhanced development environment setup for WSL2, Linux, and macOS.</b>
</p>

<p align="center">
  <a href="https://github.com/AlexanderNarbaev/opencode_initializer/actions"><img src="https://img.shields.io/github/actions/workflow/status/AlexanderNarbaev/opencode_initializer/test.yml?branch=main&label=tests" alt="Tests"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/AlexanderNarbaev/opencode_initializer"><img src="https://img.shields.io/github/stars/AlexanderNarbaev/opencode_initializer?style=social" alt="GitHub stars"></a>
  <a href="https://shellcheck.net"><img src="https://img.shields.io/badge/shellcheck-passing-brightgreen.svg" alt="ShellCheck"></a>
</p>

---

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --full
```

That's it. One command installs everything — 8 programming languages, 15 MCP servers, 15 OpenCode plugins, 12 LSP servers, and AI tooling.

## What It Sets Up

### Languages & Runtimes
Java 25 · Node.js 24 · Python 3.14 + uv · Go 1.26 · Rust 1.96 · .NET 10 · Kotlin · Zig

### OpenCode Plugins (15)
| Plugin | Purpose |
|--------|---------|
| `opencode-codegraph` | Code intelligence CPG analysis |
| `opencode-token-tracker` | Token usage monitoring |
| `opencode-orchestrator` | Sub-agent orchestration |
| `opencode-dcp` | Context pruning (30-50% token savings) |
| `opencode-auto-fallback` | Model failover with retry logic |
| `opencode-goal-mode` | Completion gate enforcement |
| `opencode-swarm` | Hub-and-spoke multi-agent orchestration |
| `opencode-vibeguard` | PII/secret desensitization |
| `opencode-notify` · `opencode-pty` · `opencode-ignore` · `opencode-snip` · `opencode-snippets` | Productivity utilities |
| `envsitter-guard` · `opencode-command-inject` | Environment & command safety |

### MCP Servers (15)
| Server | Category | Type |
|--------|----------|------|
| `context7` | Documentation | Local |
| `filesystem` | File operations | Local |
| `agentic-tools` | Task management | Local |
| `codegraph` | Code intelligence | Local |
| `playwright` | Browser automation | Local |
| `agent-browser` | Web browsing | Local |
| `chrome-devtools` | Chrome DevTools Protocol | Local |
| `loopsense` | Loop prevention | Local |
| `github` | GitHub API | Local |
| `postgres` | PostgreSQL | Local |
| `sequential-thinking` | Reasoning | Local |
| `memorylayer` | Persistent memory | Local |
| `sentry` | Error monitoring | Remote |
| `grep` | Code search | Remote |
| `ollama` | Local LLM runtime | Local |

### LSP Servers (12)
gopls · rust-analyzer · typescript · pyright · omnisharp · yaml · marksman · taplo · lua · zls · bash · dockerfile · css/html/json

### Infrastructure & Tools
Docker · ChromaDB + Muninn (vector memory) · GPU/LLM runtimes (Ollama, vLLM, SGLang, Open WebUI) · ZSH + Oh My Zsh + Powerlevel10k · Google Chrome + ChromeDriver · CLI `dev` tool

### Security
- All secrets in `~/.config/opencode/secrets.env` (chmod 600)
- `open-code-dcp` + `vibeguard`: context pruning, PII filtering
- No hardcoded credentials in any file
- ShellCheck CI on every push/PR
- MIT licensed

## Installation

### Full Install (recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --full
```

### With API Keys
```bash
bash setup.sh --full \
  -k "sk-..." \
  --deepseek-key "sk-..." \
  --xai-key "xai-..." \
  --github-token "ghp_..."
```

### Interactive Mode
```bash
bash setup.sh --interactive     # Choose what to install
bash setup.sh --dry-run --full  # Preview without changes
```

### Post-Install CLI
```bash
dev health              # Full system diagnostics (60+ checks)
dev list                # List installed components
dev update              # Update everything + migrations
dev self-update         # Update the installer itself
dev version-check       # Check installed vs latest versions
dev install llm         # Add GPU/LLM support later
dev config              # Edit setup configuration
```

## Modes

| Mode | Description |
|------|-------------|
| `--full` | Complete installation (default) |
| `--reinit` | Reinstall tools, preserve data |
| `--new <dir>` | Initialize new project only |
| `--health` | Diagnostics (60+ checks) |
| `--update` | Update installed tools |
| `--upgrade` | Full system upgrade chain |
| `--interactive` | Component-by-component selection |
| `--fix-config` | Regenerate opencode.json |
| `--fix-zshrc` | Repair shell configuration |
| `--dry-run` | Preview mode, no changes |

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
| `-s, --sudo-pass <pass>` | Sudo password (cached) |
| `-p, --project-dir <dir>` | Project directory (default: ~/projects) |
| `-n, --git-name <name>` | Git user name |
| `-e, --git-email <email>` | Git user email |

## Architecture

```
opencode_initializer/
├── setup.sh              # Orchestrator (284 lines)
├── dev.sh                # CLI: dev install|remove|update|health|list|config
├── opencode.json         # OpenCode multi-provider config
├── src/
│   ├── lib/              # 24 modules
│   │   ├── helpers.sh    # _curl, _retry, _npm_install infrastructure
│   │   ├── 00-core.sh    # OS/PKG/ARCH detection, mirrors, progress tracking
│   │   ├── 01-system.sh  # System packages (cross-distro)
│   │   ├── ...
│   │   └── 20-autoupdate.sh # topgrade + systemd timer
│   └── modes/            # 4 + 6 built-in modes
│       ├── health.sh     # Diagnostics (60+ checks)
│       ├── fix-zshrc.sh  # .zshrc repair
│       ├── upgrade.sh    # Full system upgrade
│       └── interactive.sh # Component-by-component selection
├── tests/                # Unit, integration, and E2E tests
├── migrations/           # Timestamped, idempotent migrations
├── scripts/              # Utility scripts (ai-router)
├── docs/                 # Extended documentation + plans + research
├── .github/              # CI workflows, issue/PR templates
├── CHANGELOG.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── LICENSE
└── README.md
```

## Resilience

- **Progress tracking**: `~/.cache/opencode-setup/progress` records completed steps
- **Retry logic**: All curl downloads use 5 retries with exponential backoff
- **Mirror fallback**: Auto-detects inaccessible services and switches to mirrors
- **WSL2 optimization**: DNS fix, memory limits, mirrored networking
- **Dry-run mode**: Preview changes without executing them

## Russian Mirrors

Automatically falls back to mirrors when primary servers are unreachable:
- GitHub → `ghproxy.com`
- npm → `registry.npmmirror.com`
- pip → `mirror.yandex.ru`
- Go → `goproxy.cn`

## Platform Support

| Package Manager | Distributions |
|----------------|---------------|
| `apt` | Ubuntu, Debian, Mint, Pop!_OS |
| `dnf` | Fedora, RHEL, CentOS Stream |
| `pacman` | Arch, Manjaro, EndeavourOS |
| `apk` | Alpine Linux |
| `zypper` | openSUSE |
| `brew` | macOS, Linuxbrew |

Auto-detects OS and uses the correct package manager. Supports both `amd64` and `arm64` architectures.

## Requirements

- Any Linux distribution (Ubuntu 24.04+, Debian 12+, Fedora, Arch, Alpine, openSUSE) or macOS
- WSL2 (Windows 10/11)
- 10GB+ free disk space
- Sudo access

## Documentation

- [Full Guide](docs/guide.md) — detailed feature reference
- [AGENTS.md](AGENTS.md) — AI agent documentation
- [Contributing Guide](CONTRIBUTING.md)
- [Security Policy](SECURITY.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Changelog](CHANGELOG.md) — version history

## Community

- **Issues**: [GitHub Issues](https://github.com/AlexanderNarbaev/opencode_initializer/issues)
- **Discussions**: OpenCode [Discord](https://discord.gg/opencode)
- **Mirrors**: [GitVerse](https://gitverse.ru/alexander.narbayev/opencode_initializer)

## License

MIT © 2025-2026 [Alexander Narbaev](https://github.com/AlexanderNarbaev)

---

<p align="center"><sub>Built with ❤️ for developers who want their machine ready in one command.</sub></p>
