---
layout: default
title: Ultimate Dev Machine Bootstrap
description: Одна команда — и ваша машина готова к AI-разработке. 8 языков, 13 MCP-серверов, 7 плагинов, 6 AI-провайдеров, GPU-рантаймы, ZSH+Chrome.
---

# Ultimate Dev Machine Bootstrap

**Одна команда. 15 минут. Полная AI-среда разработки.**

[![Version](https://img.shields.io/badge/version-v33.10-blue)](https://github.com/AlexanderNarbaev/opencode_initializer)
[![ShellCheck](https://img.shields.io/badge/shellcheck-passing-brightgreen)](https://github.com/AlexanderNarbaev/opencode_initializer/actions)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Stars](https://img.shields.io/github/stars/AlexanderNarbaev/opencode_initializer?style=social)](https://github.com/AlexanderNarbaev/opencode_initializer)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh) --full
```

---

## Что вы получите

Один bash-скрипт (~2300 строк) устанавливает всё это с правильными настройками.

| Языки | MCP-серверы | Плагины | AI-провайдеры |
|-------|-------------|---------|---------------|
| Java 25 | context7 | damage-control | DeepSeek V4 Pro |
| Node.js 22 | codegraph | stranger-danger | OpenCode Go |
| Python 3.12 | playwright | codegraph | xAI Grok |
| Go 1.24+ | agent-browser | auto-fallback | MiMo |
| Rust | memorylayer | dcp | Moonshot |
| .NET 9 | filesystem | lazy-loader | MiniMax |
| Kotlin | loopsense | orchestra | |
| Zig | github | | |
| | postgres | | |
| | +4 more | | |

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
| 13 серверов, примеры, команды | 7 плагинов, безопасность | 6 провайдеров, цены |
| [Языки](tools/languages.md) | [LSP-серверы](tools/lsp-servers.md) | [GPU и LLM](tools/gpu-llm.md) |
| 8 языков, менеджеры | 10 LSP, автодополнение | Локальный инференс |
| [Безопасность](tools/security.md) | [Агенты](tools/agents.md) | |
| 5 уровней защиты | 10 ролей, права | |

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

Скрипт задаст 16 вопросов: что ставить, что пропустить.

---

## Режимы работы

| Команда | Что делает | Когда |
|---------|-----------|------|
| `--full` | Полная установка | Первый запуск |
| `--reinit` | Переустановка (данные сохраняются) | Что-то сломалось |
| `--interactive` | Пошаговый выбор компонентов | Не знаете что нужно |
| `--health` | Диагностика (36+ проверок) | Проверить систему |
| `--update` | Обновление инструментов | Прошло время |
| `--upgrade` | Полное обновление системы | Капитальный апгрейд |
| `--new <dir>` | Новый проект | Ещё один проект |
| `--fix-config` | Перегенерировать opencode.json | Сломалась конфигурация |
| `--fix-zshrc` | Починить терминал | zsh глючит |
| `--dry-run` | Показать план без изменений | Посмотреть что будет |

Прогресс сохраняется. Если скрипт упал — перезапустите, он продолжит.

---

## Как это работает

```
Пользователь: @developer "добавь API для авторизации"
    │
    ▼
OpenCode CLI
    ├── stranger-danger (фильтр PII и атак)
    ├── codegraph (граф вызовов проекта)
    ▼
DeepSeek V4 Pro (генерация кода)
    ▼
    ├── damage-control (защита от опасных команд)
    ├── filesystem MCP (запись в проект)
    ├── loopsense (отслеживание ошибок)
    ▼
Готовый код + авто-исправление ошибок
```

---

## Безопасность — 5 уровней

1. **Хранение секретов** — `secrets.env` (chmod 600), никогда в shell-rc
2. **Фильтрация входа** — stranger-danger: PII, секреты, prompt-инъекции
3. **Блокировка выхода** — damage-control: 144 паттерна опасных команд
4. **Сканирование кода** — Trivy + Qodana: CVE, баги, уязвимости
5. **WSL2 hardening** — изоляция Windows PATH, systemd, авто-очистка

[Подробнее о безопасности](tools/security.md)

---

## Что под капотом

### Языки (8)

Java 25, Node.js 22, Python 3.12 + uv, Go 1.24+, Rust, .NET 9, Kotlin, Zig.
[Подробнее](tools/languages.md)

### MCP-серверы (13: 11 local + 2 remote)

context7, filesystem, agentic-tools, codegraph, playwright, agent-browser, loopsense, sequential-thinking, memorylayer, github, postgres + sentry (remote), grep (remote). GitHub MCP включается при наличии токена.
[Подробнее](tools/mcp-servers.md)

### Плагины (7)

stranger-danger, damage-control, codegraph, dcp, auto-fallback, lazy-loader, orchestra.
[Подробнее](tools/plugins.md)

### AI-провайдеры (6)

DeepSeek (основной), OpenCode Go, xAI Grok, MiMo, Moonshot, MiniMax. Динамическая активация по наличию API-ключей.
[Подробнее](tools/providers.md)

### LSP-серверы (10)

gopls, rust-analyzer, typescript, pyright, omnisharp, yaml, marksman, taplo, lua, zls.
[Подробнее](tools/lsp-servers.md)

### ZSH + Chrome

ZSH 5.8+ (chsh default), Oh My Zsh + P10k, 14 плагинов (fzf-tab, zsh-completions, npm, bun, ...). Google Chrome + chromedriver (WSL2-aware --no-sandbox), chrome-open лаунчер.
[Подробнее](guide.md)

### Агенты (10 ролей)

developer, architect, qa, security, devops, reviewer, researcher, designer, pm, analyst.
[Подробнее](tools/agents.md)

### GPU и локальные LLM

Ollama, vLLM, SGLang, Open WebUI, LlamaEdge, GPUStack.
[Подробнее](tools/gpu-llm.md)

### Инфраструктура (Docker)

PostgreSQL 18, MongoDB 8, Redis 7, Kafka, MinIO, WireMock, Keycloak, LocalStack.

---

## Как выбрать что нужно именно вам

**«Я не программист, хочу попробовать»:**
```bash
bash setup.sh --interactive
```
На вопросы про Java, Rust, .NET, Go, Docker, GPU — `n`. Оставьте Node, Python, OpenCode.

**«Я веб-разработчик (JS/Python)»:**
```bash
bash setup.sh --full --deepseek-key "sk-..." -n "Имя" -e "email"
```

**«У меня слабый ноутбук»:**
Интерактивный режим, на LLM — `n`.

**«Мне только OpenCode и Python»:**
Интерактивный режим, отключить всё кроме Python + OpenCode + MCP + LSP.

---

## CLI `dev`

```bash
dev health              # диагностика (36+ проверок)
dev list                # что установлено
dev update              # обновить инструменты
dev self-update         # обновить скрипт
dev install llm         # доустановить GPU/LLM
dev install docker      # доустановить Docker
dev remove java         # удалить компонент
dev config              # редактировать конфиг
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
| DNS/интернет (РФ) | DNS Яндекса и Cloudflare добавляются автоматически |

---

## Исследования и ресурсы

- [База знаний](KNOWLEDGE.md) — почему выбраны эти инструменты и конфигурации
- [Промпты](prompts/system-prompts.md) — оптимизированные промпты для моделей и ролей
- [Справка](reference.md) — 80+ ссылок на официальную документацию

---

**MIT License** · [Alexander Narbaev](https://github.com/AlexanderNarbaev) · 2025–2026

[GitHub](https://github.com/AlexanderNarbaev/opencode_initializer) · [GitVerse](https://gitverse.ru/alexander.narbayev/opencode_initializer) · [Star](https://github.com/AlexanderNarbaev/opencode_initializer)
