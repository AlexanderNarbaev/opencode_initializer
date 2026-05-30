# AGENTS.md — opencode_initializer

## Identity
Universal Dev Machine Bootstrap — однокомандная настройка AI-усиленной dev-машины для WSL2/Linux.
Один bash-скрипт (~1810 строк), устанавливающий полный стек разработки с AI-агентами.

## Project Structure
```
opencode_initializer/
├── setup.sh          ← основной скрипт (текущая версия, всегда актуальный)
├── v17.0.sh          ← архивные версии (эволюция)
├── v18.0.sh
├── v18.2.sh
├── v23.0.sh
├── v25.0.sh
├── v26.0.sh
├── v27.0.sh
├── README.md
├── AGENTS.md         ← этот файл
└── .gitignore
```

## File Naming Convention
- `setup.sh` — текущая рабочая версия (симлинк в ~/setup.sh)
- `vXX.Y.sh` — архивные версии (major.minor)
- Имена короткие, без пробелов (избегаем проблем с путями)

## Architecture (setup.sh)

### Helper Functions (строки 1-70)
- `_curl(url, [out], [opts])` — 5 retries, exponential backoff (2→4→8→16→32s), 24h cache
- `_retry(max, desc, cmd...)` — retry wrapper для не-curl команд
- `_npm_install(pkg, name)` — npm pack cache → npm install → bun install
- `_step_skip(id, desc)` / `_step_done(id)` — прогресс выполнения

### Modes (строки 71-130)
| Mode | Lines | Description |
|------|-------|-------------|
| full | default | Complete bootstrap |
| reinit | — | Reinstall tools, keep data |
| new | — | Init new project only |
| health | 82-141 | Diagnostics (36 checks, 5 sections) |
| update | — | Update tools only |
| upgrade | 237-308 | Full system update chain |
| interactive | 311-402 | Component-by-component selection |
| fix-config | — | Regenerate opencode.json |
| fix-zshrc | 144-234 | Repair .zshrc |

### Steps (строки 560+)
1. System packages (apt)
2. Docker (curl get.docker.com → apt fallback)
3. Zsh + Oh My Zsh + P10k
4. Java 25 (Adoptium API → SDKMAN for tools → apt fallback)
5. Node.js 22 (n → apt)
6. Python 3.12 + uv
7. Go 1.24+ (direct download → apt)
8. Rust (rustup → apt)
9. .NET 9 (dotnet-install → apt)
10. Clean old configs
11. OpenCode CLI + Bun
12. MCP servers (14) + LSP (10) + Muninn + ChromaDB
13. ChromaDB systemd service
14. Shokunin + Superpowers + Caveman
15. Security tools (Trivy, Qodana)
16. Project structure (AGENTS.md, WAL, agents, docker-compose)
17. opencode.json generation (Python inline)
18. Git config
19. PATH persistence
20. Fix .zshrc + P10k
21. Auth reminder
22. Verification (30+ checks)

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
bash -n setup.sh                    # syntax check
bash setup.sh --health              # diagnostics (36 checks)
bash setup.sh --fix-config          # regenerate opencode.json
bash setup.sh --fix-zshrc           # repair shell config
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
