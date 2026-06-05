---
layout: default
title: Ultimate Dev Machine Bootstrap
description: Одна команда — и ваша машина готова к AI-разработке. 8 языков, 13 MCP-серверов, 7 плагинов безопасности, 6 AI-провайдеров, GPU-рантаймы.
keywords: opencode, dev machine, AI agent, MCP, bash script, developer tools, WSL2, Linux, macOS
author: Alexander Narbaev
lang: ru
---

<div align="center">

# ⚡ Ultimate Dev Machine Bootstrap

**Одна команда. 15 минут. Полная AI-среда разработки.**

[![Version](https://img.shields.io/badge/version-v33.9-blue)](https://github.com/AlexanderNarbaev/opencode_initializer)
[![ShellCheck](https://img.shields.io/badge/shellcheck-passing-brightgreen)](https://github.com/AlexanderNarbaev/opencode_initializer/actions)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Stars](https://img.shields.io/github/stars/AlexanderNarbaev/opencode_initializer?style=social)](https://github.com/AlexanderNarbaev/opencode_initializer)

</div>

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh) --full
```

---

## Что вы получите

<div align="center">

| 🚀 Языки | 🔧 MCP-серверы | 🛡️ Плагины | ☁️ AI-провайдеры |
|:---:|:---:|:---:|:---:|
| Java 25 | context7 | danger-control | DeepSeek V4 Pro |
| Node.js 22 | codegraph | stranger-danger | OpenCode Go |
| Python 3.12 | playwright | codegraph | xAI Grok |
| Go 1.24+ | agent-browser | auto-fallback | MiMo |
| Rust | memorylayer | dcp | Moonshot |
| .NET 9 | filesystem | lazy-loader | MiniMax |
| Kotlin | loopsense | orchestra | — |
| Zig | +6 servers | — | — |

</div>

Один bash-скрипт (~2300 строк) устанавливает **всё это** с правильными настройками, без необходимости разбираться в каждом компоненте.

---

## Навигация

<div align="center">

| 📖 [Руководство](guide.md) | 🧠 [База знаний](KNOWLEDGE.md) | 🎯 [Промпты](prompts/system-prompts.md) |
|:---:|:---:|:---:|
| Как установить и использовать | Почему выбраны эти инструменты | Оптимальные промпты для моделей |

</div>

### Инструменты — подробные руководства

<div align="center">

| | | |
|:---:|:---:|:---:|
| [MCP-серверы](tools/mcp-servers.md) | [Плагины](tools/plugins.md) | [Провайдеры](tools/providers.md) |
| 13 серверов, примеры, команды | 7 плагинов, цепочка безопасности | 6 провайдеров, цены, сравнение |
| [Языки](tools/languages.md) | [LSP-серверы](tools/lsp-servers.md) | [GPU и LLM](tools/gpu-llm.md) |
| 8 языков, менеджеры пакетов | 10 LSP, автодополнение | Локальный инференс, кластеры |
| [Безопасность](tools/security.md) | [Агенты](tools/agents.md) | |
| 5 уровней защиты | 10 ролей, права, примеры | |

</div>

---

## Быстрый старт

### Минимальный (одна команда)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh) --full
```

### С API-ключами (рекомендуется)

```bash
bash setup.sh --full \
  --deepseek-key "sk-..." \
  -k "opencode-api-key" \
  --xai-key "xai-..." \
  -n "Ваше Имя" \
  -e "email@example.com"
```

### Интерактивный (для новичков)

```bash
bash setup.sh --interactive
```

> Скрипт задаст 16 вопросов: что ставить, что пропустить. Выбирайте только нужное.

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

**Прогресс сохраняется.** Если скрипт упал — перезапустите, он продолжит с места сбоя.

---

## Как это работает

```
Пользователь → @developer "добавь API для авторизации"
    │
    ▼
OpenCode CLI (агент-хост)
    │
    ├── stranger-danger (фильтр PII и атак)
    ├── codegraph (граф вызовов проекта)
    │
    ▼
DeepSeek V4 Pro (генерация кода)
    │
    ▼
    ├── damage-control (защита от опасных команд)
    ├── filesystem MCP (запись в проект)
    ├── loopsense (отслеживание ошибок)
    │
    ▼
Готовый код + авто-исправление ошибок
```

---

## Безопасность — 5 уровней

Скрипт реализует эшелонированную защиту AI-агента:

1. **Хранение секретов** — `secrets.env` с правами 600, никогда в shell-rc
2. **Фильтрация входа** — stranger-danger: PII, секреты, prompt-инъекции
3. **Блокировка выхода** — damage-control: 144 паттерна опасных команд
4. **Сканирование кода** — Trivy + Qodana: CVE, баги, уязвимости
5. **WSL2 hardening** — изоляция Windows PATH, systemd, авто-очистка кэша

[Подробнее о безопасности →](tools/security.md)

---

## Что под капотом

### 8 языков программирования

Java 25 · Node.js 22 · Python 3.12 + uv · Go 1.24+ · Rust · .NET 9 · Kotlin · Zig

Каждый язык — с оптимальным менеджером пакетов и fallback-стратегией. [Подробнее о языках →](tools/languages.md)

### 13 MCP-серверов

context7 · filesystem · agentic-tools · codegraph · playwright · agent-browser · loopsense · sequential-thinking · memorylayer · github · postgres · sentry · grep

9 активны по умолчанию, 4 опциональны. [Подробнее о MCP →](tools/mcp-servers.md)

### 7 плагинов безопасности и производительности

stranger-danger → damage-control → codegraph → dcp → auto-fallback → lazy-loader → orchestra

[Подробнее о плагинах →](tools/plugins.md)

### 6 AI-провайдеров

DeepSeek · OpenCode Go · xAI Grok · MiMo · Moonshot · MiniMax

Основной — DeepSeek V4 Pro (лучшее цена/качество, доступен из РФ). [Подробнее о провайдерах →](tools/providers.md)

### 10 LSP-серверов

gopls · rust-analyzer · typescript · pyright · omnisharp · yaml · marksman · taplo · lua · zls

Автодополнение, навигация, рефакторинг для каждого языка. [Подробнее о LSP →](tools/lsp-servers.md)

### 10 AI-агентов

| Агент | Модель | Роль |
|-------|--------|------|
| developer | DeepSeek V4 Pro | Пишет код |
| architect | GLM-5.1 | Проектирует |
| qa | MiniMax M2.7 | Тестирует |
| security | GLM-5 | Ищет уязвимости |
| devops | DeepSeek V4 Pro | Docker, CI/CD |
| reviewer | Qwen3.6-Plus | Код-ревью |
| researcher | DeepSeek V4 Pro | Исследует |
| designer | MiniMax M2.7 | UI/UX |
| pm | GLM-5.1 | Управляет требованиями |
| analyst | GLM-5.1 | Анализирует |

[Подробнее об агентах →](tools/agents.md)

### GPU и локальные LLM

Ollama · vLLM · SGLang · Open WebUI · LlamaEdge · GPUStack

Локальный инференс на своём железе, без интернета и облачных API. [Подробнее о GPU/LLM →](tools/gpu-llm.md)

### Инфраструктура (Docker)

PostgreSQL 18 · MongoDB 8 · Redis 7 · Kafka · MinIO · WireMock · Keycloak · LocalStack

Полный набор для локальной разработки микросервисов.

---

## Как выбрать что нужно именно вам

### «Я не программист, хочу попробовать»
```bash
bash setup.sh --interactive
```
На вопросы про Java, Rust, .NET, Go, Docker, GPU отвечайте **n**. Оставьте Node.js, Python, OpenCode.

### «Я веб-разработчик (JS/Python)»
```bash
bash setup.sh --full --deepseek-key "sk-..." -n "Имя" -e "email"
```
Всё по умолчанию. Лишние языки не мешают.

### «У меня слабый ноутбук»
```bash
bash setup.sh --interactive
```
На вопросе «Local LLM runtimes?» — **n**. GPU-рантаймы не установятся.

### «Мне только OpenCode и Python»
Интерактивный режим, отключить всё кроме Python + OpenCode + MCP + LSP.

---

## CLI `dev`

После установки:

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
| `apt` | Ubuntu, Debian, Mint, Pop!_OS |
| `dnf` | Fedora, RHEL, CentOS Stream |
| `pacman` | Arch, Manjaro, EndeavourOS |
| `apk` | Alpine |
| `zypper` | openSUSE |
| `brew` | macOS, Linuxbrew |

Архитектуры: **amd64** и **arm64**. Зеркала для РФ (GitHub, npm, PyPI, Docker, Go, Rust).

---

## Решение проблем

| Проблема | Решение |
|----------|---------|
| Скрипт упал | `bash setup.sh --health` → `bash setup.sh --full` (продолжит) |
| OpenCode не стартует | `bash setup.sh --fix-config` |
| Терминал глючит | `bash setup.sh --fix-zshrc` |
| MCP не работает | `npm list -g \| grep mcp` → `bash setup.sh --reinit` |
| DNS/интернет (РФ) | DNS Яндекса и Cloudflare добавляются автоматически |

---

<div align="center">

## 📚 Исследования и аналитика

[База знаний](KNOWLEDGE.md) — почему выбраны именно эти инструменты и конфигурации. Сравнительный анализ моделей, GPU, векторных БД, безопасности.

[Промпты](prompts/system-prompts.md) — оптимизированные системные промпты для каждой модели и роли агента. Максимум качества при минимуме токенов.

---

**MIT License** · [Alexander Narbaev](https://github.com/AlexanderNarbaev) · 2025–2026

[⭐ Star on GitHub](https://github.com/AlexanderNarbaev/opencode_initializer) · [Issues](https://github.com/AlexanderNarbaev/opencode_initializer/issues) · [GitVerse](https://gitverse.ru/alexander.narbayev/opencode_initializer)

</div>
