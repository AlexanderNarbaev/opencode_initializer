# Окружения Daytona

Управление эфемерными одноразовыми песочницами разработки через [Daytona](https://www.daytona.io/) — платформу облачных dev-окружений. Проект поставляет модуль `61-daytona.sh`, который устанавливает актуальный CLI Daytona, записывает декларативный реестр окружений и ставит обёртку `daytona-env`, связывающую команды и конфиг.

> **Состояние на 2026 год**: Daytona — платформенный продукт (управляемые песочницы). Старый OSS-проект `daytonaio/workspace-manager` **архивирован в июне 2026 года** — не используйте устаревший установщик `get.daytona.io`. Модуль ставит из актуальных релизов `github.com/daytonaio/daytona`.

## Установка

Модуль выполняется как шаг 61 настройки (`step_daytona`). Отключить: `SKIP_DAYTONA=true`.

```bash
# Homebrew (macOS)
brew install daytonaio/cli/daytona

# Прямой бинарник (Linux/macOS) — ставится автоматически модулем 61
# https://github.com/daytonaio/daytona/releases/latest/download/daytona-<os>-<arch>
```

Авторизация — только через переменную окружения `DAYTONA_API_KEY`. Никогда не коммитьте её:

```bash
export DAYTONA_API_KEY="dtn_..."
# либо через git-игнорируемый .env-файл
```

## Два стиля настройки

Обёртка поддерживает **оба** потока — императивный CLI и декларативный конфиг. Выбирайте любой или комбинируйте.

### (a) Императивный CLI

```bash
daytona login                       # авторизация (DAYTONA_API_KEY)
daytona-env list                    # показать записи реестра
daytona-env create dev-minimal      # собрать и выполнить daytona create
daytona-env status                  # daytona list
daytona-env delete <id|name>        # удалить песочницу
daytona-env prune                   # удалить ВСЕ песочницы (с подтверждением)
```

Флаги `daytona create`, доступные напрямую:

| Флаг | Смысл | Пример |
|------|-------|--------|
| `--cpu` | vCPU | `--cpu 2` |
| `--memory` | RAM (ГБ) | `--memory 4` |
| `--disk` | Диск (ГБ) | `--disk 10` |
| `--auto-stop` | Минуты простоя до авто-остановки | `--auto-stop 15` |
| `--env K=V` | Переменная окружения (повторяемый) | `--env NODE_ENV=development` |
| `--label L` | Метка (повторяемый) | `--label dev` |
| `--snapshot S` | Сборка из снапшота | `--snapshot debian-slim` |
| `--dockerfile/-f D` | Сборка из Dockerfile | `--dockerfile ./Dockerfile` |
| `--target T` | Целевой регион/провайдер | `--target us` |

Создавайте снапшот из того же Dockerfile, что использует ваша сборка `docker-compose`, чтобы песочницы повторяли production-образы.

### (b) Декларативный конфиг

`~/.config/opencode/daytona/environments.json` (генерируется модулем 61):

```json
{
  "version": 1,
  "managed_by": "opencode_initializer@61-daytona",
  "note": "Auth via DAYTONA_API_KEY env var only — never store secrets here.",
  "defaults": { "cpu": 2, "memory_gb": 4, "disk_gb": 10, "auto_stop_minutes": 15, "target": "us" },
  "environments": [
    { "name": "dev-minimal", "image": { "snapshot": "debian-slim" }, "labels": ["dev"] },
    { "name": "dev-node", "image": { "dockerfile": "./Dockerfile" }, "env": { "NODE_ENV": "development" }, "auto_stop_minutes": 30 }
  ]
}
```

| Поле | Тип | Описание |
|------|-----|----------|
| `version` | int | Версия схемы реестра |
| `managed_by` | string | Маркер происхождения |
| `defaults` | object | Значения по умолчанию: cpu/memory_gb/disk_gb/auto_stop_minutes/target |
| `environments[]` | array | По одной записи на окружение |
| `.name` | string | Имя окружения (совпадает с `daytona-env create <name>`) |
| `.image.snapshot` | string | Сборка из снапшота (взаимоисключающе с dockerfile) |
| `.image.dockerfile` | string | Сборка из пути к Dockerfile |
| `.env` | object | Пары ключ/значение → повторяемые `--env` |
| `.labels` | array | Строки → повторяемые `--label` |

Переопределение реестра под проект:

```bash
DAYTONA_ENVIRONMENTS=./.daytona/environments.json daytona-env list
```

## Интеграция с OpenCode

Плагин `opencode-daytona` (ставится отдельно) позволяет агенту поднимать песочницы. **Оговорка git-sync**: ветки агента внутри песочницы одноразовые — коммитьте работу обратно в основной репозиторий до очистки песочницы, иначе изменения пропадут вместе с ней.

## Практики «эфемерность по умолчанию»

- **Авто-остановка / авто-удаление** — ставьте короткий `auto_stop_minutes`; чистите простаивающие песочницы через `daytona-env prune`.
- **Тома для данных** — храните состояние в смонтированных томах, а не в корневой ФС песочницы.
- **Сетевая изоляция** — для недоверенного или стороннего кода запускайте с заблокированным доступом к сети; открывайте его только когда сборке это реально нужно.
- **Одна песочница — одна задача** — относитесь к песочнице как к одноразовой; не накапливайте состояние, которое жалко потерять.
