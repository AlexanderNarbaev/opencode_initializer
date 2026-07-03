# Руководство по командной настройке

Как подключить всю команду к AI-усиленной среде разработки одной командой.

## Требования

- **Linux** (Ubuntu 24.04+, Debian 12+, Fedora, Arch, Alpine, openSUSE) или **WSL2** (Windows 10/11)
- **macOS** также поддерживается через brew
- **git** и **curl** предустановлены
- **10 ГБ+** свободного места на диске
- Доступ к **sudo** (кэшируется во время установки)

## Быстрое подключение

Отправьте эту команду каждому участнику команды:

```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --full
```

Эта единственная команда устанавливает **всё**: 8 языков программирования, 21 MCP-сервер, 15 плагинов OpenCode, 13 LSP-серверов, Docker, GPU/LLM-рантаймы, LiteLLM API-шлюз, SearXNG веб-поиск, ZSH с Powerlevel10k и CLI-инструмент `dev`.

## Типовые конфигурации для команды

### Бэкенд-разработчик (Go + Rust)

```bash
bash setup.sh --full -p ~/projects -n "Ваше Имя" -e "you@company.com"
```

Устанавливает все 8 языков. Участники команды могут пропустить неиспользуемые языки с помощью `--interactive`.

### Фронтенд-разработчик (TypeScript + Python)

```bash
bash setup.sh --interactive
# Выбрать: Node.js, Python, Chrome, Docker, ZSH
# Снять: Java, Kotlin, Zig, .NET
```

### Data/ML-инженер (Python + LLM)

```bash
bash setup.sh --full -p ~/ml-projects
# LLM-рантаймы (Ollama, vLLM, Open WebUI) автоопределяют GPU
```

### CI/CD Пайплайн (Headless)

```yaml
# .github/workflows/ai-review.yml
name: AI Code Review
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup OpenCode CI
        run: |
          curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --ci
      - name: AI Review
        env:
          DEEPSEEK_API_KEY: ${{ secrets.DEEPSEEK_API_KEY }}
        run: |
          opencode --non-interactive "Review this PR for bugs, security issues, and style"
```

CI-режим устанавливает только: OpenCode CLI + Bun + необходимые MCP (filesystem, context7). Без Docker, без ZSH, без GUI-инструментов, без GPU-рантаймов.

## Добавление API-ключей

Запустите установку с командными API-ключами для полной AI-функциональности:

```bash
bash setup.sh --full \
  --deepseek-key "sk-your-deepseek-key" \
  --xai-key "xai-your-grok-key" \
  --github-token "ghp_your-github-token" \
  --gitlab-token "glpat-your-gitlab-token" \
  --google-maps-key "your-google-maps-key"
```

### Поддерживаемые API-ключи

| Флаг | Сервис | Бесплатный тариф |
|------|--------|------------------|
| `--deepseek-key` | DeepSeek | Да (platform.deepseek.com) |
| `-k, --api-key` | OpenCode Go | — |
| `--xai-key` | xAI Grok | — |
| `--mimo-key` | Xiaomi MiMo | — |
| `--moonshot-key` | Moonshot Kimi K2.7 | — |
| `--minimax-key` | MiniMax M3 | — |
| `--github-token` | GitHub (MCP, gh CLI) | Бесплатно (classic token, без scopes) |
| `--gitlab-token` | GitLab (MCP) | Бесплатно (read_api scope) |
| `--google-maps-key` | Google Maps API | Есть бесплатный тариф |

Все ключи хранятся безопасно в `~/.config/opencode/secrets.env` с правами `chmod 600` (чтение/запись только владельцем).

## Командные дотфайлы с chezmoi

v2.0.0 добавляет chezmoi для обмена командной конфигурацией:

```bash
# После установки создайте репозиторий командных дотфайлов
chezmoi init --apply git@github.com:your-org/team-dotfiles.git

# Добавьте личную конфигурацию
chezmoi add ~/.gitconfig
chezmoi add ~/.config/opencode/secrets.env  # хранится в зашифрованном виде!

# Отправьте для команды
chezmoi cd
git push
```

Участники команды применяют общую конфигурацию:

```bash
chezmoi init --apply git@github.com:your-org/team-dotfiles.git
```

## Настройка под роль

### Linux-сервер (без GUI)

```bash
bash setup.sh --interactive
# Снять: Chrome, Open WebUI, Playwright
# Оставить: все языки, Docker, ZSH, MCP
```

### WSL2 с Windows-хостом

Установщик автоматически определяет WSL2 и применяет оптимизации:
- Исправление DNS (8.8.8.8, 1.1.1.1)
- Лимиты памяти (50% от ОЗУ хоста)
- Режим зеркалированной сети
- Генерация `.wslconfig`

```bash
# Полная установка WSL2
bash setup.sh --full
```

### macOS

```bash
bash setup.sh --full
# Использует brew. GPU-функции автоопределяют Apple Silicon.
```

## Проверка после установки

Каждый участник команды должен проверить свою установку:

```bash
dev health              # 65+ диагностических проверок
dev version-check       # Сравнение установленных и актуальных версий
dev list                # Список всех установленных компонентов
```

### Что проверяется

| Раздел | Проверки | Примеры |
|--------|----------|---------|
| Система | ОС, пакеты, DNS, зеркала | apt/dnf/pacman работают |
| Языки | Java, Node, Python, Go, Rust, .NET, Zig | Версия >= минимальной |
| Инструменты | Docker, Chrome, Bun, OpenCode CLI | Бинарник в PATH |
| Оболочка | ZSH, Oh My Zsh, плагины, .zshrc | Оболочка работает |
| MCP | Бинарники серверов, bun-пути, конфиг | Холодный старт проверен |
| LLM | Ollama, vLLM, Open WebUI | GPU обнаружен, сервис запущен |
| Безопасность | Права секретов, API-ключи | chmod 600, все токены на месте |

## Решение проблем

### Сеть недоступна в WSL2

Установщик автоматически определяет WSL2 и применяет исправления DNS. Если всё равно не работает:

```powershell
# В PowerShell (от администратора):
wsl --shutdown
# Затем перезапустите терминал WSL2
```

### Запросы пароля sudo

Закэшируйте пароль sudo для неинтерактивного запуска:

```bash
bash setup.sh --full -s "your-sudo-password"
```

### Недостаточно места на диске

Пропустите тяжёлые компоненты:

```bash
bash setup.sh --interactive
# Снять: Docker, Chrome, vLLM, RAG, Open WebUI
```

### Ошибка прав Docker

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Ошибки аутентификации провайдеров

Проверьте ключи:

```bash
dev health
# Проверьте раздел «Безопасность» на наличие токенов и прав
```

Перегенерируйте opencode.json после добавления новых ключей:

```bash
bash setup.sh --fix-config --deepseek-key "sk-..."
```

## Сводка установленных компонентов

| Категория | Компоненты |
|-----------|------------|
| **Языки** | Java 25, Node.js 24, Python 3.14 + uv, Go 1.26, Rust 1.96, .NET 10, Kotlin, Zig |
| **MCP-серверы** | 21 — context7, filesystem, github, gitlab, playwright, chrome-devtools, postgres, sqlite, memory, excalidraw, brave-search, google-maps и другие |
| **LSP-серверы** | 13 — gopls, rust-analyzer, tsserver, pyright, omnisharp, yaml, marksman, bash, dockerfile, css/html/json и другие |
| **Плагины** | 15 — token-tracker, dcp, swarm, auto-fallback, goal-mode, vibeguard, orchestrator и другие |
| **Инфраструктура** | Docker, ChromaDB, LiteLLM, SearXNG, Muninn, Ollama, vLLM, SGLang, Open WebUI |
| **API-шлюз** | LiteLLM — OpenAI-совместимая точка доступа для всех 24 провайдеров |
| **Веб-поиск** | SearXNG self-hosted + sanitizer-прокси (внутренние хосты/IP/PII) |
| **Оболочка** | ZSH + Oh My Zsh + Powerlevel10k + 14 плагинов |
| **CLI** | Инструмент `dev` — install, remove, update, health, list, config, version-check |
| **Дотфайлы** | chezmoi для обмена командной конфигурацией |
| **Dev-окружения** | Devbox — изолированные окружения на базе Nix |
| **Автообновление** | systemd-таймер (еженедельно) + topgrade + unattended-upgrades (ежедневно) |

## Дальнейшие шаги

- Ознакомьтесь с [обзором архитектуры](../architecture/) — C4-диаграммы и структура модулей
- Прочитайте [AGENTS.md](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/AGENTS.md) — документация для AI-агентов
- Изучите [руководство пользователя](../user-guide/) — ежедневное использование CLI
- Сообщайте о проблемах на [GitHub](https://github.com/AlexanderNarbaev/opencode_initializer/issues)
