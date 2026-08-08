# T1.5: Corporate / Air-Gap Readiness Audit — v2.0.3

> **Аудитор:** Reviewer | **Дата:** 2026-08-08
> **Scope:** 32-isolated.sh (102 строки), 24-websearch.sh (444 строки), 15-security.sh (16 строк), audit logging/access control/model governance

---

## 1. Air-Gap Completeness

### 32-isolated.sh — Isolated Circuit Mode

**Что есть (102 строки):**
- 3 локальных бэкенда: Ollama (11434), vLLM (8000), SGLang (30000)
- Auto-detection доступных бэкендов через `curl /models`
- Auto-detection моделей через `ollama list`
- Persist в `setup.conf`
- Env-var цепочка: `ISOLATED_CIRCUIT` → `ISOLATED_FLAG` → `OPENCODE_ISOLATED_CIRCUIT` → `OPencode_ISOLATED_CIRCUIT`
- Fallback-модель: `qwen3:0.6b` если нет локальных моделей

**Что НЕ проверяется при изоляции:**

| Пробел | Почему важно |
|--------|-------------|
| **Telemetry** — не отключается | Ollama шлёт телеметрию по умолчанию (`OLLAMA_NOPRUNE=true`, analytics). vLLM/SGLang — аналогично. |
| **Update checks** — `version-check.sh` пытается достучаться до GitHub | В air-gap контуре GitHub недоступен — проверка зависнет на таймауте |
| **npm/pip/apt** — авто-обновления и зеркала | `_curl()` пытается GitHub → ghproxy, но в air-gap оба недоступны. Нужен local mirror. |
| **Docker pull** — `searxng/searxng:latest`, `ollama pull` | В air-gap нет доступа к Docker Hub, нужен pre-cached registry |
| **MCP auto-install** — `npm install -g` требует registry.npmjs.org | В air-gap нужен Verdaccio или npm-offline cache |
| **OpenCode auto-update** — systemd timer `20-autoupdate.sh` | `git pull` + `topgrade` — оба требуют сети |

**Вердикт:** Isolated Circuit Mode отключает только LLM-провайдеров (правильно). Но не отключает telemetry и не предоставляет offline-стратегию для установки пакетов. Air-gap bootstrap = ручная работа.

---

## 2. PII / Data Boundaries

### Хранение ключей

| Место | Формат | Права | Оценка |
|-------|--------|-------|--------|
| `~/.config/opencode/secrets.env` | `KEY="value"` | chmod 600 | ★★★★ — хорошо, но ключи в открытом виде на диске |
| `setup.sh` CLI args | `export *_KEY="$2"` | — | ★★ — ключи в `/proc/$$/environ` (C2 из T1.1) |
| `opencode.json` | `${ENV_VAR}` references | 644 | ★★★★ — ключи не хранятся, только ссылки на env vars |

### WAL логи

| Место | Что пишется | PII риск |
|-------|------------|----------|
| `~/.cache/opencode-setup/wal.md` | Прогресс установки, названия шагов | Низкий — нет чувствительных данных |
| `~/.cache/opencode/wal.jsonl` | Решения агентов: domain, decision, rationale | **Средний** — rationale может содержать обсуждение архитектуры, но не ключи |
| `~/.cache/opencode-setup/setup-*.log` | Полный лог установки через `tee -a` | **Высокий** — может содержать пути, имена пользователей, версии пакетов |

### RAG embeddings

| Место | Что хранится | PII риск |
|-------|-------------|----------|
| ChromaDB (`~/.cache/opencode/chromadb`) | Векторные эмбеддинги документов | **Средний** — зависит от индексируемых документов |
| Qdrant (Docker volume) | Векторы + payloads | **Средний** — то же |
| `embed-proxy` логи | Запросы на эмбеддинг | **Низкий** — только embedding vectors |

### Web search sanitizer

| Что фильтруется | Полнота |
|----------------|---------|
| Internal hostnames (`*.internal.local`, `*.corp.internal`, etc.) | ★★★ — 6 паттернов, но нет wildcard-звёзд для произвольных internal-доменов |
| Private IP ranges (10.x, 172.16.x, 192.168.x, 100.64.x, 127.x, 169.254.x) | ★★★★★ — полный RFC1918 + CGNAT |
| Secrets (API keys, Bearer tokens, passwords) | ★★★★ — 9 regex-паттернов покрывают основные форматы |
| Email addresses | ✗ — не фильтруются |
| Credit card numbers | ✗ — не фильтруются |
| SSN/passport numbers | ✗ — не фильтруются |

---

## 3. Audit Trail — SOC2/ISO27001 Readiness

### Что есть сейчас

| Компонент | Формат | Аудит-пригодность |
|-----------|--------|-------------------|
| Setup WAL | Markdown, append-only? (на самом деле перезаписывается `cat >`) | ✗ — перезаписывается, а не appends |
| Agent WAL | JSONL, append-only | △ — формат правильный, но impact не заполняется |
| `setup-*.log` | Текстовый лог через `tee` | △ — пишется, но нет structured logging |
| `sanitizer.log` | Текстовый лог прокси | △ — только для websearch |

### Что требуется для SOC2/ISO27001

| Требование | Статус | Gap |
|-----------|--------|-----|
| **Audit log всех tool calls** (кто, когда, какой инструмент, с какими параметрами) | ✗ | Нет фиксации tool calls |
| **Audit log всех model calls** (провайдер, модель, prompt/response токены) | ✗ | Нет логирования вызовов LLM |
| **Immutable logs** (append-only, checksummed) | ✗ | WAL — текстовый файл без подписей |
| **Log retention policy** (ротация, архивация) | ✗ | JSONL растёт бесконечно |
| **Access control to logs** | ✗ | WAL в `~/` — доступен всем процессам пользователя |
| **Alerting на anomalies** (подозрительные паттерны) | ✗ | Нет мониторинга |

### Что есть для безопасности

| Инструмент | Статус | Описание |
|-----------|--------|----------|
| **Trivy** | Устанавливается, но не запускается автоматически | `sudo snap install trivy` — только установка, нет scheduled scan |
| **Qodana** | Устанавливается через curl|bash | `curl ... | bash` — supply chain risk |
| **secrets.env chmod 600** | ★★★★ | Хорошая практика |

---

## 4. Security Scanning — Continuous

### 15-security.sh (16 строк)

```bash
command -v trivy &>/dev/null || sudo snap install trivy ...
command -v qodana &>/dev/null || curl ... | bash ...
```

**Проблемы:**
- **Установка, но не запуск.** Trivy и Qodana устанавливаются, но нигде не запускаются автоматически. Нет scheduled scan.
- **Supply chain.** `curl | bash` для Qodana — классический антипаттерн безопасности.
- **Нет CI-интеграции.** В `.github/workflows/` есть shellcheck и test, но нет Trivy/Qodana scan на каждый PR.
- **Нет pre-commit hook.** Сканирование не встроено в git workflow.

---

## 5. Access Control & Model Governance

### Что есть

| Механизм | Статус |
|----------|--------|
| Per-project `opencode.json` | ✓ — у каждого проекта свой конфиг с провайдерами |
| Provider allowlist/blocklist | ✗ — нет механизма «разрешить только эти провайдеры» |
| Model allowlist/blocklist | ✗ — нет ограничения на уровне модели |
| Per-agent model assignment | ✓ — в 17-project.sh агентам назначаются конкретные модели |
| Isolated circuit (только локальные) | ✓ — глобальный флаг |
| API key per provider | ✓ — secrets.env |

### Чего не хватает для corporate governance

| Механизм | Зачем |
|----------|-------|
| **Provider gate** — `OPENCODE_ALLOWED_PROVIDERS=deepseek,zai,ollama` | Запретить использование несанкционированных провайдеров |
| **Model gate** — `OPENCODE_ALLOWED_MODELS=deepseek-v4-pro,glm-4-flash` | Запретить дорогие/экспериментальные модели |
| **Cost limits** — `OPENCODE_MAX_COST_PER_SESSION=5.00` | Бюджетный контроль |
| **Data residency** — `OPENCODE_DATA_REGIONS=eu,ru` | Запретить провайдеров в нежелательных юрисдикциях |

---

## 6. Оценка зрелости

| Измерение | Оценка | Обоснование |
|-----------|--------|-------------|
| **Air-gap completeness** | 2/5 | LLM изоляция работает, но telemetry, updates, package install — требуют сети |
| **PII protection** | 3/5 | Sanitizer хорош, secrets.env с chmod 600, но ключи в /proc и логи не санитизируются |
| **Audit trail (SOC2)** | 1/5 | WAL append-only (частично), но нет immutability, retention, alerting |
| **Security scanning** | 2/5 | Инструменты устанавливаются, но не запускаются. Нет CI/CD integration |
| **Access control** | 2/5 | Per-project configs есть, но нет provider/model gate и cost limits |

**Итоговая зрелость corporate/air-gap: 2.0/5** — personal use готов, corporate/regulated — требует значительных доработок.

---

## 7. Top-5 находок

| Sev | Находка |
|-----|---------|
| **HIGH** | Air-gap неполный: telemetry не отключается, update checks зависают, Docker pull/npm install недоступны без сети — нельзя развернуть на изолированной машине |
| **HIGH** | Нет audit trail для SOC2: WAL не immutable, нет подписей, нет log retention, нет фиксации tool/model calls |
| **HIGH** | Trivy и Qodana только устанавливаются, но не запускаются автоматически. Нет scheduled scan, нет CI интеграции |
| **MEDIUM** | Sanitizer не фильтрует email, credit card numbers, SSN/passport — для GDPR/HIPAA compliance недостаточно |
| **MEDIUM** | Нет provider/model gate — в corporate контуре нельзя запретить конкретные модели или ограничить бюджет |
