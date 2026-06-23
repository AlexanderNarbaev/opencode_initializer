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
| **Полный** | *(по умолчанию)* | Полная установка — все языки, инструменты, MCP, LSP |
| **Диагностика** | `--health` | Диагностика — 60+ проверок в 5 разделах |
| **Интерактивный** | `--interactive` | Выбор компонентов по одному |
| **Переустановка** | `--reinit` | Переустановить инструменты, сохранить данные |
| **Новый проект** | `--new <папка>` | Только инициализация нового проекта |
| **Предпросмотр** | `--dry-run` | Режим просмотра, без изменений |
| **Исправить конфиг** | `--fix-config` | Пересоздать opencode.json |
| **Исправить ZSH** | `--fix-zshrc` | Восстановить .zshrc |
| **Обновление** | `--update` | Обновить только инструменты |

### Опции

| Флаг | Описание |
|------|----------|
| `--github-token <токен>` | GitHub API токен для MCP |
| `--gitlab-token <токен>` | GitLab API токен для MCP |
| `--google-maps-key <ключ>` | Google Maps API ключ |
| `--help` | Показать справку |
| `--version` | Показать версию |

### Примеры

```bash
# Полная установка
bash setup.sh

# Диагностика
bash setup.sh --health

# Интерактивный режим
bash setup.sh --interactive

# Новый проект
bash setup.sh --new ~/my-project

# С GitHub токеном
bash setup.sh --github-token ghp_xxxx
```

## `dev` CLI — Управление после установки

Доступен после установки: `~/opencode_initializer/dev.sh`.

```bash
dev <команда> [аргументы]
```

### Команды

| Команда | Описание |
|---------|----------|
| `dev health` | Полная диагностика (60+ проверок) |
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

Провайдеры строятся динамически на основе доступных API ключей:

| Провайдер | Переменная окружения | MCP-серверы |
|-----------|---------------------|-------------|
| `deepseek` | *(встроенный)* | — |
| `opencode` | *(встроенный)* | — |
| `github` | `GITHUB_TOKEN` | github-mcp |
| `gitlab` | `GITLAB_TOKEN` | gitlab-mcp |
| `google` | `GOOGLE_MAPS_KEY` | google-maps-mcp |

## Переменные окружения

| Переменная | Назначение | Обязательна |
|-----------|-----------|-------------|
| `GITHUB_TOKEN` | Доступ к GitHub API | Нет |
| `GITLAB_TOKEN` | Доступ к GitLab API | Нет |
| `GITVERSE_TOKEN` | Доступ к GitVerse API | Нет |
| `GOOGLE_MAPS_KEY` | Google Maps API | Нет |
| `OPENAI_API_KEY` | OpenAI API (не используется по умолчанию) | Нет |

Переменные хранятся в `~/.config/opencode/secrets.env` с `chmod 600`.

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

- **Счётчик шагов**: `[3/23] Установка Node.js...`
- **Спиннер**: `⠋ Установка пакетов...` при долгих операциях
- **Размытый лог**: `▌ Установка chromedriver через apt...` для подробного вывода
- **Цветной статус**: `[✓]` зелёный = готово, `[!]` жёлтый = внимание, `[✗]` красный = ошибка

## Справочник модулей

| Модуль | Файл | Строк | Назначение |
|--------|------|-------|------------|
| Helpers | `helpers.sh` | 120 | `_curl()`, `_retry()`, `_npm_install()`, `_spin_start()` / `_spin_stop()` |
| Core | `00-core.sh` | 220 | ОС/ПМ/архитектура, зеркала, прогресс |
| System | `01-system.sh` | 35 | Системные пакеты |
| Docker | `02-docker.sh` | 37 | Docker Engine |
| Chrome | `03-chrome.sh` | 114 | Chrome + ChromeDriver |
| ZSH | `04-zsh.sh` | 95 | Zsh + Oh My Zsh + P10k |
| Java | `05-java.sh` | 80 | Java 25 + Zig |
| Node | `06-node.sh` | 22 | Node.js 24 |
| Python | `07-python.sh` | 29 | Python 3.14 + uv |
| Go | `08-go.sh` | 31 | Go 1.26 |
| Rust | `09-rust.sh` | 21 | Rust 1.96 |
| .NET | `10-dotnet.sh` | 24 | .NET 10 |
| OpenCode | `11-opencode.sh` | 82 | OpenCode CLI + Bun |
| MCP/LSP | `12-mcp-lsp.sh` | 187 | 21 MCP + 15 плагинов + 13 LSP |
| ChromaDB | `13-chromadb.sh` | 56 | ChromaDB + systemd |
| Shokunin | `14-shokunin.sh` | 26 | Shokunin + Superpowers |
| Security | `15-security.sh` | 16 | Trivy, Qodana |
| LLM | `16-llm.sh` | 52 | Ollama, vLLM, SGLang |
| Project | `17-project.sh` | 521 | Структура проекта |
| JSON | `18-opencode-json.sh` | 540 | Генерация opencode.json |
| Finalize | `19-finalize.sh` | 220 | Git config, PATH, верификация |
| Autoupdate | `20-autoupdate.sh` | 80 | topgrade + systemd таймер |
| RAG | `21-rag.sh` | 30 | RAG система (опционально) |
| **mise** | `22-mise.sh` | 35 | mise-en-place — универсальный менеджер версий |
| **just** | `23-just.sh` | 55 | just — таск-раннер (аналог Make) |
| Version | `version-check.sh` | 135 | Сравнение версий |
| PreSession | `pre-session-check.sh` | 83 | Предсессионная валидация |

---

**См. также:**
- [MCP, LSP и плагины](../reference/mcp-lsp-plugins/) — каталог 24+13+18 компонентов
- [Архитектура](../architecture/) — C4-диаграммы и проектные решения
- [Руководство](../user-guide/) — повседневный CLI
- [FAQ](../faq/) — решение проблем
