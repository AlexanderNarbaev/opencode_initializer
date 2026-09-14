# Глубокое исследование улучшений — 2026-08-03

> **Базис:** коммит 0eff737 (v2.0.2), сьюит 130/130. **Метод:** статический анализ + shellcheck 0.11 + git-археология + проверка инвариантов.
> Связан: [audit-2026-08-03.md](./audit-2026-08-03.md) (первая волна находок).

## Резюме по приоритетам

| # | Проблема | Критичность | Трудоёмкость |
|---|----------|-------------|--------------|
| 1 | Регрессия плагинов на чистой установке (plugins.json-сирота) | **HIGH** | S |
| 2 | Нет миграции v2.0.2 для существующих машин | **HIGH** | S |
| 3 | Пароль sudo CLI-флагом (`-s`) — утечка в ps/history | **HIGH** | S |
| 4 | macOS-поддержка сломана: `declare -A` (bash4) + `grep -P` (GNU) | **HIGH** | M |
| 5 | Trivy в CI никогда не падает (`exit-code: '0'`) | MEDIUM | XS |
| 6 | 51 неиспользуемая переменная (SC2034) — мёртвый код | MEDIUM | M |
| 7 | 5–7 модулей без тестов + sync-скрипты без тестов | MEDIUM | M |
| 8 | `OPencode_*` — систематическая опечатка в именах env (28 вхождений) | MEDIUM | S |
| 9 | pre-session-check.sh — задокументирован, но никуда не подключён | LOW | XS |
| 10 | health mode не покрывает новые фичи (cockpit/isolated/services) | LOW | S |

---

## 1. Регрессия плагинов на чистой установке (HIGH)

**Факт:** `18-opencode-json.sh` читает tier-реестр `~/.config/opencode/plugins.json`, но **ни один модуль его не создаёт** (grep по репо: писателей нет). На машине пользователя файл датирован Jun 29 — остаток старого инсталлера. Без реестра генератор молча деградирует до пустых tiers → в `opencode.json` попадают только `opencode-codegraph` + `opencode-dcp`, хотя `12-mcp-lsp.sh` ставит **25 плагинов**.

**Дизайн-интент нарушен:** коммит 4a665b6 (Plugin Framework v2) обещал «without plugins.json, all plugins included as before» — сейчас обратное.

**Фикс:** модуль (лучше `17-project.sh` или `12-mcp-lsp.sh`) должен писать дефолтный `plugins.json`, если отсутствует (5 always / 9 conditional / on-demand по вкусу) + тест на это.

## 2. Нет миграции v2.0.2 для существующих машин (HIGH)

Волна удалила Moonshot/LiteLLM **в репозитории**, но на машинах, где v2.0.1 уже установлен, остались: kimi-proxy/litellm systemd-сервисы, pipx litellm, старые opencode.json с moonshot-провайдером, env `MOONSHOT_API_KEY` в конфигах. `dev update` запускает `migrations/*.sh` — там только `20260530-v30-config.sh`.

**Фикс:** `migrations/20260803-v2.0.2-remove-moonshot.sh`: stop/disable kimi-proxy+litellm services, `pipx uninstall litellm`, удалить `~/.local/share/kimi-proxy`, регенерировать opencode.json (идемпотентно, с маркером выполнения).

## 3. Sudo-пароль CLI-флагом (HIGH)

`setup.sh -s <password>` (setup.sh:265, задокументирован в --help): пароль попадает в `ps aux`, историю шелла, логи CI. Есть безопасный путь (`read -s`, setup.sh:362), но флаг поощряет плохой.

**Фикс:** пометить флаг deprecated в --help (или убрать в v2.1), предпочтительный путь — интерактивный `read -s` / `sudo -v` pre-caching. В CI-режиме документировать `SUDO_PASS` через env, не argv.

## 4. macOS-поддержка сломана (HIGH)

README обещает «WSL2, Linux, and macOS», но:

- `declare -A` (bash 4+) в **00-core.sh, 17-project.sh, 26-providers.sh, 30-infra.sh, 32-isolated.sh** — на стоковом macOS (bash 3.2) модули падают мгновенно. Chicken-and-egg: brew bash ставится позже.
- `grep -oP` / `grep -P` (GNU PCRE) в **8 файлах** (03-chrome, 08-go, 32-isolated, 34-observability, 37-wal, version-check, dev.sh, upgrade.sh) — BSD grep не имеет `-P`.

**Фикс (по уровням):** (a) явно задокументировать требование bash≥4 + GNU grep для macOS (brew install bash grep, PATH); (b) заменить `declare -A` на индексные массивы/функции-диспетчеры в 00-core (критичный путь); (c) `grep -oP ':\d+'` → `grep -oE ':[0-9]+'`. (a) — минимум честности, (b)+(c) — реальная портируемость.

## 5. Trivy не блокирует (MEDIUM)

`.github/workflows/security.yml`: `exit-code: '0'` — CRITICAL/HIGH находки никогда не роняют CI. Скан превратился в декорацию.

**Фикс:** `exit-code: '1'` (или отдельная джоба «advisory» с continue-on-error, а основная — блокирующая).

## 6. Мёртвый код: 51 неиспользуемая переменная (MEDIUM)

`shellcheck -S warning`: 51× SC2034 (unused), 4× SC2155 (declare+assign маскирует exit code), 4× SC1090, 2× SC2010 (ls|grep), 1× SC2088. SC2034 — маркеры мёртвых веток рефакторингов (вероятно, остатки удалённых фич — та же природа, что и у аудита).

**Фикс:** проход по SC2034 с удалением/подключением; SC2155 — разделить declare и assign.

## 7. Пробелы в покрытии (MEDIUM)

Без dedicated unit-тестов: **05-java, 13-chromadb, 21-rag, 27-dotfiles, 29-mise, 40-best-practices, 99-upstream-sync**. Без тестов также новые **sync-providers.py / sync-agents.py** (коммит ccf240e) — а sync-agents.py **мутирует AGENTS.md других проектов** (regex-вырезание секций) — рискованно без тестов.

**Фикс:** минимальные existence+syntax+pattern тесты по шаблону существующих; для sync-скриптов — fixture-тесты на временных файлах.

## 8. `OPencode_*` — системная опечатка (MEDIUM)

28 вхождений `OPencode_LOCAL_ENDPOINT`, `OPencode_LOCAL_MODEL`, `OPencode_ISOLATED_CIRCUIT` (смешанный регистр вместо `OPENCODE_*`). Работает, т.к. консистентно, но пользователь, выставивший естественный `OPENCODE_LOCAL_ENDPOINT`, будет проигнорирован.

**Фикс:** читать `OPENCODE_*` первым, `OPencode_*` — fallback (deprecation), обновить доки.

## 9. pre-session-check.sh — сирота (LOW)

Задокументирован в AGENTS.md и диаграммах архитектуры, тестами проверяется, но **не вызывается** ни setup.sh, ни dev.sh, ни zshrc-hook'ом.

**Фикс:** подключить к `dev` (например, `dev doctor`) или в 19-finalize как финальную валидацию.

## 10. health mode отстаёт от фич (LOW)

119 проверок, но нет: cockpit binary, isolated circuit status, services layer config, dist/gui service, plugins.json registry presence (связано с #1).

**Фикс:** +6–8 проверок в соответствующие секции health.sh.

## Что в порядке (проверено)

- ShellCheck: 0 errors (CI gate severity=error — честно зелёный)
- dist/opencode-gui новее исходников GUI; 35-gui.sh ставит systemd-сервис на `node server.js` (бинарь — отдельный ручной артефакт, теперь gitignored)
- `_sudo()`: пароль через pipe от shell-builtin — не светится в ps; лог не содержит пароля (read -s не эхоится в tee)
- e2e critical_path читает живой конфиг — задокументированное поведение для dev-машины; на CI есть warn-skip ветка
- 4 модуля с mktemp-HOME — эталон герметичности уже внутри репо
