---
layout: default
title: Руководство по использованию — opencode_initializer
description: Полное руководство: установка, настройка, OpenCode, MCP, плагины, агенты, память, GPU, решение проблем.
---

[Главная](index.md) · [База знаний](KNOWLEDGE.md) · [Промпты](prompts/system-prompts.md)

# Полное руководство по использованию

## Установка

### Полная установка (рекомендуется)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh) --full
```

### С API-ключами
```bash
bash setup.sh --full \
  --deepseek-key "sk-..." \
  -k "opencode-api-key" \
  --xai-key "xai-..." \
  --mimo-key "mimo-..." \
  --moonshot-key "ms-..." \
  --minimax-key "mm-..." \
  -n "Your Name" \
  -e "email@example.com"
```

### Интерактивный режим (выбрать компоненты)
```bash
bash setup.sh --interactive
```

### Dry-run (посмотреть без изменений)
```bash
bash setup.sh --dry-run --full
```

## После установки

### Проверка системы
```bash
dev health
```

### Первый запуск OpenCode
```bash
opencode
```

### Конфигурационный файл `~/.config/opencode-setup/setup.conf`

Постоянные настройки, используемые скриптом и dev CLI. Редактировать:
```bash
dev config
```

Пример содержимого:
```bash
# Dev Machine Setup Config — edit with: dev config
GIT_NAME="Alex"
GIT_EMAIL="alex@example.com"
PROJECT_DIR="$HOME/projects"
# DEEPSEEK_KEY="sk-..."
# API_KEY="sk-..."
```

### Модели и провайдеры

Конфигурация в `~/.config/opencode/opencode.json`:
- **Основная**: `deepseek/deepseek-v4-pro` (reasoning, 64K output)
- **Быстрая**: `deepseek/deepseek-v4-flash` ($0.14/1M input)
- **Small model**: `deepseek/deepseek-v4-flash` (фоновые задачи)

Переключение модели:
- `/model deepseek/deepseek-v4-pro`
- `/model opencode-go/glm-5.1`
- `/model xai/grok-3-beta`
- `/model minimax/minimax-m2.7`

### API-ключи

Хранятся в `~/.config/opencode/secrets.env` (chmod 600):
```bash
export DEEPSEEK_API_KEY="sk-..."
export OPENCODE_API_KEY="..."
export XAI_API_KEY="..."
export MIMO_API_KEY="..."
export MOONSHOT_API_KEY="..."
export MINIMAX_API_KEY="..."
```

Или через `/connect` в TUI OpenCode.

## MCP-серверы

[Подробная документация по всем MCP](tools/mcp-servers.md)

### Активные по умолчанию (18 серверов)
- **context7** — живая документация библиотек ([npm](https://www.npmjs.com/package/c7-mcp-server))
- **context7-official** — официальный MCP от Upstash ([npm](https://www.npmjs.com/package/@upstash/context7-mcp))
- **filesystem** — работа с файлами проекта ([GitHub](https://github.com/modelcontextprotocol/servers))
- **agentic-tools** — иерархическая память задач ([npm](https://www.npmjs.com/package/@pimzino/agentic-tools-mcp))
- **codegraph** — граф вызовов, навигация по коду ([npm](https://www.npmjs.com/package/@colbymchenry/codegraph))
- **playwright** — UI-тестирование браузера ([GitHub](https://github.com/microsoft/playwright-mcp))
- **agent-browser** — расширенная автоматизация браузера (60+ инструментов) ([npm](https://www.npmjs.com/package/agent-browser-mcp-server))
- **loopsense** — анализ циклов разработки ([npm](https://www.npmjs.com/package/@loopsense/mcp))
- **sequential-thinking** — пошаговое рассуждение ([GitHub](https://github.com/modelcontextprotocol/servers))
- **memorylayer** — 38 инструментов памяти ([npm](https://www.npmjs.com/package/@scitrera/memorylayer-mcp-server))
- **chrome-devtools** — Chrome DevTools протокол ([npm](https://www.npmjs.com/package/chrome-devtools-mcp))
- **memory** — Knowledge Graph память ([GitHub](https://github.com/modelcontextprotocol/servers))
- **redis** — Redis операции ([GitHub](https://github.com/modelcontextprotocol/servers))
- **git** — Git операции (uvx) ([PyPI](https://pypi.org/project/mcp-server-git/))
- **fetch** — HTTP запросы (uvx) ([PyPI](https://pypi.org/project/mcp-server-fetch/))
- **time** — конвертация времени (uvx) ([PyPI](https://pypi.org/project/mcp-server-time/))
- **sqlite** — SQLite базы данных (uvx) ([PyPI](https://pypi.org/project/mcp-server-sqlite/))
- **excalidraw** — генерация диаграмм (uvx) ([PyPI](https://pypi.org/project/excalidraw-architect-mcp/))

### С ключом API (включаются при наличии токена)
- **github** — GitHub API (нужен `GITHUB_TOKEN`)
- **postgres** — PostgreSQL (нужна строка подключения)
- **gitlab** — GitLab API (нужен `GITLAB_TOKEN`)
- **google-maps** — геолокация (нужен `GOOGLE_MAPS_KEY`)
- **brave-search** — веб-поиск (нужен `BRAVE_API_KEY`)
- **notion** — Notion API (нужен `NOTION_API_KEY`)

### Remote (без локального бинарника)
- **sentry** — мониторинг ошибок (`https://mcp.sentry.dev/mcp`)
- **grep** — поиск по коду (`https://mcp.grep.app`)

### Включение/отключение
В `~/.config/opencode/opencode.json` изменить `"enabled": true/false` в секции `mcp`.

## Плагины

[Подробная документация по всем плагинам](tools/plugins.md)

### Ядро (15 плагинов — всегда устанавливаются)

#### opencode-codegraph
Автоматически обогащает диалог графом вызовов проекта. Экономия контекста: 5x.

#### opencode-orchestrator
Оркестрация multi-agent сценариев. Координирует параллельную работу агентов.

#### opencode-token-tracker
Отслеживание использования токенов в реальном времени.

#### opencode-notify
Системные уведомления о завершении задач.

#### opencode-pty
Поддержка псевдотерминалов для интерактивных команд.

#### opencode-ignore
Управление паттернами игнорирования файлов.

#### opencode-snip / opencode-snippets
Управление сниппетами кода.

#### envsitter-guard
Защита переменных окружения и секретов. Фильтрация PII, prompt-инъекций.

#### opencode-command-inject
Внедрение пользовательских команд в контекст.

#### opencode-dcp (Dynamic Context Pruning)
Автоматическая компрессия и прунинг контекста:
- Минимальный лимит: 20K токенов
- Максимальный: 48K токенов
- Авто-компакция при переполнении

#### opencode-auto-fallback
Автоматическое переключение моделей при ошибках провайдера:
DeepSeek → OpenCode Go → xAI → MiMo → Moonshot → MiniMax.

#### opencode-goal-mode
Режим строгого следования целям (Goal Contract).

#### opencode-swarm
Рой агентов для параллельного выполнения независимых задач.

#### opencode-vibeguard
Защита от нежелательного поведения агента.

### Инфраструктура (4 плагина)
- **opencode-daytona** — интеграция с Daytona для dev-сред
- **opencode-devcontainers** — поддержка Dev Containers
- **opencode-worktree** — управление git worktrees
- **opencode-scheduler** — планировщик фоновых задач

### AI-усиление (4 плагина)
- **opencode-background-agents** — фоновые агенты
- **opencode-skillful** — улучшенные навыки
- **opencode-goal-plugin** — цель-ориентированное планирование
- **opencode-conductor** — дирижёр multi-agent оркестрации

### Память / утилиты (5 плагинов)
- **opencode-supermemory** — улучшенная долговременная память
- **opencode-websearch-cited** — веб-поиск с цитированием
- **opencode-firecrawl** — веб-скрапинг через Firecrawl
- **opencode-zellij-namer** — интеграция с Zellij
- **opencode-morph-plugin** — трансформация промптов

## Агенты

[Подробная документация по агентам](tools/agents.md)

16 предустановленных ролей в `PROJECT_DIR/.opencode/agents/`:

| Агент | Модель | Доступ |
|-------|--------|--------|
| pm | opencode-go/glm-5.1 | read-only |
| analyst | opencode-go/glm-5.1 | read-only |
| architect | opencode-go/glm-5.1 | read-only |
| developer | deepseek/deepseek-v4-pro | full |
| qa | opencode-go/minimax-m2.7 | full |
| security | opencode-go/glm-5 | read-only |
| devops | deepseek/deepseek-v4-pro | full |
| reviewer | opencode-go/qwen3.6-plus | read-only |
| researcher | deepseek/deepseek-v4-pro | read-only |
| designer | opencode-go/minimax-m2.7 | read-only |
| docs-writer | deepseek/deepseek-v4-flash | write (no bash) |
| security-auditor | deepseek/deepseek-v4-pro | read-only |
| debugger | deepseek/deepseek-v4-pro | full |
| go-dev | deepseek/deepseek-v4-pro | full |
| rust-dev | deepseek/deepseek-v4-pro | full |
| ts-dev | deepseek/deepseek-v4-flash | full |

Вызов: `@developer напиши тесты`

## Предсессионная проверка

Скрипт `lib/pre-session-check.sh` валидирует перед стартом сессии:
- Доступность провайдеров (DeepSeek API, OpenCode Go)
- Наличие выбранной модели в списке доступных
- Статус MCP-серверов (запущены/упали)
- Версии инструментов (`dev version-check`)

Встроен в хук старта OpenCode. Запустить вручную:
```bash
dev version-check
```

## Память и контекст

### ChromaDB
Векторная база данных для семантической памяти Muninn.
- Запускается как systemd-сервис при логине
- Порт: 8000 (только localhost)
- Данные: `~/.local/share/chroma/`

### Muninn
Семантическая память для OpenCode. Сохраняет контекст между сессиями.

### Agentic Tools MCP
Иерархическая память задач. Сохраняет решения, прогресс, контекст.

### WAL (Write-Ahead Log)
Файлы в `PROJECT_DIR/wal/`:
- `state.yaml` — состояние всех модулей
- `GLOBAL_WAL.md` — состояние всех модулей (legacy)
- `SESSION_WAL.md` — контекст текущей сессии

## Инструменты разработчика

### clawrouter
Умный роутинг запросов к 55+ моделям.
```bash
clawrouter --help
```

### agents-md-sync
Синхронизация AGENTS.md между проектами.
```bash
agents-md-sync --help
```

### Caveman
Сокращает выходные токены до 75% для рутинных ответов.

## GPU / Локальные LLM

[Подробная документация](tools/gpu-llm.md)

### Установка
```bash
dev install llm
# или при интерактивной установке выбрать "y" на "Local LLM runtimes?"
```

### Использование
```bash
# Ollama
ollama run qwen3:14b
ollama pull deepseek-r1:8b

# Open WebUI (чат-интерфейс)
open http://localhost:3300

# vLLM (GPU-инференс)
vllm serve Qwen/Qwen3-14B

# SGLang
python -m sglang.launch_server --model Qwen/Qwen3-14B
```

## Восстановление после сбоя

```bash
# Скрипт упал — просто перезапустить
bash setup.sh --full

# Проверить что сломалось
bash setup.sh --health

# Починить конфиг
bash setup.sh --fix-config

# Починить .zshrc
bash setup.sh --fix-zshrc

# Переустановить всё
bash setup.sh --reinit
```

## Обновление

```bash
# Обновить инструменты + миграции
dev update

# Обновить setup.sh из git
dev self-update

# Проверить версии всех инструментов
dev version-check

# Полное обновление системы (topgrade)
dev autoupdate

# Полное обновление системы (apt+snap+sdkman+omz+rustup+npm+pip)
bash setup.sh --upgrade
```

### Автообновление (systemd timer)
Topgrade запускается еженедельно (вс 04:00). `unattended-upgrades` для ежедневных security-патчей.
```bash
systemctl status opencode-autoupdate.timer
```

## Структура проекта после установки

```
~/projects/
├── AGENTS.md              # Системный промпт для AI
├── docs/
│   └── INDEX.md           # Карта знаний
├── wal/
│   ├── state.yaml         # Состояние модулей (YAML)
│   ├── GLOBAL_WAL.md      # Состояние модулей (legacy)
│   └── SESSION_WAL.md     # Контекст сессии
├── .opencode/
│   ├── agents/            # 16 AI-агентов
│   ├── skills/            # 4 проектных навыка
│   ├── commands/          # Пользовательские команды
│   └── context/           # Контекст проекта
├── infra/
│   ├── docker-compose.yml # Kafka, PG, Mongo, Redis, MinIO
│   └── wiremock/          # Моки API
├── .lock/                 # Файлы блокировок WAL
├── icon/                  # Иконки
├── templates/             # Шаблоны
└── output/                # Результаты сборки
```

## Безопасность

[Подробная документация](tools/security.md)

- Все API-ключи в `~/.config/opencode/secrets.env` (chmod 600)
- Никаких секретов в коде скрипта
- envsitter-guard фильтрует PII и prompt-инъекции
- Trivy + Qodana для сканирования уязвимостей
- WSL2: изоляция Windows PATH через `appendWindowsPath=false`

## Решение проблем

### OpenCode не стартует
```bash
# Проверить конфиг
cat ~/.config/opencode/opencode.json | python3 -m json.tool

# Перегенерировать
bash setup.sh --fix-config

# Запустить с игнорированием проекта
OPENCODE_DISABLE_PROJECT_CONFIG=1 opencode
```

### MCP-сервер не запускается
```bash
# Проверить установку
npm list -g | grep mcp

# Переустановить все MCP
bash setup.sh --reinit
```

### Проблемы с DNS (РФ/СНГ)
Скрипт автоматически добавляет Yandex DNS (77.88.8.8, 77.88.8.1), Google DNS (8.8.8.8) и Cloudflare (1.1.1.1).

### WSL2: сеть не работает
Скрипт автоматически чинит WSL2 DNS и прокси.

### Прогресс не сохраняется
Файл `~/.cache/opencode-setup/progress` отслеживает выполненные шаги. При повторном запуске `--full` скрипт продолжит с места сбоя.
