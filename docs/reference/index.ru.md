# Справочник

Полный справочник CLI для OpenCode Initializer.

## `setup.sh` — Оркестратор

Главная точка входа. Подключает модули из `src/lib/` и запускает режимы.

```bash
bash setup.sh [РЕЖИМ] [ОПЦИИ]
```

### Режимы

| Режим | Флаг | Описание |
|-------|------|----------|
| **Полный** | *(по умолчанию)* | Полная установка — все 8 языков, 24 MCP, 18 плагинов, 12 LSP |
| **Диагностика** | `--health` | Диагностика — 115+ проверок в 11 разделах |
| **Интерактивный** | `--interactive` | Выбор компонентов по одному |
| **Переустановка** | `--reinit` | Переустановить инструменты, сохранить данные |
| **Новый проект** | `--new <папка>` | Только инициализация нового проекта |
| **CI/CD** | `--ci` | Headless режим: OpenCode CLI + основные MCP |
| **Предпросмотр** | `--dry-run` | Режим просмотра, без изменений |
| **Исправить конфиг** | `--fix-config` | Пересоздать opencode.json |
| **Исправить ZSH** | `--fix-zshrc` | Восстановить .zshrc |
| **Обновление** | `--update` | Обновить только инструменты |
| **Апгрейд** | `--upgrade` | Полная цепочка обновления системы |

### Опции

| Флаг | Описание |
|------|----------|
| `-k, --api-key <ключ>` | OpenCode Go API ключ |
| `--deepseek-key <ключ>` | DeepSeek API ключ |
| `--xai-key <ключ>` | xAI Grok API ключ |
| `--mimo-key <ключ>` | Xiaomi MiMo API ключ |
| `--moonshot-key <ключ>` | Moonshot API ключ |
| `--minimax-key <ключ>` | MiniMax API ключ |
| `--github-token <токен>` | GitHub токен |
| `--gitlab-token <токен>` | GitLab токен |
| `--google-maps-key <ключ>` | Google Maps API ключ |
| `-s, --sudo-pass <пароль>` | Пароль sudo (кэшируется) |
| `-p, --project-dir <папка>` | Директория проекта (по умолчанию: ~/projects) |
| `-n, --git-name <имя>` | Имя пользователя Git |
| `-e, --git-email <email>` | Email Git |

### Примеры

```bash
# Полная установка
bash setup.sh

# Диагностика
bash setup.sh --health

# Интерактивный режим
bash setup.sh --interactive

# CI/CD режим
bash setup.sh --ci

# Новый проект
bash setup.sh --new ~/my-project

# С API ключами
bash setup.sh --full --deepseek-key sk-xxxx --github-token ghp_xxxx
```

## `dev` CLI — Управление после установки

Доступен после установки: `~/opencode_initializer/dev.sh`.

```bash
dev <команда> [аргументы]
```

### Команды

| Команда | Описание |
|---------|----------|
| `dev health` | Полная диагностика (115+ проверок, 11 разделов) |
| `dev version-check` | Сравнить установленные и последние версии |
| `dev update` | Обновить инструменты + миграции |
| `dev list` | Список установленных компонентов |
| `dev install <имя>` | Установить новый компонент |
| `dev remove <имя>` | Удалить компонент |
| `dev config` | Редактировать конфигурацию |
| `dev autoupdate` | Полное обновление системы (topgrade) |
| `dev self-update` | Git pull + переустановка dev CLI + setup.sh |

### Примеры

```bash
# Проверить всё
dev health

# Посмотреть устаревшее
dev version-check

# Установить Docker, если нет
dev install docker

# Удалить Java
dev remove java

# Полное обновление системы
dev autoupdate

# Обновить сам opencode_initializer
dev self-update
```

## `opencode.json` — Схема

Конфигурация AI-ассистента OpenCode. Генерируется модулем `18-opencode-json.sh`.

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "deepseek/deepseek-v4-pro",
  "small_model": "deepseek/deepseek-v4-flash",
  "provider": {
    "deepseek": {},
    "opencode": {}
  },
  "instructions": ["AGENTS.md"],
  "mcpServers": {
    "github": { "type": "local", "command": ["node", "..."] },
    "filesystem": { "type": "local", "command": ["node", "..."] },
    "...": "..."
  },
  "plugins": [
    ["token-tracker@latest"],
    ["dcp@latest"],
    ["swarm@latest"],
    "..."
  ]
}
```

### Конфигурация провайдеров

Провайдеры строятся динамически на основе доступных API ключей (всего 24):

| Провайдер | Переменная окружения | MCP-серверы |
|-----------|---------------------|-------------|
| `deepseek` | *(встроенный)* | — |
| `opencode` | *(встроенный)* | — |
| `openai` | `OPENAI_API_KEY` | — |
| `anthropic` | `ANTHROPIC_API_KEY` | — |
| `google` | `GOOGLE_API_KEY` / `GOOGLE_MAPS_KEY` | google-maps-mcp |
| `xai` | `XAI_API_KEY` | — |
| `moonshot` | `MOONSHOT_API_KEY` | — |
| `minimax` | `MINIMAX_API_KEY` | — |
| `mimo` | `MIMO_API_KEY` | — |
| `groq` | `GROQ_API_KEY` | — |
| `together` | `TOGETHER_API_KEY` | — |
| `fireworks` | `FIREWORKS_API_KEY` | — |
| `perplexity` | `PERPLEXITY_API_KEY` | — |
| `mistral` | `MISTRAL_API_KEY` | — |
| `cohere` | `COHERE_API_KEY` | — |
| `github` | `GITHUB_TOKEN` | github-mcp |
| `gitlab` | `GITLAB_TOKEN` | gitlab-mcp |

## Переменные окружения

| Переменная | Назначение | Обязательна |
|-----------|-----------|-------------|
| `GITHUB_TOKEN` | Доступ к GitHub API | Нет |
| `GITLAB_TOKEN` | Доступ к GitLab API | Нет |
| `GITVERSE_TOKEN` | Доступ к GitVerse API | Нет |
| `GOOGLE_MAPS_KEY` | Google Maps API | Нет |
| `OPENAI_API_KEY` | OpenAI API | Нет |
| `ANTHROPIC_API_KEY` | Anthropic API | Нет |
| `XAI_API_KEY` | xAI Grok API | Нет |
| `MOONSHOT_API_KEY` | Moonshot API | Нет |
| `MINIMAX_API_KEY` | MiniMax API | Нет |
| `MIMO_API_KEY` | MiMo API | Нет |
| `GROQ_API_KEY` | Groq API | Нет |
| `TOGETHER_API_KEY` | Together API | Нет |
| `FIREWORKS_API_KEY` | Fireworks API | Нет |
| `PERPLEXITY_API_KEY` | Perplexity API | Нет |
| `MISTRAL_API_KEY` | Mistral API | Нет |
| `COHERE_API_KEY` | Cohere API | Нет |

Все переменные хранятся в `~/.config/opencode/secrets.env` с `chmod 600`.

## Структура файлов

```
~/.cache/opencode-setup/
  ├── progress            # Журнал выполненных шагов
  └── setup-*.log         # Логи установки с меткой времени

~/.bun/bin/               # Кэш бинарников Bun (MCP cold start)

~/.config/opencode-setup/
  └── setup.conf          # Постоянные настройки

~/.config/opencode/
  └── secrets.env         # API ключи (chmod 600)

~/opencode_initializer/
  ├── opencode.json       # Сгенерированный AI конфиг
  ├── setup.sh            # Оркестратор
  └── dev.sh              # CLI после установки
```

## Отслеживание прогресса

Файл `~/.cache/opencode-setup/progress` записывает выполненные шаги:

```
step_done "01-system"      # Проверить, сделано ли
step_skip "01-system"      # Пропустить, если сделано
step_mark "01-system"      # Отметить как сделанное
```

Повторные запуски идемпотентны — компоненты пропускаются.

### Визуальный прогресс

При установке вы увидите:

- **Счётчик шагов**: `[3/29] Установка Node.js...`
- **Спиннер**: `⠋ Установка пакетов...` при долгих операциях
- **Размытый лог**: `▌ Установка chromedriver через apt...` для подробного вывода
- **Цветной статус**: `[✓]` зелёный = готово, `[!]` жёлтый = внимание, `[✗]` красный = ошибка

## Справочник модулей

| Модуль | Файл | Назначение |
|--------|------|------------|
| Helpers | `helpers.sh` | `_curl()`, `_retry()`, `_npm_install()`, инфраструктура спиннера |
| Core | `00-core.sh` | ОС/ПМ/архитектура, зеркала, прогресс |
| System | `01-system.sh` | Системные пакеты (кросс-дистрибутив: apt/dnf/pacman/apk/zypper/brew) |
| Docker | `02-docker.sh` | Docker Engine |
| Chrome | `03-chrome.sh` | Google Chrome + ChromeDriver (WSL2-aware) |
| ZSH | `04-zsh.sh` | Zsh + Oh My Zsh + Powerlevel10k + 14 плагинов |
| Java | `05-java.sh` | Java 25 (Adoptium) + Zig |
| Node | `06-node.sh` | Node.js 24 (n) |
| Python | `07-python.sh` | Python 3.14 + uv |
| Go | `08-go.sh` | Go 1.26 |
| Rust | `09-rust.sh` | Rust 1.97.1 (rustup) |
| .NET | `10-dotnet.sh` | .NET 10 |
| OpenCode | `11-opencode.sh` | OpenCode CLI + Bun |
| MCP/LSP | `12-mcp-lsp.sh` | 24 MCP + 18 плагинов + 12 LSP + Muninn |
| ChromaDB | `13-chromadb.sh` | ChromaDB + systemd сервис |
| Shokunin | `14-shokunin.sh` | Shokunin + Superpowers + Caveman |
| Security | `15-security.sh` | Trivy, Qodana |
| LLM | `16-llm.sh` | Ollama, vLLM, SGLang, Open WebUI (GPU-aware, multi-vendor) |
| Project | `17-project.sh` | Структура проекта (AGENTS.md, WAL, docker-compose) |
| JSON | `18-opencode-json.sh` | Генерация opencode.json (Python inline, bun bin paths) |
| Finalize | `19-finalize.sh` | Git config, PATH, .zshrc, верификация (36 проверок) |
| Autoupdate | `20-autoupdate.sh` | topgrade + systemd weekly timer + unattended-upgrades |
| RAG | `21-rag.sh` | Корпоративный Knowledge Assistant (ETL + Qdrant + Gemma) |
| mise | `22-mise.sh` | mise-en-place — универсальный менеджер версий |
| WebUI Service | `22-webui-service.sh` | Open WebUI systemd сервис |
| just | `23-just.sh` | just — таск-раннер с дефолтным justfile |
| WebSearch | `24-websearch.sh` | SearXNG веб-поиск + sanitizer proxy |
| LiteLLM | `25-litellm.sh` | LiteLLM OpenAI-совместимый API-шлюз |
| Providers | `26-providers.sh` | Реестр 24 LLM-провайдеров с переключением сессий |
| Infrastructure | `30-infra.sh` | PostgreSQL + Qdrant + Redis + Prometheus + Grafana + MemoryLayer |
| Dotfiles | `27-dotfiles.sh` | chezmoi — менеджер dotfiles для командного шеринга |
| Devbox | `28-devbox.sh` | Devbox — изолированные Nix-окружения |
| Version Check | `version-check.sh` | Сравнение версий (8+ инструментов, npm пакеты) |
| Pre-Session Check | `pre-session-check.sh` | Предсессионная валидация провайдеров/моделей + статус MCP |

---

**См. также:**
- [MCP, LSP и плагины](../reference/mcp-lsp-plugins/) — каталог 24+12+18 компонентов
- [Архитектура](../architecture/) — C4-диаграммы и проектные решения
- [Руководство](../user-guide/) — повседневный CLI
- [FAQ](../faq/) — решение проблем
