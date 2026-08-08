# Changelog

All notable changes to opencode_initializer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.3] — 2026-08-08

### Fixed
- **Plugins regression on clean install** — 17-project.sh now writes default `~/.config/opencode/plugins.json` with 25 plugins in tiers (5 always / 9 conditional / 11 on-demand) when registry is absent
- **Missing v2.0.2 migration** — new `migrations/20260808-v2.0.2-remove-moonshot.sh`: stops kimi-proxy/litellm systemd services, pipx uninstall, config cleanup, opencode.json regeneration
- **Sudo password CLI flag deprecated** — `-s`/`--sudo-pass` marked deprecated; `SUDO_PASS` env var as preferred path; docs updated (ru+en)
- **macOS grep -P + bash4 support** — all `grep -oP` (PCRE) patterns migrated to `grep -oE` (ERE) with `sed`/`awk` fallbacks across 8 files; macOS requirements documented in README + AGENTS.md
- **Trivy CI exit-code** — `.github/workflows/security.yml`: blocking job with `exit-code: '1'` + non-blocking advisory job with `continue-on-error: true`
- **OPencode_* env naming unified** — canonical `OPENCODE_*` prefix with `OPencode_*` as deprecated backward-compat fallback across 5 modules
- **Uncovered module tests** — 9 new test files: java, chromadb, rag, dotfiles, mise, best-practices, upstream-sync, sync-providers (Python), sync-agents (Python)
- **Health mode coverage** — +2 new checks: model router, embed proxy; total 128+ checks in 12 sections
- **dev doctor** — `cmd_doctor()` wired for pre-session provider & model validation

### Added
- `dev doctor` CLI command for pre-session checks
- macOS documentation: bash>=4 + GNU grep requirements, `declare -A` known limitation


### Security
- Sudo password no longer accepted via CLI flag (prevents `ps`/history leakage)

## [2.0.2] — 2026-08-03

### Removed
- **Moonshot/Kimi provider and kimi-proxy** — dropped along with the LiteLLM local gateway (wave v2.0.2)
  - Deleted modules `25-litellm.sh`, `39-kimi-proxy.sh` and scripts `kimi-anthropic-proxy.py`, `litellm-force-temp.py`, `kimi.sh`
  - Removed Moonshot/LiteLLM from provider registry, opencode.json configs, health checks, and docs
  - Local isolated-circuit backends are now: Ollama (:11434), vLLM (:8000), SGLang (:30000)

### Fixed
- **Test harness gate** — 23 test files defined their own `assert()` and never exited non-zero, so `run_tests.sh` and CI reported PASS despite real failures; all test files now exit non-zero on failure
- 7 previously silent test failures: stale kimi assertions in `test_model_router.sh`, dangling `zai` fallback refs in root `opencode.json` (caught by `test_providers.sh`), stale `/v1/models` literal in `test_isolated.sh`
- Dead modules wired into the orchestrator: `31-cockpit.sh` (Cockpit TUI), `32-isolated.sh` (Isolated Circuit), `33-services.sh` (Service Configuration Layer) were never sourced by `setup.sh`
- Documentation drift: module/provider/test counts in AGENTS.md and README, `docs/VERSIONS.md` endpoints, LiteLLM references across docs (en+ru)

### Changed
- Provider registry: 22 providers (19 cloud + 3 local: Ollama, vLLM, SGLang)
- `dist/` build artifacts now git-ignored

## [2.0.1] — 2026-07-27

### Added
- **kimi-proxy v14.2**: dynamic payload compression for Moonshot API's undocumented ~20KB request body limit
  - Sticky tools (bash/read/write/edit/grep/glob) always included first
  - Progressive trimming: max 10 tools, 15 messages, truncated descriptions
  - IPv4-only upstream workaround, SSE streaming, `reasoning_content` stripping
  - Tunable via `KIMI_PROXY_*` environment variables
  - VPN requirement documented for RU networks

> **Note:** Moonshot/Kimi support (including kimi-proxy) was subsequently removed in v2.0.2.

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
- **Alibaba Qwen3.7** provider — native SDK in opencode
- **DeepInfra** provider — fast inference, competitive pricing
- **Model Routing Intelligence** (`36-model-router.sh`) — task-based model selection
  - 8 task profiles: coding, reasoning, fast, agentic, budget, vision, isolated, ru_cn
  - Cost table with per-1M-token prices from models.dev
  - `dev models <task>` CLI command for recommendations
  - `dev models install <model>` for local model download via Ollama
  - `dev models list-local` for installed local models
- **Web GUI** — full management interface (port 4200)
  - 9 sections: Overview, Providers, Model Router, MCP, LSP, Infrastructure, Isolated Circuit, Backup, Logs
  - Real-time status of all providers, MCP/LSP servers, infrastructure services
  - Toggle Isolated Circuit, create backups from browser
- MemoryLayer AI memory: Docker backend + Ollama embed proxy (mxbai-embed-large, 1024-dim) + systemd auto-start
- Embed proxy: `scripts/embed-proxy.py` — bridges Ollama embeddings to MemoryLayer API format
- `opencode-embed-proxy.service`: systemd user service for Ollama embedding proxy
- Observability stack: Prometheus (:9090) + Grafana (:3001) with auto-provisioning
  - Infrastructure overview dashboard (container status, PostgreSQL, Redis, Qdrant, uptime)
  - Agent performance dashboard (token usage, cost by provider, model success rate)
- **Corporate proxy support** — HTTP_PROXY, HTTPS_PROXY, CURL_CA_BUNDLE in _curl()
- **Config backup/restore** — `dev backup create|list|restore`
- **Pre-session check** — all 24 providers, local backends, model recommendations, infra status
- **MCP/LSP post-install verification** — reports installed vs missing counts
- Go apt fallback in `08-go.sh`: if direct download fails, use ppa:longsleep/golang-backports
- Unit tests: `test_infra.sh`, `test_cockpit.sh`, `test_isolated.sh`, `test_providers.sh`, `test_observability.sh`, `test_embed_proxy.sh` (105+ new assertions)
- CI: Python syntax check, Go format check, opencode.json validity check, cross-distro matrix (Fedora, Debian, Ubuntu)
- Critical audit + provider/LLM ecosystem analysis + requirements specification (`docs/research/`)

### Changed
- Module count: 29 → 39
- Module numbering fixed: 22-mise→29-mise, 32-observability→34-observability, 33-gui→35-gui
- `26-providers.sh`: 15→20 cloud + 4 local OpenAI-compatible providers (24 total)
- `18-opencode-json.sh`: `_build_providers()` supports ISOLATED_CIRCUIT mode + z.ai/OpenRouter/Alibaba/DeepInfra
- `00-core.sh`: ISOLATED_CIRCUIT auto-load from config, version v2.0.0
- `setup.sh`: version v2.0.0, 561 lines
- opencode.json: z.ai provider added with fallback chain
- Model IDs verified against models.dev: Grok 4→4.3, Kimi K2→K2.7 Code, Claude→Opus 4.8, GPT-5→5.5, Gemini→3.5 Flash, Qwen3→3.7 Plus
- `pre-session-check.sh`: expanded from 5 to 24 providers + local backends + model recommendations
- `helpers.sh`: corporate proxy support (HTTP_PROXY, HTTPS_PROXY, CURL_CA_BUNDLE)
- `12-mcp-lsp.sh`: post-install MCP/LSP verification
- `34-observability.sh`: Grafana provisioning volumes mounted
- AGENTS.md: full rewrite with all 39 modules, 24 providers, model routing, v2.0.0
- Cockpit: 7-tab TUI (F1 System, F2 Plugins, F3 GPU/Models, F4 Sessions, F5 Tasks, F6 Logs, F7 Infra) + `[ISOLATED]` indicator
- Cockpit: Web GUI with 9 management sections
- GUI: rewritten from stub to full management interface (server.js + index.html)

### Fixed
- MemoryLayer: backend not running — deployed Docker container + Ollama embed proxy pipeline
- `test_infra.sh`: isolated from real config (uses temp dir), +4 new assertions
- `test_core.sh`: version assertion updated for v2.0.0
- `test_helpers.sh`: version assertion updated for v2.0.0
- `test_modules.sh`: line count bounds adjusted for 561-line orchestrator
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
