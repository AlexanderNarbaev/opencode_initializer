# Changelog

All notable changes to opencode_initializer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0-alpha] — 2026-06-29

### Added
- `30-infra.sh`: Infrastructure provisioning — PostgreSQL + Qdrant + Redis via Docker Compose
- `31-cockpit.sh`: Cockpit C++ server management daemon (build + systemd service)
- Go apt fallback in `08-go.sh`: if direct download fails, use ppa:longsleep/golang-backports
- Unit tests: `tests/unit/test_infra.sh`, `tests/unit/test_cockpit.sh`

### Changed
- Module count: 29 → 35
- AGENTS.md: Phase 0-4 plan, new module entries, IaC design decision, v2.0.0-alpha header

## [Unreleased]

### Added
- GPU workload benchmarks for backend selection tuning
- Cross-platform CI matrix expansion (macOS, ARM)

## [1.1.0] — 2026-06-26

### Added
- **Hardware auto-detection**: multi-vendor GPU (NVIDIA, AMD ROCm, Intel Arc) + NPU (Ryzen AI, Meteor Lake) + Apple Silicon detection
- **LiteLLM API Gateway**: OpenAI-compatible `/v1` endpoint unifying Ollama, vLLM, SGLang backends with auto-routing and fallback chains
- **SearXNG Web Search**: self-hosted private search engine + sanitizer proxy (strips internal hosts/IP/PII)
- **CI/CD Headless Mode**: `--ci` flag for lightweight OpenCode CLI + essential MCPs (5 steps, no GUI, no Docker, no ZSH)
- `22-webui-service.sh`: Open WebUI systemd user service for auto-start on login
- `23-just.sh`: just task runner with default justfile
- `24-websearch.sh`: SearXNG + sanitizer proxy
- `25-litellm.sh`: LiteLLM OpenAI-compatible local API gateway
- `26-providers.sh`: 15+ LLM provider registry (OpenAI, Anthropic, Google, Mistral, Groq, Together, Cohere, Fireworks, Cerebras, Perplexity) with session switching
- `27-dotfiles.sh`: chezmoi dotfiles manager for team config sharing
- `28-devbox.sh`: Devbox Nix-based isolated dev environments
- `22-mise.sh`: mise-en-place universal tool version manager
- WebUI auto-install via `uv tool install open-webui` (Docker-less alternative)
- Multimodal support: whisper.cpp (speech-to-text), stable-diffusion.cpp (image generation), llava (vision)
- Multiple interaction modes: TUI (terminal UI), JSON output, RPC server, Python SDK
- ONNX Runtime cross-platform model portability
- Env-var substitution for token/credential propagation
- `--mimo-key`, `--moonshot-key`, `--minimax-key` CLI flags
- `--gitlab-token`, `--gitverse-token`, `--google-maps-key` CLI flags
- RAG System module (`21-rag.sh`) as optional component
- Architecture-aware LSP downloads (arm64 + amd64)

### Changed
- Module count: 24 → 33 (21-rag, 22-mise, 22-webui-service, 23-just, 24-websearch, 25-litellm, 26-providers, 27-dotfiles, 28-devbox)
- Step count: 23 → 29 in orchestrator
- `16-llm.sh`: rewritten with multi-vendor GPU/NPU detection and optimal backend selection
- Health checks: 60+ → 65+

### Fixed
- ChromaDB systemd service: proper working directory and restart policy
- Ollama systemd service: WantedBy=default.target for auto-start
- Open WebUI: runs as systemd user service, survives reboots
- Version consistency: all files now v1.1.0
- CI test.yml: fixed paths `lib/` → `src/lib/`, `modes/` → `src/modes/`
- Removed dangling `WALEOF` word in 17-project.sh
- `sudo apt-get` → `_sudo` in 05-java.sh
- `cmd.exe` proxy detection guarded behind WSL check
- `return 1` crash in 15-security.sh replaced with safe `return 0`
- All curl calls: added `--retry 3 --retry-delay 2`
- Secrets: added GITLAB_TOKEN, GITVERSE_TOKEN, GOOGLE_MAPS_KEY
- topgrade systemd service: flexible path detection
- 17-project.sh backup dir `~/agi` → `~/projects`

## [1.0.0] — 2026-06-22

### Added
- Initial public release of OpenCode Initializer
- 8 programming languages (Java 25, Node.js 24, Python 3.14, Go 1.26, Rust 1.96, .NET 10, Kotlin, Zig)
- 21 MCP servers for AI-assisted development
- 15+ OpenCode plugins (token-tracker, dcp, swarm, goal-mode, vibeguard, orchestrator, notify, pty, snip, snippets, envsitter-guard, command-inject, ignore, auto-fallback)
- 13 LSP servers (gopls, rust-analyzer, tsserver, pyright, omnisharp, yaml, marksman, taplo, lua, zls, bash, dockerfile, css/html/json)
- Infrastructure: Docker, ChromaDB + Muninn, GPU/LLM runtimes (Ollama, vLLM, SGLang, Open WebUI)
- ZSH + Oh My Zsh + Powerlevel10k with 18 plugins
- Google Chrome + ChromeDriver (WSL2-aware)
- CLI `dev` tool for post-install management
- Auto-update via systemd weekly timer + topgrade
- Cross-distro support (apt/dnf/pacman/apk/zypper/brew)
- Russian mirrors for network-constrained environments
- Progress tracking with retry logic and exponential backoff
- WSL2 optimization (DNS fix, memory limits, mirrored networking)
- Comprehensive test suite (unit, integration, E2E)
- ShellCheck CI on every push/PR
- Full open source documentation (README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, CHANGELOG)
- GitVerse mirror

[Unreleased]: https://github.com/AlexanderNarbaev/opencode_initializer/compare/v1.1.0...main
[1.1.0]: https://github.com/AlexanderNarbaev/opencode_initializer/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/AlexanderNarbaev/opencode_initializer/releases/tag/v1.0.0
