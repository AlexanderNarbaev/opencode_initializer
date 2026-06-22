# Исследование: лучшие практики Dev Machine Bootstrapping и AI Tooling (2025–2026)

> Составлено: 22 июня 2026
> Фокус: opencode_initializer v1.0.0+

---

## 1. Что топовые инструменты делают хорошо

**thoughtbot/laptop** (8.6k звёзд, эталон 2011–2024):
- Идемпотентность: можно запускать многократно на одной машине — устанавливает/обновляет/пропускает пакеты
- Логирование: `tee ~/laptop.log` — полный лог каждого запуска
- Расширяемость: `~/.laptop.local` — хук для пользовательских кастомизаций
- Тестирование: рекомендуют проверять на свежей macOS VM (UTM), используют ShellCheck
- Прозрачность: "review the script before running it" в README

**Google Shell Style Guide** (индустриальный стандарт):
- `#!/bin/bash` — только bash, не POSIX sh (единообразие)
- ShellCheck для всех скриптов, больших и малых
- `[[ ]]` предпочтительнее `[ ]` (безопаснее, regex, pattern matching)
- `$(command)` вместо бэктиков (вложенность, читаемость)
- `main()` как точка входа в конце файла
- `local` для всех переменных внутри функций
- `set -e` + отдельные строки для `local` и присваивания из `$(…)`

**mvdan/sh (shfmt)** (8.8k звёзд, стандарт форматирования shell):
- Форматтер как часть CI: `shfmt -l -w script.sh`
- Отказ от бесконечных опций форматирования — консистентность важнее личных предпочтений
- Интеграция с pre-commit, редакторами, GitHub Actions

**bats-core** (6.1k звёзд, стандарт тестирования Bash):
- TAP-совместимый вывод (можно интегрировать с CI)
- `set -e` внутри тестов — каждая строка = assertion
- 2000+ коммитов, активное сообщество

**MCP Reference Servers** (87.6k звёзд, Anthropic):
- SDK на 10 языках (C#, Go, Java, Kotlin, PHP, Python, Ruby, Rust, Swift, TypeScript)
- Чёткое разделение: reference implementations (не production-ready) vs community servers
- Архитектура: Host → Client → Server, слой данных (JSON-RPC 2.0) + транспортный слой (stdio/HTTP)
- Стандартные примитивы: Tools, Resources, Prompts, Sampling, Elicitation, Logging
- Версионирование протокола: `"protocolVersion": "2025-06-18"`

**OpenCode** (177k звёзд):
- `/init` генерирует AGENTS.md — AI-first подход к документированию проекта
- Конфигурация слиянием (merge, не replace) — иерархия 8 уровней
- `{env:VAR}` и `{file:path}` подстановки в конфиге
- JSONC с `$schema` для автокомплита в редакторе
- Модульная конфигурация: все ключи независимы

**Docker Desktop WSL2 Best Practices:**
- WSL версии ≥ 2.1.5 (минимум), рекомендована последняя
- `autoMemoryReclaim` — предотвращает утечку памяти через page cache ядра
- Исходный код хранить в Linux filesystem (не `/mnt/c`), для `inotify` + производительности
- Bind-mount из `~/project`, не из `/mnt/c/users/...`

---

## 2. Топ-10 лучших практик

### 2.1 Архитектура
1. **Модульность через `source`**: Разбивка на 24 модуля — correctly. Но добавить интерфейсный контракт: каждый модуль должен expose `_module_XX_check()` и `_module_XX_install()`.
2. **Идемпотентность**: Скрипт должен безопасно перезапускаться. `progress file` — отлично. Добавить явную проверку "уже установлено" перед каждым шагом.
3. **Orchestrator + plugins**: Паттерн как у thoughtbot/laptop — минимальный entry point, вся логика в подключаемых модулях.

### 2.2 Качество кода
4. **ShellCheck в CI**: Уже есть в `.github/workflows/`. Добавить `shellcheck -S error` как блокирующий шаг.
5. **shfmt**: Добавить `shfmt -d -i 2 -ci .` в CI для единого стиля. 2 пробела, Google-style.
6. **bats-core тесты**: Уже 193 теста — отлично. Добавить `bats --tap` вывод для CI-интеграции.

### 2.3 Безопасность
7. **Никаких секретов в коде**: Уже реализовано. Добавить `detect-secrets` или `gitleaks` в pre-commit.
8. **`chmod 600` для sensitive файлов**: Уже реализовано для auth.json.

### 2.4 Пользовательский опыт
9. **Прогресс-бар / трассировка**: `~/.cache/opencode-setup/progress` — хорошо. Добавить `--verbose` и `--quiet` режимы.
10. **Логирование каждого запуска**: как у thoughtbot (`tee ~/laptop.log`). Добавить `tee ~/.cache/opencode-setup/setup.log`.

---

## 3. Топ-5 частых ошибок в shell-based install скриптах

### 3.1 Отсутствие идемпотентности
Самый частый баг: скрипт падает при повторном запуске, потому что добавляет дублирующиеся строки в `.zshrc`, перезаписывает конфиги, или падает на `mkdir` существующей директории.

**Решение**: `mkdir -p`, `grep -q` перед `echo >>`, проверка `command -v` перед установкой.

### 3.2 `set -e` в неправильном контексте
Источник: [ShellCheck SC2310, SC2311]. `set -e` игнорируется в:
- `if func; then` — функция в условии теряет `errexit`
- `$(func)` — command substitution отключает `errexit`
- `func | while read` — пайпы создают subshell

**Решение**: `set -euo pipefail` + `shopt -s inherit_errexit` (bash 4.4+). Явная проверка `$?` после критических команд.

### 3.3 Неправильное цитирование
Источник: [ShellCheck SC2086, SC2046, SC2068]. Самые частые:
- `$var` без кавычек — word splitting + globbing
- `$@` без кавычек — то же что `$*`
- `$(cmd)` без кавычек в присваивании массиву

**Решение**: `"$var"`, `"$@"`, `"${array[@]}"`. ShellCheck ловит 95% случаев.

### 3.4 Кроссплатформенные различия package manager
`apt` vs `dnf` vs `pacman` vs `apk` vs `zypper` vs `brew` — разные имена пакетов, флаги, пути.

**Решение**: Таблица маппинга пакетов (уже есть в `00-core.sh`). Но нужно тестировать на всех дистрибутивах в CI-матрице.

### 3.5 WSL2-specific баги
- DNS не резолвится → `echo "nameserver 8.8.8.8" >> /etc/resolv.conf` (уже реализовано)
- Windows firewall блокирует Docker registry → `New-NetFirewallRule`
- Файловая система: `/mnt/c` — очень медленно. Предупреждать пользователя
- GPU passthrough: требует WSL 2.6+ для Enhanced Container Isolation

---

## 4. Топ-5 фич, которые пользователи больше всего хотят

На основе анализа issues в anomalyco/opencode (~5000+ issues) и setup-script репозиториев:

1. **Dry-run / preview mode** — увидеть что будет установлено до реального запуска. Уже есть в opencode_initializer.
2. **Interactive component selection** — выбор компонентов через меню. Уже есть.
3. **Health check / диагностика** — быстро понять что сломано. Уже есть (`--health`, 60+ проверок). 
4. **Auto-update / self-healing** — автоматическое обновление инструментов. Уже есть (`systemd timer + topgrade`).
5. **Быстрый cold-start MCP серверов** — критично для AI-агентов. Уже решено через `local_cmd()` с абсолютными путями к `~/.bun/bin/`.

**Дополнительно из OpenCode issues (June 2026):**
- Subagents hang indefinitely (нужен timeout)
- O(N) dispatch overhead on plugin triggers (нужна оптимизация)
- Интеграция с MCP Registry (новый стандарт)

---

## 5. Must-have MCP серверы и AI инструменты (June 2026)

### Reference Servers (официальные, от Anthropic):
- **Memory** — knowledge graph-based persistent memory
- **Filesystem** — secure file operations
- **Git** — repository operations
- **Sequential Thinking** — reflective problem-solving
- **Fetch** — web content fetching
- **Everything** — test/reference server

### Must-have для dev-машины:
- **Sentry MCP** — error tracking (теперь официальный, поддерживается Sentry)
- **Brave Search MCP** — web search (официальный сервер)
- **Slack MCP** — team communication (теперь Zencoder)
- **PostgreSQL / SQLite MCP** — database access (заархивированы, но рабочие)
- **GitHub MCP** — repo management (заархивирован, заменён официальным)
- **Chrome DevTools MCP** — browser automation

### Тренды:
- **MCP Registry** (registry.modelcontextprotocol.io) — централизованный каталог серверов
- **Streamable HTTP transport** — для remote MCP (альтернатива stdio)
- **Tasks (Experimental)** — durable execution для долгих операций
- **Elicitation** — сервер может запрашивать confirmation у пользователя

---

## 6. Стандарты документации Open Source

### README (международный стандарт):
- **Что делает проект** — одна фраза вверху
- **Быстрый старт** — 3 команды для установки
- **Requirements** — явный список зависимостей
- **Badges**: CI status, license, version, stars
- **Скриншот/демо** если есть UI

### CONTRIBUTING.md:
- Как настроить dev-окружение
- Как запустить тесты
- Code style guide (ShellCheck, shfmt)
- PR process
- Code of Conduct (Contributor Covenant v2.1 — стандарт)

### CHANGELOG.md:
- Формат [Keep a Changelog](https://keepachangelog.com/en/2.0.0/)
- Секции: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`
- Дата в ISO 8601 (`YYYY-MM-DD`)
- `[Unreleased]` вверху
- Ссылки на сравнение версий (compare URLs)
- Версионирование: [SemVer](https://semver.org)

### Структура репозитория (эталонная, как у MCP servers):
```
.github/          — CI, issue/PR templates
src/              — исходный код
scripts/          — утилиты
tests/            — тесты (unit, integration, e2e)
migrations/       — миграции
docs/             — документация + plans + research
README.md         — главная
CONTRIBUTING.md   — для контрибьюторов
CHANGELOG.md      — история изменений
CODE_OF_CONDUCT.md— кодекс поведения
SECURITY.md       — процесс disclosure
LICENSE           — лицензия
AGENTS.md         — инструкции для AI-агентов
```

---

## 7. Что делает отличный opencode.json / AGENTS.md

### opencode.json (конфиг OpenCode):
- **`$schema`** — ссылка на `opencode.ai/config.json` (автокомплит)
- **`model`** + **`small_model`** — primary и fallback модели
- **`provider`** — настройки провайдеров с `{env:VAR}` подстановкой
- **`mcp`** — конфигурация MCP серверов
- **`tools`** — включение/выключение инструментов (write, bash, edit…)
- **`permission`** — политики безопасности
- **`instructions`** — пути к правилам и гайдлайнам

### AGENTS.md (инструкции для AI):
- **Язык общения** — на каком языке отвечать
- **Структура проекта** — дерево директорий с описанием
- **Naming conventions** — как называть файлы
- **Architecture decisions** — ключевые решения и почему
- **Testing** — как запускать тесты, линтеры
- **Git remotes** — ссылки на репозиторий

**Лучшие практики из MCP servers (CLAUDE.md):**
- Краткость: одна страница
- Факты, не проза
- Команды для частых операций
- Архитектурная диаграмма в ASCII

---

## 8. GPU/LLM setup для локальных dev-машин

### WSL2 GPU:
- WSL 2.6+ для корректного GPU passthrough
- Docker Desktop: Settings > Resources > WSL Integration
- NVIDIA Container Toolkit для Docker GPU-доступа
- `autoMemoryReclaim` в `.wslconfig`

### Ollama (уже в opencode_initializer):
- Установка через snap или официальный скрипт
- Модели: `llama3.3`, `qwen3`, `deepseek-r1`, `codestral`
- GPU-ускорение автоматическое на NVIDIA (CUDA) и AMD (ROCm)

### vLLM / SGLang:
- vLLM: лучший throughput для production
- SGLang: лучше для structured outputs (JSON mode)
- Оба требуют CUDA 12.x+
- Рекомендация: vLLM для server-режима, Ollama для локальной разработки

### Open WebUI:
- Фронтенд для Ollama/vLLM
- Установка через Docker: `docker run -d -p 3000:8080 ghcr.io/open-webui/open-webui`
- GPU passthrough: `--gpus all`

---

## 9. Docker WSL2 Best Practices (детально)

1. **WSL версия ≥ 2.1.5** — иначе Docker Desktop может зависать
2. **Исходный код в Linux filesystem** (`~/project`, не `/mnt/c/Users/...`)
3. **Bind-mount из Linux FS**: `docker run -v ~/project:/src` (не `/mnt/c/...`)
4. **`autoMemoryReclaim`** в `.wslconfig` — предотвращает зависание `vmmem`
5. **Ограничение CPU/памяти** в `.wslconfig`:
   ```
   [wsl2]
   memory=8GB
   processors=4
   swap=4GB
   autoMemoryReclaim=gradual
   ```
6. **Docker Desktop WSL Integration**: Settings > Resources > WSL Integration > Enable для нужных дистрибутивов
7. **Не ставить Docker Engine внутрь WSL** параллельно с Docker Desktop — конфликты
8. **Enhanced Container Isolation** требует WSL 2.6+ (ядро 6.3+)

---

## 10. Кроссплатформенный shell scripting

### Инструменты:
- **ShellCheck**: `# shellcheck shell=bash` — явно указывать целевой shell
- **shfmt**: `-i 2 -ci -bn` для Google-стиля
- **bats-core**: единый тестовый фреймворк

### Подходы:
1. **Определять OS в рантайме**: `uname -s`, `/etc/os-release`, `$OSTYPE`
2. **Маппинг пакетных менеджеров**: единая абстракция `_pkg_install()` над apt/dnf/pacman/apk/zypper/brew
3. **`command -v` вместо `which`**: POSIX-совместимо, встроенная команда
4. **Избегать bash-specific фич если цель POSIX**: `[[ ]]` → `[ ]`, `local` → отсутствует в sh
5. **`#!/usr/bin/env bash`** вместо `#!/bin/bash` для macOS совместимости (но Google рекомендует `#!/bin/bash`)
6. **Тестировать на всех платформах**: GitHub Actions matrix: `ubuntu-latest`, `macos-latest`, `windows-latest` (с WSL)

---

## Специфические рекомендации для opencode_initializer

### Что уже сделано отлично:
1. Модульная архитектура (284 строки оркестратора + 24 модуля) — **золотой стандарт**
2. `_curl()`, `_retry()`, `_npm_install()`, `_sudo()` — абстракции для надёжности
3. Прогресс-файл для пропуска выполненных шагов
4. WSL2 DNS fix, `.wslconfig` генерация
5. `local_cmd()` с bun bin путями для мгновенного cold-start MCP
6. Auto-update через systemd timer + topgrade
7. 193 теста (bats-core)

### Рекомендации к внедрению:

**Высокий приоритет:**
1. **Лог каждого запуска**: `tee ~/.cache/opencode-setup/setup-$(date +%Y%m%d-%H%M%S).log`
2. **ShellCheck severity level**: повысить до `-S error` в CI (блокирующий), `-S warning` для разработки
3. **shfmt в CI**: `shfmt -d -i 2 -ci src/lib/*.sh src/modes/*.sh`
4. **dry-run по умолчанию для опасных операций**: `rm -rf`, `chmod`, изменения в `/etc`
5. **`set -euo pipefail` + `shopt -s inherit_errexit`** в каждом модуле (уже частично)

**Средний приоритет:**
6. **CI матрица дистрибутивов**: Ubuntu 22.04/24.04, Debian 12, Fedora 40, Arch, Alpine
7. **Pre-commit hooks**: ShellCheck + shfmt + detect-secrets
8. **CHANGELOG.md в формате Keep a Changelog**: `Added/Changed/Deprecated/Removed/Fixed/Security`
9. **Версионирование миграций**: timestamped уже есть — добавить SemVer тэги
10. **Health check в CI**: запускать `setup.sh --health` после тестовой установки

**Низкий приоритет (nice to have):**
11. **Интерактивный TUI**: `dialog` или `whiptail` для выбора компонентов (сейчас CLI)
12. **Параллельная установка независимых компонентов**: `xargs -P 4` для apt-пакетов
13. **Интеграция с MCP Registry**: автообнаружение новых MCP серверов
14. **Самодиагностика перед запуском**: `setup.sh --preflight` — проверка сети, дискового пространства, прав

### Что точно НЕ надо делать:
- **Не добавлять фреймворки вроде Ansible** — оверхед для single-machine bootstrap
- **Не переходить с bash на Python** — shell scripting остаётся правильным выбором для этой задачи
- **Не добавлять интерактивные подтверждения по умолчанию** — убивает автоматизацию. Только в `interactive` режиме

---

## Источники

1. [thoughtbot/laptop](https://github.com/thoughtbot/laptop) — эталон dev setup script (8.6k звёзд)
2. [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) — индустриальный стандарт Bash
3. [ShellCheck](https://github.com/koalaman/shellcheck/) (39.6k звёзд) — статический анализатор shell-скриптов
4. [mvdan/sh (shfmt)](https://github.com/mvdan/sh) (8.8k звёзд) — форматтер shell
5. [bats-core](https://github.com/bats-core/bats-core) (6.1k звёзд) — тестовый фреймворк для Bash
6. [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) (87.6k звёзд) — эталонные MCP серверы
7. [MCP Architecture](https://modelcontextprotocol.io/docs/concepts/architecture) — официальная документация
8. [Keep a Changelog](https://keepachangelog.com/en/2.0.0/) — стандарт CHANGELOG (v2.0.0)
9. [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/) — стандарт Code of Conduct v2.1
10. [Docker Desktop WSL2 Best Practices](https://docs.docker.com/desktop/features/wsl/best-practices/)
11. [OpenCode Config Documentation](https://opencode.ai/docs/config/) — opencode.json схема
12. [anomalyco/opencode issues](https://github.com/anomalyco/opencode/issues) — 5000+ issues, обратная связь пользователей
13. [setup-script topic на GitHub](https://github.com/topics/setup-script) — 425 репозиториев
14. [dev-environment-setup topic на GitHub](https://github.com/topics/dev-environment-setup) — 26 репозиториев
