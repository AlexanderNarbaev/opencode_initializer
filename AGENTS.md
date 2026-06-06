# AGENTS.md — opencode_initializer

## Identity
Universal Dev Machine Bootstrap — однокомандная настройка AI-усиленной dev-машины для WSL2/Linux.
Модульная архитектура: 257-строчный оркестратор + 25 модулей, устанавливающих полный стек разработки с AI-агентами.

## Язык общения
Всё общение строго на русском языке. Код и комментарии — на английском.

## Project Structure
```
opencode_initializer/
├── setup.sh          ← оркестратор (257 строк, source модули из lib/)
├── lib/              ← 21 модуль (00-core.sh … 19-finalize.sh + helpers.sh)
├── modes/            ← 4 режимных скрипта (health, fix-zshrc, upgrade, interactive)
├── dev.sh            ← CLI: dev install|remove|update|health|list|config
├── migrations/       ← timestamped, idempotent, auto-run by 'dev update'
├── .github/workflows/← CI (ShellCheck)
├── v17.0.sh ... v33.11.sh ← архивные версии
├── README.md
├── AGENTS.md         ← этот файл
└── .gitignore
```

## File Naming Convention
- `setup.sh` — текущая рабочая версия (симлинк в ~/setup.sh)
- `vXX.Y.sh` — архивные версии (major.minor)
- Имена короткие, без пробелов (избегаем проблем с путями)

## Architecture (setup.sh)

### Orchestrator (257 lines)
Minimal entry point that sources modules from `lib/` and dispatches modes from `modes/`.

### Module Layout (lib/)
| Module | Responsibility |
|--------|---------------|
| `helpers.sh` | `_curl()`, `_retry()`, `_npm_install()` — shared infrastructure |
| `00-core.sh` | Progress tracking, step skip/done, OS detection, cache dirs |
| `01-system.sh` | System packages (apt/dnf/pacman/apk/zypper/brew) |
| `02-docker.sh` | Docker engine installation |
| `03-chrome.sh` | Google Chrome + chromedriver (WSL2-aware) |
| `04-zsh.sh` | Zsh + Oh My Zsh + P10k + 14 plugins |
| `05-java.sh` | Java 25 (Adoptium API → SDKMAN → apt) |
| `06-node.sh` | Node.js 24 (n → apt) |
| `07-python.sh` | Python 3.14 + uv |
| `08-go.sh` | Go 1.26 (direct download → apt) |
| `09-rust.sh` | Rust 1.93 (rustup → apt) |
| `10-dotnet.sh` | .NET 10 (dotnet-install → apt) |
| `11-opencode.sh` | OpenCode CLI + Bun |
| `12-mcp-lsp.sh` | 15 MCP servers + 10 LSP + Muninn + ChromaDB |
| `13-chromadb.sh` | ChromaDB systemd service |
| `14-shokunin.sh` | Shokunin + Superpowers + Caveman |
| `15-security.sh` | Trivy, Qodana |
| `16-llm.sh` | Ollama, vLLM, SGLang, Open WebUI (optional) |
| `17-project.sh` | Project structure (AGENTS.md, WAL, agents, docker-compose) |
| `18-opencode-json.sh` | opencode.json generation (Python inline) |
| `19-finalize.sh` | Git config, PATH persistence, .zshrc fix, auth reminder, verification |

### Modes (modes/)
| Mode | Description |
|------|-------------|
| full | Complete bootstrap (default) |
| reinit | Reinstall tools, keep data |
| new | Init new project only |
| health | Diagnostics (36 checks, 5 sections) |
| update | Update tools only |
| upgrade | Full system update chain |
| interactive | Component-by-component selection |
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

## Testing & Verification
```bash
bash -n setup.sh                          # syntax check (orchestrator)
for f in lib/*.sh modes/*.sh; do bash -n "$f"; done  # modular syntax check
bash setup.sh --health                    # diagnostics (36 checks)
bash setup.sh --fix-config                # regenerate opencode.json
bash setup.sh --fix-zshrc                 # repair shell config
```

## Git Remotes
- GitHub: https://github.com/AlexanderNarbaev/opencode_initializer
- GitVerse: https://gitverse.ru/alexander.narbayev/opencode_initializer

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

## Modular Architecture (v34)

```
opencode_initializer/
├── setup.sh              ← оркестратор (257 строк) + lib/ модули
├── dev.sh                ← CLI: dev install|remove|update|health|list|config
├── lib/
│   └── helpers.sh        ← _curl, _retry, _npm_install (shared)
├── modes/
│   └── health.sh ...     ← режимные скрипты
├── migrations/
│   └── YYYYMMDD-name.sh  ← timestamped, idempotent, auto-run by 'dev update'
├── .github/workflows/
│   └── shellcheck.yml    ← CI для каждого push/PR
└── v17.0.sh ...          ← архивные версии
```

**CLI `dev` commands:**
- `dev install docker` — install a new component
- `dev remove java` — remove a component
- `dev update` — update all tools + run pending migrations
- `dev health` — full diagnostic
- `dev list` — list installed components
- `dev config` — edit setup config file

**Config file:** `~/.config/opencode-setup/setup.conf` — persistent settings, sourced by both setup.sh and dev CLI.
