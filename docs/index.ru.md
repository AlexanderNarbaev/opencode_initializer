# OpenCode Initializer v2.0.0

[![GitHub stars](https://img.shields.io/github/stars/AlexanderNarbaev/opencode_initializer?style=social)](https://github.com/AlexanderNarbaev/opencode_initializer)
[![License](https://img.shields.io/github/license/AlexanderNarbaev/opencode_initializer)](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/LICENSE)
[![ShellCheck](https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/shellcheck.yml)
[![Docs](https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/docs.yml/badge.svg)](https://alexandernarbaev.github.io/opencode_initializer/)

**Универсальный Dev Machine Bootstrap** — одна команда для настройки полного AI-усиленного окружения разработчика.

[Установить](#_2){ .md-button .md-button--primary }
[GitHub :fontawesome-brands-github:](https://github.com/AlexanderNarbaev/opencode_initializer){ .md-button }

---

## :fontawesome-solid-chart-simple: Быстрая статистика

| Метрика | Значение |
|---------|----------|
| Модулей | 39 (+ 3 инфраструктурных) |
| Оркестратор | 373 строки Bash |
| Режимов CLI | 11 (full, health, interactive, ci и другие) |
| Языков | 8 |
| MCP-серверов | 24 |
| LSP-серверов | 13 |
| Плагинов OpenCode | 15 |
| AI-провайдеров | 24 (20 облачных + 4 локальных) |
| Model Router | 8 профилей (coding, reasoning, fast, agentic, budget, vision, isolated, ru_cn) |
| Инфраструктура | 6 сервисов (PostgreSQL, Qdrant, Redis, Prometheus, Grafana, MemoryLayer) |
| Web GUI | 9 разделов управления (порт 4200) |
| Тестов | 350+ проверок |
| Пакетных менеджеров | apt, dnf, pacman, apk, zypper, brew |
| Архитектур | amd64, arm64 |

## :fontawesome-solid-bolt: Что это?

Один скрипт, который превращает свежую машину на Linux/WSL2 в готовое к работе окружение:

- :fontawesome-solid-code: **8 языков программирования** — Java 25, Node.js 24, Python 3.14, Go 1.26, Rust 1.96, .NET 10, Kotlin, Zig
- :fontawesome-solid-robot: **24 MCP-серверов** — GitHub, GitLab, Filesystem, Playwright, Chrome DevTools, SQLite, Postgres, Memory, Excalidraw, Brave Search, Context7, Google Maps и другие
- :fontawesome-solid-puzzle-piece: **15 плагинов OpenCode** — token-tracker, dcp, swarm, goal-mode, vibeguard, orchestrator, auto-fallback, notify, pty, snip, snippets, envsitter-guard, command-inject, ignore
- :fontawesome-solid-gears: **13 LSP-серверов** — gopls, rust-analyzer, tsserver, pyright, omnisharp, yaml, marksman, taplo, lua, zls, bash, dockerfile, css/html/json
- :fontawesome-solid-box: **Infrastructure as Code** — PostgreSQL, Qdrant, Redis, Prometheus, Grafana, MemoryLayer через Docker Compose
- :fontawesome-solid-display: **Cockpit TUI** — 7-вкладочный терминальный UI для управления сервером
- :fontawesome-solid-shield-halved: **Isolated Circuit Mode** — air-gapped LLM с локальными бэкендами
- :fontawesome-solid-cloud: **24 AI-провайдера** — DeepSeek, z.ai GLM-5.2, OpenRouter, OpenAI, Anthropic, Google, xAI, Moonshot, Alibaba Qwen3 и другие
- :fontawesome-solid-microchip: **GPU/LLM** — Ollama, vLLM, SGLang, Open WebUI, WasmEdge (автоопределение GPU)
- :fontawesome-solid-terminal: **ZSH** — Oh My Zsh + Powerlevel10k с 14 плагинами
- :fontawesome-solid-globe: **Chrome** — Google Chrome + ChromeDriver (оптимизирован для WSL2)
- :fontawesome-solid-clock-rotate-left: **Автообновление** — systemd weekly timer + topgrade

## :fontawesome-solid-star: Новое в v2.0.0

| Возможность | Описание |
|-------------|----------|
| Infrastructure as Code | PostgreSQL + Qdrant + Redis + Prometheus + Grafana + MemoryLayer через Docker Compose |
| Cockpit TUI | 7-вкладочный терминальный UI — System, Plugins, GPU/Models, Sessions, Tasks, Logs, Infra |
| Isolated Circuit Mode | Air-gapped LLM с Ollama, LiteLLM, vLLM, SGLang |
| Model Routing Intelligence | 8 профилей: coding, reasoning, fast, agentic, budget, vision, isolated, ru_cn |
| Web GUI | 9-разделочный интерфейс управления: провайдеры, модели, MCP/LSP, инфраструктура, backup, логи |
| z.ai GLM-5.2 | Основной провайдер для RU/CN рынков, OpenAI-совместимый, free tier |
| OpenRouter | Агрегатор доступа к 100+ моделям через один API-ключ |
| Alibaba Qwen3.7 | Нативный SDK, последняя модель Qwen |
| DeepInfra | Быстрый инференс, конкурентные цены |
| MemoryLayer | AI-память с Ollama embed proxy (mxbai-embed-large) |
| Observability | Prometheus + Grafana с авто-провиженингом дашбордов |
| Corporate Proxy | Поддержка HTTP_PROXY, HTTPS_PROXY, CURL_CA_BUNDLE |
| Config Backup | `dev backup create\|list\|restore` для disaster recovery |
| Model Download | `dev models install <model>` для локальных Ollama моделей |
| 24 провайдера | 20 облачных + 4 локальных (было 16 в v1.1.0) |
| 39 модулей | Было 29 в v1.1.0 |

## :fontawesome-solid-download: Быстрая установка

```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash
```

Или клонировать и запустить:

```bash
git clone https://github.com/AlexanderNarbaev/opencode_initializer.git ~/opencode_initializer
cd ~/opencode_initializer && bash setup.sh
```

!!! tip "Просмотрите перед запуском"
    Всегда проверяйте скрипты перед выполнением. Весь код открыт и документирован.

### С API-ключами

```bash
bash setup.sh --full \
  --deepseek-key "sk-..." \
  --zai-key "..." \
  --openrouter-key "sk-or-..." \
  --github-token "ghp_..." \
  --gitlab-token "glpat-..." \
  --google-maps-key "..."
```

### Isolated Circuit Mode (Air-Gapped)

```bash
bash setup.sh --full --isolated    # Только локальные LLM-бэкенды
dev isolated on                     # Включить после установки
dev isolated status                 # Проверить текущее состояние
```

## :fontawesome-solid-list-check: Что устанавливается

| Категория | Инструменты |
|-----------|-------------|
| **Языки** | Java 25, Node.js 24, Python 3.14 + uv, Go 1.26, Rust 1.96, .NET 10, Kotlin, Zig |
| **Оболочка** | Zsh 5.8+, Oh My Zsh, Powerlevel10k, 14 плагинов |
| **Браузер** | Google Chrome, ChromeDriver (оптимизирован для WSL2) |
| **Контейнеры** | Docker Engine |
| **Инфраструктура** | PostgreSQL, Qdrant, Redis, Prometheus, Grafana, MemoryLayer |
| **AI/ML** | Ollama, vLLM, SGLang, Open WebUI, ChromaDB, WasmEdge, ONNX |
| **API-шлюз** | LiteLLM — OpenAI-совместимый эндпоинт для всех провайдеров |
| **Веб-поиск** | SearXNG self-hosted поиск + sanitizer proxy |
| **MCP-серверы** | 21 сервер для AI-ассистированной разработки |
| **LSP-серверы** | 13 языковых серверов |
| **Плагины** | 15 плагинов продуктивности OpenCode |
| **Безопасность** | Trivy, Qodana |
| **Утилиты** | bat, btm, fd, ripgrep, sd, typos, topgrade, just, mise |
| **Dotfiles** | chezmoi для командного шеринга конфигов |
| **Dev-окружения** | Devbox — изолированные Nix-окружения |
| **Cockpit** | 7-вкладочный TUI для управления сервером |

## :fontawesome-solid-globe: Поддерживаемые платформы

| ОС | Статус | Пакетный менеджер |
|----|--------|-------------------|
| Ubuntu 22.04/24.04 | :fontawesome-solid-check: Полностью | apt |
| Debian 12 | :fontawesome-solid-check: Полностью | apt |
| Fedora 40+ | :fontawesome-solid-check: Полностью | dnf |
| Arch Linux | :fontawesome-solid-check: Полностью | pacman |
| Alpine Linux | :fontawesome-solid-check: Полностью | apk |
| openSUSE | :fontawesome-solid-check: Полностью | zypper |
| macOS | :fontawesome-solid-check: Полностью | brew |
| WSL2 | :fontawesome-solid-check: Оптимизирован (DNS fix, лимиты памяти) | apt |

## :fontawesome-solid-sliders: Режимы

| Режим | Флаг | Применение |
|-------|------|-----------|
| Полный | `--full` | Полная установка (по умолчанию) |
| Переустановка | `--reinit` | Переустановить инструменты, сохранить данные |
| Новый проект | `--new <dir>` | Только инициализация проекта |
| CI/CD | `--ci` | Headless установка для пайплайнов |
| Диагностика | `--health` | Полная диагностика (65+ проверок) |
| Обновление | `--update` | Обновить установленные инструменты |
| Апгрейд | `--upgrade` | Полная цепочка обновления системы |
| Интерактивный | `--interactive` | Выбор компонентов по одному |
| Fix Config | `--fix-config` | Пересоздать opencode.json |
| Fix ZSH | `--fix-zshrc` | Восстановить конфигурацию оболочки |
| Dry Run | `--dry-run` | Предпросмотр без изменений |

## :fontawesome-solid-book: Документация

- [Начало работы](getting-started/) — установка для начинающих
- [Руководство](user-guide/) — повседневное использование
- [Продвинутое](advanced/) — кастомизация, WSL2, GPU
- [Архитектура](architecture/) — C4-диаграммы, модули
- [Справочник](reference/) — CLI, opencode.json, MCP/LSP каталог
- [Участие](contributing/) — как помочь
- [FAQ](faq/) — частые вопросы
- [Командная установка](guides/team-setup/) — гайд для онбординга команд

## :fontawesome-solid-heart: Сообщество

- :fontawesome-brands-github: [GitHub](https://github.com/AlexanderNarbaev/opencode_initializer)
- :fontawesome-brands-git: [Зеркало на GitVerse](https://gitverse.ru/AlexandrNarbaev/opencode_initializer)
- :fontawesome-solid-bug: [Сообщить об ошибке](https://github.com/AlexanderNarbaev/opencode_initializer/issues/new?template=bug_report.md)
- :fontawesome-solid-lightbulb: [Предложить фичу](https://github.com/AlexanderNarbaev/opencode_initializer/issues/new?template=feature_request.md)
- :fontawesome-solid-book: [Руководство контрибьютора](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/CONTRIBUTING.md)

## :fontawesome-solid-scale-balanced: Лицензия

MIT — см. [LICENSE](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/LICENSE).
