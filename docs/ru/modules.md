# Модули

## Обзор

OpenCode Initializer содержит 62 модуля в директории `src/lib/`. Каждый модуль отвечает за установку и настройку конкретного компонента.

## Список модулей

### Базовые (00-10)

| Модуль | Описание | Зависимости |
|--------|----------|-------------|
| 00-core.sh | Базовая инфраструктура, прогресс, OS/PKG определение | — |
| 01-system.sh | Системные пакеты (apt/dnf/pacman/apk/zypper/brew) | 00-core |
| 01b-linux-platform.sh | Определение Linux платформы (WSL2/Ubuntu/Debian/Fedora/Arch/Alpine) | 00-core |
| 02-docker.sh | Docker engine | 01-system |
| 03-chrome.sh | Google Chrome + chromedriver | 01-system |
| 04-zsh.sh | Zsh + Oh My Zsh + P10k + 14 плагинов | 01-system |
| 05-java.sh | Java 25 (Adoptium API → SDKMAN → apt) | 01-system |
| 06-node.sh | Node.js 24 (n → apt) | 01-system |
| 07-python.sh | Python 3.14 + uv | 01-system |
| 08-go.sh | Go 1.26 (direct download → apt fallback) | 01-system |
| 09-rust.sh | Rust 1.97.1 (rustup → apt) | 01-system |
| 10-dotnet.sh | .NET 10 (dotnet-install → apt) | 01-system |

### Инструменты (11-20)

| Модуль | Описание | Зависимости |
|--------|----------|-------------|
| 11-opencode.sh | OpenCode CLI 1.17 + Bun 1.3.14 | 06-node |
| 12-mcp-lsp.sh | 24 MCP сервера + 15 плагинов + 13 LSP + Muninn | 11-opencode |
| 13-chromadb.sh | ChromaDB systemd сервис | 07-python |
| 14-shokunin.sh | Shokunin + Superpowers + Caveman | 06-node |
| 15-security.sh | Trivy, Qodana | 01-system |
| 16-llm.sh | Ollama, vLLM, SGLang, Open WebUI, WasmEdge | 01-system |
| 17-project.sh | Структура проекта (AGENTS.md, WAL, agents, docker-compose) | — |
| 18-opencode-json.sh | Генерация opencode.json (Python inline, bun bin paths, 23 providers) | 11-opencode |
| 19-finalize.sh | Git config, PATH, .zshrc, auth reminder, verification (36 checks) | — |
| 20-autoupdate.sh | topgrade + systemd weekly timer + unattended-upgrades | 01-system |

### RAG и Web (21-30)

| Модуль | Описание | Зависимости |
|--------|----------|-------------|
| 21-rag.sh | RAG система — Corporate Knowledge Assistant | 13-chromadb |
| 22-webui-service.sh | Open WebUI systemd user service | 16-llm |
| 23-just.sh | just — task runner с default justfile | 01-system |
| 24-websearch.sh | SearXNG веб-поиск + sanitizer proxy | 01-system |
| 26-providers.sh | 23 LLM provider registry с session switching | 11-opencode |
| 27-dotfiles.sh | chezmoi dotfiles manager | 01-system |
| 28-devbox.sh | Devbox — Nix-based isolated dev environments | 01-system |
| 29-mise.sh | mise-en-place — universal tool version manager | 01-system |
| 30-infra.sh | Infrastructure: PostgreSQL + Qdrant + Redis + Prometheus + Grafana + MemoryLayer | 02-docker |

### Инфраструктура (31-40)

| Модуль | Описание | Зависимости |
|--------|----------|-------------|
| 31-cockpit.sh | Cockpit TUI server management daemon (7-tab TUI) | 01-system |
| 32-isolated.sh | Isolated Circuit Mode — air-gapped LLM | 16-llm |
| 33-services.sh | Unified Service Layer — port resolution, service modes | 30-infra |
| 34-observability.sh | Grafana + Prometheus + Node Exporter | 30-infra |
| 35-gui.sh | Web GUI — management interface on port 4200 | 06-node |
| 36-model-router.sh | Model routing intelligence — task-based model selection | 26-providers |
| 37-wal.sh | Write-Ahead Log — setup checkpoint + agent session journal | — |
| 38-ide-plugins.sh | IDE AI plugins — DevoxxGenie + GitHub Copilot | 01-system |
| 40-best-practices.sh | Best practices — linting, formatting, pre-commit hooks | 01-system |

### SDD и Governance (41-50)

| Модуль | Описание | Зависимости |
|--------|----------|-------------|
| 41-constitution.sh | Constitution + spec format generator | 17-project |
| 42-hooks.sh | Lifecycle hooks framework — pre-request, post-response, pre-commit, on-error | — |
| 43-governance.sh | Model governance — model-policy.json allowlist/blocklist | — |
| 44-audit.sh | Audit trail — 7 WAL event types, SHA-256 hash-chain | 37-wal |
| 45-pii-guard.sh | PII sanitizer — 9 детекторов | — |
| 46-offline-bundle.sh | Air-gap offline bootstrap — tarball bundle, SHA-256 manifest | — |
| 47-lynis.sh | Lynis CIS scanner — system security audit + cron.weekly | 01-system |
| 48-auditd.sh | Linux audit daemon — 18 kernel audit rules | 01-system |
| 49-deepseek-harness.sh | DeepSeek Harness (dsh) — agent harness с plugin architecture | 06-node |
| 50-sandcastle.sh | Sandcastle — sandboxed agent orchestration (Docker/Podman/Vercel) | 06-node |

### Контекст и интеллект (51-60)

| Модуль | Описание | Зависимости |
|--------|----------|-------------|
| 51-opencode-desktop.sh | OpenCode Desktop — desktop version installer | 06-node |
| 52-context-selector.sh | Context-Aware MCP/LSP Selector — task-scoped selection | 12-mcp-lsp |
| 53-auto-skills.sh | Auto-triggering skill system | — |
| 54-task-distributor.sh | Intelligent task distribution across agents | — |
| 55-context-bundle.sh | opencode-context + opencode-router integration | 12-mcp-lsp |
| 56-grace-semantics.sh | GRACE semantic contracts & clarity metrics | — |
| 57-context-guard.sh | Context protection and optimization | — |
| 58-provider-discovery.sh | Automatic provider discovery | 26-providers |
| 59-local-memory.sh | Local memory management | — |
| 60-caching.sh | Prompt caching stack | 12-mcp-lsp |

### Хелперы

| Модуль | Описание |
|--------|----------|
| helpers.sh | _curl(), _retry(), _npm_install(), _sudo() — shared infrastructure |
| version-check.sh | Version check: Rust/Go/Node/Python/Bun/OpenCode/Ollama/Zig |
| pre-session-check.sh | Pre-session provider/model validation + MCP status |

## Конфигурация модулей

### Переменные окружения

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| SKIP_DOTFILES | Пропустить dotfiles | false |
| SKIP_DEVBOX | Пропустить Devbox | false |
| SKIP_GUI | Пропустить GUI | false |
| SKIP_CONTEXT_BUNDLE | Пропустить context bundle | false |
| SKIP_GRACE | Пропустить GRACE семантику | false |
| SKIP_CACHING | Пропустить кэширование | false |

### Прогресс файл

`~/.cache/opencode-setup/progress` — записывает завершённые шаги для идемпотентности.

### Лог файл

`~/.cache/opencode-setup/setup-YYYYMMDD-HHMMSS.log` — лог установки.
