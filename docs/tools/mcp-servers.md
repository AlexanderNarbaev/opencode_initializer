---
layout: default
title: MCP-серверы — opencode_initializer
description: 13 MCP-серверов: описание, примеры, команды. Model Context Protocol для AI-агентов.
---

[Главная](../index.md) · [Справка](../reference.md)

# MCP-серверы

MCP (Model Context Protocol) — протокол, позволяющий AI-агенту взаимодействовать с внешними инструментами. Без MCP агент «слеп». С MCP — читает файлы, запускает браузер, анализирует код.

[Официальная спецификация MCP](https://modelcontextprotocol.io/)

### Что такое MCP — просто

AI-агент — это разработчик в пустой комнате с терминалом. MCP-серверы — инструменты, которые вы ему даёте:

- **filesystem** — доступ к проекту (чтение, запись файлов)
- **codegraph** — карта кода (кто кого вызывает)
- **playwright** — браузер (открыть сайт, проверить работу)
- **context7** — документация (актуальные API библиотек)
- **memorylayer** — записная книжка (помнит прошлые сессии)

Без MCP агент только «думает». С MCP — «думает и делает».

---

## Активные по умолчанию (9 серверов)

### context7 — документация в реальном времени

Пакет: `c7-mcp-server` · Команда: `c7-mcp-server`

Доступ к живой документации популярных библиотек (React, Next.js, Prisma, Spring Boot и сотни других).

```
Пользователь: "Добавь авторизацию через NextAuth с Prisma"
Без Context7: агент использует training data (могла устареть)
С Context7: агент читает актуальную доку NextAuth
```

Критичен: модели обучаются на данных 6-12 мес. давности. API меняется быстрее.

### filesystem — доступ к файлам

Пакет: `@modelcontextprotocol/server-filesystem` · Команда: `npx -y @modelcontextprotocol/server-filesystem <project_dir>`

Инструменты: read_text_file, write_file, list_directory, search_files, grep, edit_file.

### agentic-tools — память задач

Пакет: `@pimzino/agentic-tools-mcp` · Команда: `npx -y @pimzino/agentic-tools-mcp` · 38 инструментов

Создание проектов, задач, подзадач с приоритетами и зависимостями. Поиск и сохранение знаний.

### codegraph — граф вызовов

Пакет: `@colbymchenry/codegraph` · Команда: `codegraph serve --mcp`

Инструменты: context (главный), search, node, trace, impact, explore, explain_function, review.

### playwright — браузерное тестирование

Пакет: `@playwright/mcp` · Команда: `npx -y @playwright/mcp`

Навигация, клики, заполнение форм, скриншоты, JavaScript, перехват сетевых запросов.

### agent-browser — расширенный браузер

Пакет: `agent-browser-mcp-server` · Команда: `npx -y agent-browser-mcp-server` · 60+ инструментов

Уникальные фичи: PDF, cookie/localStorage, network routing (mock API), profiler, tracing, запись видео, сравнение скриншотов.

### loopsense — отслеживание изменений

Пакет: `@loopsense/mcp` · Команда: `npx -y @loopsense/mcp`

Watchers: файлы (chokidar), процессы, CI/CD (GitHub Actions), URL polling, входящие вебхуки.

### sequential-thinking — пошаговое рассуждение

Пакет: `@modelcontextprotocol/server-sequential-thinking` · Команда: `npx -y @modelcontextprotocol/server-sequential-thinking`

Структура: гипотеза → проверка → ревизия → вывод. Поддерживает ветвление и пересмотр.

### memorylayer — персистентная память

Пакет: `@scitrera/memorylayer-mcp-server` · Команда: `npx -y @scitrera/memorylayer-mcp-server` · 38 инструментов

remember, recall, reflect, session_start/end, chat_threads. Сочетает векторный поиск + графовую структуру.

---

## Отключённые по умолчанию (4 сервера)

| Сервер | Пакет | Почему отключён | Как включить |
|--------|-------|-----------------|-------------|
| github | `@modelcontextprotocol/server-github` | Нужен GITHUB_TOKEN | Установить токен, `enabled: true` |
| postgres | `@modelcontextprotocol/server-postgres` | Нужен PostgreSQL | Указать строку подключения |
| sentry | remote `https://mcp.sentry.dev/mcp` | Нужен аккаунт Sentry | `enabled: true` |
| grep | remote `https://mcp.grep.app` | Нужен интернет | `enabled: true` |

Включение/отключение: в `~/.config/opencode/opencode.json` изменить `"enabled": true/false` в секции `mcp`.
