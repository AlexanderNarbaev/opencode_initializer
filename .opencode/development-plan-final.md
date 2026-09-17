# OpenCode Initializer — Итоговый план развития
# Дата: 2026-09-11
# Статус: APPROVED — после интервью с пользователем

## Принятые решения

1. **Стратегия интеграции:** VibeVM, Microsoft APM, AgentRC, Omakub — НЕ конкуренты,
   а ресурсы для интеграции. opencode_initializer — мета-проект, лучший сборник для
   машины разработчика. Fork + customize, subproject, dependency, inspiration.

2. **Docker тесты:** Testcontainers (Go/Python). Изолированные контейнеры для каждого теста.

3. **Multi-agent targets:** ПОКА НЕ НУЖНО. AGENTS.md как стандарт. Остальное — v4.0.0+.

4. **Язык документации:** Билингва (.en.md + .ru.md пары).

5. **Приоритет v3.4.0:** TOML конфиг + тесты 80%+ + F1/F2 + документация.

---

## Фаза 1: v3.4.0 — TOML + тесты + F1/F2 (4-6 недель)

### 1.1 TOML конфиг + интерактивный режим [P0]

Файлы для создания/изменения:
- `src/lib/00b-config.toml.sh` — новый модуль: _toml_get, _toml_load
- `src/data/setup.toml.template` — шаблон конфига
- `setup.sh` — добавить --config=FILE, --print-config
- `dev.sh` — добавить dev config-from <file>
- `tests/unit/test_toml_config.sh` — тесты
- `docs/guides/toml-config.en.md` + `.ru.md` — документация

Схема setup.toml:
```toml
[meta]
version = "1.0"
schema = "opencode-init/v1"

[user]
name = "Alexander Narbaev"
email = "alex@example.com"
shell = "zsh"

[features]
docker = true
postgres = "17"
nodejs = "24"
python = "3.14"
rust = false
install_gui = true

[services]
postgres = true
qdrant = true
redis = true
prometheus = true
grafana = true
memorylayer = true

[providers]
deepseek = true
opencode = true
minimax = true
mimo = true

[drift]
verify_on_run = true
manifest_file = "~/.local/state/opencode-init/manifest.json"

[dry_run]
default = false
```

Прецедент: CLI > env > toml > defaults

### 1.2 80%+ deep tests [P0]

Текущий уровень: ~35% shallow, ~40% medium, ~25% deep
Целевой уровень: ~10% shallow, ~30% medium, ~60% deep

Что сделать:
- [ ] Переписать 35% shallow tests на deep
- [x] Добавить Testcontainers тесты (PostgreSQL, Redis, Qdrant) — tests/integration/test_infra_containers.py
- [x] Добавить mode-specific тесты (health, ci, interactive, upgrade) — tests/integration/test_modes.sh
- [x] Добавить E2E smoke test в CI: `setup.sh --dry-run --mode ci` — tests/e2e/test_smoke_ci.sh
- [ ] Добавить интеграционные тесты для 18-opencode-json.sh
- [ ] Добавить тесты для 11 модулей с нулевым покрытием

Testcontainers подход:
```python
# tests/integration/test_infra_docker.py
import testcontainers.postgres
import testcontainers.redis
import testcontainers.qdrant

def test_postgres_connection():
    with testcontainers.postgres.PostgresContainer("postgres:17-alpine") as pg:
        # Test that opencode_initializer can connect
        assert pg.get_connection_url()
```

### 1.3 Audit F1: Per-step fault tolerance [P1]

Файлы для изменения:
- `setup.sh` — refactor _run_step

Что сделать:
- [x] Обернуть `_run_step` в subshell: `(set +e; source "$module")`
- [x] Capture exit code; on failure, mark step as `PARTIAL`
- [ ] При повторном запуске, `PARTIAL` шаги перезапускаются
- [ ] Лог: `warn "step_X FAILED — re-run will retry"`

### 1.4 Audit F2: WAL race condition [P1]

Файлы для изменения:
- `src/lib/helpers.sh` — улучшить _wal_locked_append

Что сделать:
- [ ] Проверить что параллельные модули безопасны
- [ ] Fallback для систем без flock (macOS): mkdir-based lock
- [ ] Стресс-тест: 5 concurrent writes

### 1.5 Документация [P1]

Что сделать:
- [x] Обновить README.md/README.ru.md (устаревшие счетчики) — обновлено до v15.0.0
- [x] Обновить architecture.md (ссылается на "24 модуля", сейчас 76) — обновлено до 146 модулей
- [ ] Добавить ADR для каждого архитектурного решения
- [ ] Добавить runbook для типовых операций

---

## Фаза 2: v3.5.0 — Ускорение + APM подготовка (4-6 недель)

### 2.1 Ускорение установки [P1]

Что сделать:
- [x] Параллельная установка модулей (flock для WAL) — src/lib/00d-parallel.sh
- [x] Кеширование загрузок — src/lib/00e-cache-mgr.sh
- [x] Зеркала для CN/RU — src/lib/00-core.sh (GITHUB_MIRROR, NPM_REGISTRY, PYPI_MIRROR, etc.)
- [x] Инкрементальная установка — src/lib/00d-parallel.sh (_is_module_installed)
- [x] --skip флаги — setup.sh (--skip, --devbox-skip, --skip-caching, --dotfiles-skip)

### 2.2 APM подготовка [P2]

Что сделать:
- [ ] Исследовать apm.yml формат
- [ ] Создать прототип генерации apm.yml из setup.toml
- [ ] Оценить сложность интеграции

---

## Фаза 3: v4.0.0 — APM интеграция + Multi-agent (8-12 недель)

### 3.1 APM интеграция [P2]

Что сделать:
- [ ] Поддержка `apm install opencode_initializer`
- [ ] Интеграция с apm-policy.yml
- [ ] SBOM экспорт

### 3.2 Multi-agent targets [P3]

Что сделать:
- [ ] Генерация .github/copilot-instructions.md
- [ ] Генерация .claude/settings.json
- [ ] Генерация .cursor/settings.json

---

## Метрики успеха v3.4.0

| Метрика | Текущее | Целевое |
|---------|---------|---------|
| Deep tests | ~25% | 60%+ |
| TOML конфиг | Нет | Есть |
| Installation time | 30+ min | <15 min |
| Docker services | 2/7 stuck | 7/7 running |
| opencode.json drift | Не обнаружен | Обнаружен + masked |
| Documentation | Устаревшая | Актуальная |

---

## Немедленные следующие шаги

1. **TOML конфиг** — начать с src/lib/00b-config.toml.sh
2. **Исправить literal PAT bug** в 18-opencode-json.sh:318
3. **Обновить session_checkpoint.json**
4. **Обновить architecture.md**
5. **Начать переписку shallow tests на deep**