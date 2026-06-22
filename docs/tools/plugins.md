---
layout: default
title: Плагины OpenCode — 29 плагинов безопасности, производительности и AI-усиления
description: 15+ ядерных плагинов + 14 дополнительных: codegraph, orchestrator, dcp, token-tracker, auto-fallback, swarm, vibeguard и другие.
---

[Главная](../index.md) · [Справка](../reference.md)

# Плагины OpenCode

Плагины работают внутри OpenCode и влияют на его поведение. В отличие от MCP (внешние инструменты), плагины — часть самого агента.

## Архитектура

```
envsitter-guard → codegraph → orchestrator → swarm → goal-mode
   (безопасность)   (анализ)   (координация)  (паралл.)  (цели)
```

---

## Ядро (15 плагинов — устанавливаются всегда)

### opencode-codegraph

Пакет: `opencode-codegraph` · [npm](https://www.npmjs.com/package/opencode-codegraph)

Автоматически обогащает диалог графом вызовов. Экономия контекста: 5x (200 токенов вместо 1000).

```json
"plugin": ["opencode-codegraph"]
```

### opencode-orchestrator

Пакет: `opencode-orchestrator` · [npm](https://www.npmjs.com/package/opencode-orchestrator)

Оркестрация multi-agent сценариев. Координирует параллельную работу агентов: architect → developer → reviewer → qa.

### opencode-token-tracker

Пакет: `opencode-token-tracker` · [npm](https://www.npmjs.com/package/opencode-token-tracker)

Отслеживание использования токенов в реальном времени. Статистика по провайдерам и моделям.

### opencode-notify

Пакет: `opencode-notify` · [npm](https://www.npmjs.com/package/opencode-notify)

Системные уведомления о завершении длительных задач (через `notify-send` на Linux).

### opencode-pty

Пакет: `opencode-pty` · [npm](https://www.npmjs.com/package/opencode-pty)

Поддержка псевдотерминалов для интерактивных CLI команд.

### opencode-ignore

Пакет: `opencode-ignore` · [npm](https://www.npmjs.com/package/opencode-ignore)

Управление паттернами `.gitignore`-подобного игнорирования файлов для AI-контекста.

### opencode-snip / opencode-snippets

Пакеты: `opencode-snip`, `opencode-snippets` · [npm snip](https://www.npmjs.com/package/opencode-snip) · [npm snippets](https://www.npmjs.com/package/opencode-snippets)

Управление и вставка сниппетов кода. `snip` — быстрое, `snippets` — с категоризацией.

### envsitter-guard — защита переменных окружения

Пакет: `envsitter-guard` · [npm](https://www.npmjs.com/package/envsitter-guard)

Фильтрация PII и секретов из промптов. Блокирует prompt-инъекции. Заменяет stranger-danger.

Что фильтрует: API-ключи, токены, пароли, email, телефоны, попытки injection. Не даёт агенту читать `.env` файлы.

### opencode-command-inject

Пакет: `opencode-command-inject` · [npm](https://www.npmjs.com/package/opencode-command-inject)

Внедрение пользовательских команд в контекст агента. Позволяет кастомизировать поведение.

### opencode-dcp — Dynamic Context Pruning

Пакет: `@tarquinen/opencode-dcp` · [npm](https://www.npmjs.com/package/@tarquinen/opencode-dcp)

Сжимает контекст при переполнении. Экономия: до 62% стоимости запросов.

```json
["opencode-dcp", {
  "compress": {
    "enabled": true,
    "minContextLimit": 20000,
    "maxContextLimit": 48000,
    "autoCompaction": true
  },
  "prune": {
    "enabled": true,
    "protectTokens": 40000,
    "minTokens": 20000
  }
}]
```

| Ситуация | Действие |
|----------|----------|
| Меньше 20K токенов | Сжатие не требуется |
| 20K-48K | Агрессивное сжатие старых сообщений |
| Больше 48K | Защита последних 40K, сжатие остального |

### opencode-auto-fallback — автопереключение

Пакет: `opencode-auto-fallback` · [npm](https://www.npmjs.com/package/opencode-auto-fallback)

Порядок переключения: DeepSeek → OpenCode Go → xAI → MiMo → Moonshot → MiniMax.

### opencode-goal-mode

Пакет: `opencode-goal-mode` · [npm](https://www.npmjs.com/package/opencode-goal-mode)

Режим строгой проверки целей. Каждое действие агента проверяется на соответствие Goal Contract.

### opencode-swarm

Пакет: `opencode-swarm` · [npm](https://www.npmjs.com/package/opencode-swarm)

Рой агентов для параллельного выполнения независимых задач. Автоматическое разделение работы.

### opencode-vibeguard

Пакет: `opencode-vibeguard` · [npm](https://www.npmjs.com/package/opencode-vibeguard)

Мониторинг и фильтрация нежелательного поведения агента. Детекция вредоносных паттернов.

---

## Инфраструктура (4 плагина)

### opencode-daytona

Пакет: `opencode-daytona` · [npm](https://www.npmjs.com/package/opencode-daytona)

Интеграция с [Daytona](https://daytona.io) для управления dev-средами.

### opencode-devcontainers

Пакет: `opencode-devcontainers` · [npm](https://www.npmjs.com/package/opencode-devcontainers)

Поддержка Dev Containers: создание, запуск, управление контейнерами разработки.

### opencode-worktree

Пакет: `opencode-worktree` · [npm](https://www.npmjs.com/package/opencode-worktree)

Управление git worktrees для изолированной параллельной разработки.

### opencode-scheduler

Пакет: `opencode-scheduler` · [npm](https://www.npmjs.com/package/opencode-scheduler)

Планировщик фоновых задач и периодических проверок.

---

## AI-усиление (4 плагина)

### opencode-background-agents

Пакет: `opencode-background-agents` · [npm](https://www.npmjs.com/package/opencode-background-agents)

Фоновые агенты для асинхронных задач (индексация, анализ, мониторинг).

### opencode-skillful

Пакет: `@zenobius/opencode-skillful` · [npm](https://www.npmjs.com/package/@zenobius/opencode-skillful)

Улучшенная система навыков с авто-обнаружением и ранжированием.

### opencode-goal-plugin

Пакет: `opencode-goal-plugin` · [npm](https://www.npmjs.com/package/opencode-goal-plugin)

Цель-ориентированное планирование с авто-декомпозицией задач.

### opencode-conductor

Пакет: `opencode-conductor` · [npm](https://www.npmjs.com/package/opencode-conductor)

Дирижёр multi-agent оркестрации — маршрутизация, балансировка, мониторинг.

---

## Память / утилиты (5 плагинов)

### opencode-supermemory

Пакет: `opencode-supermemory` · [npm](https://www.npmjs.com/package/opencode-supermemory)

Улучшенная долговременная память с автоматической индексацией и поиском.

### opencode-websearch-cited

Пакет: `opencode-websearch-cited` · [npm](https://www.npmjs.com/package/opencode-websearch-cited)

Веб-поиск с автоматическим цитированием источников.

### opencode-firecrawl

Пакет: `@lyculs/opencode-firecrawl` · [npm](https://www.npmjs.com/package/@lyculs/opencode-firecrawl)

Веб-скрапинг через Firecrawl API. Извлечение структурированного контента.

### opencode-zellij-namer

Пакет: `opencode-zellij-namer` · [npm](https://www.npmjs.com/package/opencode-zellij-namer)

Автоматическое именование Zellij-панелей на основе текущей задачи.

### opencode-morph-plugin

Пакет: `@morphllm/opencode-morph-plugin` · [npm](https://www.npmjs.com/package/@morphllm/opencode-morph-plugin)

Трансформация и оптимизация промптов для разных моделей.

---

## Телеметрия (1 плагин)

### opencode-otel

Пакет: `@devtheops/opencode-plugin-otel` · [npm](https://www.npmjs.com/package/@devtheops/opencode-plugin-otel)

OpenTelemetry-интеграция: traces, metrics, logs для мониторинга агента.
