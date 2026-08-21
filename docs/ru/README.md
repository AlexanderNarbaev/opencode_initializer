# OpenCode Initializer v3.2.0

> **Модель эксплуатации:** Мультиагентный фреймворк v3.0 | **Волна:** [current_wave.md](../current_wave.md) | **Контрольная точка:** [session_checkpoint.json](../session_checkpoint.json)

## Быстрый старт

```bash
# Установка
git clone https://github.com/AlexanderNarbaev/opencode_initializer.git
cd opencode_initializer
bash setup.sh --full

# Проверка
har status
har agents
```

## Архитектура

- **62 модуля** в `src/lib/`
- **57 агентов** (7 primary + 50 subagents)
- **32 плагина** opencode-*
- **16 MCP серверов**
- **12 LSP серверов**
- **43 навыка** (26 SDD + 17 Matt Pocock)

## Модули

| Модуль | Описание |
|--------|----------|
| 00-core.sh | Базовая инфраструктура |
| 01-system.sh | Системные пакеты |
| 02-docker.sh | Docker |
| 03-chrome.sh | Google Chrome |
| 04-zsh.sh | Zsh + Oh My Zsh |
| 05-java.sh | Java 25 |
| 06-node.sh | Node.js 24 |
| 07-python.sh | Python 3.14 |
| 08-go.sh | Go 1.26 |
| 09-rust.sh | Rust 1.97 |
| 10-dotnet.sh | .NET 10 |
| 11-opencode.sh | OpenCode CLI |
| 12-mcp-lsp.sh | MCP + LSP серверы |
| 13-chromadb.sh | ChromaDB |
| 14-shokunin.sh | Shokunin |
| 15-security.sh | Безопасность |
| 16-llm.sh | LLM рантаймы |
| 17-project.sh | Структура проекта |
| 18-opencode-json.sh | Конфигурация OpenCode |
| 19-finalize.sh | Финализация |
| 20-autoupdate.sh | Автообновление |
| 21-rag.sh | RAG система |
| 22-webui-service.sh | Web UI |
| 23-just.sh | Just task runner |
| 24-websearch.sh | Веб-поиск |
| 26-providers.sh | Провайдеры LLM |
| 27-dotfiles.sh | Dotfiles |
| 28-devbox.sh | Devbox |
| 29-mise.sh | Mise |
| 30-infra.sh | Инфраструктура |
| 31-cockpit.sh | Cockpit TUI |
| 32-isolated.sh | Изолированный режим |
| 33-services.sh | Сервисы |
| 34-observability.sh | Мониторинг |
| 35-gui.sh | Web GUI |
| 36-model-router.sh | Маршрутизация моделей |
| 37-wal.sh | Write-Ahead Log |
| 38-ide-plugins.sh | IDE плагины |
| 40-best-practices.sh | Лучшие практики |
| 41-constitution.sh | Конституция проекта |
| 42-hooks.sh | Хуки жизненного цикла |
| 43-governance.sh | Управление моделями |
| 44-audit.sh | Аудит |
| 45-pii-guard.sh | PII санитайзер |
| 46-offline-bundle.sh | Офлайн бандл |
| 47-lynis.sh | Lynis CIS |
| 48-auditd.sh | Auditd |
| 49-deepseek-harness.sh | DeepSeek Harness |
| 50-sandcastle.sh | Sandcastle |
| 51-opencode-desktop.sh | OpenCode Desktop |
| 52-context-selector.sh | Контекстный селектор |
| 53-auto-skills.sh | Авто-навыки |
| 54-task-distributor.sh | Распределение задач |
| 55-context-bundle.sh | Контекстный бандл |
| 56-grace-semantics.sh | GRACE семантика |
| 57-context-guard.sh | Защита контекста |
| 58-provider-discovery.sh | Обнаружение провайдеров |
| 59-local-memory.sh | Локальная память |
| 60-caching.sh | Кэширование |

## Конфигурация

### Основной конфиг
`~/.config/opencode/opencode.json`

### Shared config для харнессов
`~/.config/opencode/bundle.json`

### Навыки проекта
`.opencode/skills/`

## Команды har

```bash
har status          # Статус системы
har agents          # Список агентов
har skills          # Список навыков
har plugins         # Список плагинов
har mcp             # MCP серверы
har lsp             # LSP серверы
har providers       # Провайдеры LLM
har context         # Контекст
har grace help      # GRACE семантика
har apply-all       # Применить ко всем проектам
har evolve          # Самоулучшение
har web             # Веб-интерфейс
har update          # Обновление
```

## GRACE семантика

```bash
har grace contract <file>      # Создать контракт
har grace clarity <file>       # Оценить ясность
har grace position <file>      # Позиционный контекст
har grace focus <file> <query> # Sparse focus
har grace normalize <file>     # Нормализация JSON
har grace hallucination <ctx> <out> # Проверка галлюцинаций
```

## Агенты

### Primary (7)
- **build** — основной агент
- **plan** — планирование
- **architect** — архитектор (Commander)
- **goal** — автономная доставка
- **compaction** — компактизация контекста
- **summary** — резюме сессии
- **title** — заголовок сессии

### Subagents (50)
- **coder** — реализация (Worker)
- **researcher** — исследования (Planner)
- **reviewer** — ревью (Reviewer)
- **goal-*** — 26 goal-специалистов
- **general, explore, code-reviewer** — встроенные
- **critic, curator, sme, test_engineer** — специалисты

## Плагины

### Установленные (32)
- opencode-codegraph — граф знаний
- opencode-dcp — динамическое прунинг контекста
- opencode-auto-fallback — фоллбэк провайдеров
- opencode-goal-mode — режим цели
- opencode-goal-plugin — инструменты цели
- opencode-orchestrator — оркестратор
- opencode-swarm — рой агентов
- opencode-supermemory — память
- opencode-token-tracker — трекинг токенов
- opencode-vibeguard — безопасность
- opencode-context — семантический поиск
- opencode-router — маршрутизация
- и другие...

## MCP серверы (16)

- context7 — документация
- codegraph — анализ кода
- playwright — браузер
- github — GitHub API
- memory — память
- sqlite — SQLite
- filesystem — файловая система
- excalidraw — диаграммы
- и другие...

## LSP серверы (12)

- typescript-language-server — TypeScript/JavaScript
- pyright — Python
- gopls — Go
- rust-analyzer — Rust
- yaml-language-server — YAML
- marksman — Markdown
- taplo — TOML
- bash-language-server — Bash
- docker-langserver — Docker
- vscode-css-language-server — CSS
- vscode-html-language-server — HTML
- vscode-json-language-server — JSON

## Навыки (43)

### SDD (26)
- coprocessor — двойное мышление
- specify — спецификация
- plan — планирование
- execute — исполнение
- brainstorm — брейнсторминг
- clarify — уточнение
- deep-dive — глубокое исследование
- deep-research — глубокий research
- design-docs — дизайн-документы
- discover — исследование
- running-tests — запуск тестов
- writing-tests — написание тестов
- commit-pr — коммит и PR
- consult — консультации
- council — совет экспертов
- codebase-review-swarm — ревью кодовой базы
- и другие...

### Matt Pocock (17)
- grill-me — прожарка идей
- grill-with-docs — прожарка с документацией
- tdd — разработка через тесты
- diagnosing-bugs — дебаггинг
- code-review — ревью кода
- codebase-design — проектирование
- domain-modeling — доменная модель
- implement — реализация
- to-spec — генерация спеков
- to-tickets — генерация тикетов
- wayfinder — планирование
- prototype — прототипы
- research — исследования
- improve-codebase-architecture — улучшение архитектуры
- resolving-merge-conflicts — разрешение конфликтов
- wizard — визарды

## Харнессы

### DeepSeek Harness (dsh)
```bash
dsh web              # Веб-интерфейс
dsh --profile headless # Headless режим
dsh --profile tui    # TUI режим
```

### Sandcastle
```bash
# Оркестрация в песочницах
# Docker, Podman, Vercel
```

### OpenCode Desktop
```bash
opencode-desktop     # Десктопная версия
```

## Лицензия

MIT License

## Ссылки

- [GitHub](https://github.com/AlexanderNarbaev/opencode_initializer)
- [Документация](../docs/)
- [Руководство](../docs/guides/)
