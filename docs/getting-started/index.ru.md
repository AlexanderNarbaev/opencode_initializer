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
```

!!! warning "Пользователи Windows (WSL2)"
    Перед запуском убедитесь, что WSL2 правильно настроен. Скрипт настроит:
    - DNS fix (8.8.8.8, 1.1.1.1)
    - Лимиты памяти в `.wslconfig`
    - Mirrored networking mode
    - Chrome с `--no-sandbox` для WSL2

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

## :fontawesome-solid-check: После установки

### Проверка

```bash
# Запустить диагностику
bash ~/opencode_initializer/setup.sh --health

# Или через dev CLI
dev health

# Проверить версии инструментов
dev version-check
```

### Первые шаги

1. **Перезапустите оболочку** или `source ~/.zshrc`
2. **Настройте git**:
   ```bash
   git config --global user.name "Ваше Имя"
   git config --global user.email "you@example.com"
   ```
3. **Начните использовать AI**:
   ```bash
   opencode "Создай простой веб-сервер на Go"
   ```

### CLI `dev`

```bash
dev health          # Полная диагностика (60+ проверок)
dev version-check   # Сравнить версии с последними
dev update          # Обновить инструменты
dev list            # Список установленного
dev install docker  # Установить компонент
dev remove java     # Удалить компонент
dev config          # Редактировать конфиг
dev autoupdate      # Полное обновление системы
dev self-update     # Обновить сам setup.sh
```

## :fontawesome-solid-triangle-exclamation: Частые проблемы

### "Permission denied" при curl|bash

Не запускайте от root. Скрипт использует `sudo` где нужно.

### WSL2: DNS не работает

Скрипт добавляет Google DNS автоматически. Если не помогло:
```bash
sudo sh -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
```

### "Package not found" на не-Ubuntu системах

Скрипт автоопределяет пакетный менеджер. При ошибке установите эквивалентные пакеты вручную и перезапустите.

### Chrome не запускается в WSL2

Chrome настроен с `--no-sandbox`. Используйте:
```bash
chrome-open
```

## :fontawesome-solid-arrow-right: Далее

- [Руководство](../user-guide/) — повседневное использование
- [Продвинутое](../advanced/) — кастомизация и WSL2
- [Архитектура](../architecture/) — как это работает
- [Справочник](../reference/) — CLI и конфигурация
- [FAQ](../faq/) — частые вопросы
