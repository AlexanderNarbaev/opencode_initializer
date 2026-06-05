# Ultimate Dev Machine Bootstrap

**Однокомандная настройка AI-усиленной dev-машины — WSL2, Linux, macOS.**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh) --full
```

## Что делает (v33.9)

- **8 языков**: Java 25 (Adoptium), Node.js 22, Python 3.12 + uv, Go 1.26, Rust 1.93, .NET 9, Kotlin, Zig
- **13 MCP-серверов (11 local + 2 remote)**: context7, filesystem, agentic-tools, codegraph, playwright, agent-browser, loopsense, memorylayer, github, postgres, sequential-thinking (+ sentry, grep — remote)
- **7 плагинов**: opencode-codegraph, open-orchestra, opencode-dcp (контекст-прунинг), opencode-lazy-loader, opencode-stranger-danger (PII-фильтрация), opencode-damage-control (144 guardrails), opencode-auto-fallback (model switching)
- **Dev-инструменты**: clawrouter (умный роутинг, 55+ моделей), agents-md-sync (AGENTS.md синхронизация), CLI `dev`
- **10 LSP-серверов**: gopls, rust-analyzer, typescript, pyright, omnisharp, yaml, marksman, taplo, lua, zls
- **Безопасность**: dcp + damage-control через plugin tuple (валидная schema), 144 защищённых паттерна, secrets.env (chmod 600)
- **Multi-Provider AI (6 провайдеров)**: DeepSeek V4 Pro, OpenCode Go, Xiaomi MiMo, xAI Grok, Moonshot (Kimi K2.6), MiniMax M3 — авто-переключение, setCacheKey для 99% экономии
- **GPU/LLM (опционально)**: Ollama, vLLM, SGLang, Open WebUI, LlamaEdge
- **Память**: ChromaDB + Muninn (векторная БД) + MemoryLayer MCP (38 инструментов памяти)
- **Безопасность**: damage-control (144 защищённых паттерна), stranger-danger (PII/секреты), secrets.env (chmod 600)
- **Инфраструктура**: Docker, Kafka, Postgres, MongoDB, Redis, MinIO
- **Кроссплатформа**: Ubuntu, Debian, Fedora, Arch, Alpine, openSUSE, macOS (brew)
- **Архитектуры**: amd64 + arm64
- **Зеркала для РФ**: авто-фолбэк GitHub→ghproxy, npm→npmmirror, pip→yandex

## Быстрый старт

```bash
# Полная установка (curl, без скачивания скрипта)
bash <(curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh) --full

# С ключами API
bash setup.sh --full -k "sk-..." --deepseek-key "sk-..." -s "мой-sudo-пароль"

# Интерактивный режим (выбрать что ставить)
bash setup.sh --interactive

# Только посмотреть что будет (dry-run)
bash setup.sh --dry-run --full

# Диагностика (без изменений)
bash setup.sh --health
```

## После установки — CLI `dev`

```bash
dev health              # диагностика всей системы
dev list                # список установленных компонентов
dev update              # обновить всё + миграции
dev self-update         # обновить сам скрипт из git
dev install llm         # доустановить GPU/LLM
dev config              # редактировать конфиг
```

## Восстановление после сбоя

```bash
# Если скрипт упал — просто перезапустить. Прогресс сохраняется.
bash setup.sh --full

# Проверить что сломалось
bash setup.sh --health

# Починить конфиг OpenCode
bash setup.sh --fix-config

# Починить .zshrc
bash setup.sh --fix-zshrc

# Переустановить всё (данные проекта сохранятся)
bash setup.sh --reinit
```

## GPU / Локальные LLM

```bash
# При интерактивной установке выбрать "y" на вопрос "Local LLM runtimes?"
bash setup.sh --interactive

# Или доустановить потом:
dev install llm

# После установки:
ollama run qwen3:14b           # запустить модель (14B — для 16GB VRAM)
ollama pull deepseek-r1:8b     # ещё одна модель
open http://localhost:3300     # Open WebUI — чат-интерфейс
```

## Зеркала для России

Скрипт автоматически определяет недоступность сервисов и переключается на зеркала:
- GitHub → `ghproxy.com`
- npm → `registry.npmmirror.com`
- pip → `mirror.yandex.ru`
- Go → `golang.google.cn`

Никаких ручных настроек не требуется.

## Кроссплатформа

| Пакетный менеджер | Дистрибутивы |
|-------------------|-------------|
| `apt` | Ubuntu, Debian, Mint, Pop!_OS |
| `dnf` | Fedora, RHEL, CentOS Stream |
| `pacman` | Arch, Manjaro, EndeavourOS |
| `apk` | Alpine Linux |
| `zypper` | openSUSE |
| `brew` | macOS, Linuxbrew |

Скрипт автоматически определяет систему и использует правильный пакетный менеджер.

## Все режимы

| Режим | Описание |
|-------|----------|
| `--full` | Полная установка (по умолчанию) |
| `--reinit` | Переустановка инструментов, данные сохраняются |
| `--new <dir>` | Инициализация нового проекта |
| `--health` | Диагностика (36+ проверок) |
| `--update` | Обновление инструментов |
| `--upgrade` | Полное обновление системы |
| `--interactive` | Пошаговый выбор компонентов |
| `--fix-config` | Перегенерировать opencode.json |
| `--fix-zshrc` | Починить .zshrc |
| `--dry-run` | Показать что будет, без изменений |

## Опции

| Флаг | Описание |
|------|----------|
| `-k, --api-key` | OpenCode Go API ключ |
| `--deepseek-key` | DeepSeek API ключ |
| `--xai-key` | xAI Grok API ключ |
| `--mimo-key` | Xiaomi MiMo API ключ |
| `--moonshot-key` | Moonshot (Kimi K2.6) API ключ |
| `--minimax-key` | MiniMax M3 API ключ |
| `-s, --sudo-pass` | Sudo пароль (кешируется) |
| `-p, --project-dir` | Директория проекта (default: ~/projects) |
| `-n, --git-name` | Имя для git |
| `-e, --git-email` | Email для git |

## Структура проекта

```
opencode_initializer/
├── setup.sh              # основной скрипт (2309 строк)
├── dev.sh                # CLI: dev install|remove|update|health|list|config
├── lib/helpers.sh        # общие функции (_curl, _retry, _npm_install)
├── migrations/           # миграции (авто-запуск при dev update)
├── .github/workflows/    # CI (ShellCheck)
├── v17.0.sh ... v27.0.sh # архивные версии
└── AGENTS.md             # документация для AI-агентов
```

## Требования

- Любой Linux (Ubuntu 24.04+, Debian 12+, Fedora, Arch, Alpine, openSUSE)
- macOS (Homebrew)
- WSL2 (Windows 10/11)
- amd64 или arm64
- 10GB+ свободного места
- Sudo-доступ

## Лицензия

MIT

## Документация

- [Полное руководство](docs/guide.md) — все функции, MCP, плагины, агенты
- [GitHub Pages](https://alexandernarbaev.github.io/opencode_initializer/)
- [AGENTS.md](AGENTS.md) — документация для AI-агентов
