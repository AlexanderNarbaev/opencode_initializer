# :fontawesome-solid-rocket: OpenCode Initializer

[![GitHub stars](https://img.shields.io/github/stars/AlexanderNarbaev/opencode_initializer?style=social)](https://github.com/AlexanderNarbaev/opencode_initializer)
[![License](https://img.shields.io/github/license/AlexanderNarbaev/opencode_initializer)](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/LICENSE)
[![ShellCheck](https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/shellcheck.yml)
[![Docs](https://github.com/AlexanderNarbaev/opencode_initializer/actions/workflows/docs.yml/badge.svg)](https://alexandernarbaev.github.io/opencode_initializer/)

**Универсальный Dev Machine Bootstrap** — одна команда для настройки полного AI-усиленного окружения разработчика.

[Установить](#_2){ .md-button .md-button--primary }
[GitHub :fontawesome-brands-github:](https://github.com/AlexanderNarbaev/opencode_initializer){ .md-button }

---

## :fontawesome-solid-bolt: Что это?

Один скрипт, который превращает свежую машину на Linux/WSL2 в готовое к работе окружение:

- :fontawesome-solid-code: **8 языков программирования** — Java 25, Node.js 24, Python 3.14, Go 1.26, Rust 1.96, .NET 10, Kotlin, Zig
- :fontawesome-solid-robot: **21 MCP-сервер** — GitHub, GitLab, Filesystem, Git, SQLite, Postgres, Docker, Chrome DevTools, Sequential Thinking, Memory, Puppeteer, Fetch, Time, Redis, Slack, Everything, Google Maps, Sentry и другие
- :fontawesome-solid-puzzle-piece: **15+ OpenCode плагинов** — token-tracker, dcp, swarm, goal-mode, vibeguard, orchestrator, notify, pty, snip, snippets, envsitter-guard, command-inject, ignore, auto-fallback
- :fontawesome-solid-gears: **13 LSP-серверов** — gopls, rust-analyzer, tsserver, pyright, omnisharp, yaml, marksman, taplo, lua, zls, bash, dockerfile, css/html/json
- :fontawesome-solid-box: **Инфраструктура** — Docker, ChromaDB, Muninn, GPU/LLM (Ollama, vLLM, SGLang, Open WebUI)
- :fontawesome-solid-terminal: **ZSH** + Oh My Zsh + Powerlevel10k с 18 плагинами
- :fontawesome-solid-globe: **Google Chrome** + ChromeDriver (оптимизирован для WSL2)
- :fontawesome-solid-clock-rotate-left: **Автообновление** через systemd weekly timer + topgrade

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

## :fontawesome-solid-list-check: Что устанавливается

| Категория | Инструменты |
|-----------|-------------|
| **Языки** | Java 25, Node.js 24, Python 3.14, Go 1.26, Rust 1.96, .NET 10, Zig |
| **Оболочка** | Zsh 5.8+, Oh My Zsh, Powerlevel10k, 18 плагинов |
| **Браузер** | Google Chrome, ChromeDriver |
| **Контейнеры** | Docker Engine |
| **AI/ML** | Ollama, vLLM, SGLang, Open WebUI, ChromaDB |
| **MCP-серверы** | 21 сервер для AI-ассистированной разработки |
| **LSP-серверы** | 13 языковых серверов |
| **Плагины** | 15+ плагинов продуктивности OpenCode |
| **Безопасность** | Trivy, Qodana |
| **Утилиты** | bat, btm, fd, ripgrep, sd, typos, topgrade |

## :fontawesome-solid-globe: Поддерживаемые платформы

| ОС | Статус |
|----|--------|
| Ubuntu 22.04/24.04 | :fontawesome-solid-check: Полностью |
| Debian 12 | :fontawesome-solid-check: Полностью |
| Fedora 40+ | :fontawesome-solid-check: dnf |
| Arch Linux | :fontawesome-solid-check: pacman |
| Alpine Linux | :fontawesome-solid-check: apk |
| openSUSE | :fontawesome-solid-check: zypper |
| macOS | :fontawesome-solid-check: brew |
| WSL2 | :fontawesome-solid-check: Оптимизирован (DNS fix, лимиты памяти) |

## :fontawesome-solid-book: Документация

- [Начало работы](getting-started/) — установка для начинающих
- [Руководство](user-guide/) — повседневное использование
- [Продвинутое](advanced/) — кастомизация, WSL2, GPU
- [Архитектура](architecture/) — C4-диаграммы, модули
- [Справочник](reference/) — CLI, opencode.json
- [Участие](contributing/) — как помочь
- [FAQ](faq/) — частые вопросы

## :fontawesome-solid-heart: Сообщество

- :fontawesome-brands-github: [GitHub](https://github.com/AlexanderNarbaev/opencode_initializer)
- :fontawesome-solid-bug: [Сообщить об ошибке](https://github.com/AlexanderNarbaev/opencode_initializer/issues/new?template=bug_report.md)
- :fontawesome-solid-lightbulb: [Предложить фичу](https://github.com/AlexanderNarbaev/opencode_initializer/issues/new?template=feature_request.md)
- :fontawesome-solid-book: [Руководство контрибьютора](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/CONTRIBUTING.md)

## :fontawesome-solid-scale-balanced: Лицензия

MIT — см. [LICENSE](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/LICENSE).

---

:fontawesome-solid-star: **Поставьте звёздочку на GitHub**, если проект сэкономил вам время!
