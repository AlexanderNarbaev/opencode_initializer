# Аудит проекта — 2026-08-03

> **HEAD:** ccf240e (`chore: add sync scripts...`) · **Ветка:** main · **Волна:** v2.0.2 (ACTIVE, uncommitted)
> **Метод:** ручная инспекция + запуск тестов + grep-верификация + codegraph
> **Предыдущий аудит:** [audit-v2.0.0.md](./audit-v2.0.0.md)

## 1. Резюме

Проект структурно здоров: весь shell-код проходит `bash -n`, 5 CI-воркфлоу, сабмодули закреплены, тестовый раннер завершается с exit 0. Однако найдены **два критических системных дефекта** (сломанный гейт тестов и мёртвые модули) и **незавершённая волна v2.0.2**, плюс массовый дрейф документации.

| Область | Статус | Комментарий |
|---------|--------|-------------|
| Синтаксис (все .sh) | ✅ | `bash -n` чисто по setup.sh, dev.sh, src/lib, src/modes |
| Тестовый раннер | ⚠️ | exit 0, но **не видит реальные падения** (см. §3.1) |
| Волна v2.0.2 | ⚠️ | Ядро вычищено, хвосты остались (см. §4) |
| Документация | ❌ | Системный дрейф чисел и фич (см. §5) |
| Git | ⚠️ | 40 файлов изменений не закоммичены (+58/−1118) |

## 2. Фактическое состояние (замерено)

| Метрика | Факт |
|---------|------|
| setup.sh | 586 строк |
| dev.sh | 592 строки |
| Модули src/lib | **43 файла** = 40 нумерованных (00–24, 26–38, 40, 99) + 3 helpers |
| Режимы src/modes | 5 файлов (ci, fix-zshrc, health, interactive, upgrade) |
| Тесты | **37 файлов**: 28 unit + 5 integration + 4 e2e; **486 assertion-вызовов** |
| Health mode | **119** `_check`-вызовов |
| Провайдеры (генератор 18-opencode-json.sh) | **22** = 19 облачных (env-var) + 3 локальных (ollama, vllm, sglang) |
| Корневой opencode.json | Локальный рабочий конфиг: 5 провайдеров (deepseek, mimo, minimax, opencode, opencode-go) |
| Сабмодули | 5 upstream, все инициализированы и чисты |
| Codegraph | Индекс свежий (737 файлов), демон работает; контекстный API недоступен (405/410) |
| SCRIPT_VERSION | v2.0.0 (00-core.sh:8) |

## 3. Критические находки

### 3.1 Сломан гейт тестового раннера (CRITICAL)

`tests/run_tests.sh` судит о прохождении по **exit-коду** файла. Но **24 из 37 тестовых файлов** определяют собственный `assert()` и завершаются `echo "... passed, N failed"` **без `exit 1`** — раннер и CI видят PASS при любых падениях.

**Прямо сейчас скрыты 7 реальных падений:**

| Файл | Падения | Причина |
|------|---------|---------|
| tests/unit/test_model_router.sh | 4 | assertion'ы на `kimi-k3`, `kimi-k2.7-code-highspeed` в profiles/costs — фича удалена волной v2.0.2, тест не обновлён |
| tests/unit/test_providers.sh | 2 | ожидает `zai` + fallback в корневом opencode.json, но корневой файл — локальный 5-провайдерный конфиг |
| tests/unit/test_isolated.sh | 1 | проверка `/v1/models` endpoint |

Файлы с корректным гейтом (`[ "$TESTS_FAIL" -eq 0 ] || exit 1`): test_core, test_gui, test_helpers, test_mcp_registry, test_mirrors + все 5 integration + 3 из 4 e2e.

**Фикс:** добавить `[ "$TESTS_FAIL" -eq 0 ] || exit 1` (или `cleanup_test` из test_lib.sh) в 24 файла; затем чинить вскрывшиеся падения.

### 3.2 Мёртвые модули (CRITICAL)

Три модуля **нигде не подключаются**: grep по репозиторию находит ссылки только из их собственных тестов.

| Модуль | Заявлено | Факт |
|--------|----------|------|
| src/lib/31-cockpit.sh | Cockpit TUI daemon (Phase 4 «Done») | Не вызывается из setup.sh (41 `_run_step`, ни одного на него) |
| src/lib/32-isolated.sh | Isolated Circuit — флагман v2.0.0 | Не выполняется при установке; `dev isolated` реализован инлайн в dev.sh:386 |
| src/lib/33-services.sh | Unified Service Layer | Комментарий в тесте «used by dev.sh CLI» — неверен, dev.sh его не подключает |

**Решение (нужен выбор):** подключить в оркестратор / dev.sh **или** удалить как dead code и закрыть тесты.

## 4. Волна v2.0.2 — незакрытые хвосты

Цель: удалить Moonshot/Kimi + LiteLLM. Ядро вычищено корректно (26-providers.sh, 36-model-router.sh, таблица провайдеров в AGENTS.md, удаление 25-litellm.sh/39-kimi-proxy.sh, скриптов и systemd-сервисов). Осталось:

- [ ] `tests/unit/test_model_router.sh` — 4 kimi-assertion'а (см. §3.1)
- [ ] `src/modes/health.sh:124` — проверка «LiteLLM API» на :4000
- [ ] `src/lib/32-isolated.sh` (шапка) — LiteLLM как бэкенд isolated-контура
- [ ] `dev.sh:402` — рекомендация «ensure Ollama or LiteLLM is running»
- [ ] `docs/VERSIONS.md` — строка Moonshot endpoint (proxy 127.0.0.1:9876)
- [ ] `README.md` — «LiteLLM API gateway» в Quick Start + «24 providers» (вкл. Moonshot)
- [ ] 10+ файлов docs/ (getting-started, faq, architecture, reference, comparison, index — en+ru, provider-setup, team-setup)
- [ ] `SCRIPT_VERSION` v2.0.0 → v2.0.2
- [ ] `CHANGELOG.md` — нет секций [2.0.1] и [2.0.2] (пост docs/changelog/posts/2026-07-27-v2.0.1.md есть)
- [ ] `src/lib/18-opencode-json.sh:178` — устаревший исторический комментарий про kimi-proxy
- [ ] Коммит 40 изменённых файлов (+58/−1118)

## 5. Дрейф документации (claimed vs actual)

| Метрика | AGENTS.md / README | Факт |
|---------|--------------------|------|
| Модули | «42 модуля», таблица без 40/99 | 43; 40-best-practices.sh и 99-upstream-sync.sh **подключены** (setup.sh:576–577), но не задокументированы |
| Провайдеры | 24 (20 cloud + 4 local) | 22 (19 + 3) |
| Тесты | 12u/5i/4e, «398+ assertions», «20 tests, 350+» | 28u/5i/4e, 486 |
| setup.sh | 589 строк | 586 |
| Health | «65+ checks» | 119 |
| session_checkpoint.json | — | Устарел с 2026-07-19 (moonshot_fix, 42 модуля, 69% coverage) |

## 6. Гигиена репозитория

- `dist/opencode-gui` — 94 МБ бинарь, untracked, **не в .gitignore** (риск случайного коммита).
- `.opencode/goals/state.json.migrated.*` — мусор от миграции плагина.
- Корневой `opencode.json` — локальный рабочий конфиг; тесты ошибочно трактуют его как генерируемый полный конфиг (см. §3.1).

## 7. Что в порядке

- Синтаксис всех shell-файлов чист; Python-скрипты компилируются; Go отформатирован.
- CI: test, shellcheck, docs, security, build — 5 воркфлоу.
- 5 upstream-сабмодулей закреплены и инициализированы.
- Ядро волны v2.0.2 выполнено корректно и последовательно.
- Модули 40/99 корректно вwired в оркестратор.

## 8. Приоритизированный план

1. **P0** — Починить гейт тестов (§3.1): 24 файла + `exit 1`; прогнать, зафиксировать вскрывшиеся падения.
2. **P0** — Решить судьбу мёртвых модулей (§3.2): подключить или удалить.
3. **P1** — Закрыть хвосты волны v2.0.2 (§4) и закоммитить.
4. **P1** — Обновить AGENTS.md/README/CHANGELOG/VERSIONS/session_checkpoint (§5).
5. **P2** — `dist/` в .gitignore; разобраться с дублированием логики isolated (dev.sh vs 32-isolated.sh).
