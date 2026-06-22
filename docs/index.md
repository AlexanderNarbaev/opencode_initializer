---
layout: default
title: Ultimate Dev Machine Bootstrap
description: Одна команда — и ваша машина готова к AI-разработке. 8 языков, 21 MCP-сервер, 15+ плагинов, 6 AI-провайдеров, GPU-рантаймы, ZSH+Chrome.
---

# Ultimate Dev Machine Bootstrap

**Одна команда. 15 минут. Полная AI-среда разработки.**

[![Version](https://img.shields.io/badge/version-v36.0-blue)](https://github.com/AlexanderNarbaev/opencode_initializer)
[![ShellCheck](https://img.shields.io/badge/shellcheck-passing-brightgreen)](https://github.com/AlexanderNarbaev/opencode_initializer/actions)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Stars](https://img.shields.io/github/stars/AlexanderNarbaev/opencode_initializer?style=social)](https://github.com/AlexanderNarbaev/opencode_initializer)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh) --full
```

---

## Навигация по уровням

### Начинающим — с чего начать

| | | |
|---|---|---|
| [Руководство](guide.md) | [Промпты](prompts/system-prompts.md) | [Справка](reference.md) |
| Установка и использование | Готовые промпты для моделей | Официальная документация |

### Практикующим — углублённые руководства

| | | |
|---|---|---|
| [MCP-серверы](tools/mcp-servers.md) | [Плагины](tools/plugins.md) | [Провайдеры](tools/providers.md) |
| 21+ серверов, примеры, команды | 15+ плагинов, безопасность | 6 провайдеров, цены |
| [Языки](tools/languages.md) | [LSP-серверы](tools/lsp-servers.md) | [GPU и LLM](tools/gpu-llm.md) |
| 8 языков, менеджеры | 13 LSP, автодополнение | Локальный инференс |
| [Безопасность](tools/security.md) | [Агенты](tools/agents.md) | |
| 5 уровней защиты | 16 ролей, права | |

### Экспертам — исследования и аналитика

| |
|---|
| [База знаний](KNOWLEDGE.md) — глубокий анализ: модели, RAG, GPU, безопасность, CI/CD, галлюцинации, SGLang, память |

---

## Быстрый старт

**Минимальный (одна команда):**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh) --full
```

**С API-ключами (рекомендуется):**

```bash
bash setup.sh --full \
  --deepseek-key "sk-..." \
  -k "opencode-api-key" \
  --xai-key "xai-..." \
  -n "Ваше Имя" \
  -e "email@example.com"
```

**Интерактивный (для новичков):**

```bash
bash setup.sh --interactive
```

Скрипт задаст вопросы: что ставить, что пропустить.

---

## Что вы получите

Модульная архитектура (284-строчный оркестратор + 24 модуля) устанавливает всё это с правильными настройками.

### Языки (8)

Java 25, Node.js 24, Python 3.14 + uv, Go 1.26, Rust, .NET 10, Kotlin, Zig 0.16.
[Подробнее](tools/languages.md)

### MCP-серверы (21+: локальные + Python + remote)

| Активные по умолчанию | С ключом | Remote |
|---|---|---|
| context7 | github (GITHUB_TOKEN) | sentry |
| context7-official | postgres (PG_STRING) | grep |
| filesystem | gitlab (GITLAB_TOKEN) | |
| agentic-tools | google-maps (MAPS_KEY) | |
| codegraph | brave-search (BRAVE_KEY) | |
| playwright | notion (NOTION_KEY) | |
| agent-browser | | |
| loopsense | | |
| sequential-thinking | | |
| memorylayer | | |
| chrome-devtools | | |
| memory | | |
| redis | | |
| git (uvx) | | |
| fetch (uvx) | | |
| time (uvx) | | |
| sqlite (uvx) | | |
| excalidraw (uvx) | | |

[Подробнее](tools/mcp-servers.md)

### Плагины (15+)

| Ядро | Инфраструктура | AI-усиление |
|---|---|---|
| opencode-codegraph | opencode-daytona | opencode-background-agents |
| opencode-orchestrator | opencode-devcontainers | opencode-skillful |
| opencode-token-tracker | opencode-worktree | opencode-goal-plugin |
| opencode-notify | opencode-scheduler | opencode-conductor |
| opencode-pty | | opencode-supermemory |
| opencode-ignore | | opencode-websearch-cited |
| opencode-snip | | opencode-firecrawl |
| opencode-snippets | | |
| envsitter-guard | | |
| opencode-command-inject | | |
| opencode-dcp | | |
| opencode-auto-fallback | | |
| opencode-goal-mode | | |
| opencode-swarm | | |
| opencode-vibeguard | | |

[Подробнее](tools/plugins.md)

### AI-провайдеры (6)

DeepSeek (основной), OpenCode Go, xAI Grok, MiMo, Moonshot, MiniMax. Динамическая активация по наличию API-ключей.
[Подробнее](tools/providers.md)

### LSP-серверы (13 пакетов / 15 серверов)

gopls, rust-analyzer, typescript-language-server, pyright, omnisharp/csharp-ls, yaml-language-server, marksman, taplo, lua-language-server, zls, bash-language-server, dockerfile-language-server-nodejs, vscode-langservers-extracted (css+html+json).
[Подробнее](tools/lsp-servers.md)

### Агенты (16 ролей)

developer, architect, qa, security, devops, reviewer, researcher, designer, pm, analyst, docs-writer, security-auditor, debugger, go-dev, rust-dev, ts-dev.
[Подробнее](tools/agents.md)

### ZSH + Chrome

ZSH 5.8+ (chsh default), Oh My Zsh + P10k, 14 плагинов (fzf-tab, zsh-completions, npm, bun, ...). Google Chrome + chromedriver (WSL2-aware --no-sandbox), chrome-open лаунчер.
[Подробнее](guide.md)

### GPU и локальные LLM

Ollama, vLLM, SGLang, Open WebUI, LlamaEdge, GPUStack.
[Подробнее](tools/gpu-llm.md)

### Безопасность — 5 уровней

1. **Хранение секретов** — `secrets.env` (chmod 600), никогда в shell-rc
2. **Фильтрация входа** — envsitter-guard: PII, секреты, prompt-инъекции
3. **Блокировка выхода** — deterministic políticas block опасных команд
4. **Сканирование кода** — Trivy + Qodana: CVE, баги, уязвимости
5. **WSL2 hardening** — изоляция Windows PATH, systemd, авто-очистка

[Подробнее](tools/security.md)

### Инфраструктура (Docker)

PostgreSQL 18, MongoDB 8, Redis 7, Kafka, MinIO, WireMock, Keycloak, LocalStack.

---

## Режимы работы

| Команда | Что делает | Когда |
|---------|-----------|------|
| `--full` | Полная установка | Первый запуск |
| `--reinit` | Переустановка (данные сохраняются) | Что-то сломалось |
| `--interactive` | Пошаговый выбор компонентов | Не знаете что нужно |
| `--health` | Диагностика (60+ проверок) | Проверить систему |
| `--update` | Обновление инструментов | Прошло время |
| `--upgrade` | Полное обновление системы | Капитальный апгрейд |
| `--new <dir>` | Новый проект | Ещё один проект |
| `--fix-config` | Перегенерировать opencode.json | Сломалась конфигурация |
| `--fix-zshrc` | Починить терминал | zsh глючит |
| `--dry-run` | Показать план без изменений | Посмотреть что будет |

Прогресс сохраняется. Если скрипт упал — перезапустите, он продолжит с места сбоя.

---

## Как это работает

```
Пользователь: @developer "добавь API для авторизации"
    │
    ▼
OpenCode CLI
    ├── envsitter-guard (фильтр PII и атак)
    ├── codegraph (граф вызовов проекта)
    ▼
DeepSeek V4 Pro (генерация кода)
    ▼
    ├── orchestrator (координация multi-agent сценариев)
    ├── filesystem MCP (запись в проект)
    ├── loopsense (отслеживание ошибок)
    ▼
Готовый код + авто-исправление ошибок
```

---

## CLI `dev`

```bash
dev health              # диагностика (60+ проверок)
dev list                # что установлено
dev update              # обновить инструменты + миграции
dev self-update         # обновить скрипт из git
dev version-check       # сравнить версии с актуальными
dev autoupdate          # полное обновление системы (topgrade)
dev install llm         # доустановить GPU/LLM
dev install docker      # доустановить Docker
dev remove java         # удалить компонент
dev config              # редактировать ~/.config/opencode-setup/setup.conf
```

---

## Кроссплатформенность

| Пакетный менеджер | Дистрибутивы |
|-------------------|-------------|
| apt | Ubuntu, Debian, Mint, Pop!_OS |
| dnf | Fedora, RHEL, CentOS Stream |
| pacman | Arch, Manjaro, EndeavourOS |
| apk | Alpine |
| zypper | openSUSE |
| brew | macOS, Linuxbrew |

Архитектуры: amd64 и arm64. Зеркала для РФ.

---

## Решение проблем

| Проблема | Решение |
|----------|---------|
| Скрипт упал | `bash setup.sh --health` затем `--full` (продолжит) |
| OpenCode не стартует | `bash setup.sh --fix-config` |
| Терминал глючит | `bash setup.sh --fix-zshrc` |
| MCP не работает | `npm list -g \| grep mcp` затем `--reinit` |
| DNS/интернет (РФ) | Yandex DNS (77.88.8.8) + Google/Cloudflare добавляются автоматически |

---

## Исследования и ресурсы

- [Руководство](guide.md) — полная установка, настройка, решение проблем
- [База знаний](KNOWLEDGE.md) — почему выбраны эти инструменты и конфигурации
- [Промпты](prompts/system-prompts.md) — оптимизированные промпты для моделей и ролей
- [Справка](reference.md) — 100+ ссылок на официальную документацию

---

**MIT License** · [Alexander Narbaev](https://github.com/AlexanderNarbaev) · 2025–2026

[GitHub](https://github.com/AlexanderNarbaev/opencode_initializer) · [GitVerse](https://gitverse.ru/alexander.narbayev/opencode_initializer) · [Star](https://github.com/AlexanderNarbaev/opencode_initializer)
