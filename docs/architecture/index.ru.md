# Архитектура

OpenCode Initializer построен на модульной архитектуре: лёгкий **оркестратор** (`setup.sh`, 284 строки), который подключает 25 **модулей** и запускает 4 **режимных скрипта**.

## C4 Уровень 1: Контекст системы

```mermaid
C4Context
    title opencode_initializer — Контекст системы

    Person(dev, "Разработчик", "Хочет готовое AI-усиленное окружение для разработки")
    System(oci, "OpenCode Initializer", "Настраивает полную dev-машину: 8 языков, 21 MCP, 15 плагинов, инфраструктура")
    
    System_Ext(gh, "GitHub", "Исходный код, релизы, CI/CD")
    System_Ext(ghp, "GitHub Packages", "npm пакеты, Docker образы")
    System_Ext(apt, "Реестры пакетов", "apt, dnf, pacman, apk, zypper, brew")
    System_Ext(mcp_registry, "MCP Registry", "MCP-серверы")
    System_Ext(ai_api, "AI Провайдеры", "OpenCode, DeepSeek и др.")
    
    Rel(dev, oci, "Запускает setup.sh", "curl|bash")
    Rel(oci, gh, "Скачивает", "HTTPS")
    Rel(oci, ghp, "Устанавливает пакеты", "npm, pip, cargo")
    Rel(oci, apt, "Устанавливает системные пакеты", "apt/dnf/pacman")
    Rel(oci, mcp_registry, "Загружает MCP-серверы", "npm, npx")
    Rel(oci, ai_api, "Настраивает провайдеров", "HTTPS/API")
```

## C4 Уровень 2: Контейнеры

```mermaid
C4Container
    title opencode_initializer — Контейнеры

    Container_Boundary(oci, "OpenCode Initializer") {
        Container(setup, "setup.sh", "Bash", "Оркестратор — запускает режимы, подключает модули, отслеживает прогресс")
        Container(dev_cli, "dev CLI", "Bash", "Управление после установки: install, remove, update, health, config")
        Container(lib, "src/lib/ (25 модулей)", "Bash", "Основные модули: система, языки, инструменты, MCP, LSP, LLM")
        Container(modes, "src/modes/ (4 режима)", "Bash", "Режимы: health, fix-zshrc, upgrade, interactive")
        Container(tests, "tests/", "Bash + Bats", "Юнит, интеграционные, E2E тесты")
        Container(docs_site, "Сайт документации", "MkDocs Material", "Документация (эта страница)")
    }
    
    System_Ext(gh_actions, "GitHub Actions", "CI/CD — ShellCheck, shfmt, тесты, деплой доков")
    System_Ext(github_pages, "GitHub Pages", "Хостинг документации")
    
    Rel(setup, lib, "Подключает модули", "source")
    Rel(setup, modes, "Запускает режим", "bash")
    Rel(dev_cli, lib, "Подключает helpers", "source")
    Rel(gh_actions, tests, "Запускает", "CI триггер")
    Rel(gh_actions, docs_site, "Собирает и деплоит", "mkdocs build + gh-pages")
    Rel(docs_site, github_pages, "Деплоится на", "GitHub Pages")
```

## C4 Уровень 3: Схема модулей

```mermaid
C4Container
    title src/lib/ — 25 модулей

    Container_Boundary(modules, "src/lib/") {
        Container(helpers, "helpers.sh", "Bash", "_curl, _retry, _npm_install — общая инфраструктура")
        Container(core, "00-core.sh", "Bash", "Определение ОС/ПМ/архитектуры, зеркала, прогресс")
        
        Container(sys, "01-system.sh", "Bash", "Системные пакеты (кросс-дистрибутив)")
        Container(docker, "02-docker.sh", "Bash", "Docker Engine")
        Container(chrome, "03-chrome.sh", "Bash", "Google Chrome + chromedriver")
        Container(zsh, "04-zsh.sh", "Bash", "Zsh + Oh My Zsh + P10k + 14 плагинов")
        
        Container(java, "05-java.sh", "Bash", "Java 25 (Adoptium)")
        Container(node, "06-node.sh", "Bash", "Node.js 24 (n)")
        Container(python, "07-python.sh", "Bash", "Python 3.14 + uv")
        Container(go, "08-go.sh", "Bash", "Go 1.26")
        Container(rust, "09-rust.sh", "Bash", "Rust 1.96 (rustup)")
        Container(dotnet, "10-dotnet.sh", "Bash", ".NET 10")
        
        Container(opencode, "11-opencode.sh", "Bash", "OpenCode CLI + Bun")
        Container(mcp, "12-mcp-lsp.sh", "Bash", "21 MCP + 15 плагинов + 13 LSP")
        Container(chromadb, "13-chromadb.sh", "Bash", "ChromaDB + systemd")
        Container(shokunin, "14-shokunin.sh", "Bash", "Shokunin + Superpowers + Caveman")
        Container(sec, "15-security.sh", "Bash", "Trivy, Qodana")
        Container(llm, "16-llm.sh", "Bash", "Ollama, vLLM, SGLang, Open WebUI")
        
        Container(project, "17-project.sh", "Bash", "Структура проекта (AGENTS.md, WAL)")
        Container(json, "18-opencode-json.sh", "Bash", "Генерация opencode.json")
        Container(finalize, "19-finalize.sh", "Bash", "Git config, PATH, верификация (36 проверок)")
        Container(update, "20-autoupdate.sh", "Bash", "topgrade + systemd таймер")
        Container(rag, "21-rag.sh", "Bash", "RAG система (опционально)")
        
        Container(vcheck, "version-check.sh", "Bash", "Сравнение версий (8 инструментов)")
        Container(precheck, "pre-session-check.sh", "Bash", "Предсессионная валидация")
    }

    Rel(core, helpers, "Использует")
    Rel(sys, core, "Зависит")
    Rel(java, core, "Зависит")
    Rel(mcp, helpers, "Использует _curl/_npm_install")
    Rel(finalize, json, "Вызывает")
    Rel(project, core, "Зависит")
```

## Поток выполнения setup.sh

```mermaid
flowchart TD
    A["setup.sh (284 строки)"] --> B["Определить SCRIPT_DIR"]
    B --> C["Подключить helpers.sh"]
    C --> D["Подключить 00-core.sh"]
    D --> E{"Разбор аргументов CLI"}
    E -->|"--health"| H["Режим диагностики"]
    E -->|"--interactive"| K["Интерактивный режим"]
    E -->|"--dry-run"| J["Предпросмотр"]
    E -->|"по умолчанию (full)"| M["Полная установка"]
    
    M --> N["Последовательно: 01-system.sh … 21-rag.sh"]
    N --> O["18-opencode-json.sh"]
    O --> P["19-finalize.sh"]
    P --> Q["Верификация: 36 проверок"]
    Q --> R["Готово"]
```

## Карта зависимостей модулей

```mermaid
graph LR
    subgraph "Инфраструктурный слой"
        helpers["helpers.sh"]
        core["00-core.sh"]
    end
    
    subgraph "Системный слой"
        sys["01-system.sh"]
        docker["02-docker.sh"]
        chrome["03-chrome.sh"]
        zsh["04-zsh.sh"]
    end
    
    subgraph "Языковой слой"
        java["05-java.sh"]
        node["06-node.sh"]
        python["07-python.sh"]
        go["08-go.sh"]
        rust["09-rust.sh"]
        dotnet["10-dotnet.sh"]
    end
    
    subgraph "Инструментальный слой"
        opencode["11-opencode.sh"]
        mcp["12-mcp-lsp.sh"]
        chromadb["13-chromadb.sh"]
        shokunin["14-shokunin.sh"]
        sec["15-security.sh"]
        llm["16-llm.sh"]
        rag["21-rag.sh"]
    end
    
    subgraph "Слой финализации"
        project["17-project.sh"]
        json["18-opencode-json.sh"]
        finalize["19-finalize.sh"]
        update["20-autoupdate.sh"]
    end
    
    helpers --> core
    core --> sys
    core --> docker
    core --> chrome
    core --> zsh
    sys --> java
    sys --> node
    sys --> python
    sys --> go
    sys --> rust
    sys --> dotnet
    helpers --> opencode
    helpers --> mcp
    helpers --> chromadb
    helpers --> llm
    core --> project
    project --> json
    json --> finalize
    finalize --> update
```

## Ключевые архитектурные решения

| Решение | Обоснование |
|---------|-------------|
| **Модульная архитектура** | Каждый язык/инструмент изолирован. Легко добавлять/удалять/обновлять |
| **Отслеживание прогресса** | `~/.cache/opencode-setup/progress` запоминает выполненные шаги. Повторные запуски идемпотентны |
| **Adoptium API для Java** | GitHub CDN, надёжен в WSL2 в отличие от sdkman.io |
| **npm pack кэш для MCP** | `.tgz` файлы кэшируются локально, переживают повторные запуски |
| **Весь curl через _curl()** | 5 попыток, экспоненциальная задержка, кэш 24ч |
| **Весь npm через _npm_install()** | npm pack → bun fallback |
| **WSL2 DNS fix** | Добавляет 8.8.8.8 + 1.1.1.1 в /etc/resolv.conf |
| **Нет секретов в коде** | Все API ключи только через аргументы CLI |
| **Bun binary paths для MCP** | Абсолютные пути к `~/.bun/bin/` вместо `npx -y`, мгновенный холодный старт |
| **Автообновление через systemd** | topgrade еженедельно (Вс 04:00), unattended-upgrades ежедневно |
| **Логирование установки** | `tee` в `~/.cache/opencode-setup/setup-YYYYMMDD-HHMMSS.log` |
