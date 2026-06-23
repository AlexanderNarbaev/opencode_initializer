# :fontawesome-solid-rocket: OpenCode Initializer

[![GitHub stars](https://img.shields.io/github/stars/AlexanderNarbaev/opencode_initializer?style=social)](https://github.com/AlexanderNarbaev/opencode_initializer)
[![License](https://img.shields.io/github/license/AlexanderNarbaev/opencode_initializer)](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/LICENSE)
[![ShellCheck](https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/shellcheck.yml)
[![Docs](https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/docs.yml/badge.svg)](https://alexandernarbaev.github.io/opencode_initializer/)

**Universal Dev Machine Bootstrap** — one command to set up a complete AI-enhanced development environment.

[Install](#getting-started){ .md-button .md-button--primary }
[View on GitHub :fontawesome-brands-github:](https://github.com/AlexanderNarbaev/opencode_initializer){ .md-button }

---

## :fontawesome-solid-bolt: What is it?

A single script that turns a fresh Linux/WSL2 machine into a production-ready development environment with:

- :fontawesome-solid-code: **8 programming languages** — Java 25, Node.js 24, Python 3.14, Go 1.26, Rust 1.96, .NET 10, Kotlin, Zig
- :fontawesome-solid-robot: **21 MCP servers** — GitHub, GitLab, Filesystem, Git, SQLite, Postgres, Docker, Chrome DevTools, Sequential Thinking, Memory, Puppeteer, Fetch, Time, Redis, Slack, Everything, Google Maps, Sentry, and more
- :fontawesome-solid-puzzle-piece: **15+ OpenCode plugins** — token-tracker, dcp, swarm, goal-mode, vibeguard, orchestrator, notify, pty, snip, snippets, envsitter-guard, command-inject, ignore, auto-fallback
- :fontawesome-solid-gears: **13 LSP servers** — gopls, rust-analyzer, tsserver, pyright, omnisharp, yaml, marksman, taplo, lua, zls, bash, dockerfile, css/html/json
- :fontawesome-solid-box: **Infrastructure** — Docker, ChromaDB, Muninn, GPU/LLM (Ollama, vLLM, SGLang, Open WebUI)
- :fontawesome-solid-terminal: **ZSH** + Oh My Zsh + Powerlevel10k with 18 plugins
- :fontawesome-solid-globe: **Google Chrome** + ChromeDriver (WSL2-aware)
- :fontawesome-solid-clock-rotate-left: **Auto-update** via systemd weekly timer + topgrade

## :fontawesome-solid-download: Quick Install

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

## :fontawesome-solid-list-check: What gets installed

| Category | Tools |
|----------|-------|
| **Languages** | Java 25, Node.js 24, Python 3.14, Go 1.26, Rust 1.96, .NET 10, Zig |
| **Shell** | Zsh 5.8+, Oh My Zsh, Powerlevel10k, 18 plugins |
| **Browser** | Google Chrome, ChromeDriver |
| **Containers** | Docker Engine |
| **AI/ML** | Ollama, vLLM, SGLang, Open WebUI, ChromaDB |
| **MCP Servers** | 21 servers for AI-assisted development |
| **LSP Servers** | 13 language servers |
| **Plugins** | 15+ OpenCode productivity plugins |
| **Security** | Trivy, Qodana |
| **Utilities** | bat, btm, fd, ripgrep, sd, typos, topgrade |

## :fontawesome-solid-globe: Supported Platforms

| OS | Status |
|----|--------|
| Ubuntu 22.04/24.04 | :fontawesome-solid-check: Fully supported |
| Debian 12 | :fontawesome-solid-check: Fully supported |
| Fedora 40+ | :fontawesome-solid-check: dnf backend |
| Arch Linux | :fontawesome-solid-check: pacman backend |
| Alpine Linux | :fontawesome-solid-check: apk backend |
| openSUSE | :fontawesome-solid-check: zypper backend |
| macOS | :fontawesome-solid-check: brew backend |
| WSL2 | :fontawesome-solid-check: Optimized (DNS fix, memory limits) |

## :fontawesome-solid-book: Documentation

- [Getting Started](getting-started/) — beginner-friendly installation guide
- [User Guide](user-guide/) — day-to-day usage
- [Advanced Guide](advanced/) — customization, WSL2, GPU setup
- [Architecture](architecture/) — C4 diagrams, module reference
- [Reference](reference/) — CLI, opencode.json schema
- [Contributing](contributing/) — how to help
- [FAQ](faq/) — common questions

## :fontawesome-solid-heart: Community

- :fontawesome-brands-github: [GitHub](https://github.com/AlexanderNarbaev/opencode_initializer)
- :fontawesome-solid-bug: [Report a bug](https://github.com/AlexanderNarbaev/opencode_initializer/issues/new?template=bug_report.md)
- :fontawesome-solid-lightbulb: [Request a feature](https://github.com/AlexanderNarbaev/opencode_initializer/issues/new?template=feature_request.md)
- :fontawesome-solid-book: [Contributing Guide](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/CONTRIBUTING.md)

## :fontawesome-solid-scale-balanced: License

MIT — see [LICENSE](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/LICENSE).

---

:fontawesome-solid-star: **Star us on GitHub** if this project saved you time!
