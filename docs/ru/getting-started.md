# Быстрый старт

## Требования

- Ubuntu 22.04+ / Debian 12+ / Fedora 40+
- Node.js 24+
- Python 3.14+
- Go 1.26+
- Rust 1.97+

## Установка

```bash
# Клонировать репозиторий
git clone https://github.com/AlexanderNarbaev/opencode_initializer.git
cd opencode_initializer

# Запустить установку
bash setup.sh --full

# Проверить установку
har status
```

## Первые шаги

1. Проверить статус: `har status`
2. Посмотреть агентов: `har agents`
3. Проверить навыки: `har skills`
4. Запустить OpenCode: `opencode`

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
