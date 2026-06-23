# Справочник MCP, LSP и плагинов

Полный справочник всей AI-инфраструктуры, настраиваемой OpenCode Initializer.

## MCP-серверы (24)

MCP (Model Context Protocol) серверы расширяют OpenCode внешними инструментами и источниками данных.

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
| **sentry** | `@sentry/mcp` | Мониторинг | Отслеживание ошибок (удалённый) |
| **grep** | `grep-mcp` | Утилиты | Поиск по содержимому (удалённый) |
| **agentic-tools** | `@pimzino/agentic-tools-mcp` | Агент | Управление задачами, планирование |
| **codegraph** | `codegraph-mcp` | Анализ | Анализ зависимостей и графа вызовов |
| **loopsense** | `@loopsense/mcp` | Анализ | Качество кода и лучшие практики |
| **excalidraw** | `excalidraw-mcp` | Дизайн | Архитектурные диаграммы |
| **google-maps** | `mcp-server-google-maps` | Локация | Геокодирование и маршруты Google Maps |

### Холодный старт

Большинство MCP-серверов используют **абсолютные пути к Bun** (`~/.bun/bin/mcp-server-*`) вместо `npx -y`:

- :zap: **0.5с холодный старт** против 5-15с с npx
- :package: **Без сети** после установки
- :recycle: **Переживает** очистку кэша npm

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

## Плагины (18)

| Плагин | Описание |
|--------|----------|
| **token-tracker** | Отслеживание расхода токенов |
| **dcp** | Damage Control Protocol — предотвращение опасных действий |
| **swarm** | Координация множественных агентов |
| **goal-mode** | Структурированная разработка по целям |
| **vibeguard** | Контроль качества перед завершением |
| **orchestrator** | Оркестрация и делегирование задач |
| **notify** | Уведомления на рабочий стол |
| **pty** | Эмуляция терминала |
| **snip** | Управление сниппетами кода |
| **snippets** | Переиспользуемые шаблоны кода |
| **envsitter-guard** | Защита переменных окружения |
| **command-inject** | Внедрение команд для субагентов |
| **ignore** | Игнорирование файлов по шаблону |
| **auto-fallback** | Автоматическое переключение провайдеров |
| **gitlab** | Интеграция с GitLab |
| **google-maps** | Интеграция с Google Maps |
| **chrome-devtools** | Интеграция с Chrome DevTools |
| **postgres** | Интеграция с PostgreSQL (условно) |

---

**См. также:**
- [Архитектура](../architecture/) — C4-диаграммы и схема модулей
- [Справочник](../reference/) — CLI и схема opencode.json
- [Руководство](../user-guide/) — повседневное использование MCP и LSP
- [Продвинутое](../advanced/) — собственная настройка MCP/LSP
