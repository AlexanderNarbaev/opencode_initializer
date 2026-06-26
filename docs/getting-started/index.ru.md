# :fontawesome-solid-download: Начало работы

Впервые с opencode_initializer? Здесь всё — от нуля до полностью работающего AI-окружения.

!!! info "Оценка времени"
    Полная установка занимает **15-30 минут** в зависимости от интернета и скорости машины. Повторные запуски быстрее (идемпотентны).

## :fontawesome-solid-circle-info: Что нужно

### Системные требования

| Требование | Минимум | Рекомендуется |
|------------|---------|---------------|
| **ОС** | Ubuntu 22.04+ / Debian 12 / WSL2 / Fedora 40+ | Ubuntu 24.04 LTS |
| **RAM** | 4 GB | 16 GB+ (для LLM) |
| **Диск** | 10 GB свободно | 50 GB+ (с моделями LLM) |
| **Интернет** | Широкополосный | Быстрый (много загрузок) |
| **Оболочка** | bash 4.0+ | zsh (будет установлен) |

### Перед началом

1. :fontawesome-solid-check: **Свежая установка ОС** рекомендуется
2. :fontawesome-solid-check: **Подключение к интернету** — скрипт скачивает много пакетов
3. :fontawesome-solid-check: **Sudo доступ** — нужно будет ввести пароль
4. :fontawesome-solid-check: **Просмотрите скрипт** — `curl -fsSL <url> | less` перед запуском

## :fontawesome-solid-play: Установка

### Вариант 1: Одна команда (проще всего)

```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash
```

### Вариант 2: Клонировать и запустить (больше контроля)

```bash
git clone https://github.com/AlexanderNarbaev/opencode_initializer.git ~/opencode_initializer
cd ~/opencode_initializer
bash setup.sh
```

### Вариант 3: Определённый режим

```bash
# Диагностика (без изменений)
bash setup.sh --health

# Интерактивный режим — выбрать что устанавливать
bash setup.sh --interactive

# Только новый проект (пропустить системные инструменты)
bash setup.sh --new ~/my-project

# Предпросмотр (dry-run)
bash setup.sh --dry-run

# Обновить инструменты, сохранить данные
bash setup.sh --reinit

# CI/CD headless режим (без GUI, Docker, ZSH)
bash setup.sh --ci
```

## :fontawesome-solid-key: API-ключи

Укажите API-ключи для включения полной AI-функциональности. Все ключи опциональны — скрипт работает без них, но MCP-серверы и провайдеры, требующие ключей, будут отключены.

### Быстрый старт с ключами

```bash
bash setup.sh --full \
  --deepseek-key "sk-..." \
  --github-token "ghp_..." \
  --gitlab-token "glpat-..." \
  --google-maps-key "..."
```

### Все доступные опции ключей

| Флаг | Сервис | Для чего | Бесплатный тариф |
|------|--------|---------|------------------|
| `-k, --api-key` | OpenCode Go | OpenCode провайдер | — |
| `--deepseek-key` | DeepSeek | DeepSeek провайдер | :white_check_mark: [platform.deepseek.com](https://platform.deepseek.com) |
| `--xai-key` | xAI Grok | xAI/Grok провайдер | — |
| `--mimo-key` | Xiaomi MiMo | MiMo провайдер | — |
| `--moonshot-key` | Moonshot Kimi | Moonshot провайдер | — |
| `--minimax-key` | MiniMax M3 | MiniMax провайдер | — |
| `--github-token` | GitHub (classic token) | GitHub MCP, `gh` CLI | :white_check_mark: Бесплатно, без scopes |
| `--gitlab-token` | GitLab | GitLab MCP | :white_check_mark: `read_api` scope |
| `--google-maps-key` | Google Maps | Google Maps MCP | :white_check_mark: Есть бесплатный тариф |

### Дополнительные переменные окружения

Для провайдеров без CLI-флагов задайте переменные перед запуском:

```bash
export OPENAI_API_KEY="sk-..."        # OpenAI
export ANTHROPIC_API_KEY="sk-..."     # Anthropic Claude
export GOOGLE_API_KEY="..."           # Google Gemini
export GROQ_API_KEY="gsk_..."         # Groq
export TOGETHER_API_KEY="..."         # Together AI
export FIREWORKS_API_KEY="..."        # Fireworks
export MISTRAL_API_KEY="..."          # Mistral
export COHERE_API_KEY="..."           # Cohere
export PERPLEXITY_API_KEY="..."       # Perplexity
export REPLICATE_API_KEY="..."        # Replicate

bash setup.sh --full
```

Все ключи хранятся в `~/.config/opencode/secrets.env` с `chmod 600` (только владелец).

## :fontawesome-brands-windows: Настройка WSL2

Пользователи Windows на WSL2 получают автоматические оптимизации:

### Что настраивает скрипт

| Настройка | Значение | Зачем |
|-----------|----------|-------|
| DNS-серверы | `8.8.8.8`, `1.1.1.1` | Исправляет проблемы с DNS в WSL2 |
| Лимит памяти | 50% RAM хоста | Предотвращает захват всей памяти WSL2 |
| Режим сети | Mirrored (Windows 11) | Лучшая совместимость сети |
| Chrome | `--no-sandbox` | Необходим для Chrome в WSL2 |
| `.wslconfig` | Генерируется в `%USERPROFILE%` | Постоянные настройки WSL2 |

### Ручная подготовка WSL2

Перед запуском setup.sh на WSL2:

```powershell
# В PowerShell (администратор) — убедиться, что WSL2 по умолчанию
wsl --set-default-version 2

# Опционально: настроить ресурсы WSL2
# Редактировать %USERPROFILE%\.wslconfig:
[wsl2]
memory=8GB
processors=4
localhostForwarding=true
networkingMode=mirrored
```

### Chrome в WSL2

Chrome установлен с совместимостью WSL2. Используйте обёртку `chrome-open`:

```bash
chrome-open                     # Запустить Chrome
chrome-open https://github.com  # Открыть конкретный URL
```

### Производительность WSL2

- :fontawesome-solid-check: Работайте в `~/projects/` (файловая система Linux) — не в `/mnt/c/`
- :fontawesome-solid-xmark: Избегайте межфайловых операций (медленнее в 10-100 раз)
- Установщик задаёт `~/projects` как папку проектов по умолчанию

## :fontawesome-solid-eye: Что происходит при установке

Скрипт проходит следующие этапы:

| # | Этап | Что делает | ~Время |
|---|------|-----------|--------|
| 1 | **Проверка системы** | Определяет ОС, пакетный менеджер, архитектуру | 1с |
| 2 | **Системные пакеты** | Устанавливает build tools, curl, git | 3м |
| 3 | **Docker** | Установка Docker Engine | 2м |
| 4 | **Chrome** | Google Chrome + ChromeDriver | 1м |
| 5 | **ZSH** | Zsh + Oh My Zsh + P10k + плагины | 2м |
| 6 | **Языки** | Java, Node, Python, Go, Rust, .NET, Zig | 10м |
| 7 | **OpenCode CLI** | OpenCode + Bun | 1м |
| 8 | **MCP + LSP** | 21 MCP-серверов + 13 LSP-серверов | 5м |
| 9 | **ChromaDB** | Векторная БД + Muninn | 1м |
| 10 | **LLM** | Ollama, vLLM, SGLang, Open WebUI | 5м |
| 11 | **Проект** | AGENTS.md, структура проекта | 1с |
| 12 | **Финализация** | PATH, git config, верификация | 1м |

## :fontawesome-solid-check: Проверка после установки

### Проверить всё

```bash
# Полная диагностика (65+ проверок в 7 разделах)
dev health

# Сравнить версии с последними релизами
dev version-check

# Список установленного
dev list
```

### Что проверяет health check

| Раздел | Проверки | Примеры |
|--------|----------|---------|
| Система | ОС, пакеты, DNS, зеркала, диск | apt/dnf/pacman работает |
| Языки | Java, Node, Python, Go, Rust, .NET, Zig | Версия >= минимум |
| Инструменты | Docker, Chrome, Bun, OpenCode CLI | Бинарник в PATH |
| Оболочка | ZSH, Oh My Zsh, плагины, .zshrc | Оболочка функционирует |
| MCP | Бинарники серверов, пути bun, конфиг | Холодный старт проверен |
| LLM | Ollama, vLLM, Open WebUI | GPU определён, сервис работает |
| Безопасность | Права секретов, API-ключи | `chmod 600`, токены на месте |

### Первые шаги после установки

1. **Перезапустите оболочку** или `source ~/.zshrc`
2. **Настройте Git**:
   ```bash
   git config --global user.name "Ваше Имя"
   git config --global user.email "you@example.com"
   ```
3. **Проверьте AI-генерацию кода**:
   ```bash
   opencode "Создай простой веб-сервер на Go с эндпоинтами /health и /users"
   ```
4. **Изучите MCP-серверы** — они уже настроены в `opencode.json`:
   ```bash
   cat ~/opencode_initializer/opencode.json | python3 -m json.tool | head -80
   ```
5. **Запустите GPU-сервисы** (если есть GPU):
   ```bash
   systemctl --user start ollama
   ollama pull llama3.2    # Загрузить модель 2GB
   ollama run llama3.2 "Привет, что ты умеешь?"
   ```
6. **Откройте Web UI**:
   ```bash
   systemctl --user start open-webui
   # Откройте http://localhost:3000
   ```

### CLI `dev`

```bash
dev health          # Полная диагностика (65+ проверок)
dev version-check   # Сравнить версии с последними
dev update          # Обновить инструменты
dev list            # Список установленного
dev install docker  # Установить компонент
dev remove java     # Удалить компонент
dev config          # Редактировать конфиг
dev autoupdate      # Полное обновление системы
dev self-update     # Обновить сам setup.sh
```

## :fontawesome-solid-play: Типовые сценарии

### Сценарий 1: Свежая Ubuntu/WSL2 — всё сразу

```bash
curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash
# Подождать 15-20 минут
# Перезапустить терминал или source ~/.zshrc
dev health
opencode "Чем ты можешь помочь?"
```

### Сценарий 2: Добавление OpenCode на существующую машину

```bash
git clone https://github.com/AlexanderNarbaev/opencode_initializer.git ~/opencode_initializer
cd ~/opencode_initializer
bash setup.sh --interactive
# Выбрать: OpenCode CLI, MCP + LSP, ZSH
# Снять: языки, которые уже есть
```

### Сценарий 3: CI/CD пайплайн

```bash
# В GitHub Actions workflow:
- name: Setup OpenCode CI
  run: |
    curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh | bash -s -- --ci
```

CI-режим устанавливает только: OpenCode CLI + Bun + основные MCP (filesystem, context7). Без Docker, ZSH, GUI.

### Сценарий 4: Онбординг члена команды

```bash
# Отправьте эту команду новым членам команды:
bash setup.sh --full \
  --deepseek-key "sk-team-key" \
  --github-token "ghp_team-github-token" \
  --gitlab-token "glpat-team-gitlab-token"
```

См. [Руководство по командной установке](../guides/team-setup/).

### Сценарий 5: ML/AI разработчик с GPU

```bash
bash setup.sh --full
# GPU автоопределён: NVIDIA → Ollama с CUDA
# Проверить GPU:
nvidia-smi
ollama run llama3.2 "Какой GPU ты используешь?"
```

## :fontawesome-solid-triangle-exclamation: Частые проблемы

### "Permission denied" при curl|bash

Не запускайте от root. Скрипт использует `sudo` где нужно.

### WSL2: DNS не работает

Скрипт добавляет Google DNS автоматически. Если не помогло:

```bash
sudo sh -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
```

Если проблема сохраняется после перезапуска:

```powershell
# В PowerShell (администратор):
wsl --shutdown
```

### "Package not found" на не-Ubuntu системах

Скрипт автоопределяет пакетный менеджер. При ошибке установите эквивалентные пакеты вручную и перезапустите.

### Chrome не запускается в WSL2

Chrome настроен с `--no-sandbox`. Используйте:

```bash
chrome-open
```

### MCP-серверы не запускаются

MCP-серверы используют абсолютные пути к `~/.bun/bin/`. При ошибке "command not found":

```bash
# Переустановить Bun и MCP
curl -fsSL https://bun.sh/install | bash
bash setup.sh --reinit
```

### Мало места на диске

Пропустите тяжёлые компоненты:

```bash
bash setup.sh --interactive
# Снять: Docker, Chrome, vLLM, RAG, Open WebUI, Ollama
```

## :fontawesome-solid-arrow-right: Далее

- [Руководство](../user-guide/) — повседневное использование
- [Продвинутое](../advanced/) — кастомизация и WSL2
- [Архитектура](../architecture/) — как это работает
- [Справочник](../reference/) — CLI и конфигурация
- [FAQ](../faq/) — частые вопросы
- [Сравнение](../comparison/) — сравнение с альтернативами
