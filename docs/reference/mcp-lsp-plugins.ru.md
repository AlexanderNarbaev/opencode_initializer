# Справочник MCP, LSP и плагинов

Полный справочник всей AI-инфраструктуры, настраиваемой OpenCode Initializer.

## MCP-серверы (21 локальный + 4 удалённых)

MCP (Model Context Protocol) серверы расширяют OpenCode внешними инструментами и источниками данных.

### Локальные серверы

| Сервер | Пакет | Категория | Описание |
|--------|-------|-----------|----------|
| **filesystem** | `@modelcontextprotocol/server-filesystem` | Ядро | Операции с файловой системой — чтение, запись, список, поиск |
| **git** | `mcp-server-git` | Ядро | Git-операции — log, diff, branch, commit |
| **github** | `@modelcontextprotocol/server-github` | Платформа | GitHub API — репозитории, issues, PR, поиск |
| **gitlab** | `mcp-server-gitlab` | Платформа | GitLab API — зеркало GitHub-сервера |
| **memory** | `@modelcontextprotocol/server-memory` | AI | Граф знаний с постоянной памятью |
| **sequential-thinking** | `@modelcontextprotocol/server-sequential-thinking` | AI | Пошаговые цепочки рассуждений |
| **memorylayer** | `@scitrera/memorylayer-mcp-server` | AI | Продвинутая память с сохранением сессий |
| **fetch** | `mcp-server-fetch` | Сеть | HTTP-запросы, получение веб-контента |
| **time** | `mcp-server-time` | Утилиты | Конвертация часовых поясов, текущее время |
| **sqlite** | `mcp-server-sqlite` | Данные | Запросы и управление SQLite |
| **postgres** | `@modelcontextprotocol/server-postgres` | Данные | Доступ к PostgreSQL (требуется токен) |
| **redis** | `@modelcontextprotocol/server-redis` | Данные | Операции с Redis |
| **playwright** | `@playwright/mcp` | Браузер | Полная автоматизация браузера (Chromium) |
| **agent-browser** | `agent-browser-mcp-server` | Браузер | Лёгкое управление браузером для веб-задач |
| **chrome-devtools** | `chrome-devtools-mcp` | Браузер | Доступ к Chrome DevTools Protocol |
| **brave-search** | `brave-search-mcp` | Поиск | Веб-поиск через Brave Search API |
| **context7** | `context7-mcp` | Поиск | Поиск по документации кода |
| **context7-official** | `@upstash/context7-mcp` | Поиск | Официальная документация библиотек Context7 |
| **agentic-tools** | `@pimzino/agentic-tools-mcp` | Агент | Управление задачами, планирование |
| **codegraph** | `codegraph-mcp` | Анализ | Анализ зависимостей и графа вызовов |
| **loopsense** | `@loopsense/mcp` | Анализ | Качество кода и лучшие практики |

### Удалённые серверы

| Сервер | Пакет | Категория | Описание |
|--------|-------|-----------|----------|
| **sentry** | `@sentry/mcp` | Мониторинг | Отслеживание ошибок и производительности |
| **grep** | `grep-mcp` | Утилиты | Поиск по содержимому кодовой базы |
| **excalidraw** | `excalidraw-mcp` | Дизайн | Архитектурные диаграммы и технические рисунки |
| **google-maps** | `mcp-server-google-maps` | Локация | Геокодирование и маршруты Google Maps |

### Холодный старт

Большинство MCP-серверов используют **абсолютные пути к Bun** (`~/.bun/bin/mcp-server-*`) вместо `npx -y`:

- 0.5с холодный старт против 5-15с с npx
- Без сети после установки
- Переживает очистку кэша npm

## LSP-серверы (13)

| Сервер | Язык | Возможности |
|--------|------|-------------|
| **gopls** | Go | Автодополнение, переход к определению, рефакторинг |
| **rust-analyzer** | Rust | Полный IDE-опыт, интеграция с borrow checker |
| **tsserver** | TypeScript/JavaScript | Проверка типов, автодополнение, быстрые исправления |
| **pyright** | Python | Статическая проверка типов, автодополнение |
| **omnisharp** | C# / .NET | Полная поддержка C# |
| **yaml-ls** | YAML | Валидация схем, автодополнение, форматирование |
| **marksman** | Markdown | Проверка ссылок, генерация оглавления |
| **taplo** | TOML | Форматирование, валидация, автодополнение |
| **lua-ls** | Lua | Автодополнение, диагностика, аннотации |
| **zls** | Zig | Полная поддержка Zig |
| **bash-ls** | Bash/Shell | Анализ shell-скриптов, диагностика |
| **dockerfile-ls** | Dockerfile | Подсветка синтаксиса, валидация |
| **css/html/json** | Web | Поддержка CSS/HTML/JSON |

### Архитектурно-зависимые LSP

| Сервер | amd64 | arm64 |
|--------|-------|-------|
| gopls | :white_check_mark: | :white_check_mark: |
| rust-analyzer | :white_check_mark: | :white_check_mark: |
| omnisharp | :white_check_mark: x64 | :white_check_mark: arm64 |
| zls | :white_check_mark: x86_64 | :white_check_mark: aarch64 |

Установщик автоматически определяет архитектуру CPU и загружает правильный бинарник.

## Плагины (15)

| Плагин | Описание |
|--------|----------|
| **token-tracker** | Отслеживание расхода токенов |
| **dcp** | Damage Control Protocol — предотвращение опасных действий |
| **swarm** | Координация множественных агентов |
| **goal-mode** | Структурированная разработка по целям |
| **vibeguard** | Контроль качества перед завершением |
| **orchestrator** | Оркестрация и делегирование задач |
| **auto-fallback** | Автоматическое переключение провайдеров |
| **notify** | Уведомления на рабочий стол |
| **pty** | Эмуляция терминала |
| **snip** | Управление сниппетами кода |
| **snippets** | Переиспользуемые шаблоны кода |
| **envsitter-guard** | Защита переменных окружения |
| **command-inject** | Внедрение команд для субагентов |
| **ignore** | Игнорирование файлов по шаблону |
| **gitlab** | Интеграция с GitLab |

## Конфигурация

### Форматы команд MCP-серверов

```json
// Локальный сервер (bun — быстрый холодный старт)
{
  "type": "local",
  "command": ["/home/user/.bun/bin/mcp-server-filesystem", "/project"]
}

// Локальный сервер (npx fallback — если bun отсутствует)
{
  "type": "local",
  "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "/project"]
}

// Удалённый сервер (HTTP)
{
  "type": "remote",
  "url": "https://mcp.example.com/sse"
}
```

### Формат плагинов

```json
{
  "plugin": [
    ["token-tracker@latest"],
    ["dcp@v2.0.0"],
    ["swarm@latest"]
  ]
}
```

### Добавление своих MCP/LSP/плагинов

1. **MCP-сервер**: Добавить в `opencode.json` -> `mcpServers`
2. **LSP-сервер**: Добавить в `opencode.json` -> `lsp`
3. **Плагин**: Добавить в `opencode.json` -> `plugin`

Для общесистемной установки измените `src/lib/12-mcp-lsp.sh` и запустите `bash setup.sh --reinit`.

---

**См. также:**
- [Архитектура](../architecture/) — C4-диаграммы и схема модулей
- [Справочник](../reference/) — CLI и схема opencode.json
- [Руководство](../user-guide/) — повседневное использование MCP и LSP
- [Продвинутое](../advanced/) — собственная настройка MCP/LSP
