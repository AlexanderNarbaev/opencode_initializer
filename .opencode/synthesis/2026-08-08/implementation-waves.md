# T4.1: Implementation Wave Decomposition — v3.0

> **Планировщик:** Reviewer | **Дата:** 2026-08-08
> **Вход:** T1.1-T1.5 audit (15+5 findings), T2.1-T2.5 research, T3.1 gap-matrix, T3.4 corporate profile
> **Цель:** Разложить gap matrix на атомарные implementation waves с приоритетами

---

## Wave 1: P0 — Security & Air-Gap Foundation (est. 2-3 дня)

### M5.1.1: Air-Gap Completeness
- **S5.1.1.1:** `32-isolated.sh` — добавить guard на `version-check.sh` (строка: проверка `ISOLATED_CIRCUIT=true` → skip внешних curl)
- **S5.1.1.2:** `20-autoupdate.sh` — gate на `ISOLATED_CIRCUIT`: не устанавливать systemd timer при isolated
- **S5.1.1.3:** `00-core.sh` — `_set_dns()` dry-run guard (F4.1 из T1.1)
- **S5.1.1.4:** `setup.sh:558` — убрать `rm -rf ~/.cache/opencode` (F2.4 из T1.1)

### M5.1.2: Supply-Chain Hardening
- **S5.1.2.1:** `29-mise.sh` — заменить `curl | sh` на download→verify SHA256→execute
- **S5.1.2.2:** `28-devbox.sh` — то же
- **S5.1.2.3:** `16-llm.sh:177` — WasmEdge: download→verify
- **S5.1.2.4:** `14-shokunin.sh` — download→verify
- **S5.1.2.5:** `04-zsh.sh` — добавить SHA256 проверку Oh My Zsh

### M5.1.3: Model Governance (новый модуль 41-model-policy.sh)
- **S5.1.3.1:** Создать `src/lib/41-model-policy.sh` с `model-policy.json` allowlist
- **S5.1.3.2:** Интегрировать в `18-opencode-json.sh` — генерить только allowed providers
- **S5.1.3.3:** Интегрировать в `pre-session-check.sh` — валидация модели

### M5.1.4: Offline Bundle (новый модуль 44-offline-bundle.sh)
- **S5.1.4.1:** `dev bundle create` — сборка tarball со всеми зависимостями
- **S5.1.4.2:** `setup.sh --airgap` — установка из офлайн-бандла

---

## Wave 2: P1 — SDD Harness (est. 3-5 дней)

### M5.2.1: Constitution + Spec Format
- **S5.2.1.1:** `17-project.sh` — добавить генерацию `memory/constitution.md`
- **S5.2.1.2:** `17-project.sh` — добавить `AGENTS.md` секцию SDD workflow
- **S5.2.1.3:** Шаблон `spec.md` с FR-###/SC-###/NFR, GIVEN/WHEN/THEN

### M5.2.2: Task Decomposition (M/T/S канон)
- **S5.2.2.1:** Шаблон `.opencode/todo.md` с M/T/S структурой и [P]-маркерами
- **S5.2.2.2:** `plan` skill — добавить FR→Task трассировку
- **S5.2.2.3:** `critic-gate` skill — добавить coverage-матрицу

### M5.2.3: Audit Trail (новый модуль 43-audit-chain.sh)
- **S5.2.3.1:** `37-wal.sh` — добавить 7 event types (model_call, tool_call, provider_switch, pii_redacted)
- **S5.2.3.2:** SHA-256 хеш-чейн для WAL
- **S5.2.3.3:** Ротация >10MB → gzip + Qdrant архив

### M5.2.4: PII Sanitizer (новый модуль 42-pii-guard.sh)
- **S5.2.4.1:** `scripts/pii-guard.py` — 9 детекторов
- **S5.2.4.2:** Pre-LLM-request hook интеграция
- **S5.2.4.3:** WAL + лог-интеграция

### M5.2.5: Upstream Sync Hardening
- **S5.2.5.1:** `99-upstream-sync.sh` — заменить `git merge` на 3-way merge с конфликт-резолюцией

---

## Wave 3: P2 — Developer Experience (est. 2-3 дня)

### M5.3.1: Error Handling
- **S5.3.1.1:** `_run_step()` — try/catch паттерн вместо жёсткого `set -e` (F3.1 из T1.1)
- **S5.3.1.2:** `_sudo()` — заменить pipe на here-string (F3.2)
- **S5.3.1.3:** WAL_MODULE_COUNT race condition fix (F2.3)

### M5.3.2: Progress/Dry-Run Fixes
- **S5.3.2.1:** `TOTAL_STEPS` унификация (F4.2)
- **S5.3.2.2:** Dry-run: сначала `_step_skip`, потом dry-run check (F2.2)
- **S5.3.2.3:** Верификация 19-finalize.sh: guarded от dry-run (F4.3)

### M5.3.3: Provider Registry
- **S5.3.3.1:** Вынос provider URLs в data-файл (из Python-строки 18-opencode-json.sh)
- **S5.3.3.2:** Удаление дубликата minimax (F1.3)

---

## Wave 4: P3 — Polish & Release (est. 1-2 дня)

### M5.4.1: Security Scanning
- **S5.4.1.1:** `15-security.sh` — systemd timer для daily Trivy scan
- **S5.4.1.2:** SBOM генерация (CycloneDX)
- **S5.4.1.3:** Pre-commit hook

### M5.4.2: Compliance Docs
- **S5.4.2.1:** `docs/compliance/soc2-checklist.md`
- **S5.4.2.2:** `docs/compliance/iso27001-mapping.md`

### M5.4.3: Version Bump & Release
- **S5.4.3.1:** `SCRIPT_VERSION=v3.0.0`
- **S5.4.3.2:** CHANGELOG + AGENTS.md update
- **S5.4.3.3:** Git commit + push

---

## Summary

| Wave | Priority | Subtasks | Est. effort | Модули |
|------|:--------:|:--------:|:-----------:|--------|
| M5.1 | P0 | 14 | 2-3 дня | 32-isolated, 20-autoupdate, 00-core, 41-model-policy, 44-offline-bundle |
| M5.2 | P1 | 15 | 3-5 дней | 17-project, 43-audit-chain, 42-pii-guard, 99-upstream-sync, skills/* |
| M5.3 | P2 | 8 | 2-3 дня | setup.sh, helpers.sh, 18-opencode-json, 19-finalize |
| M5.4 | P3 | 8 | 1-2 дня | 15-security, docs/compliance, version bump |
| **Total** | | **45** | **8-13 дней** | |

### Dependency chain
```
M5.1 (P0 security) → M5.2 (P1 SDD) → M5.3 (P2 DX) → M5.4 (P3 release)
```
M5.1.1-M5.1.3 могут идти параллельно. M5.2.1-M5.2.3 параллельно после M5.1.
