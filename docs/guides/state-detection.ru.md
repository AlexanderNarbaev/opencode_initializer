# Обнаружение состояния и разрешение конфликтов портов

`dev state` и проверка занятости портов перед запуском в `setup.sh --with-all-infra` —
это две половины одной идеи: **обнаружить существующее состояние машины до того, как его менять**.

## Зачем это нужно

Скрипт установки изначально писался для *развёртывания* AI-машины разработчика
с чистого состояния. На чистом хосте это правильно. На хосте, где уже есть
сервисы (Postgres, Redis, Qdrant и т. д.) — например, от соседнего `docker compose`
проекта или от предыдущей установки OpenCode — скрипт молча сталкивается на
первом же порту. Столкновение глотается `2>/dev/null` в шаге запуска, контейнер
навсегда остаётся в состоянии `Created`. `docker ps` его показывает, `docker logs`
пустой, и ничто не указывает на причину.

`dev state` — это сторона чтения: выводит всё, о чём скрипт заботится, и завершается
с ненулевым кодом при отклонении. Pre-flight в `30-infra.sh` — это сторона записи:
отказывается запускать контейнер, чей хост-порт уже занят, и предлагает сдвинутый
порт.

## Что показывает `dev state`

Четыре секции, exit-код 0 информационный / 1 при `--strict` с дрейфом.

```
── Tools ────────────────────────────────────
  PRESENT  docker       /usr/bin/docker
  PRESENT  bash         /usr/bin/bash
  PRESENT  git          /usr/bin/git
  ...

── Config files ─────────────────────────────
  PRESENT  /home/.../.config/opencode/opencode.json
  PRESENT  /home/.../.config/opencode/infra.yml
  PRESENT  /home/.../.config/opencode/secrets.env
  PRESENT  /home/.../.config/opencode-setup/setup.conf
  PRESENT  /home/.../.config/opencode/.goal-mode-manifest.json

── OpenCode docker services ────────────────
  RUNNING  opencode-postgres
  STOPPED  opencode-qdrant (created)
  STOPPED  opencode-redis (created)
  RUNNING  opencode-prometheus
  RUNNING  opencode-grafana
  ABSENT   opencode-node_exporter (no container)
  RUNNING  opencode-memorylayer

── Listening ports (canonical defaults) ─────
  BOUND    postgres        :5432  by opencode-postgres
  BOUND    qdrant          :6333  by rag-qdrant
  BOUND    redis           :6379  by rag-redis
  BOUND    prometheus      :9090  by opencode-prometheus
  ...

total=35  fails=3  strict=0
```

Каждая запись `BOUND` указывает владеющий docker-контейнер (или `pid/NNN` для
не-docker слушателя, или `<unknown>`, если оба способа не сработали). Используйте
это, чтобы понять, какой соседний проект занял канонический opencode-порт.

## Как работает разрешение конфликта портов

Когда запускается `setup.sh --with-all-infra` (или любой режим, который вызывает
`30-infra.sh`), pre-flight блок проходит по списку включённых сервисов и проверяет
каждый хост-bind порт против живой таблицы `ss`/`lsof`/`/proc/net/tcp`.

Для каждого конфликта:

1. Определяется владеющий контейнер / процесс (тот же lookup, что использует
   `dev state`).
2. Сдвинутый порт вычисляется через `_find_free_port` — он прибавляет 10 000 к
   дефолту и идёт вперёд до 50 кандидатов, пока не найдёт свободный.
   (`REDIS_PORT=16380`, `QDRANT_PORT=16333` и т. п. на хосте с rag-redis /
   rag-qdrant.)
3. Сдвинутый порт сохраняется в `~/.config/opencode-setup/setup.conf` через
   `_set_config`. При следующем запуске env-var приоритет подхватывает его
   автоматически.
4. Следующий `docker compose up` использует сдвинутый порт.

Конфликт логируется как предупреждение, а не ошибка. Сдвиг автоматический, но
аудируемый: `cat ~/.config/opencode-setup/setup.conf` показывает, что изменилось.

## Что обнаруживается, а что нет

| Обнаруживается | Не обнаруживается |
|---|---|
| Порты, занятые любым docker-контейнером | Порты, удерживаемые процессом, невидимым `ss`/`lsof` (редко — обычно kernel-listener-ы) |
| Порты, удерживаемые сервисами с `network_mode: host` (нет docker-proxy) — через `docker ps -a` | Связь контейнер-порт, когда контейнер удалён, но порт ещё в TIME_WAIT |
| Контейнеры в Created/Exited (с аннотацией `(Created/Exited)`) | Связь контейнер-порт, когда docker-daemon недоступен |
| `pid/NNN` для не-docker слушателей через `lsof -iTCP:PORT` fallback | PID слушателя при вызове без root (нет колонки `pid=` от `ss`) |

## Контракт идемпотентности

Запуск `setup.sh --with-all-infra` дважды подряд не должен ничего менять при
втором запуске. Конкретно:

- Контейнер в состоянии `RUNNING` пропускается — `docker compose up` для него
  не вызывается.
- Уже сдвинутый порт (записан в `setup.conf`) используется повторно; bump-арифметика
  не перезапускается.
- Отсутствующий файл конфигурации в `~/.config/opencode/` вызывает установку;
  присутствующий с идентичным содержимым пропускается (`bash -n` — самая дешёвая
  sanity-проверка).

`dev state --strict` — это скриптуемая проверка «дрейфует ли что-то от последнего
известного хорошего состояния?». Можно запускать периодически из CI / crontab.

## Когда использовать

- **Перед `setup.sh --with-all-infra`** — посмотреть, что уже есть, и решить,
  добавлять ли opencode-сервисы рядом или вместо существующих.
- **После ручного редактирования `~/.config/opencode/opencode.json`** — проверить,
  нет ли дрейфа (например, регрессия `opencode-context` из `audit/2026-08-08/`).
- **При инциденте** — когда opencode-сервис не стартует, первый шаг —
  `dev state --strict`, чтобы увидеть, кто держит канонический порт.

## Diff-before-write для `opencode.json`

`src/lib/18-opencode-json.sh` теперь следует тому же контракту идемпотентности,
что и port pre-flight:

1. **SHA-256 предложенного вывода** (с заголовком + каноническим `json.dumps`).
2. **Сравнение с on-disk файлом**. Если равны → эмитировать `UNCHANGED:<hash>`
   в stderr и пропустить запись.
3. **Если различаются** → эмитировать unified diff (с маскированием секретов)
   в stderr.
4. **Если `DRY_RUN=1`** → также напечатать предложенный JSON в stdout, пропустить
   запись.

Это означает, что второй `setup.sh --fix-config` после успешного запуска —
теперь no-op (нулевые записи, нулевое изменение mtime) — та же гарантия, которую
port pre-flight даёт для `infra.yml`.

Diff также маскирует секреты. Три паттерна заменяются на `<REDACTED:ENV>`:

- `apiKey: "sk-..."` / `apiKey: "xai-..."` / `apiKey: "tp-..."` / `apiKey: "dtn_..."`
  / `apiKey: "github_pat_..."` (и JSON-стиль `"apiKey": "..."`)
- `password: "..."` / `token: "..."` / `secret: "..."` с теми же префиксами
- Существующий баг на строке 318 (литеральный `GITHUB_PERSONAL_ACCESS_TOKEN`
  писался на диск в `gh_entry["env"]`) теперь тоже маскируется — утечка PAT
  через `--diff-only` невозможна.

Чтобы посмотреть предложенный `opencode.json` без записи:

```bash
DRY_RUN=1 bash ./setup.sh --fix-config
```

Чтобы увидеть, что генератор хочет изменить, без применения — самый простой путь:
модифицировать `~/.config/opencode/opencode.json` и запустить `setup.sh --fix-config`;
diff будет эмитирован в stderr.

Фикс детерминизма на строке 845 (сортировка `task_profiles[].mcp` и `disabled`)
гарантирует, что два последовательных запуска дают побайтово идентичный вывод —
это требуется для того, чтобы hash-сравнение когда-нибудь сообщило `UNCHANGED`.

## Конфигурация из файла (TOML)

Вместо передачи множества флагов CLI можно объявить конфигурацию в TOML-файле
и передать её через `--config`:

```bash
bash setup.sh --config setup.toml --dry-run
```

### Приоритет

Значения конфигурации разрешаются в следующем порядке (выше = приоритетнее):

1. **Флаги CLI** — `--deepseek-key`, `--with-postgres` и т.д.
2. **Переменные окружения** — `DEEPSEEK_KEY`, `INFRA_SERVICES` и т.д.
3. **TOML-файл** — значения из `--config setup.toml`
4. **Значения по умолчанию** — захардкожены в `00-core.sh`

### Создание конфигурационного файла

Скопируйте шаблон и раскомментируйте нужные значения:

```bash
cp setup.toml.template setup.toml
# Отредактируйте setup.toml
```

Шаблон документирует все доступные параметры с значениями по умолчанию.

### Структура TOML

```toml
[meta]
profile = "corporate"           # personal | corporate | airgapped | hybrid

[user]
git_name = "Ваше Имя"
git_email = "you@example.com"
project_dir = "~/projects"

[features]
isolated_circuit = true          # Только локальный LLM

[features.skip]
devbox = true                    # Пропустить Devbox (Nix)

[services]
postgres = true                  # Включить PostgreSQL
redis = true                     # Включить Redis

[ports]
postgres = 5433                  # Переопределить порт по умолчанию

[providers]
deepseek_key = "sk-..."         # API-ключ (лучше через env)

[tools]
node_ver = "22"                  # Переопределить версию
```

### Проверка resolved-значений

Используйте `--print-config` чтобы увидеть, что скрипт будет использовать:

```bash
bash setup.sh --config setup.toml --print-config
```

Или через dev CLI:

```bash
dev config-from setup.toml
```
