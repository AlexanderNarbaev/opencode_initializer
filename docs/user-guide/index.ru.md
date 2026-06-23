# Руководство пользователя

Повседневное использование вашего окружения на базе OpenCode Initializer.

## Ежедневный рабочий процесс

```mermaid
flowchart LR
    A[Открыть терминал] --> B[Проверить здоровье]
    B --> C[Писать код]
    C --> D[AI-ассистент]
    D --> E[Тестировать и деплоить]
    E --> F[Еженедельное обновление]
```

## CLI `dev`

Главный инструмент управления после установки. Доступен как `~/opencode_initializer/dev.sh`.

### Проверка здоровья

Запускайте первым делом для проверки окружения:

```bash
dev health
```

Вывод охватывает 5 разделов:
1. **Система** — ОС, ядро, пакетный менеджер, место на диске
2. **Оболочка** — ZSH, плагины, версия Oh My Zsh
3. **Языки** — Java, Node, Python, Go, Rust, .NET, Zig
4. **Инструменты** — Docker, Chrome, OpenCode, Bun
5. **AI/LLM** — MCP-серверы, Ollama, ChromaDB

### Проверка версий

```bash
dev version-check
```

Сравнивает установленные версии с последними из:
- GitHub Releases (Go, Zig, Bun)
- API (Node, Python)
- Реестров пакетов (Rust, .NET)

### Обновление

```bash
# Только инструменты разработки
dev update

# Полное обновление системы (все пакеты)
dev autoupdate
```

## Работа с AI

### Базовая кодогенерация

```bash
opencode "Создай Python Flask API с эндпоинтами /health и /users"
```

### Код-ревью

```bash
opencode "Проверь файл src/main.go на проблемы безопасности"
```

### Понимание проекта

OpenCode читает `AGENTS.md` и `opencode.json` для контекста:

```bash
opencode "Объясни архитектуру этого проекта"
```

## Управление проектами

### Создать новый проект

```bash
bash setup.sh --new ~/my-new-project
```

Создаётся:
```
~/my-new-project/
├── AGENTS.md         # Инструкции для AI
├── opencode.json     # AI конфигурация
├── docker-compose.yml
├── .gitignore
└── agents/           # Пользовательские AI субагенты
```

### Интеграция с существующим проектом

Просто добавьте `AGENTS.md` в любую папку проекта. OpenCode подхватит автоматически.

## MCP-серверы

### Список активных MCP

```bash
cat ~/opencode_initializer/opencode.json | grep -A 3 '"mcpServers"'
```

### Добавить свой MCP-сервер

Отредактируйте `opencode.json` и добавьте:

```json
{
  "mcpServers": {
    "my-server": {
      "type": "local",
      "command": ["node", "/path/to/server.js"]
    }
  }
}
```

### Диагностика MCP

```bash
# Проверить Bun
which bun

# Проверить кэш MCP
ls ~/.cache/opencode-setup/mcp-cache/

# Переустановить MCP
bash setup.sh --reinit
```

## Docker

```bash
# Запустить Docker
sudo systemctl start docker

# Тестовый контейнер
docker run hello-world

# Проверить в health
dev health
```

## Chrome (WSL2)

```bash
# Запустить Chrome
chrome-open

# С конкретным URL
chrome-open https://github.com
```

## LLM / GPU

### Проверить GPU

```bash
nvidia-smi
```

### Управление Ollama

```bash
# Запустить
systemctl --user start ollama

# Список моделей
ollama list

# Загрузить модель
ollama pull llama3.2

# Тест
ollama run llama3.2 "Привет!"
```

### Open WebUI

Доступен на `http://localhost:3000` после запуска:

```bash
systemctl --user start open-webui
```

## Логи

Весь вывод установки логируется:

```bash
ls -lt ~/.cache/opencode-setup/setup-*.log | head -1
```

Просмотр последнего лога:

```bash
tail -100 ~/.cache/opencode-setup/setup-*.log
```

## Советы

### Алиасы

Установщик добавляет полезные алиасы в `.zshrc`:

```bash
alias dev='~/opencode_initializer/dev.sh'
alias chrome-open='google-chrome-stable --no-sandbox'
```

### Горячие клавиши (ZSH с плагинами)

| Клавиши | Действие |
|---------|----------|
| `Ctrl+T` | Нечёткий поиск файлов (fzf) |
| `Ctrl+R` | Нечёткий поиск истории |
| `Alt+C` | Нечёткий переход по папкам |
| `Tab` | Умный автокомплит (zsh-autosuggestions) |

### Производительность

1. **Закрывайте неиспользуемые контейнеры**: `docker system prune`
2. **Ограничьте модели Ollama**: загружайте только нужные
3. **Чистите кэш npm**: `npm cache clean --force`
4. **Проверяйте диск**: `dev health` включает использование диска

### Бэкап конфигурации

```bash
tar -czf opencode-backup-$(date +%Y%m%d).tar.gz \
  ~/.config/opencode-setup/ \
  ~/.config/opencode/ \
  ~/opencode_initializer/opencode.json
```
