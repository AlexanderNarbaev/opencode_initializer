# Audit Report: Core Architecture — opencode_initializer v2.0.3
> **Scope:** setup.sh, 00-core.sh, helpers.sh, 18-opencode-json.sh, 19-finalize.sh
> **Date:** 2026-08-08 | **Auditor:** Planner | **Severity:** CRITICAL → HIGH → MEDIUM → LOW

---

## Executive Summary

Ядро opencode_initializer — это линейный оркестратор (615 строк setup.sh), который подгружает 43 модуля через `source` в единый bash-процесс. Архитектура простая, понятная, но хрупкая: **нет изоляции модулей, нет per-step error recovery, глобальное состояние разделяется между всеми модулями**. Сильные стороны: продуманная система зеркал, _curl с ретраями и кешированием, _npm_install с fallback-цепочкой. Критические проблемы: отсутствие per-step fault tolerance и race condition в параллельной установке.

---

## Findings

### F1. [CRITICAL] No per-step error recovery — single failure stops entire bootstrap
**Location:** `setup.sh:527-539` (`_run_step`), `setup.sh:4` (`set -euo pipefail`)

`_run_step` делает `source "$module"`. При `set -e` любая ошибка в модуле (включая `warn` которая не-exit, но некоторые команды через `|| true` подавлены) приводит к немедленному завершению ВСЕГО setup.sh. Неустановившиеся шаги 6-41 никогда не запустятся.

**Реальный сценарий:** если `03-chrome.sh` упадёт из-за таймаута загрузки, пользователь теряет Java, Node, Python, Go, Rust, OpenCode — всё, что идёт после Chrome.

**Mitigation exists, но хрупкое:** progress-файл (`_step_skip`) позволяет при повторном запуске пропустить успешные шаги. НО: модуль, который упал на полпути, тоже помечен как "done" (`_step_done` вызывается в `_wal_checkpoint` ПОСЛЕ `source`, а не до). То есть: если модуль отработал частично и упал — progress уже записан, шаг считается выполненным, остаётся сломанное состояние.

**Recommendation:** Обернуть `source "$module"` в subshell `(source "$module")` — тогда `set -e` в модуле не уронит родителя. Или: временно `set +e` перед `source`.

---

### F2. [CRITICAL] Parallel install race condition on shared state
**Location:** `setup.sh:582-596`

5 модулей запускаются фоном (`&`): 21-rag.sh, 22-webui-service.sh, 29-mise.sh, 23-just.sh, 24-websearch.sh. Все они разделяют:
- Глобальные переменные (`PATH`, `NPM_CONFIG_REGISTRY`, etc.)
- Файловую систему (`SECRETS_FILE`, `PROGRESS`, `WAL_FILE`)
- Процесс-специфичные ресурсы (stdout/stderr через `exec > >(tee ...)`)

`_wal_checkpoint` использует `sed -i` — неатомарная операция. При одновременном вызове из 5 процессов WAL-файл будет повреждён.

**Recommendation:** Использовать `flock` для записи в WAL/PROGRESS, или запускать фоновые модули в изолированных subshell-ах с отдельным stdout.

---

### F3. [HIGH] Double logging initialization — first log file lost
**Location:** `setup.sh:39-42` vs `setup.sh:515-516`

```bash
# Line 39-41: FIRST log
SETUP_LOG="${HOME}/.cache/opencode-setup/setup-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$SETUP_LOG") 2>&1

# Line 515-516: SECOND log — OVERWRITES the first!
LOG_FILE="$HOME/setup-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
```

Второй `exec > >(...)` переопределяет stdout/stderr. Всё, что было записано в `SETUP_LOG` (DNS fix, WSL2 detection, network check), остаётся в старом fd. `SETUP_LOG` никогда не упоминается после строки 42 — это мёртвый код.

**Recommendation:** Удалить первый `exec > >(tee ...)` на строке 41, оставить только второй.

---

### F4. [HIGH] WAL checkpoint is non-atomic — corruption on crash/concurrency
**Location:** `00-core.sh:163-179` (`_wal_checkpoint`)

Использует множественные `sed -i` на одном файле:
```bash
sed -i "s|_Updated:.*|_Updated: ${now}|" "$WAL_FILE"
sed -i "s|DONE: [0-9]\+/${_WAL_TOTAL}|DONE: ${WAL_MODULE_COUNT}/${_WAL_TOTAL}|" "$WAL_FILE"
sed -i "/^## Next Step/,/^$/{s|^- .*|- ${step_name}|}" "$WAL_FILE"
echo "$module_key" >> "$PROGRESS"
```

Четыре неатомарные мутации. При сбое между sed-ами — WAL в несогласованном состоянии. При параллельной установке (F2) — гарантированная гонка.

**Recommendation:** Писать WAL через атомарное переименование: записать в `.tmp`, `mv .tmp wal.md`.

---

### F5. [MEDIUM] Module source graph — fragile, undocumented dependency order
**Location:** `setup.sh:542-606`

43 модуля загружаются в жёстко заданном порядке через `_run_step`. Зависимости между модулями неявные:
- `00-core.sh` ожидает что `helpers.sh` уже загружен (явно указано)
- `30-infra.sh` использует `DEPLOYMENT_PROFILE` из `00-core.sh`
- `18-opencode-json.sh` использует env vars, экспортированные в `setup.sh:491-508`

Но: если кто-то переставит порядок модулей местами, зависимости молча сломаются. Нет валидации что модуль X загружен до модуля Y.

**Recommendation:** Добавить `declare -A MODULE_LOADED` и в каждом модуле проверять `[[ -n "${MODULE_LOADED[helpers]:-}" ]] || err "helpers.sh must be loaded first"`.

---

### F6. [MEDIUM] `_step_skip` uses grep — fragile substring matching
**Location:** `00-core.sh:155`

```bash
_step_skip() { grep -qxF "$1" "$PROGRESS" 2>/dev/null && ...; }
```

`grep -x` требует точного совпадения всей строки — это хорошо. Но если ключ шага `step_system` совпадёт с подстрокой в другой строке прогресс-файла — `grep -F` найдёт. Пример: ключ `step_go` матчит `step_golang` (если такой появится).

**Recommendation:** Хранить ключи с уникальным префиксом (например `STEP:step_go`) и использовать точное совпадение с якорем `^STEP:step_go$`.

---

### F7. [MEDIUM] Mirror resolution blocks startup — 30 second delay on cold cache
**Location:** `00-core.sh:110-146`

`_mirror_url` делает до 3 HTTP-запросов с таймаутом 10 секунд каждый. 6 вызовов (GITHUB, NPM, PYPI, DOCKER, GO, RUSTUP, ZIG, JAVA = 8) — потенциально 8 × 3 × 10 = 240 секунд на старте при плохой сети.

На практике curl быстро фейлится на недоступных хостах (connection refused занимает ~1-3 секунды), но DNS-резолвинг в WSL2 может занимать до 10 секунд на каждый хост.

**Recommendation:** Кешировать результаты mirror resolution в `/tmp/opencode-mirrors.cache` на 1 час. Или: использовать `--connect-timeout 3` вместо 5.

---

### F8. [MEDIUM] setup.conf sourced twice with different patterns
**Location:** `00-core.sh:280-283` vs `00-core.sh:365`

```bash
# ISOLATED_CIRCUIT (line 280)
[ -z "$ISOLATED_CIRCUIT" ] && [ -f "$HOME/.config/opencode-setup/setup.conf" ] && \
  . "$HOME/.config/opencode-setup/setup.conf" 2>/dev/null && \
  ISOLATED_CIRCUIT="${ISOLATED_CIRCUIT:-}"

# DEPLOYMENT_PROFILE (line 365)
[ -z "$DEPLOYMENT_PROFILE" ] && [ -f "$SETUP_CONF" ] && \
  . "$SETUP_CONF" 2>/dev/null && DEPLOYMENT_PROFILE="${DEPLOYMENT_PROFILE:-}"
```

Два отдельных source одного и того же файла. Каждый source перезаписывает ВСЕ переменные из конфига. Второй source (DEPLOYMENT_PROFILE) перезатрёт ISOLATED_CIRCUIT если он был изменён между вызовами.

**Recommendation:** Source `setup.conf` ОДИН раз в начале, сохранить все значения в ассоциативный массив.

---

### F9. [LOW] `_sudo` wrapper masks errors
**Location:** `helpers.sh:193-198`

```bash
_sudo() {
  if [ -n "${SUDO_PASS:-}" ]; then
    echo "$SUDO_PASS" | sudo -S "$@" 2>/dev/null
  else
    sudo "$@" 2>/dev/null
  fi
}
```

`2>/dev/null` скрывает ВСЕ ошибки sudo, включая permission denied и неверный пароль. Модуль думает что операция успешна, но пакет не установлен.

**Recommendation:** Сохранять stderr в переменную и логировать при ошибке, или убрать `2>/dev/null` и позволить `set -e` обработать.

---

### F10. [LOW] `_progress` and `_spin_start` fight for the same terminal line
**Location:** `helpers.sh:33-47` vs `helpers.sh:62-65`

`_spin_start` пишет в `\r  ⠋ Doing...`, а `_progress` пишет `\r  [3/41] Step name`. Оба используют `\r` (carriage return) для перезаписи одной строки. Если вызвать `_progress` пока крутится `_spin_start`, вывод наложится.

**Recommendation:** `_progress` должен убивать активный спиннер перед записью, или использовать отдельную строку.

---

### F11. [LOW] Cleanup trap — partial, не чистит все временные файлы
**Location:** `helpers.sh:94-107`

```bash
cleanup() {
  rm -f /tmp/docker-install.*.sh /tmp/uv-install.*.sh /tmp/bun-install.*.sh \
    /tmp/sdkman-install.sh /tmp/superpowers.* /tmp/dotnet-install.*.sh \
    /tmp/rustup-init.*.sh /tmp/opencode-install.sh /tmp/ollama-install.sh 2>/dev/null
```

Жёстко закодированный список временных файлов. Если новый модуль создаст `/tmp/foo-install.sh`, cleanup его не подчистит.

**Recommendation:** Создавать временную директорию `/tmp/opencode-setup-XXXXX` через `mktemp -d` и чистить её рекурсивно.

---

### F12. [LOW] Progress file never truncated — grows indefinitely
**Location:** `00-core.sh:154-156`

Каждый успешный шаг дописывает строку в `$DL_CACHE/progress`. После 10 полных запусков — 410 строк. Файл никогда не чистится, не ротируется.

**Recommendation:** Добавить `_reset_progress` и вызывать при `--reinit`.

---

## Severity Summary

| Severity | Count | Findings |
|----------|-------|----------|
| CRITICAL | 2 | F1 (no per-step recovery), F2 (parallel race) |
| HIGH | 2 | F3 (double logging), F4 (non-atomic WAL) |
| MEDIUM | 4 | F5 (implicit deps), F6 (fragile grep), F7 (slow mirrors), F8 (double source) |
| LOW | 4 | F9-F12 (cosmetic/edge-case) |
| **TOTAL** | **12** | |

---

## Scorecard

| Dimension | Score | Notes |
|-----------|-------|-------|
| Модульность | ⭐⭐⭐ | Линейный source, нет изоляции. Но структура понятная. |
| Идемпотентность | ⭐⭐⭐⭐ | Progress-файл работает, но F1 подрывает. |
| Error handling | ⭐⭐ | `set -e` + `trap cleanup` — но нет per-step recovery. |
| Progress / Dry-run | ⭐⭐⭐ | `_progress` + `DRY_RUN` покрывают основные ветки. |
| Observability | ⭐⭐⭐ | Двойной лог (F3), WAL неатомарный (F4). |
