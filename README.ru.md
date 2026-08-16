[EN](README.md) | [RU](README.ru.md)

# OpenCode Initializer v3.2.0

> **Рабочая модель:** Multi-Agent Framework v3.0 | **Волна:** [current_wave.md](./current_wave.md) | **Чекпоинт:** [session_checkpoint.json](./session_checkpoint.json)
<p align="center">
  <b>AI-Native SDD Harness — среда разработки с ИИ-усилением в одну команду для WSL2, Linux и macOS. 4 профиля развёртывания.</b><br>
  <sub>Оркестратор на 685 строк · 52 модуля · 12 режимов · 24 MCP · 15 плагинов · 13 LSP · 23 провайдера · air-gap · governance · PII guard · аудит · офлайн-пакет</sub>
</p>

<p align="center">
  <a href="https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/test.yml"><img src="https://img.shields.io/github/actions/workflow/status/AlexanderNarbaev/opencode_initializer/test.yml?branch=main&label=tests" alt="Tests"></a>
  <a href="https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/shellcheck.yml"><img src="https://img.shields.io/github/actions/workflow/status/AlexanderNarbaev/opencode_initializer/shellcheck.yml?branch=main&label=shellcheck" alt="ShellCheck"></a>
  <a href="https://alexandernarbaev.github.io/opencode_initializer/"><img src="https://img.shields.io/github/actions/workflow/status/AlexanderNarbaev/opencode_initializer/docs.yml?branch=main&label=docs" alt="Docs"></a>
  <a href="https://alexandernarbaev.github.io/opencode_initializer/"><img src="https://img.shields.io/badge/docs-online-4051b5.svg" alt="Documentation"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/AlexanderNarbaev/opencode_initializer"><img src="https://img.shields.io/github/stars/AlexanderNarbaev/opencode_initializer?style=social" alt="GitHub stars"></a>
  <a href="https://gitverse.ru/AlexandrNarbaev/opencode_initializer"><img src="https://img.shields.io/badge/gitverse-mirror-8b5cf6.svg" alt="GitVerse Mirror"></a>
</p>

---

## Быстрый старт

```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --full
```

Одна команда устанавливает всё: 8 языков, 52 инфраструктурных модуля, 24 MCP-сервера, 15 плагинов OpenCode, 13 LSP-серверов, 23 AI-провайдера, инфраструктуру как код (PostgreSQL + Qdrant + Redis + Prometheus + Grafana + Node Exporter + MemoryLayer), Cockpit TUI (7 вкладок), Web GUI, Isolated Circuit Mode, авто-определение оборудования, Lynis CIS scanner, правила auditd для ядра и поиск SearXNG.

[Полная документация](https://alexandernarbaev.github.io/opencode_initializer/)

> **Пользователям macOS:** Требуется `bash>=4` и `grep` с поддержкой `-E` (GNU grep). Установка: `brew install bash grep`.
> Ассоциативные массивы (`declare -A`) требуют bash>=4; стандартный bash 3.2 в macOS требует `brew install bash`.

## Матрица возможностей

| Категория | Кол-во | Состав |
|-----------|--------|--------|
| Языки | 8 | Java 25, Node.js 24, Python 3.14, Go 1.26, Rust 1.97.1, .NET 10, Kotlin, Zig |
| Модули | 52 | Система, Docker, Chrome, ZSH, 7 языков, OpenCode, MCP/LSP, ChromaDB, LLM, RAG, SearXNG, провайдеры, dotfiles, Devbox, Infra, Cockpit, Isolated Circuit, Services, Observability, GUI, Model Router, WAL, Best Practices, Upstream Sync, Linux Platform, Lynis, auditd, DeepSeek Harness, Sandcastle, OpenCode Desktop и другие |
| MCP-серверы | 24 | GitHub, GitLab, Filesystem, Playwright, Chrome DevTools, Postgres, SQLite, Memory, Excalidraw, Brave Search, Context7, Google Maps и другие |
| LSP-серверы | 13 | gopls, rust-analyzer, tsserver, pyright, omnisharp, yaml, marksman, taplo, lua, zls, bash, dockerfile, css/html/json |
| Плагины | 15 | token-tracker, dcp, swarm, goal-mode, vibeguard, orchestrator, auto-fallback, notify, pty, snip, snippets, envsitter-guard, command-inject, ignore |
| AI-провайдеры | 22 | DeepSeek, OpenCode, **z.ai GLM-5.2**, **OpenRouter**, OpenAI, Anthropic Claude 4, Google Gemini, xAI Grok 4, MiniMax, MiMo, **Alibaba Qwen3**, **DeepInfra**, Groq, Together, Fireworks, Perplexity, Mistral, Cohere, Cerebras + 3 локальных (Ollama, vLLM, SGLang) |
| Model Router | 8 профилей | coding, reasoning, fast, agentic, budget, vision, isolated, ru_cn |
| Режимы CLI | 11 | full, reinit, new, health, update, upgrade, interactive, ci, fix-config, fix-zshrc, dry-run |
| Инфраструктура | 7 | PostgreSQL, Qdrant, Redis, Prometheus, Grafana, Node Exporter, MemoryLayer |
| Наблюдаемость | Полный стек | Метрики Prometheus, дашборды Grafana, экспортёр метрик OpenCode, системные метрики Node Exporter |
| GUI | Веб | Статус провайдеров, менеджер моделей, model router, управление MCP/LSP, мониторинг инфраструктуры, Grafana iframe, бэкап, переключатель Isolated Circuit |
| Пакетные менеджеры | 6 | apt, dnf, pacman, apk, zypper, brew |

### Новые интеграции

- **DeepSeek Harness** (`49-deepseek-harness.sh`): agent-харнесс `dsh` — «всё — плагин» (Cordis), Web UI на порту 3080
- **Sandcastle** (`50-sandcastle.sh`): изолированные AI-агенты кодинга (Docker/Podman/Vercel) через API `sandcastle.run()`
- **OpenCode Desktop** (`51-opencode-desktop.sh`): десктопный GUI для OpenCode (.deb/.rpm/AppImage)
- **Навыки Matt Pocock**: 17 инженерных навыков (TDD, code review, проектирование кодовой базы, доменное моделирование, отладка, wayfinder, wizard и другие) в `.opencode/skills/matt-pocock/`

### v2.0.0 — Инфраструктура как код + Isolated Circuit + Наблюдаемость

- **Инфраструктура как код**: PostgreSQL + Qdrant + Redis + Prometheus + Grafana + Node Exporter + MemoryLayer через Docker Compose
- **Cockpit TUI**: 7-вкладочный терминальный интерфейс (Services, Plugins, GPU/Models, Sessions, Tasks, Logs, Infra)
- **Web GUI**: Полная панель управления на порту 4200 с Metrics iframe, переключением моделей, управлением инфраструктурой
- **Isolated Circuit Mode**: Air-gapped работа LLM с локальными OpenAI-совместимыми бэкендами (Ollama, vLLM, SGLang)
- **z.ai GLM-5.2**: Основной провайдер для рынков RU/CN, OpenAI-совместимый API, бесплатный тариф
- **OpenRouter**: Агрегатор доступа к 100+ моделям через единый API-ключ
- **OpenCode Metrics**: Экспортёр Prometheus в реальном времени на порту 9464 — сессии, записи WAL, состояние контейнеров, модели Ollama, активная конфигурация
- **Node Exporter**: Системные метрики (CPU, RAM, диск, uptime), собираемые Prometheus
- **Grafana Dashboards**: Обзор инфраструктуры + Производительность агентов — авто-предоставление
- **Авто-определение портов**: Автоматическое разрешение конфликтов портов со сдвигом — переопределение через env var для всех сервисов
- **Профили развёртывания**: personal / corporate / airgapped / hybrid с контролем режимов сервисов (local/external/disabled)
- **Unified Service Layer**: Единая точка конфигурации для всех 18 инфраструктурных сервисов через `setup.conf`
- **Поддержка внешних сервисов**: Подключение любого компонента к внешним URL — корпоративный OTel, существующий Grafana, управляемые БД
- **MemoryLayer**: Система памяти ИИ с Ollama embed proxy (mxbai-embed-large, 1024-мерный)

### v3.0.0 — SDD-ориентированная среда: Аудит и Управление

- **Model Governance** (`43-governance.sh`): `model-policy.json` — разрешительные/запретительные списки для проектов, 3 режима (allow-all/allowlist/corporate)
- **PII Sanitizer** (`45-pii-guard.sh`): 9 детекторов (email, телефон, ИНН, СНИЛС, паспорт, кредитная карта, IP, API-ключ) — фильтрация перед отправкой в LLM
- **Audit Trail** (`44-audit.sh`): 7 типов событий WAL (model_call, tool_call, provider_switch, pii_redacted, checkpoint, error, session_boundary), цепочка хешей SHA-256, ротация >10MB → gzip+Qdrant
- **Constitution + Spec Format** (`41-constitution.sh`): Генератор `memory/constitution.md`, SDD-воркфлоу (constitution→specify→clarify→plan→tasks→implement→verify→converge)
- **Lifecycle Hooks** (`42-hooks.sh`): Фреймворк хуков pre-request, post-response, pre-commit, on-error
- **Offline Bundle** (`46-offline-bundle.sh`): `dev bundle create` для полностью автономной установки, манифест SHA-256
- **Укрепление цепочки поставок**: `curl|sh` → загрузка+проверка SHA256 для всех 6 затронутых модулей (mise, devbox, WasmEdge, Shokunin, Oh My Zsh)
- **SOC2/ISO27001 Ready**: Чек-листы соответствия (CC5.2/CC7.2/CC8.2, A.9/A.12/A.14/A.16/A.17/A.18 + GDPR Art.32/35)
- **Плановые проверки безопасности**: Systemd-таймер для ежедневного Trivy + Qodana сканирования, генерация SBOM (CycloneDX), pre-commit хук

## Архитектура

```
opencode_initializer/
├── setup.sh                  # Оркестратор (685 строк)
├── dev.sh                    # CLI: dev install|remove|update|health|metrics|observability|isolated|...
├── opencode.json             # Генерируемый мульти-провайдерный конфиг OpenCode (23 провайдера)
├── src/
│   ├── lib/                  # 42 модуля (39 номерных + 3 вспомогательных)
│   │   ├── helpers.sh        # Инфраструктура: _curl, _retry, _npm_install
│   │   ├── 00-core.sh        # Определение OS/PKG/ARCH, зеркала, прогресс, ISOLATED_CIRCUIT, разрешение портов
│   │   ├── 01-system.sh      # Системные пакеты (кросс-дистрибутив: apt/dnf/pacman/apk/zypper/brew)
│   │   ├── ...               # 02-29: Языки, инструменты, инфраструктура
│   │   ├── 30-infra.sh       # Инфраструктура: PostgreSQL + Qdrant + Redis + Prometheus + Grafana + Node Exporter + MemoryLayer
│   │   ├── 31-cockpit.sh     # Демон управления Cockpit TUI (7 вкладок)
│   │   ├── 32-isolated.sh    # Isolated Circuit Mode — автономный LLM
│   │   ├── 33-services.sh    # Unified Service Layer — разрешение портов, режимы сервисов, профили развёртывания
│   │   ├── 34-observability.sh  # Стек наблюдаемости Prometheus + Grafana + OTel
│   │   ├── 35-gui.sh         # Web GUI (Node.js, порт 4200)
│   │   ├── 36-model-router.sh   # Интеллектуальная маршрутизация моделей (8 профилей задач, таблица стоимости)
│   │   ├── 37-wal.sh         # Write-Ahead Log — журнал установки + сессий агентов
│   │   ├── version-check.sh  # Сравнение версий (8+ инструментов)
│   │   └── pre-session-check.sh  # Предсессионная проверка провайдеров/моделей
│   ├── cockpit/               # Исходники Go TUI (фреймворк BubbleTea)
│   ├── gui/                   # Web GUI (сервер Node.js + HTML панель)
│   ├── grafana/               # Предоставление Grafana (источники данных + дашборды)
│   ├── systemd/               # Пользовательские unit'ы systemd (opencode-metrics.service)
│   └── modes/                 # 5 скриптов режимов (+ 6 встроенных)
├── scripts/                   # Утилиты (provider-check, embed-proxy, ai-router, oc-*)
│   ├── oc-metrics.py          # Экспортёр метрик OpenCode Prometheus (:9464)
│   ├── oc-sdk.py              # Python SDK
│   ├── embed-proxy.py         # Мост Ollama → MemoryLayer embedding
│   └── ai-router/             # Интеллектуальная маршрутизация моделей
├── tests/                     # Unit (12), интеграционные (5), E2E (4) — 398+ проверок
├── migrations/                # Временные метки, идемпотентные миграции
├── docs/                      # Сайт документации MkDocs Material (EN/RU)
├── .github/                   # CI воркфлоу (test, shellcheck, build, security, docs)
└── CHANGELOG.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, LICENSE
```

## Режимы

| Режим | Флаг | Описание |
|--------|------|-----------|
| Full | `--full` (по умолч.) | Полный цикл — все модули |
| Reinit | `--reinit` | Переустановка инструментов, данные сохраняются |
| New Project | `--new <dir>` | Только инициализация нового проекта |
| CI/CD | `--ci` | Headless CI: OpenCode CLI + основные MCP |
| Health | `--health` | Полная диагностика (65+ проверок) |
| Update | `--update` | Обновление установленных инструментов |
| Upgrade | `--upgrade` | Полный цикл обновления системы |
| Interactive | `--interactive` | Покомпонентный выбор |
| Fix Config | `--fix-config` | Только перегенерация opencode.json |
| Fix ZSH | `--fix-zshrc` | Восстановление .zshrc |
| Dry Run | `--dry-run` | Режим предпросмотра, без изменений |

## Установка

### Полная установка

```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --full
```

### С API-ключами

```bash
bash setup.sh --full \
  --deepseek-key "sk-..." \
  --zai-key "..." \
  --openrouter-key "sk-or-..." \
  --xai-key "xai-..." \
  --github-token "ghp_..." \
  --gitlab-token "glpat-..."
```

### Профили развёртывания

```bash
# Корпоративная среда — подключение к существующей инфраструктуре
DEPLOYMENT_PROFILE=corporate \
  POSTGRES_MODE=external POSTGRES_EXTERNAL_URL=pg.internal:5432 \
  GRAFANA_MODE=external EXTERNAL_GRAFANA_URL=https://grafana.company.com \
  PROMETHEUS_MODE=external EXTERNAL_PROMETHEUS_URL=https://prom.internal:9090 \
  OTEL_EXPORTER_ENABLED=true OTEL_EXPORTER_ENDPOINT=otel-collector:4317 \
  bash setup.sh --full

# Автономный режим — только локальные LLM
bash setup.sh --full --isolated
```

### Интерактивный режим

```bash
bash setup.sh --interactive     # Выбор компонентов для установки
bash setup.sh --dry-run --full  # Предпросмотр без изменений
```

### CLI после установки

```bash
dev health              # Полная диагностика (65+ проверок)
dev list                # Список установленных компонентов
dev update              # Обновление всего + миграции
dev self-update         # Обновление самого установщика
dev version-check       # Сравнение установленных и актуальных версий
dev config              # Редактирование файла конфигурации
dev provider-check      # Проверка связи с AI-провайдерами
dev autoupdate          # Запуск полного обновления системы через topgrade
dev remove java         # Удаление компонента
dev plugins list        # Показать установленные плагины

# Наблюдаемость
dev observability status    # Статус Prometheus + Grafana
dev observability reload    # Перегенерация prometheus.yml + перезапуск
dev metrics start           # Запуск экспортёра метрик
dev metrics status          # Просмотр метрик в реальном времени

# Инфраструктура
dev infra up                # Запуск всех Docker-сервисов
dev infra status            # Обзор состояния контейнеров
dev infra down              # Остановка всех сервисов

# Isolated Circuit (автономный LLM)
dev isolated on              # Включение режима только локальных моделей
dev isolated status          # Проверка текущего состояния

# Управление моделями
dev models coding            # Получить рекомендацию модели для программирования
dev models install qwen3:32b # Загрузить локальную модель
dev models list-local        # Список установленных локальных моделей

# GUI и Cockpit
dev gui start                # Запуск Web GUI (http://localhost:4200)
cockpit                      # Запуск TUI (или 'dev install cockpit')

# Бэкап
dev backup create            # Бэкап всех конфигов
dev backup list              # Список доступных бэкапов
dev backup restore <file>    # Восстановление из бэкапа

# Добавление компонентов позже
dev install llm              # Добавить поддержку GPU/LLM
dev install docker           # Установить Docker Engine
```

## Стек наблюдаемости

### Компоненты

| Компонент | Порт | Описание | Автозапуск |
|-----------|------|----------|------------|
| **Prometheus** | 9090 | Сбор и хранение метрик | systemd `opencode-infra.service` |
| **Grafana** | 3001 | Дашборды (инфраструктура + производительность агентов) | systemd `opencode-infra.service` |
| **Node Exporter** | 9100 | Системные метрики (CPU, RAM, диск, uptime) | Docker `unless-stopped` |
| **OpenCode Metrics** | 9464 | Сессии, WAL, контейнеры, модели, конфигурация | systemd `opencode-metrics.service` |

### Дашборды

- **Обзор инфраструктуры** (`/d/opencode-infra`): Состояние контейнеров, подключения PostgreSQL, память Redis, коллекции Qdrant, uptime сервисов
- **Производительность агентов** (`/d/opencode-tokens`): Использование токенов, оценка стоимости, активные сессии, распределение моделей, затраты провайдеров

### Доступ

```bash
# Вкладка Metrics в Web GUI
http://localhost:4200  →  Вкладка Metrics (Grafana iframe)

# Cockpit TUI
cockpit → Вкладка 8 (Grafana) → Нажмите 'o' для открытия в браузере

# Прямой доступ
http://localhost:3001  →  Grafana (admin/admin)
http://localhost:9090  →  Prometheus
http://localhost:9464/metrics  →  Метрики OpenCode
```

## Управление портами

Все порты сервисов настраиваются через переменные окружения или `~/.config/opencode-setup/setup.conf`:

```bash
# Переопределение портов по умолчанию
POSTGRES_PORT=5433
GRAFANA_PORT=3002
METRICS_EXPORTER_PORT=9465

# Или авто-определение (установите 0)
POSTGRES_PORT=0   # Находит первый свободный порт ≥ 5432

# Режимы сервисов
POSTGRES_MODE=external  POSTGRES_EXTERNAL_URL=pg.internal:5432
REDIS_MODE=disabled
```

## Опции

| Флаг | Описание |
|------|----------|
| `-k, --api-key <key>` | API-ключ OpenCode Go |
| `--deepseek-key <key>` | API-ключ DeepSeek |
| `--isolated` | Включить Isolated Circuit Mode (только локальные LLM) |
| `--zai-key <key>` | API-ключ z.ai GLM |
| `--openrouter-key <key>` | API-ключ OpenRouter |
| `--alibaba-key <key>` | API-ключ Alibaba Qwen |
| `--deepinfra-key <key>` | API-ключ DeepInfra |
| `--with-observability` | Включить Prometheus + Grafana |
| `--with-grafana` | Включить дашборды Grafana |
| `--with-prometheus` | Включить мониторинг Prometheus |
| `--with-all-infra` | Включить все инфраструктурные сервисы |
| `--github-token <token>` | Персональный токен GitHub |
| `--gitlab-token <token>` | Персональный токен GitLab |
| `--google-maps-key <key>` | API-ключ Google Maps |
| `-s, --sudo-pass <pass>` | **[УСТАРЕЛО]** Используйте `SUDO_PASS` или интерактивный `read -s` |
| `-p, --project-dir <dir>` | Директория проектов (по умолчанию: ~/projects) |
| `-n, --git-name <name>` | Имя пользователя Git |
| `-e, --git-email <email>` | Email пользователя Git |

## Отказоустойчивость

- **Отслеживание прогресса**: `~/.cache/opencode-setup/progress` записывает выполненные шаги — повторные запуски идемпотентны
- **Логика повторных попыток**: Все загрузки curl используют 5 повторов с экспоненциальной задержкой
- **Резервные зеркала**: Авто-определение недоступных сервисов и переключение на зеркала (ghproxy.com, npmmirror.com, yandex.ru, goproxy.cn)
- **npm pack кэш**: MCP `.tgz` файлы кэшируются локально, переживают очистку npm cache
- **Bun binary paths**: Абсолютные пути к `~/.bun/bin/` — холодный старт 0.5с против 5-15с с npx
- **Авто-определение портов**: Безопасное назначение портов с автоматическим сдвигом при конфликтах
- **Оптимизация WSL2**: Исправление DNS, лимиты памяти, mirrored networking, настройка .wslconfig
- **Режим dry-run**: Предпросмотр всех изменений без выполнения
- **Isolated Circuit**: Автономная работа LLM с авто-определением локальных бэкендов
- **Профили развёртывания**: Преднастроенное поведение для персональной, корпоративной, автономной и гибридной сред

## Поддержка платформ

| Пакетный менеджер | Дистрибутивы | Архитектура |
|-------------------|-------------|-------------|
| apt | Ubuntu, Debian, Mint, Pop!_OS | amd64, arm64 |
| dnf | Fedora, RHEL, CentOS Stream | amd64, arm64 |
| pacman | Arch, Manjaro, EndeavourOS | amd64 |
| apk | Alpine Linux | amd64, arm64 |
| zypper | openSUSE | amd64 |
| brew | macOS, Linuxbrew | amd64, arm64 |

## Безопасность

- Все секреты в `~/.config/opencode/secrets.env` (chmod 600)
- `opencode-dcp` + `opencode-vibeguard`: обрезка контекста, фильтрация PII/секретов
- Никаких жёстко зашитых учётных данных в исходниках
- Все API-ключи только через аргументы CLI
- ShellCheck CI при каждом push и PR
- Экспортёр метрик привязан к 127.0.0.1 (только локально)
- Systemd-сервисы работают от пользователя (не root)
- Лицензия MIT

## Документация

- [Полное руководство](https://alexandernarbaev.github.io/opencode_initializer/) — Сайт MkDocs Material (EN/RU)
- [Руководство по командной настройке](docs/guides/team-setup.md) — онбординг коллег
- [Архитектура](https://alexandernarbaev.github.io/opencode_initializer/architecture/) — C4 диаграммы, справочник модулей
- [AGENTS.md](AGENTS.md) — Документация для AI-агентов
- [Руководство по участию](CONTRIBUTING.md)
- [Политика безопасности](SECURITY.md)
- [Кодекс поведения](CODE_OF_CONDUCT.md)
- [Список изменений](CHANGELOG.md)

## Сообщество

- [GitHub Issues](https://github.com/AlexanderNarbaev/opencode_initializer/issues)
- [Зеркало GitVerse](https://gitverse.ru/AlexandrNarbaev/opencode_initializer)

## Лицензия

MIT (c) 2025-2026 [Alexander Narbaev](https://github.com/AlexanderNarbaev)
