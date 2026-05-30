# Ultimate Dev Machine Bootstrap

**Однокомандная настройка AI-усиленной dev-машины в WSL2/Linux.**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AlexandrNarbaev/opencode_initializer/main/setup_v28.1.sh) --full
```

## Что делает

За 10-15 минут превращает свежий WSL2/Linux в готовую среду разработки с:

- **8 языков**: Java 25, Node.js 22, Python 3.12, Go 1.26, Rust 1.93, .NET 9, Kotlin, Zig
- **14 MCP-серверов**: context7, filesystem, agentic-tools, codegraph, playwright, agent-browser, codesorb, mcp-replay, open-orchestra, loopsense, datafy, github, postgres, sequential-thinking
- **10 LSP-серверов**: gopls, rust-analyzer, typescript, pyright, omnisharp, yaml, marksman, taplo, lua, zls
- **Multi-Provider AI**: DeepSeek V4 Pro (primary) + OpenCode Go (fallback) — авто-переключение
- **Память**: ChromaDB + Muninn (векторная БД для AI-агентов)
- **Экосистема**: Shokunin (62+ skills), Superpowers, Caveman
- **Инфраструктура**: Docker, Kafka, Postgres, MongoDB, Redis, MinIO (docker-compose)

## Быстрый старт

```bash
# Минимально (только системные пакеты + OpenCode)
bash setup_v28.1.sh --full

# С ключами API
bash setup_v28.1.sh -k "sk-..." --deepseek-key "sk-..." --full

# Интерактивный режим (выбор компонентов)
bash setup_v28.1.sh --interactive

# Диагностика
bash setup_v28.1.sh --health

# Только починить конфиг
bash setup_v28.1.sh --fix-config
```

## Режимы

| Режим | Описание |
|-------|----------|
| `--full` | Полная установка (по умолчанию) |
| `--reinit` | Переустановка инструментов, данные проекта сохраняются |
| `--new <dir>` | Только инициализация нового проекта |
| `--health` | Диагностика всех компонентов без изменений |
| `--update` | Обновление инструментов |
| `--upgrade` | Полное обновление системы |
| `--interactive` | Пошаговый выбор компонентов |
| `--fix-config` | Перегенерировать opencode.json |
| `--fix-zshrc` | Починить .zshrc |

## Ключевые фичи v28.1

- **Anti-hang**: `timeout` на всех npm install и curl (120s), защита от зависания
- **WSL2 network fix**: авто-детект прокси Windows, сброс DHCP при обрыве связи
- **_curl() wrapper**: 5 попыток с экспоненциальной задержкой (2→4→8→16→32s), кеш 24ч
- **MCP npm→bun fallback**: при сбое npm автоматически пробует bun
- **Multi-provider**: `opencode.json` содержит оба провайдера (`deepseek` + `opencode`)
- **Download cache**: `~/.cache/opencode-setup/` — повторные запуски без скачивания

## Требования

- Ubuntu 24.04+ / Debian 12+ / WSL2
- 10GB+ свободного места
- Sudo-доступ

## Лицензия

MIT
