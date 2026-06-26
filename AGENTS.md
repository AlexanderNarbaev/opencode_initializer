# AGENTS.md — opencode_initializer

## Identity
Universal Dev Machine Bootstrap — однокомандная настройка AI-усиленной dev-машины для WSL2/Linux.
Модульная архитектура: 351-строчный оркестратор + 33 модуля + автообновление через systemd-таймер.

## Язык общения
Всё общение строго на русском языке. Код и комментарии — на английском.

## Project Structure
```
opencode_initializer/
├── setup.sh          ← оркестратор (351 строк, source модули из src/lib/)
├── src/
│   ├── lib/          ← 33 модуля (00-core.sh … 28-devbox.sh + 22-webui-service.sh + helpers.sh + version-check.sh + pre-session-check.sh)
│   └── modes/            ← 5 режимных скриптов (+ 6 встроенных режимов)
├── dev.sh            ← CLI
├── scripts/          ← утилиты (ai-router)
├── tests/            ← unit, integration, e2e
├── migrations/       ← timestamped, idempotent
├── docs/             ← документация + plans + research
├── .github/          ← CI + issue/PR шаблоны
├── README.md
└── AGENTS.md         ← этот файл
```

## File Naming Convention
- `setup.sh` — текущая рабочая версия (симлинк в ~/setup.sh)
- `vXX.Y.sh` — архивные версии (major.minor)
- Имена короткие, без пробелов (избегаем проблем с путями)

## Architecture (setup.sh)

### Orchestrator (351 lines)
Minimal entry point that sources modules from `src/lib/` and dispatches modes from `src/modes/`.

### Module Layout (src/lib/ — 30 modules + 3 infra)
| Module | Responsibility |
|--------|---------------|
| `helpers.sh` | `_curl()`, `_retry()`, `_npm_install()`, `_sudo()` — shared infrastructure |
| `00-core.sh` | Progress tracking, step skip/done, OS/PKG detection, mirrors, npm prefix, cache dirs |
| `01-system.sh` | System packages (apt/dnf/pacman/apk/zypper/brew) |
| `02-docker.sh` | Docker engine installation |
| `03-chrome.sh` | Google Chrome + chromedriver (WSL2-aware) |
| `04-zsh.sh` | Zsh + Oh My Zsh + P10k + 14 plugins |
| `05-java.sh` | Java 25 (Adoptium API → SDKMAN → apt) + Zig 0.15.1 |
| `06-node.sh` | Node.js 24 (n → apt) |
| `07-python.sh` | Python 3.14 + uv |
| `08-go.sh` | Go 1.26 (direct download → apt) |
| `09-rust.sh` | Rust 1.96 (rustup → apt) |
| `10-dotnet.sh` | .NET 10 (dotnet-install → apt) |
| `11-opencode.sh` | OpenCode CLI 1.17 + Bun 1.3 |
| `12-mcp-lsp.sh` | 21 MCP servers + 15 plugins + 13 LSP + Muninn |
| `13-chromadb.sh` | ChromaDB systemd service |
| `14-shokunin.sh` | Shokunin + Superpowers + Caveman |
| `15-security.sh` | Trivy, Qodana |
| `16-llm.sh` | Ollama, vLLM, SGLang, Open WebUI, WasmEdge (GPU-aware, multi-vendor) |
| `17-project.sh` | Project structure (AGENTS.md, WAL, agents, docker-compose) |
| `18-opencode-json.sh` | opencode.json generation (Python inline, bun bin paths) |
| `19-finalize.sh` | Git config, PATH, .zshrc, auth reminder, verification (36 checks) |
| `20-autoupdate.sh` | topgrade + systemd weekly timer + unattended-upgrades + abtop |
| `21-rag.sh` | RAG System — Corporate Knowledge Assistant (ETL + proxy + Qdrant + Gemma) |
| `22-mise.sh` | mise-en-place — universal tool version manager |
| `22-webui-service.sh` | Open WebUI systemd user service (auto-start) |
| `23-just.sh` | just — task runner with default justfile |
| `24-websearch.sh` | SearXNG web search + sanitizer proxy (internal hosts/IP/PII) |
| `25-litellm.sh` | LiteLLM — OpenAI-compatible local API gateway |
| `26-providers.sh` | 15+ LLM provider registry with session switching |
| `27-dotfiles.sh` | chezmoi dotfiles manager for team config sharing |
| `28-devbox.sh` | Devbox — Nix-based isolated dev environments |
| `version-check.sh` | Version check: Rust/Go/Node/Python/Bun/OpenCode/Ollama/Zig + npm packages |
| `pre-session-check.sh` | Pre-session provider/model validation + MCP status |

### Modes (src/modes/)
| Mode | Description |
|------|-------------|
| full | Complete bootstrap (default) |
| reinit | Reinstall tools, keep data |
| new | Init new project only |
| health | Diagnostics (65+ checks, 7 sections) |
| update | Update tools only |
| upgrade | Full system update chain |
| interactive | Component-by-component selection |
| ci | Lightweight headless mode for CI/CD — OpenCode CLI + essential MCPs |
| fix-config | Regenerate opencode.json |
| fix-zshrc | Repair .zshrc |
| dry-run | Preview mode, no changes |

### Multi-Provider Config (opencode.json)
```json
{
  "model": "deepseek/deepseek-v4-pro",
  "small_model": "deepseek/deepseek-v4-flash",
  "provider": {
    "deepseek": {},
    "opencode": {}
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

## Testing & Verification
```bash
bash -n setup.sh                          # syntax check (orchestrator)
for f in src/lib/*.sh src/modes/*.sh; do bash -n "$f"; done  # modular syntax check
bash tests/run_tests.sh                   # full test suite (15+ tests, 250+ assertions)
bash setup.sh --health                    # diagnostics (60+ checks)
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
| v33.5 | MCP fixes: type:local, LSP extensions, auth.json, mkdir permissions |
| v33.6 | MCP overhaul: fix bun detection (pkg_installed), codegraph serve, agent-browser-mcp-server, remove broken MCPs (codesorb/mcp-replay/datafy), open-orchestra → plugin, drop grep/sentry from local install |
| v33.7 | Fix codegraph MCP: add missing --mcp flag to serve command (broken since v33.6) |
| v33.9 | Fix **critical**: remove `dcp`/`damageControl` top-level keys (schema rejected them — hard crash). Convert to plugin tuple format. Bump all version strings. Add missing packages to upgrade mode. Add missing CLI flags to help. Regenerate valid opencode.json. Install dev CLI. Clean stale packages (codesorb, mcp-replay, datafy). |
| v33.10 | ZSH: version check (5.8+), chsh default shell, +14 plugins (fzf-tab, zsh-completions, npm, bun, etc.), git via ghproxy mirrors. Google Chrome: apt repo install + chromedriver, WSL2-aware --no-sandbox, chrome-open launcher in .zshrc and ~/.local/bin. GitHub MCP: --github-token CLI arg, enabled+env when token present. Providers: dynamic _build_providers() based on available API keys. Postgres MCP: conditional enabled. auth.json: all 6 tokens. Interactive: Chrome option. |
| v33.11 | Version bumps (Node 24, Python 3.14, .NET 10, Go 1.26, Zig 0.16). Critical bug fixes (39), LSP fixes (3). Added gitlab + google-maps MCP servers. |
| v34.0 | Modular architecture: 23 files, 257-line orchestrator. Bug fixes (39), LSP fixes (3), version bumps (Node 24, Python 3.14, .NET 10, Zig 0.16). New MCPs (gitlab, google-maps). |
| v34.5 | Auto-update system (topgrade + systemd timer), version-check (8 tools), IDE config (Sublime Text + VS Code + mime), abtop 0.4.8, bun bin paths for MCP cold-start, npm prefix fix, 19-step progress tracking, bat symlink, Zig 0.15.1 fix (0.16 didn't exist), Rust 1.93→1.96. dev CLI: version-check, autoupdate, self-update commands. |
| v35.0 | RU mirrors (goproxy.cn, npmmirror, yandex), CA certs improved, 8 new plugins (token-tracker, notify, pty, ignore, snip, snippets, envsitter-guard, command-inject, orchestrator), dead plugins removed, gopls via goproxy.cn, Ollama via snap, GOPROXY=goproxy.cn default, PATH +~/go/bin, tests: test_critical_path.sh (30+ checks). |
| v35.1 | Pre-session provider/model check script. Version check expanded. 22→24 modules. |
| v35.3 | Research-driven: +5 plugins (dcp, auto-fallback, goal-mode, swarm, vibeguard), +1 MCP (chrome-devtools), +5 LSP (bash, dockerfile, css, html, json), +3 CLI tools (btm, sd, typos). Fixed: ZSH crash (set -e leak), opencode.json validity (// comments), Gradle symlink, health 54→54 checks. New tests: test_mcp_registry.sh (52 checks), test_opencode_json_gen.sh (62 checks). README rewritten to international standard. CONTRIBUTING.md comprehensive guide. |
| v1.0.0 | Initial public release. Clean open source launch with full documentation (README, CHANGELOG, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY). 8 languages, 21 MCPs, 15 plugins, 13 LSPs, 193-test suite. |
| v1.1.0 | Ecosystem expansion: hardware auto-detection (multi-vendor GPU/NPU), LiteLLM OpenAI-compatible API gateway, SearXNG web search + sanitizer proxy, CI/CD headless mode, multimodal (whisper.cpp + stable-diffusion.cpp + llava), 15+ LLM providers, TUI/JSON/RPC/SDK interaction modes, chezmoi dotfiles, Devbox integration, ONNX runtime. 24→29 modules, 26→29 steps, 65+ health checks. |

## Modular Architecture (v1.0.0)

```
opencode_initializer/
├── setup.sh              ← оркестратор (351 строк)
├── dev.sh                ← CLI
├── opencode.json         ← конфиг OpenCode
├── src/
│   ├── lib/
│   │   ├── helpers.sh    ← _curl, _retry, _npm_install
│   │   ├── pre-session-check.sh
│   │   └── version-check.sh
│   └── modes/
│       └── health.sh ... ← режимные скрипты
├── tests/                ← unit / integration / e2e
├── migrations/
├── scripts/              ← утилиты
├── docs/                 ← документация + plans + research
├── .github/workflows/    ← CI
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

**Config file:** `~/.config/opencode-setup/setup.conf` — persistent settings, sourced by both setup.sh and dev CLI.
