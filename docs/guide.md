[← На главную](index.md) · [База знаний](KNOWLEDGE.md) · [Промпты](prompts/system-prompts.md)

# Полное руководство по использованию

## Установка

### Полная установка (рекомендуется)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AlexanderNarbaev/opencode_initializer/main/setup.sh) --full
```

### С API-ключами
```bash
bash setup.sh --full \
  --deepseek-key "sk-..." \
  -k "opencode-api-key" \
  --xai-key "xai-..." \
  --mimo-key "mimo-..." \
  --moonshot-key "ms-..." \
  --minimax-key "mm-..." \
  -n "Your Name" \
  -e "email@example.com"
```

### Интерактивный режим (выбрать компоненты)
```bash
bash setup.sh --interactive
```

### Dry-run (посмотреть без изменений)
```bash
bash setup.sh --dry-run --full
```

## После установки

### Проверка системы
```bash
dev health
```

### Первый запуск OpenCode
```bash
opencode
```

### Модели и провайдеры

Конфигурация в `~/.config/opencode/opencode.json`:
- **Основная**: `deepseek/deepseek-v4-pro` (reasoning, 64K output)
- **Быстрая**: `deepseek/deepseek-v4-flash` ($0.14/1M input)
- **Small model**: `deepseek/deepseek-v4-flash` (фоновые задачи)

Переключение модели:
- `/model deepseek/deepseek-v4-pro`
- `/model opencode-go/glm-5.1`
- `/model xai/grok-3-beta`
- `/model minimax/minimax-m2.7`

### API-ключи

Хранятся в `~/.config/opencode/secrets.env` (chmod 600):
```bash
export DEEPSEEK_API_KEY="sk-..."
export OPENCODE_API_KEY="..."
export XAI_API_KEY="..."
export MIMO_API_KEY="..."
export MOONSHOT_API_KEY="..."
export MINIMAX_API_KEY="..."
```

Или через `/connect` в TUI OpenCode.

## MCP-серверы

### Активные по умолчанию
- **context7** — живая документация библиотек
- **filesystem** — работа с файлами проекта
- **agentic-tools** — иерархическая память задач
- **codegraph** — граф вызовов, навигация по коду
- **playwright** — UI-тестирование браузера
- **agent-browser** — автоматизация браузера
- **loopsense** — анализ циклов разработки
- **sequential-thinking** — пошаговое рассуждение
- **memorylayer** — 38 инструментов памяти

### Отключённые (включить вручную)
- **github** — взаимодействие с GitHub API
- **postgres** — работа с PostgreSQL
- **sentry** — мониторинг ошибок (remote)
- **grep** — поиск по коду (remote)

### Включение/отключение
В `~/.config/opencode/opencode.json` изменить `"enabled": true/false`.

## Плагины

### opencode-codegraph
Автоматически обогащает диалог графом вызовов проекта.

### opencode-dcp (Dynamic Context Pruning)
Автоматическая компрессия и прунинг контекста:
- Минимальный лимит: 20K токенов
- Максимальный: 48K токенов
- Авто-компакция при переполнении

### opencode-stranger-danger
Фильтрация PII и секретов из диалогов:
- Блокировка ключей, токенов, паролей
- Предотвращение prompt-инъекций

### opencode-damage-control
144 защищённых паттерна:
- Блокировка опасных команд (`rm -rf /`, `DROP TABLE`, `terraform destroy`)
- Блокировка чувствительных путей (`~/.ssh`, `~/.aws`, `.env`)
- Защищённый аудит-лог (365 дней)

### opencode-auto-fallback
Автоматическое переключение моделей при ошибках провайдера.

### opencode-lazy-loader
Отложенная загрузка плагинов для ускорения старта.

### open-orchestra
Оркестрация multi-agent сценариев.

## Агенты

10 предустановленных ролей в `PROJECT_DIR/.opencode/agents/`:

| Агент | Модель | Разрешено |
|-------|--------|-----------|
| pm | opencode-go/glm-5.1 | read-only |
| analyst | opencode-go/glm-5.1 | read-only |
| architect | opencode-go/glm-5.1 | read-only |
| developer | deepseek/deepseek-v4-pro | all |
| qa | opencode-go/minimax-m2.7 | all |
| security | opencode-go/glm-5 | read-only |
| devops | deepseek/deepseek-v4-pro | all |
| reviewer | opencode-go/qwen3.6-plus | read-only |
| researcher | deepseek/deepseek-v4-pro | read-only |
| designer | opencode-go/minimax-m2.7 | read-only |

Вызов: `@developer напиши тесты`

## Память и контекст

### ChromaDB
Векторная база данных для семантической памяти Muninn.
- Запускается как systemd-сервис при логине
- Порт: 8000 (только localhost)
- Данные: `~/.local/share/chroma/`

### Muninn
Семантическая память для OpenCode. Сохраняет контекст между сессиями.

### Agentic Tools MCP
Иерархическая память задач. Сохраняет решения, прогресс, контекст.

### WAL (Write-Ahead Log)
Файлы в `PROJECT_DIR/wal/`:
- `GLOBAL_WAL.md` — состояние всех модулей
- `SESSION_WAL.md` — контекст текущей сессии

## Инструменты разработчика

### clawrouter
Умный роутинг запросов к 55+ моделям.
```bash
clawrouter --help
```

### agents-md-sync
Синхронизация AGENTS.md между проектами.
```bash
agents-md-sync --help
```

### Caveman
Сокращает выходные токены до 75% для рутинных ответов.

## GPU / Локальные LLM

### Установка
```bash
dev install llm
# или при интерактивной установке выбрать "y" на "Local LLM runtimes?"
```

### Использование
```bash
# Ollama
ollama run qwen3:14b
ollama pull deepseek-r1:8b

# Open WebUI (чат-интерфейс)
open http://localhost:3300

# vLLM (GPU-инференс)
vllm serve Qwen/Qwen3-14B

# SGLang
python -m sglang.launch_server --model Qwen/Qwen3-14B
```

## Восстановление после сбоя

```bash
# Скрипт упал — просто перезапустить
bash setup.sh --full

# Проверить что сломалось
bash setup.sh --health

# Починить конфиг
bash setup.sh --fix-config

# Починить .zshrc
bash setup.sh --fix-zshrc

# Переустановить всё
bash setup.sh --reinit
```

## Структура проекта после установки

```
~/projects/
├── AGENTS.md              # Системный промпт для AI
├── docs/
│   └── INDEX.md           # Карта знаний
├── wal/
│   ├── GLOBAL_WAL.md      # Состояние модулей
│   └── SESSION_WAL.md     # Контекст сессии
├── .opencode/
│   ├── agents/            # 10 AI-агентов
│   ├── skills/            # Caveman skill
│   ├── commands/          # Пользовательские команды
│   └── context/           # Контекст проекта
├── infra/
│   ├── docker-compose.yml # Kafka, PG, Mongo, Redis, MinIO
│   └── wiremock/          # Моки API
├── .lock/                 # Файлы блокировок WAL
├── icon/                  # Иконки
├── templates/             # Шаблоны
└── output/                # Результаты сборки
```

## Обновление

```bash
# Обновить инструменты + миграции
dev update

# Обновить setup.sh из git
dev self-update

# Полное обновление системы
bash setup.sh --upgrade
```

## Безопасность

- Все API-ключи в `~/.config/opencode/secrets.env` (chmod 600)
- Никаких секретов в коде скрипта
- damage-control блокирует опасные операции
- stranger-danger фильтрует PII
- Trivy + Qodana для сканирования уязвимостей

## Решение проблем

### OpenCode не стартует
```bash
# Проверить конфиг
cat ~/.config/opencode/opencode.json | python3 -m json.tool

# Перегенерировать
bash setup.sh --fix-config

# Запустить с игнорированием проекта
OPENCODE_DISABLE_PROJECT_CONFIG=1 opencode
```

### MCP-сервер не запускается
```bash
# Проверить установку
npm list -g | grep mcp

# Переустановить все MCP
bash setup.sh --reinit
```

### Проблемы с DNS (РФ/СНГ)
Скрипт автоматически добавляет Yandex DNS (77.88.8.8) и Cloudflare (1.1.1.1).

### WSL2: сеть не работает
Скрипт автоматически чинит WSL2 DNS и прокси.

### Прогресс не сохраняется
Файл `~/.cache/opencode-setup/progress` отслеживает выполненные шаги. При повторном запуске `--full` скрипт продолжит с места сбоя.
