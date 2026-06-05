---
layout: default
---

# Ultimate Dev Machine Bootstrap

**Однокомандная настройка AI-усиленной dev-машины** — WSL2, Linux, macOS.

Один bash-скрипт (~2300 строк), устанавливающий полный стек разработки с AI-агентами, MCP-серверами, LSP, плагинами и GPU-рантаймами.

## Быстрый старт

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh) --full
```

## Что устанавливается

### Языки (8)
Java 25 (Adoptium) · Node.js 22 · Python 3.12 + uv · Go 1.26 · Rust 1.93 · .NET 9 · Kotlin · Zig

### MCP-серверы (13)
context7 · filesystem · agentic-tools · codegraph · playwright · agent-browser · loopsense · memorylayer · github · postgres · sequential-thinking · sentry · grep

### Плагины (7)
opencode-codegraph · open-orchestra · opencode-dcp · opencode-lazy-loader · opencode-stranger-danger · opencode-damage-control · opencode-auto-fallback

### Провайдеры AI (6)
DeepSeek V4 Pro · OpenCode Go · xAI Grok · Xiaomi MiMo · Moonshot Kimi K2.6 · MiniMax M3

### Инструменты
clawrouter (умный роутинг 55+ моделей) · agents-md-sync (AGENTS.md синхронизация) · ChromaDB (векторная память) · Muninn · Shokunin (62+ skills) · Superpowers · Caveman

### Безопасность
damage-control (144 защищённых паттерна) · stranger-danger (PII/секреты) · Trivy · Qodana

### Инфраструктура
Docker · Kafka · PostgreSQL 18 · MongoDB 8 · Redis 7 · MinIO

### GPU/LLM (опционально)
Ollama · vLLM · SGLang · Open WebUI · LlamaEdge

## Режимы

| Команда | Описание |
|---------|----------|
| `bash setup.sh --full` | Полная установка |
| `bash setup.sh --reinit` | Переустановка инструментов |
| `bash setup.sh --new <dir>` | Инициализация нового проекта |
| `bash setup.sh --health` | Диагностика (36+ проверок) |
| `bash setup.sh --update` | Обновление инструментов |
| `bash setup.sh --upgrade` | Полное обновление системы |
| `bash setup.sh --interactive` | Пошаговый выбор компонентов |
| `bash setup.sh --fix-config` | Перегенерировать opencode.json |
| `bash setup.sh --fix-zshrc` | Починить .zshrc |
| `bash setup.sh --dry-run --full` | Показать что будет |

## CLI `dev`

```bash
dev health              # диагностика всей системы
dev list                # список установленных компонентов
dev update              # обновить всё + миграции
dev self-update         # обновить скрипт из git
dev install llm         # доустановить GPU/LLM
dev install docker      # доустановить Docker
dev remove java         # удалить компонент
dev config              # редактировать конфиг
```

## Кроссплатформа

| Пакетный менеджер | Дистрибутивы |
|-------------------|-------------|
| `apt` | Ubuntu, Debian, Mint, Pop!_OS |
| `dnf` | Fedora, RHEL, CentOS Stream |
| `pacman` | Arch, Manjaro, EndeavourOS |
| `apk` | Alpine Linux |
| `zypper` | openSUSE |
| `brew` | macOS, Linuxbrew |

## Зеркала для России

Автоматический фолбэк: GitHub → ghproxy.com, npm → npmmirror.com, pip → mirror.yandex.ru, Go → golang.google.cn.

## Требования

- Любой Linux (Ubuntu 24.04+, Debian 12+, Fedora, Arch, Alpine, openSUSE)
- macOS (Homebrew)
- WSL2 (Windows 10/11)
- amd64 или arm64
- 10GB+ свободного места
- Sudo-доступ

## Лицензия

MIT

---

[GitHub](https://github.com/AlexanderNarbaev/opencode_initializer) · [GitVerse](https://gitverse.ru/alexander.narbayev/opencode_initializer)
