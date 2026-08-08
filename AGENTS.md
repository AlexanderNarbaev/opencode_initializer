# AGENTS.md — opencode_initializer
> **Operating Model:** Multi-Agent Continuous Development Framework v3.0 ([ADR](./docs/architecture/adr/2026-07-18-multi-agent-framework-v3.md))
> **Current Wave:** [current_wave.md](./current_wave.md) | **Checkpoint:** [session_checkpoint.json](./session_checkpoint.json)

## Status: v3.1.0 — Core Hardening: WAL flock, safe-rm, unified error strategy, macOS bash 3.2 compat, SSOT completion

| Phase | Status | Description |
|-------|--------|-------------|
| 0 | Done | Foundation: 30-infra.sh, 31-cockpit.sh, 33-services.sh, tests, Go apt fallback |
| 1 | Done | Docker Infrastructure Layer (postgres, qdrant, redis) |
| 2 | Done | Plugin Framework v2 (always/conditional/on-demand) |
| 3 | Done | Integration tests, CI/CD for new modules |
| 4 | Done | Cockpit TUI + Observability + Isolated Circuit + Documentation |
| 5 | Done | v3.1.0 Core Hardening (WAL flock, safe-rm, macOS bash 3.2, SSOT) |

## Identity
Universal Dev Machine Bootstrap — AI-Native SDD Harness для WSL2/Linux. 4 deployment profiles: personal, corporate, air-gapped, hybrid.
Модульная архитектура: 589 строк оркестратор + 49 модулей + автообновление через systemd-таймер.

## Язык общения
Всё общение строго на русском языке. Код и комментарии — на английском.

## Project Structure
```
opencode_initializer/
├── setup.sh          ← оркестратор (589 строк, source модули из src/lib/)
├── src/
│   ├── lib/          ← 49 модулей (00-core.sh … 46-offline-bundle.sh + 99-upstream-sync.sh + helpers.sh + version-check.sh + pre-session-check.sh)
│   └── modes/            ← 5 режимных скриптов (+ 6 встроенных режимов)
├── dev.sh            ← CLI (dev install|metrics|observability|infra|...)
├── .env.example      ← шаблон переменных окружения (API ключи)
├── scripts/          ← утилиты (provider-check, ai-router, embed-proxy, pii-guard, oc-json, oc-rpc, oc-sdk, oc-tui, oc-metrics)
├── tests/            ← unit (28), integration (5), e2e (4) — 480+ assertions
├── migrations/       ← timestamped, idempotent
├── docs/             ← документация + plans + research
├── .github/          ← CI (test, shellcheck, docs) + issue/PR шаблоны
├── README.md
└── AGENTS.md         ← этот файл
```

## File Naming Convention
- `setup.sh` — текущая рабочая версия (симлинк в ~/setup.sh)
- `vXX.Y.sh` — архивные версии (major.minor)
- Имена короткие, без пробелов (избегаем проблем с путями)

## Architecture (setup.sh)

### Orchestrator (589 lines)
Minimal entry point that sources modules from `src/lib/` and dispatches modes from `src/modes/`.

### Module Layout (src/lib/ — 46 numbered + 3 helpers)
| Module | Responsibility |
|--------|---------------|
| `helpers.sh` | `_curl()`, `_retry()`, `_npm_install()`, `_sudo()` — shared infrastructure |
| `00-core.sh` | Progress tracking, step skip/done, OS/PKG detection, mirrors, npm prefix, cache dirs, ISOLATED_CIRCUIT |
| `01-system.sh` | System packages (apt/dnf/pacman/apk/zypper/brew) |
| `02-docker.sh` | Docker engine installation |
| `03-chrome.sh` | Google Chrome + chromedriver (WSL2-aware) |
| `04-zsh.sh` | Zsh + Oh My Zsh + P10k + 14 plugins |
| `05-java.sh` | Java 25 (Adoptium API → SDKMAN → apt) + Zig 0.15.2 |
| `06-node.sh` | Node.js 24 (n → apt) |
| `07-python.sh` | Python 3.14 + uv |
| `08-go.sh` | Go 1.26 (direct download → apt fallback) |
| `09-rust.sh` | Rust 1.97.1 (rustup → apt) |
| `10-dotnet.sh` | .NET 10 (dotnet-install → apt) |
| `11-opencode.sh` | OpenCode CLI 1.17 + Bun 1.3.14 |
| `12-mcp-lsp.sh` | 24 MCP servers + 15 plugins + 13 LSP + Muninn |
| `13-chromadb.sh` | ChromaDB systemd service |
| `14-shokunin.sh` | Shokunin + Superpowers + Caveman |
| `15-security.sh` | Trivy, Qodana |
| `16-llm.sh` | Ollama, vLLM, SGLang, Open WebUI, WasmEdge (GPU-aware, multi-vendor) |
| `17-project.sh` | Project structure (AGENTS.md, WAL, agents, docker-compose) |
| `18-opencode-json.sh` | opencode.json generation (Python inline, bun bin paths, 22 providers, ISOLATED_CIRCUIT) |
| `19-finalize.sh` | Git config, PATH, .zshrc, auth reminder, verification (36 checks) |
| `20-autoupdate.sh` | topgrade + systemd weekly timer + unattended-upgrades + abtop |
| `21-rag.sh` | RAG System — Corporate Knowledge Assistant (ETL + proxy + Qdrant + Gemma) |
| `22-webui-service.sh` | Open WebUI systemd user service (auto-start) |
| `23-just.sh` | just — task runner with default justfile |
| `24-websearch.sh` | SearXNG web search + sanitizer proxy (internal hosts/IP/PII) |
| `26-providers.sh` | 22 LLM provider registry (19 cloud + 3 local) with session switching |
| `27-dotfiles.sh` | chezmoi dotfiles manager for team config sharing |
| `28-devbox.sh` | Devbox — Nix-based isolated dev environments |
| `29-mise.sh` | mise-en-place — universal tool version manager |
| `30-infra.sh` | Infrastructure: PostgreSQL + Qdrant + Redis + Prometheus + Grafana + MemoryLayer |
| `31-cockpit.sh` | Cockpit TUI server management daemon (7-tab TUI) |
| `32-isolated.sh` | Isolated Circuit Mode — air-gapped LLM (Ollama/vLLM/SGLang) |
| `33-services.sh` | Unified Service Layer — port resolution, service modes (local/external/disabled), deployment profiles |
| `34-observability.sh` | Grafana + Prometheus + Node Exporter observability stack + OTel support |
| `35-gui.sh` | Web GUI — management interface on port 4200 |
| `36-model-router.sh` | Model routing intelligence — task-based model selection, cost table, recommendations |
| `37-wal.sh` | Write-Ahead Log — setup checkpoint + agent session journal (JSONL) |
| `38-ide-plugins.sh` | IDE AI plugins — DevoxxGenie + GitHub Copilot for JetBrains/VS Code |
| `39-shell.sh` | Shell integration — zsh/bash completions, aliases, prompt helpers |
| `40-best-practices.sh` | Best practices — linting, formatting, pre-commit hooks |
| `41-constitution.sh` | Constitution + spec format generator — `memory/constitution.md` at project init |
| `42-hooks.sh` | Lifecycle hooks framework — pre-request, post-response, pre-commit, on-error |
| `43-governance.sh` | Model governance — `model-policy.json` allowlist/blocklist per deployment profile |
| `44-audit.sh` | Audit trail — 7 WAL event types, SHA-256 hash-chain, rotation >10MB → gzip+Qdrant |
| `45-pii-guard.sh` | PII sanitizer — 9 detectors (email, phone, INN, SNILS, passport, credit card, IP, API key) |
| `46-offline-bundle.sh` | Air-gap offline bootstrap — tarball bundle, SHA-256 manifest, `dev bundle create` |
| `version-check.sh` | Version check: Rust/Go/Node/Python/Bun/OpenCode/Ollama/Zig + npm packages |
| `pre-session-check.sh` | Pre-session provider/model validation + MCP status |

### Provider Registry (26-providers.sh — 22 providers)
| Provider | Model | Free Tier | SDK |
|----------|-------|-----------|-----|
| deepseek | DeepSeek V4 Pro / V4 Flash | yes | native |
| opencode | OpenCode Go proxy | yes | native |
| **zai** | **z.ai GLM-5.2 / GLM-4-Flash** | **yes** | **openai-compatible** |
| **openrouter** | **OpenRouter (100+ models)** | **yes** | **native** |
| xai | xAI Grok 4.3 / Grok 4.20 | no | native |
| mimo | Xiaomi MiMo V2.5 | yes | openai-compatible |
| minimax | MiniMax M3 | no | openai-compatible |
| openai | OpenAI GPT-5.5 / GPT-5.4 Mini | no | native |
| anthropic | Anthropic Claude Opus 4.8 / Sonnet 4.6 | no | native |
| google | Google Gemini 3.5 Flash | yes | native |
| mistral | Mistral Large 3 / Small | no | native |
| groq | Groq Cloud (Llama 4 Maverick) | yes | native |
| together | Together AI (Llama 4) | yes | native |
| cohere | Cohere Command R+ | yes | native |
| fireworks | Fireworks AI | no | openai-compatible |
| cerebras | Cerebras (fast inference) | no | native |
| perplexity | Perplexity (online search) | no | native |
| **alibaba** | **Alibaba Qwen3.7 Plus** | **yes** | **native** |
| **deepinfra** | **DeepInfra (Llama 4)** | **yes** | **openai-compatible** |
| ollama | Ollama (localhost:11434) | yes | local |
| vllm | vLLM (localhost:8000) | yes | local |
| sglang | SGLang (localhost:30000) | yes | local |

### Modes (src/modes/)
| Mode | Description |
|------|-------------|
| full | Complete bootstrap (default) |
| reinit | Reinstall tools, keep data |
| new | Init new project only |
| health | Diagnostics (119 checks, 7 sections) |
| update | Update tools only |
| upgrade | Full system update chain |
| interactive | Component-by-component selection |
| ci | Lightweight headless mode for CI/CD — OpenCode CLI + essential MCPs |
| fix-config | Regenerate opencode.json |
| fix-zshrc | Repair .zshrc |
| dry-run | Preview mode, no changes |
| airgap | Offline install from bundle, no network |

### Multi-Provider Config (opencode.json)
```json
{
  "model": "deepseek/deepseek-v4-pro",
  "small_model": "deepseek/deepseek-v4-flash",
  "provider": {
    "deepseek": { "fallback": ["zai", "opencode", "xai", "minimax"] },
    "zai": { "options": { "baseURL": "https://api.z.ai/api/paas/v4" }, "fallback": ["deepseek", "opencode"] },
    "opencode": { "fallback": ["deepseek", "zai", "minimax"] }
  }
}
```

## Key Design Decisions

1. **Adoptium API for Java** (v29) — GitHub-hosted CDN, reliable in WSL2 unlike sdkman.io
2. **npm pack cache for MCP** (v29) — .tgz files cached locally, survive re-runs
3. **Progress file** (v29) — `~/.cache/opencode-setup/progress` records completed steps
4. **All curl piped through _curl()** — 5 retries, exponential backoff, 24h cache
5. **All npm through _npm_install()** — npm pack → bun fallback
6. **WSL2 DNS fix** (v29) — adds 8.8.8.8 + 1.1.1.1 to /etc/resolv.conf
7. **No secrets in code** — all API keys via command-line arguments only
8. **Short filenames** — no spaces, no long names (avoid path issues)
9. **Bun binary paths for MCP** (v34.5) — `local_cmd()` generates absolute paths to `~/.bun/bin/` instead of `npx -y`, enabling instant cold start
10. **Auto-update via systemd timer** (v34.5) — topgrade runs weekly (Sun 04:00), unattended-upgrades for daily security
11. **Version check** (v34.5) — `dev version-check` compares installed versions against latest from GitHub/APIs
12. **Infrastructure as Code** (v2.0) — PostgreSQL + Qdrant + Redis + Prometheus + Grafana + MemoryLayer via Docker Compose
13. **Isolated Circuit Mode** (v2.0) — air-gapped LLM operation with local OpenAI-compatible backends
14. **z.ai GLM-5.2 integration** (v2.0) — primary provider for RU/CN markets, OpenAI-compatible API
15. **OpenRouter aggregator** (v2.0) — single API key for 100+ models
16. **Model routing intelligence** (v2.0) — task-based model selection with 8 profiles (coding, reasoning, fast, agentic, budget, vision, isolated, ru_cn)
17. **Grafana dashboards** (v2.0) — auto-provisioned datasource + infrastructure overview dashboard
18. **Config backup/restore** (v2.0) — `dev backup` for disaster recovery
19. **OPENCODE_* env naming** (v2.0.3) — canonical prefix `OPENCODE_` for local endpoint/model/circuit vars (`OPencode_` still accepted as deprecated backward-compat fallback)
20. **Model Governance** (v3.0) — `model-policy.json` per-project allowlist/blocklist, 3 modes (allow-all/allowlist/corporate)
21. **Air-Gap Offline Bundle** (v3.0) — `--airgap` mode + `dev bundle create` for fully offline installation
22. **PII Sanitizer** (v3.0) — 9 detectors (email, phone, INN, passport, credit card, IP, API key), pre-LLM-request gate
23. **Audit Trail** (v3.0) — 7 WAL event types, SHA-256 hash-chain, rotation >10MB → gzip+Qdrant archive
24. **Supply-Chain Hardening** (v3.0) — `_download_verify()` with SHA256, all `curl|sh` replaced with download→verify→execute
25. **SDD-native Workflow** (v3.0) — constitution→specify→clarify→plan→tasks→implement→verify→converge lifecycle

## Testing & Verification
```bash
bash -n setup.sh                          # syntax check (orchestrator)
for f in src/lib/*.sh src/modes/*.sh; do bash -n "$f"; done  # modular syntax check
bash tests/run_tests.sh                   # full test suite (37 tests, 480+ assertions)
bash setup.sh --health                    # diagnostics (119 checks)
bash setup.sh --fix-config                # regenerate opencode.json
bash setup.sh --fix-zshrc                 # repair shell config
```

## Git Remotes
- GitHub: https://github.com/AlexanderNarbaev/opencode_initializer
- GitVerse: https://gitverse.ru/AlexandrNarbaev/opencode_initializer

## Version History
| Version | Key Change |
|---------|-----------|
| v17-v25 | Evolution from Opora-specific to universal |
| v26 | 8 languages, 14 MCP, 10 LSP |
| v27 | Interactive mode, auto-detect Go, MCP cold-start |
| v28 | Multi-provider, _curl/_retry/_npm_install, WSL2 fix, anti-hang |
| v29 | Adoptium Java, MCP npm cache, DNS fix, progress file |
| v30 | Secrets security (chmod 600), WSL2 .wslconfig/wsl.conf, OS validation, timestamps, dry-run, opencode.json overhaul, Sentry+Grep MCP, ShellCheck CI
| v31 | GPU/LLM runtimes (Ollama, vLLM, SGLang, Open WebUI), self-update, architecture detection (amd64+arm64), enhanced interactive mode
| v32 | RU mirrors (GitHub/npm/pip/Docker/Go), cross-distro packages (apt/dnf/pacman/apk/zypper/brew), certificate handling, SDKMAN mirror
| v33.5-v33.11 | MCP fixes, plugin overhaul, ZSH plugins, Chrome, version bumps, gitlab/google-maps MCPs |
| v34.0 | Modular architecture: 23 files, 257-line orchestrator |
| v34.5 | Auto-update system (topgrade + systemd timer), version-check, IDE config, bun bin paths |
| v35.0-v35.3 | RU mirrors, plugins, MCP, LSP, CLI tools, tests, README rewrite |
| v1.0.0 | Initial public release. 8 languages, 21 MCPs, 15 plugins, 13 LSPs, 193-test suite. |
| v1.1.0 | Ecosystem expansion: hardware auto-detection, LiteLLM, SearXNG, CI/CD mode, multimodal, 15+ providers, chezmoi, Devbox, ONNX. 29 modules, 65+ health checks. |
| v2.0.0 | Infrastructure as Code (PostgreSQL+Qdrant+Redis+Prometheus+Grafana+MemoryLayer), Cockpit TUI (7-tab), Isolated Circuit Mode, z.ai GLM-5.2 + OpenRouter + Alibaba + DeepInfra providers, MemoryLayer embed proxy, 41 module, 24 providers, 350+ test assertions. |
| v2.0.1 | kimi-proxy v14.2: dynamic payload compression for Moonshot API's undocumented 20KB limit. Sticky tools (bash/read/write/edit/grep/glob), progressive trimming, VPN requirement documented. |
| v2.0.2 | Moonshot/Kimi + LiteLLM removed. Test harness gate fixed (23 files gained exit-on-failure; 7 silent failures surfaced and fixed). Dead modules wired: 31-cockpit, 32-isolated, 33-services. 22 providers (19 cloud + 3 local), 43 modules, 37 test files / 480+ assertions. |
| v3.0.0 | SDD-native AI Harness: air-gap completeness, model governance, PII sanitizer, audit trail, supply-chain hardening (SHA256 verify), offline bundle, 4 deployment profiles (personal/corporate/air-gapped/hybrid). 22 providers, 49 modules, 37 test files / 480+ assertions. |
| v2.0.3 | Deep-research 10 findings: plugins fix, macOS compat, env naming, CI gates, test coverage, health checks, dev doctor, sudo deprecation, migration |

## Modular Architecture (v3.0.0)

```
opencode_initializer/
├── setup.sh              ← оркестратор (589 строк)
├── dev.sh                ← CLI
├── opencode.json         ← конфиг OpenCode (22 providers)
├── .env.example          ← шаблон переменных окружения (API ключи)
├── src/
│   ├── lib/
│   │   ├── helpers.sh    ← _curl, _retry, _npm_install
│   │   ├── pre-session-check.sh
│   │   └── version-check.sh
│   └── modes/
│       └── health.sh ... ← режимные скрипты
├── tests/                ← unit (12) / integration (5) / e2e (4)
├── migrations/
├── scripts/              ← утилиты (provider-check, embed-proxy, ai-router, oc-*)
├── docs/                 ← документация + plans + research
├── .github/workflows/    ← CI (test, shellcheck, docs)
├── README.md
├── CONTRIBUTING.md
└── AGENTS.md
```

**CLI `dev` commands:**
- `dev install docker` — install a new component
- `dev remove java` — remove a component
- `dev update` — update all tools + run pending migrations
- `dev health` — full diagnostic
- `dev list` — list installed components
- `dev config` — edit setup config file
- `dev version-check` — check installed vs latest versions
- `dev autoupdate` — run topgrade full system update
- `dev self-update` — git pull + reinstall dev CLI + setup.sh
- `dev isolated on|off|status` — toggle Isolated Circuit Mode
- `dev models <task>` — model recommendation for task type (coding, reasoning, fast, etc.)
- `dev doctor` — pre-session provider & model validation
- `dev backup create|list|restore` — config backup/restore
- `dev bundle create|list|verify <path>` — offline installation bundle
- `dev governance show|policy` — model policy management
- `dev audit log|stats|rotate` — audit trail inspection
- `dev pii scan <file>` — PII scan and redaction

**Config file:** `~/.config/opencode-setup/setup.conf` — persistent settings, sourced by both setup.sh and dev CLI.

## Agent System Prompt

The primary agent operates as a **Universal AI Coprocessor** (see `.opencode/skills/coprocessor/SKILL.md`).

### Core Protocols

| Protocol | Description |
|----------|-------------|
| **Dual-Process Reasoning** | System 1 (fast: edits, grep, fixes) / System 2 (slow: analysis, planning, multi-file refactors). Escalate after 2 failures or >3 files touched. |
| **Memory Hierarchy** | WAL (session journal) → Specs (persistent designs) → Artifacts (ground truth). Artifacts override stale specs. |
| **Shared State = IPC** | Files are the communication protocol. Read before action, verify after write. `.opencode/state/` for inter-agent coordination. |
| **Keyboard Correction** | Auto-detect RU↔EN layout mismatch. Silent for unambiguous, confirm for ambiguous. Log to WAL with `[KB]`. |
| **CO-STAR Output** | Context → Objective → Steps → Thinking → Answer → References. Skip for trivial outputs. |
| **Memory Anchor** | Every response starts with `[CTX: domain]`. Enables context resumption after compaction. |
| **Source Ladder** | Official docs > authoritative secondary > encyclopedias > model knowledge. Flag tier: `[L1]`–`[L4]`. |

### Hard Gates
- Never emit secrets. Redact with `***`.
- Never delete code you don't understand. `#S2` analyze first.
- Never skip WAL. Journal every consequential decision.
- Never speculate. Flag `[speculative]` when confidence < 80%.

## WAL Protocol

### Location
`~/.cache/opencode/wal.jsonl` — append-only session journal in JSONL format.

### When to Checkpoint
Write a WAL entry on every:
- Tool call error or unexpected output
- Model or provider switch
- Architectural decision (file creation/deletion, API change, dependency change)
- Context compaction event
- Every 10 interaction turns (as safety net)

### Entry Format
```jsonl
{"ts":"ISO8601","domain":"setup|health|fix|refactor|audit|explore|review|docs|debug","decision":"what was decided","rationale":"why","impact":["file1","file2"],"confidence":0.85,"mode":"S1|S2"}
```

### Session Start Ritual
1. Read last 20 lines of WAL for context resume
2. Read `AGENTS.md` and active `.opencode/skills/`
3. Emit `[CTX: domain]` anchor
4. Begin work

## Known Limitations

### macOS
- **bash 4+ required**: Stock macOS ships bash 3.2. Associative arrays (`declare -A`) and other bash 4 features are unavailable without `brew install bash`.
- **GNU grep required**: macOS ships BSD grep without `-P` (Perl regex) support. All `grep -oP` patterns have been migrated to `grep -oE` (ERE) with `sed`/`awk` fallbacks since v2.0.3. Install GNU grep via `brew install grep` for full compatibility.
- **`declare -A` deferred**: Modules using associative arrays (`32-isolated.sh`, `26-providers.sh`) will fail on stock macOS bash 3.2. A future migration to indexed arrays or a bash version gate is planned.

### Non-Linux Environments
- The project is optimised for **WSL2/Linux**. macOS and Windows-native paths are not actively tested in CI.
- Docker-based services (`30-infra.sh`, `34-observability.sh`) require Docker Desktop on macOS.
- Systemd user services are Linux-only; macOS equivalents (launchd) are not implemented.
