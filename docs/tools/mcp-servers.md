---
layout: default
title: MCP-серверы — opencode_initializer
description: 21+ MCP-серверов: описание, примеры, команды. Model Context Protocol для AI-агентов.
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

## Активные по умолчанию (18 серверов)

### context7 — документация в реальном времени

Пакет: `c7-mcp-server` · Команда: `c7-mcp-server` · [npm](https://www.npmjs.com/package/c7-mcp-server)

Доступ к живой документации популярных библиотек (React, Next.js, Prisma, Spring Boot и сотни других).

```
Пользователь: "Добавь авторизацию через NextAuth с Prisma"
Без Context7: агент использует training data (могла устареть)
С Context7: агент читает актуальную доку NextAuth
```

Критичен: модели обучаются на данных 6-12 мес. давности. API меняется быстрее.

### context7-official — официальный MCP от Upstash

Пакет: `@upstash/context7-mcp` · [npm](https://www.npmjs.com/package/@upstash/context7-mcp)

Официальная версия Context7 MCP от Upstash. Заменяет community-версию `c7-mcp-server`.

### filesystem — доступ к файлам

Пакет: `@modelcontextprotocol/server-filesystem` · Команда: `npx -y @modelcontextprotocol/server-filesystem <project_dir>` · [GitHub](https://github.com/modelcontextprotocol/servers)

Инструменты: read_text_file, write_file, list_directory, search_files, grep, edit_file.

### agentic-tools — память задач

Пакет: `@pimzino/agentic-tools-mcp` · 38 инструментов · [npm](https://www.npmjs.com/package/@pimzino/agentic-tools-mcp)

Создание проектов, задач, подзадач с приоритетами и зависимостями. Поиск и сохранение знаний.

### codegraph — граф вызовов

Пакет: `@colbymchenry/codegraph` · Команда: `codegraph serve --mcp` · [npm](https://www.npmjs.com/package/@colbymchenry/codegraph)

Инструменты: context (главный), search, node, trace, impact, explore, explain_function, review.

### playwright — браузерное тестирование

Пакет: `@playwright/mcp` · Команда: `npx -y @playwright/mcp` · [GitHub](https://github.com/microsoft/playwright-mcp)

Навигация, клики, заполнение форм, скриншоты, JavaScript, перехват сетевых запросов.

### agent-browser — расширенный браузер

Пакет: `agent-browser-mcp-server` · Команда: `npx -y agent-browser-mcp-server` · 60+ инструментов · [npm](https://www.npmjs.com/package/agent-browser-mcp-server)

Уникальные фичи: PDF, cookie/localStorage, network routing (mock API), profiler, tracing, запись видео, сравнение скриншотов.

### loopsense — отслеживание изменений

Пакет: `@loopsense/mcp` · Команда: `npx -y @loopsense/mcp` · [npm](https://www.npmjs.com/package/@loopsense/mcp)

Watchers: файлы (chokidar), процессы, CI/CD (GitHub Actions), URL polling, входящие вебхуки.

### sequential-thinking — пошаговое рассуждение

Пакет: `@modelcontextprotocol/server-sequential-thinking` · [GitHub](https://github.com/modelcontextprotocol/servers)

Структура: гипотеза → проверка → ревизия → вывод. Поддерживает ветвление и пересмотр.

### memorylayer — персистентная память

Пакет: `@scitrera/memorylayer-mcp-server` · 38 инструментов · [npm](https://www.npmjs.com/package/@scitrera/memorylayer-mcp-server)

remember, recall, reflect, session_start/end, chat_threads. Сочетает векторный поиск + графовую структуру.

### chrome-devtools — Chrome DevTools Protocol

Пакет: `chrome-devtools-mcp` · Команда: `npx -y chrome-devtools-mcp` · [npm](https://www.npmjs.com/package/chrome-devtools-mcp)

Lighthouse аудит, performance tracing, heap snapshot, скриншоты, навигация, клики, заполнение форм.

### memory — Knowledge Graph память

Пакет: `@modelcontextprotocol/server-memory` · [GitHub](https://github.com/modelcontextprotocol/servers)

Создание сущностей, наблюдений, отношений в Knowledge Graph. Семантический поиск.

### redis — Redis операции

Пакет: `@modelcontextprotocol/server-redis` · [GitHub](https://github.com/modelcontextprotocol/servers)

Взаимодействие с Redis: ключи, хеши, списки, множества, паб/саб.

### git — Git операции (Python/uvx)

Пакет: `mcp-server-git` · Команда: `uvx mcp-server-git` · [PyPI](https://pypi.org/project/mcp-server-git/)

Git операции: status, log, diff, branch, commit. Устанавливается через uvx/pipx.

### fetch — HTTP запросы (Python/uvx)

Пакет: `mcp-server-fetch` · Команда: `uvx mcp-server-fetch` · [PyPI](https://pypi.org/project/mcp-server-fetch/)

HTTP GET запросы к внешним URL. Конвертация HTML в Markdown.

### time — конвертация времени (Python/uvx)

Пакет: `mcp-server-time` · Команда: `uvx mcp-server-time` · [PyPI](https://pypi.org/project/mcp-server-time/)

Конвертация между часовыми поясами, получение текущего времени.

### sqlite — SQLite базы данных (Python/uvx)

Пакет: `mcp-server-sqlite` · Команда: `uvx mcp-server-sqlite` · [PyPI](https://pypi.org/project/mcp-server-sqlite/)

Чтение/запись SQLite баз, выполнение запросов, интроспекция схем.

### excalidraw — генерация диаграмм (Python/uvx)

Пакет: `excalidraw-architect-mcp` · Команда: `uvx excalidraw-architect-mcp` · [PyPI](https://pypi.org/project/excalidraw-architect-mcp/)

Генерация архитектурных диаграмм в формате Excalidraw из описаний.

---

## С ключом API (6 серверов — включаются при наличии токена)

| Сервер | Пакет | Ключ | GitHub |
|--------|-------|------|--------|
| github | `@modelcontextprotocol/server-github` | `GITHUB_TOKEN` | [servers](https://github.com/modelcontextprotocol/servers) |
| postgres | `@modelcontextprotocol/server-postgres` | `PG_CONNECTION_STRING` | [servers](https://github.com/modelcontextprotocol/servers) |
| gitlab | `mcp-server-gitlab` | `GITLAB_TOKEN` | [servers](https://github.com/modelcontextprotocol/servers) |
| google-maps | `mcp-server-google-maps` | `GOOGLE_MAPS_API_KEY` | [servers](https://github.com/modelcontextprotocol/servers) |
| brave-search | `brave-search-mcp` | `BRAVE_API_KEY` | — |
| notion | `@notionhq/notion-mcp-server` | `NOTION_API_KEY` | — |

---

## Remote (2 сервера — без локального бинарника)

| Сервер | URL | Почему отключён | Как включить |
|--------|-----|-----------------|-------------|
| sentry | `https://mcp.sentry.dev/mcp` | Нужен аккаунт Sentry | `enabled: true` |
| grep | `https://mcp.grep.app` | Нужен интернет | `enabled: true` |

Включение/отключение: в `~/.config/opencode/opencode.json` изменить `"enabled": true/false` в секции `mcp`.
