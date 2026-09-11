# TOML конфигурация

`setup.sh` поддерживает декларативную конфигурацию через TOML-файлы. Это заменяет
(или дополняет) флаги командной строки и переменные окружения одним файлом
конфигурации с контролем версий.

## Быстрый старт

```bash
# Скопировать шаблон
cp src/data/setup.toml.template setup.toml

# Отредактировать под ваше окружение
$EDITOR setup.toml

# Предпросмотр что будет установлено (dry-run)
bash setup.sh --config setup.toml --dry-run

# Установить с TOML конфигом
bash setup.sh --config setup.toml
```

## Приоритет

Значения конфигурации разрешаются в следующем порядке (высший приоритет первым):

1. **Флаги CLI** (`--deepseek-key`, `--project-dir` и т.д.)
2. **Переменные окружения** (`DEEPSEEK_API_KEY`, `PROJECT_DIR` и т.д.)
3. **TOML файл** (`setup.toml`)
4. **Значения по умолчанию** (захардкожены в setup.sh)

Это означает что вы можете задать значения по умолчанию в TOML и переопределить
конкретные значения через CLI или env vars без изменения файла.

## Схема

```toml
[meta]
version = "1.0"           # Версия схемы
profile = "personal"      # Профиль установки

[user]
git_name = "Your Name"    # Git идентификация
git_email = "you@example.com"
shell = "zsh"             # Shell по умолчанию
project_dir = "~/projects" # Директория проектов

[features]
docker = true             # Основные фичи
gui = true
nodejs = true             # Языковые тулчейны
python = true
go = true
rust = false

[features.skip]
devbox = false            # Пропустить конкретные компоненты

[services]
postgres = true           # Инфраструктурные сервисы
redis = true
qdrant = true
prometheus = true
grafana = true

[ports]
postgres = 5432           # Переопределения портов
redis = 6379

[providers]
deepseek_key = "..."      # API ключи (предпочтительно env vars)

[tools]
node_ver = "24"           # Переопределения версий
python_ver = "3.14"
```

## Маппинг переменных окружения

TOML значения экспортируются как `UPPER_CASE` переменные окружения:

| TOML путь | Переменная окружения |
|-----------|---------------------|
| `[meta] version` | `META_VERSION` |
| `[user] git_name` | `USER_GIT_NAME` |
| `[features] docker` | `FEATURES_DOCKER` |
| `[services] postgres` | `SERVICES_POSTGRES` |
| `[ports] postgres` | `PORTS_POSTGRES` |
| `[providers] deepseek_key` | `PROVIDERS_DEEPSEEK_KEY` |

## Валидация

```bash
# Показать разрешенную конфигурацию (TOML + env + defaults)
bash setup.sh --config setup.toml --print-config
```

## Безопасность

- API ключи в TOML хранятся в **открытом виде**
- Предпочтительно использовать переменные окружения для чувствительных значений
- Используйте `--print-config` чтобы убедиться что секреты не раскрыты
- `.gitignore` исключает `setup.toml` по умолчанию

## Смотрите также

- `src/data/setup.toml.template` — полный аннотированный шаблон
- `docs/guides/provider-setup.ru.md` — конфигурация провайдеров
- `docs/guides/state-detection.ru.md` — обнаружение дрейфа
