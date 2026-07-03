# Changelog

All notable changes to opencode_initializer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] — 2026-07-03

### Added
- `30-infra.sh`: Infrastructure provisioning — PostgreSQL + Qdrant + Redis + Prometheus + Grafana + MemoryLayer via Docker Compose
- `31-cockpit.sh`: Cockpit TUI server management daemon (7-tab TUI + web GUI)
- `32-isolated.sh`: **Isolated Circuit Mode** — air-gapped / offline-first LLM operation
  - Flag: `--isolated` / `--no-isolated` CLI, `ISOLATED_CIRCUIT=true` config, env var
  - Local OpenAI-compatible backends: Ollama (:11434), LiteLLM (:4000), vLLM (:8000), SGLang (:30000)
  - Auto-detection of running backends at `/v1/models`
  - Config persist: `~/.config/opencode-setup/setup.conf`
  - `dev isolated on|off|status` CLI command
  - Cockpit TUI: `[ISOLATED]` indicator in header
- **z.ai (GLM-5.2)** provider — critical for RU/CN markets, OpenAI-compatible API
- **OpenRouter** provider — aggregator access to 100+ models via single API key
- **Alibaba Qwen3** provider — native SDK in opencode
- **DeepInfra** provider — fast inference, competitive pricing
- MemoryLayer AI memory: Docker backend + Ollama embed proxy (mxbai-embed-large, 1024-dim) + systemd auto-start
- Embed proxy: `scripts/embed-proxy.py` — bridges Ollama embeddings to MemoryLayer API format
- `opencode-embed-proxy.service`: systemd user service for Ollama embedding proxy
- Observability stack: Prometheus (:9090) + Grafana (:3001) with auto-provisioning
- Go apt fallback in `08-go.sh`: if direct download fails, use ppa:longsleep/golang-backports
- Unit tests: `test_infra.sh`, `test_cockpit.sh`, `test_isolated.sh`, `test_providers.sh`, `test_observability.sh`, `test_embed_proxy.sh` (105+ new assertions)
- CI: Python syntax check, Go format check, opencode.json validity check
- Critical audit + provider/LLM ecosystem analysis (`docs/research/`)

### Changed
- Module count: 29 → 38
- Module numbering fixed: 22-mise→29-mise, 32-observability→34-observability, 33-gui→35-gui
- `26-providers.sh`: 15→20 cloud + 4 local OpenAI-compatible providers (24 total)
- `18-opencode-json.sh`: `_build_providers()` supports ISOLATED_CIRCUIT mode + z.ai/OpenRouter/Alibaba/DeepInfra
- `00-core.sh`: ISOLATED_CIRCUIT auto-load from config, version v2.0.0
- `setup.sh`: version v2.0.0, 373 lines
- opencode.json: z.ai provider added with fallback chain
- Model versions updated: Grok 3→4, Kimi K2.6→K2, Claude Sonnet→Opus
- AGENTS.md: full rewrite with all 38 modules, 24 providers, v2.0.0
- Cockpit: 7-tab TUI (F1 System, F2 Plugins, F3 GPU/Models, F4 Sessions, F5 Tasks, F6 Logs, F7 Infra) + `[ISOLATED]` indicator
- Cockpit: Web GUI foundation for remote management

### Fixed
- MemoryLayer: backend not running — deployed Docker container + Ollama embed proxy pipeline
- `test_infra.sh`: isolated from real config (uses temp dir), +4 new assertions
- `test_core.sh`: version assertion updated for v2.0.0
- `test_helpers.sh`: version assertion updated for v2.0.0
- `test_modules.sh`: line count bounds adjusted for 373-line orchestrator
- Duplicate module numbers resolved (22 and 32)

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

[Unreleased]: https://github.com/AlexanderNarbaev/opencode_initializer/compare/v2.0.0...main
[2.0.0]: https://github.com/AlexanderNarbaev/opencode_initializer/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/AlexanderNarbaev/opencode_initializer/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/AlexanderNarbaev/opencode_initializer/releases/tag/v1.0.0
