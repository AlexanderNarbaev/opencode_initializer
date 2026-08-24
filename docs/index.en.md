# OpenCode Initializer v3.3.0

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
| Modules | 64 |
| New in v3.2 | Lynis CIS scanner + auditd kernel rules + AI Gateway proxy + pre-commit hook |
| Orchestrator | 726 lines of Bash |
| CLI modes | 12 (full, health, interactive, ci, airgap, and more) |
| Languages | 6 |
| MCP servers | 24 |
| LSP servers | 12 |
| OpenCode plugins | 21 |
| AI providers | 22 (19 cloud + 3 local) |
| Model Router | 9 task profiles (coding, reasoning, fast, agentic, budget, vision, isolated, ru_cn, testing) |
| Infrastructure | 7 services (PostgreSQL, Qdrant, Redis, Prometheus, Grafana, Node Exporter, MemoryLayer) |
| Web GUI | 9 management sections (port 4200) |
| Test suite | 268 checks (85 unit + 6 integration + 5 e2e) |
| Package managers | apt, dnf, pacman, apk, zypper, brew |
| Architectures | amd64, arm64 |

## What is it?

A single script that turns a fresh Linux/WSL2 machine into a production-ready development environment:

- **6 programming languages** — Java 25, Node.js 24, Python 3.14, Go 1.26, Rust (stable), .NET 10
- **24 MCP servers** — GitHub, GitLab, Filesystem, Playwright, Chrome DevTools, SQLite, Postgres, Memory, Excalidraw, Brave Search, Context7, Google Maps, and more
- **21 OpenCode plugins** — codegraph, dcp, auto-fallback, goal-mode, swarm, vibeguard, devcontainers, worktree, scheduler, background-agents, goal-plugin, conductor, zellij-namer, morph-plugin, supermemory, websearch-cited, firecrawl, plugin-otel, token-tracker, orchestrator, daytona
- **12 LSP servers** — gopls, rust-analyzer, typescript, pyright, yaml, marksman, taplo, bash, dockerfile, css, html, json
- **Infrastructure as Code** — PostgreSQL, Qdrant, Redis, Prometheus, Grafana, Node Exporter, MemoryLayer via Docker Compose
- **Cockpit TUI** — 8-tab terminal UI for server management
- **Isolated Circuit Mode** — air-gapped LLM operation with local backends
- **22 AI providers** — DeepSeek, z.ai GLM-5.2, OpenRouter, OpenAI, Anthropic, Google, xAI, MiniMax M3, Alibaba Qwen3, and more
- **GPU/LLM** — Ollama, vLLM, SGLang, Open WebUI, WasmEdge (multi-vendor GPU auto-detection)
- **ZSH** — Oh My Zsh + Powerlevel10k with 14 plugins
- **Chrome** — Google Chrome + ChromeDriver (WSL2-optimized)
- **Auto-update** — systemd weekly timer + topgrade

## What's New in v3.3.0

| Feature | Description |
|---------|-------------|
| Daytona Environments | `61-daytona.sh` + `daytona-env`: current-platform CLI, declarative environments registry, commands AND config-file setup |
| Skills Audit | `dev skills`: installed-vs-registered drift, oversize/stale detection, usage evidence from recent logs |
| Context Budget | `dev context`: per-model context limits from routing.json SSOT, usage vs THE session model's max, WARN 77% / ACT 90% |
| Docs IA | i18n parity gate in CI, zero nav orphans, Operations & Working Documents sections |

## What's New in v3.0.0

| Feature | Description |
|---------|-------------|
| SDD-native AI Harness | Full SDD lifecycle: constitution → specify → clarify → plan → tasks → implement → verify |
| Model Governance | `model-policy.json` — provider/model allowlist/blocklist, 3 modes, audit log |
| PII Sanitizer | 9 detectors (email, phone, INN, SNILS, passport, credit card, IP, API key) — pre-LLM gate |
| Audit Trail | 7 WAL event types, SHA-256 hash-chain, rotation >10MB → gzip+Qdrant |
| Air-Gap Completeness | `--airgap` mode, `dev bundle create\|list\|verify`, SHA-256 manifest |
| Supply-Chain Hardening | 6 `curl\|sh` replaced with download→verify SHA256 |
| 4 Deployment Profiles | personal, corporate, airgapped, hybrid — enforced rules per profile |
| 7 New Modules | 41-constitution, 42-hooks, 43-governance, 44-audit, 45-pii-guard, 46-offline-bundle, pii-guard.py |

## What's New in v2.0.0

| Feature | Description |
|---------|-------------|
| Infrastructure as Code | PostgreSQL + Qdrant + Redis + Prometheus + Grafana + Node Exporter + MemoryLayer via Docker Compose |
| Cockpit TUI | 8-tab terminal UI — Services, Plugins, GPU/Models, Sessions, Tasks, Logs, Infra, Grafana |
| Isolated Circuit Mode | Air-gapped LLM operation with Ollama, vLLM, SGLang |
| Model Routing Intelligence | 8 task profiles: coding, reasoning, fast, agentic, budget, vision, isolated, ru_cn |
| Web GUI | 9-section management interface: providers, models, MCP/LSP, infra, backup, logs |
| z.ai GLM-5.2 | Primary provider for RU/CN markets, OpenAI-compatible, free tier |
| OpenRouter | Aggregator access to 100+ models via single API key |
| Alibaba Qwen3.7 | Native SDK, latest Qwen model |
| DeepInfra | Fast inference, competitive pricing |
| MemoryLayer | AI memory system with Ollama embed proxy (mxbai-embed-large) |
| Observability | Prometheus + Grafana with auto-provisioned dashboards |
| Corporate Proxy | HTTP_PROXY, HTTPS_PROXY, CURL_CA_BUNDLE support |
| Config Backup | `dev backup create\|list\|restore` for disaster recovery |
| Model Download | `dev models install <model>` for local Ollama models |
| 22 providers | 19 cloud + 3 local (was 16 in v1.1.0) |
| Provider Check | \`bash scripts/provider-check.sh\` to verify provider connectivity |
| .env.example | Template with all 20 API key variables |
| 64 modules | Was 29 in v1.1.0, 42 in v2.0.0 |

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
| **Languages** | Java 25, Node.js 24, Python 3.14 + uv, Go 1.26, Rust (stable), .NET 10 |
| **Shell** | Zsh 5.8+, Oh My Zsh, Powerlevel10k, 14 plugins |
| **Browser** | Google Chrome, ChromeDriver (WSL2-aware) |
| **Containers** | Docker Engine |
| **Infrastructure** | PostgreSQL, Qdrant, Redis, Prometheus, Grafana, Node Exporter, MemoryLayer |
| **AI/ML** | Ollama, vLLM, SGLang, Open WebUI, ChromaDB, WasmEdge, ONNX |
| **Web Search** | SearXNG self-hosted search + sanitizer proxy |
| **MCP Servers** | 24 servers for AI-assisted development |
| **LSP Servers** | 12 language servers |
| **Plugins** | 21 OpenCode productivity plugins |
| **Security** | Trivy, Qodana |
| **Utilities** | bat, btm, fd, ripgrep, sd, typos, topgrade, just, mise |
| **Dotfiles** | chezmoi for team config sharing |
| **Dev Environments** | Devbox — Nix-based isolated envs |
| **Cockpit** | 8-tab TUI for server management |
| **Agent Harness** | DeepSeek Harness (dsh) — plugin-based agent harness |
| **Sandboxed Agents** | Sandcastle — isolated AI coding agents (Docker/Podman/Vercel) |
| **Desktop App** | OpenCode Desktop — native GUI (.deb/.rpm/AppImage) |

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
| Health | `--health` | Full diagnostics (128+ checks) |
| Update | `--update` | Update installed tools |
| Upgrade | `--upgrade` | Full system upgrade chain |
| Interactive | `--interactive` | Pick components individually |
| Fix Config | `--fix-config` | Regenerate opencode.json |
| Fix ZSH | `--fix-zshrc` | Repair shell configuration |
| Dry Run | `--dry-run` | Preview without changes |

## Documentation

- [Getting Started](getting-started/index.md) — beginner-friendly installation guide
- [User Guide](user-guide/index.md) — day-to-day usage
- [Advanced Guide](advanced/index.md) — customization, WSL2, GPU setup
- [Architecture](architecture/index.md) — C4 diagrams, module reference
- [Reference](reference/index.md) — CLI, opencode.json schema, MCP/LSP catalog
- [Contributing](contributing/index.md) — how to help
- [FAQ](faq/index.md) — common questions
- [Team Setup](guides/team-setup.md) — onboarding guide for teams

## Community

- :fontawesome-brands-github: [GitHub](https://github.com/AlexanderNarbaev/opencode_initializer)
- :fontawesome-brands-git: [GitVerse Mirror](https://gitverse.ru/AlexandrNarbaev/opencode_initializer)
- [Report a bug](https://github.com/AlexanderNarbaev/opencode_initializer/issues/new?template=bug_report.md)
- [Request a feature](https://github.com/AlexanderNarbaev/opencode_initializer/issues/new?template=feature_request.md)
- [Contributing Guide](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/CONTRIBUTING.md)

## License

MIT — see [LICENSE](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/LICENSE).
