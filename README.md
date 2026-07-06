# OpenCode Initializer v2.0.0

<p align="center">
  <b>One-command AI-enhanced development environment setup for WSL2, Linux, and macOS.</b><br>
  <sub>583-line orchestrator · 40 modules · 11 modes · 24 MCPs · 15 plugins · 13 LSPs · 24 providers · model routing · GUI · metrics</sub>
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

One command installs everything: 8 languages, 40 infrastructure modules, 24 MCP servers, 15 OpenCode plugins, 13 LSP servers, 24 AI providers, infrastructure as code (PostgreSQL + Qdrant + Redis + Prometheus + Grafana + Node Exporter + MemoryLayer), Cockpit TUI (8 tabs), Web GUI, Isolated Circuit Mode, hardware auto-detection, LiteLLM API gateway, and SearXNG web search.

[Full Documentation](https://alexandernarbaev.github.io/opencode_initializer/)

## Feature Grid

| Category | Count | Details |
|----------|-------|---------|
| Languages | 8 | Java 25, Node.js 24, Python 3.14, Go 1.26, Rust 1.96, .NET 10, Kotlin, Zig |
| Modules | 40 | System, Docker, Chrome, ZSH, 7 languages, OpenCode, MCP/LSP, ChromaDB, LLM, RAG, LiteLLM, SearXNG, providers, dotfiles, Devbox, Infra, Cockpit, Isolated Circuit, Services, Observability, GUI, Model Router, WAL, and more |
| MCP Servers | 24 | GitHub, GitLab, Filesystem, Playwright, Chrome DevTools, Postgres, SQLite, Memory, Excalidraw, Brave Search, Context7, Google Maps, and more |
| LSP Servers | 13 | gopls, rust-analyzer, tsserver, pyright, omnisharp, yaml, marksman, taplo, lua, zls, bash, dockerfile, css/html/json |
| Plugins | 15 | token-tracker, dcp, swarm, goal-mode, vibeguard, orchestrator, auto-fallback, notify, pty, snip, snippets, envsitter-guard, command-inject, ignore |
| AI Providers | 24 | DeepSeek, OpenCode, **z.ai GLM-5.2**, **OpenRouter**, OpenAI, Anthropic Claude 4, Google Gemini, xAI Grok 4, Moonshot Kimi K2, MiniMax, MiMo, **Alibaba Qwen3**, **DeepInfra**, Groq, Together, Fireworks, Perplexity, Mistral, Cohere, Cerebras + 4 local (Ollama, LiteLLM, vLLM, SGLang) |
| Model Router | 8 profiles | coding, reasoning, fast, agentic, budget, vision, isolated, ru_cn |
| CLI Modes | 11 | full, reinit, new, health, update, upgrade, interactive, ci, fix-config, fix-zshrc, dry-run |
| Infrastructure | 7 | PostgreSQL, Qdrant, Redis, Prometheus, Grafana, Node Exporter, MemoryLayer |
| Observability | Full stack | Prometheus metrics, Grafana dashboards, OpenCode metrics exporter, Node Exporter system metrics |
| GUI | Web | Provider status, model manager, model router, MCP/LSP management, infra monitoring, Grafana iframe, backup, Isolated Circuit toggle |
| Package Managers | 6 | apt, dnf, pacman, apk, zypper, brew |

### v2.0.0 — Infrastructure as Code + Isolated Circuit + Observability

- **Infrastructure as Code**: PostgreSQL + Qdrant + Redis + Prometheus + Grafana + Node Exporter + MemoryLayer via Docker Compose
- **Cockpit TUI**: 8-tab terminal UI (Services, Plugins, GPU/Models, Sessions, Tasks, Logs, Infra, Grafana)
- **Web GUI**: Full management dashboard on port 4200 with Metrics iframe, model switching, infrastructure control
- **Isolated Circuit Mode**: Air-gapped LLM operation with local OpenAI-compatible backends (Ollama, LiteLLM, vLLM, SGLang)
- **z.ai GLM-5.2**: Primary provider for RU/CN markets, OpenAI-compatible API, free tier
- **OpenRouter**: Aggregator access to 100+ models via single API key
- **OpenCode Metrics**: Real-time Prometheus exporter on port 9464 — sessions, WAL entries, container health, Ollama models, active configuration
- **Node Exporter**: System-level metrics (CPU, RAM, disk, uptime) scraped by Prometheus
- **Grafana Dashboards**: Infrastructure overview + Agent performance — auto-provisioned
- **Port Auto-Detection**: Automatic port conflict resolution with shifting — env var overrides for all services
- **Deployment Profiles**: personal / corporate / airgapped / hybrid with per-service mode control (local/external/disabled)
- **Unified Service Layer**: Single configuration point for all 18 infrastructure services via `setup.conf`
- **External Service Support**: Point any component to external URLs — corporate OTel, existing Grafana, managed databases
- **MemoryLayer**: AI memory system with Ollama embed proxy (mxbai-embed-large, 1024-dim)

## Architecture

```
opencode_initializer/
├── setup.sh                  # Orchestrator (583 lines)
├── dev.sh                    # CLI: dev install|remove|update|health|metrics|observability|isolated|...
├── opencode.json             # Generated OpenCode multi-provider config (24 providers)
├── src/
│   ├── lib/                  # 40 modules (35 numbered + 5 infra)
│   │   ├── helpers.sh        # _curl, _retry, _npm_install infrastructure
│   │   ├── 00-core.sh        # OS/PKG/ARCH detection, mirrors, progress, ISOLATED_CIRCUIT, port resolution
│   │   ├── 01-system.sh      # System packages (cross-distro: apt/dnf/pacman/apk/zypper/brew)
│   │   ├── ...               # 02-29: Languages, tools, infrastructure
│   │   ├── 30-infra.sh       # Infrastructure: PostgreSQL + Qdrant + Redis + Prometheus + Grafana + Node Exporter + MemoryLayer
│   │   ├── 31-cockpit.sh     # Cockpit TUI server management daemon (8-tab)
│   │   ├── 32-isolated.sh    # Isolated Circuit Mode — air-gapped LLM
│   │   ├── 33-services.sh    # Unified Service Layer — port resolution, service modes, deployment profiles
│   │   ├── 34-observability.sh  # Prometheus + Grafana observability stack + OTel
│   │   ├── 35-gui.sh         # Web GUI (Node.js, port 4200)
│   │   ├── 36-model-router.sh   # Model routing intelligence (8 task profiles, cost table)
│   │   ├── 37-wal.sh         # Write-Ahead Log — setup + agent session journal
│   │   ├── version-check.sh  # Version comparison (8+ tools)
│   │   └── pre-session-check.sh  # Pre-session provider/model validation
│   ├── cockpit/               # Go TUI source (BubbleTea framework)
│   ├── gui/                   # Web GUI (Node.js server + HTML dashboard)
│   ├── grafana/               # Grafana provisioning (datasources + dashboards)
│   ├── systemd/               # Systemd user units (opencode-metrics.service)
│   └── modes/                 # 5 mode scripts (+ 6 built-in)
├── scripts/                   # Utilities
│   ├── oc-metrics.py          # OpenCode Prometheus metrics exporter (:9464)
│   ├── oc-sdk.py              # Python SDK
│   ├── embed-proxy.py         # Ollama → MemoryLayer embedding bridge
│   └── ai-router/             # Model routing intelligence
├── tests/                     # Unit (12), integration (5), E2E (4) — 398+ assertions
├── migrations/                # Timestamped, idempotent migrations
├── docs/                      # MkDocs Material documentation site (EN/RU)
├── .github/                   # CI workflows (test, shellcheck, build, security, docs)
└── CHANGELOG.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, LICENSE
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
| Fix Config | `--fix-config` | Regenerate opencode.json only |
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

### Deployment Profiles

```bash
# Corporate environment — point to existing infrastructure
DEPLOYMENT_PROFILE=corporate \
  POSTGRES_MODE=external POSTGRES_EXTERNAL_URL=pg.internal:5432 \
  GRAFANA_MODE=external EXTERNAL_GRAFANA_URL=https://grafana.company.com \
  PROMETHEUS_MODE=external EXTERNAL_PROMETHEUS_URL=https://prom.internal:9090 \
  OTEL_EXPORTER_ENABLED=true OTEL_EXPORTER_ENDPOINT=otel-collector:4317 \
  bash setup.sh --full

# Air-gapped — local LLMs only
bash setup.sh --full --isolated
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

# Observability
dev observability status    # Prometheus + Grafana status
dev observability reload    # Regenerate prometheus.yml + restart
dev metrics start           # Start metrics exporter
dev metrics status          # View real-time metrics

# Infrastructure
dev infra up                # Start all Docker services
dev infra status            # Container health overview
dev infra down              # Stop all services

# Isolated Circuit (air-gapped LLM)
dev isolated on              # Enable local-only mode
dev isolated status          # Check current state

# Model Management
dev models coding            # Get model recommendation for coding
dev models install qwen3:32b # Download local model
dev models list-local        # List installed local models

# GUI & Cockpit
dev gui start                # Start Web GUI (http://localhost:4200)
cockpit                      # Launch TUI (or run 'dev install cockpit')

# Backup
dev backup create            # Backup all configs
dev backup list              # Show available backups
dev backup restore <file>    # Restore from backup

# Add components later
dev install llm              # Add GPU/LLM support
dev install docker           # Install Docker Engine
```

## Observability Stack

### Components

| Component | Port | Description | Auto-Start |
|-----------|------|-------------|------------|
| **Prometheus** | 9090 | Metrics collection & storage | systemd `opencode-infra.service` |
| **Grafana** | 3001 | Dashboards (infrastructure + agent performance) | systemd `opencode-infra.service` |
| **Node Exporter** | 9100 | System metrics (CPU, RAM, disk, uptime) | Docker `unless-stopped` |
| **OpenCode Metrics** | 9464 | Sessions, WAL, containers, models, config | systemd `opencode-metrics.service` |

### Dashboards

- **Infrastructure Overview** (`/d/opencode-infra`): Container status, PostgreSQL connections, Redis memory, Qdrant collections, service uptime
- **Agent Performance** (`/d/opencode-tokens`): Token usage, cost estimates, active sessions, model distribution, provider costs

### Access

```bash
# Web GUI Metrics tab
http://localhost:4200  →  Metrics tab (Grafana iframe)

# Cockpit TUI
cockpit → Tab 8 (Grafana) → Press 'o' to open in browser

# Direct
http://localhost:3001  →  Grafana (admin/admin)
http://localhost:9090  →  Prometheus
http://localhost:9464/metrics  →  OpenCode metrics
```

## Port Management

All service ports are configurable via environment variables or `~/.config/opencode-setup/setup.conf`:

```bash
# Override default ports
POSTGRES_PORT=5433
GRAFANA_PORT=3002
METRICS_EXPORTER_PORT=9465

# Or use auto-detection (set to 0)
POSTGRES_PORT=0   # Finds first free port ≥ 5432

# Service modes
POSTGRES_MODE=external  POSTGRES_EXTERNAL_URL=pg.internal:5432
REDIS_MODE=disabled
```

## Options

| Flag | Description |
|------|-------------|
| `-k, --api-key <key>` | OpenCode Go API key |
| `--deepseek-key <key>` | DeepSeek API key |
| `--isolated` | Enable Isolated Circuit Mode (local LLM only) |
| `--zai-key <key>` | z.ai GLM API key |
| `--openrouter-key <key>` | OpenRouter API key |
| `--alibaba-key <key>` | Alibaba Qwen API key |
| `--deepinfra-key <key>` | DeepInfra API key |
| `--with-observability` | Enable Prometheus + Grafana |
| `--with-grafana` | Enable Grafana dashboards |
| `--with-prometheus` | Enable Prometheus monitoring |
| `--with-all-infra` | Enable all infrastructure services |
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
- **Port auto-detection**: Collision-safe port assignment with automatic shifting
- **WSL2 optimization**: DNS fix, memory limits, mirrored networking, .wslconfig tuning
- **Dry-run mode**: Preview all changes without executing them
- **Isolated Circuit**: Air-gapped LLM operation with auto-detection of local backends
- **Deployment profiles**: Pre-configured behaviors for personal, corporate, airgapped, and hybrid environments

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
- Metrics exporter binds to 127.0.0.1 (local only)
- Systemd services run as user (no root)
- MIT licensed

## Documentation

- [Full Guide](https://alexandernarbaev.github.io/opencode_initializer/) — MkDocs Material site (EN/RU)
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
