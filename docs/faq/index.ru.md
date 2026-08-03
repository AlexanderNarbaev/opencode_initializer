# FAQ и решение проблем

## Установка

### В: Скрипт падает с "Permission denied"
**О:** Убедитесь, что есть sudo доступ. Скрипт запускается от пользователя и использует `sudo` для системных операций. НЕ запускайте весь скрипт от root.

### В: Можно запускать скрипт несколько раз?
**О:** Да. Скрипт идемпотентен — отслеживает выполненные шаги в `~/.cache/opencode-setup/progress` и пропускает уже установленное.

### В: Сколько длится полная установка?
**О:** 15-30 минут, зависит от интернета и скорости машины. Самые тяжёлые части — LLM инструменты (модели Ollama) и компиляторы (Rust, .NET).

### В: Можно пропустить отдельные компоненты?
**О:** Используйте интерактивный режим: `bash setup.sh --interactive`. Или `dev remove <компонент>` после установки.

### В: Нужны ли все API токены?
**О:** Нет. Предоставляйте только те токены, которые хотите использовать. Скрипт работает без токенов — MCP-серверы, требующие токены, будут отключены.

## Языки и инструменты

### В: Почему Java 25, а не LTS?
**О:** Java 25 — последний стабильный релиз. Проект ориентируется на последние версии всех языков. Можно установить другую версию вручную.

### В: Можно ли сменить версию языка после установки?
**О:** Да. Каждый менеджер версий (nvm, sdkman, rustup и др.) позволяет переключаться:
- Node: `nvm install 22`, `nvm use 22`
- Java: `sdk use java 21.0.2-tem`
- Go: `go install golang.org/dl/go1.25@latest && go1.25 download`
- Python: `uv python install 3.13`

### В: Почему npm prefix установлен в `~/.local`?
**О:** Чтобы избежать проблем с правами на глобальные npm пакеты. Это XDG-совместимое расположение.

## WSL2

### В: Chrome не запускается / падает
**О:** Используйте `chrome-open` — обёртка с `--no-sandbox` для совместимости с WSL2.

### В: DNS не работает
**О:** Скрипт добавляет Google DNS автоматически. Если не помогло:
```bash
sudo sh -c 'printf "nameserver 8.8.8.8\nnameserver 1.1.1.1\n" > /etc/resolv.conf'
```

### В: Docker не запускается
**О:** Убедитесь, что интеграция WSL2 включена в Docker Desktop. Или используйте установку Docker Engine из скрипта.

### В: Проблемы с памятью/CPU
**О:** Скрипт настраивает `.wslconfig` с лимитами. Настройте:
```ini
[wsl2]
memory=8GB
processors=4
```

## MCP и LSP

### В: MCP-серверы не запускаются / "command not found"
**О:** MCP-серверы используют абсолютные пути к `~/.bun/bin/`. Убедитесь, что Bun установлен:
```bash
curl -fsSL https://bun.sh/install | bash
```

### В: Можно добавить свои MCP-серверы?
**О:** Да. Отредактируйте `opencode.json` напрямую или через `dev config`.

### В: LSP-сервер не работает в редакторе
**О:** LSP-серверы настроены прежде всего для OpenCode. Для VS Code/Vim/Emacs может понадобиться дополнительная настройка.

## AI / LLM

### В: Модели Ollama скачиваются вечно
**О:** Модели большие (4-27 GB). Скачивайте только нужное:
```bash
ollama pull llama3.2    # 2 GB
ollama pull codellama   # 3.8 GB
ollama pull deepseek-r1 # 4.7 GB
```

### В: GPU не определяется для Ollama
**О:** Убедитесь, что драйверы NVIDIA + CUDA toolkit установлены:
```bash
nvidia-smi  # Должен показать информацию о GPU
```

### В: Open WebUI не запускается
**О:** Сначала должен работать Ollama:
```bash
systemctl --user start ollama
# или
ollama serve
```

## Обновления

### В: Как обновить все инструменты?
**О:**
```bash
dev update       # Обновить инструменты разработки
dev autoupdate   # Полное обновление системы через topgrade
```

### В: Автообновление включено — как проверить?
**О:**
```bash
systemctl --user status opencode-topgrade.timer
systemctl --user list-timers
```

### В: Как полностью удалить?
**О:** Автоматического удаления нет. Инструменты установлены в стандартные расположения. Удалите вручную:
```bash
rm -rf ~/opencode_initializer
rm -rf ~/.cache/opencode-setup
rm -rf ~/.config/opencode-setup
rm -rf ~/.config/opencode
# Инструменты остаются в своих стандартных путях
```

## Конфигурация

### В: Где файл конфигурации?
**О:** `~/.config/opencode-setup/setup.conf`

### В: Как пересоздать opencode.json?
**О:**
```bash
bash setup.sh --fix-config
```

### В: Как исправить .zshrc?
**О:**
```bash
bash setup.sh --fix-zshrc
```

## Помощь

- :fontawesome-brands-github: [GitHub Issues](https://github.com/AlexanderNarbaev/opencode_initializer/issues)
- :fontawesome-solid-book: [Полная документация](https://alexandernarbaev.github.io/opencode_initializer/)
- :fontawesome-solid-code: [Исходный код](https://github.com/AlexanderNarbaev/opencode_initializer)

---

**См. также:**
- [Начало работы](../getting-started/) — руководство по установке
- [Руководство](../user-guide/) — повседневное использование
- [Продвинутое](../advanced/) — WSL2, GPU, кастомизация
- [Справочник](../reference/) — CLI и схема конфигурации
