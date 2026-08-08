# Corporate / Air-Gap Profile Spec — v3.0

> **Синтез:** M1 audit (T1.5 air-gap) + ai-native-infra + competitive matrix | **Дата:** 2026-08-08
> **Цель:** Спроектировать корпоративный профиль для air-gapped/regulated сред
> **Предыдущая версия:** 227 строк (фоновый Planner) | **Дополнено:** key rotation, SBOM, supply-chain, integration map

---

## 1. Deployment Profiles

### 1.1 Четыре профиля
| Профиль | Описание | Cloud LLM | Local LLM | Audit | PII Sanitizer |
|---------|----------|:---------:|:---------:|:-----:|:-------------:|
| **personal** | Энтузиаст, открытый интернет | ✅ 22 провайдера | ✅ опционально | ❌ | ❌ |
| **corporate** | Компания, compliance | ⚠️ allowlist | ✅ | ✅ basic | ✅ |
| **airgapped** | Полная изоляция | ❌ | ✅ (Ollama/vLLM/SGLang) | ✅ full | ✅ |
| **hybrid** | Corporate + selective cloud | ⚠️ allowlist (audited) | ✅ | ✅ full | ✅ |

### 1.2 Переключение профиля
```bash
# При первом запуске:
bash setup.sh --profile corporate

# Смена профиля:
dev profile set airgapped
dev profile status
```

### 1.3 Поведенческие gate'ы по профилю

| Модуль | personal | corporate | airgapped | hybrid |
|--------|:--------:|:---------:|:---------:|:------:|
| 20-autoupdate (topgrade) | ✅ | ⚠️ security-only | ❌ | ⚠️ security-only |
| version-check (GitHub API) | ✅ | ⚠️ cached | ❌ | ⚠️ cached |
| pre-session-check (cloud) | ✅ 15 провайдеров | ⚠️ allowlist | ❌ cloud, ✅ local | ⚠️ allowlist |
| 40-best-practices (git clone) | ✅ | ❌ (use cache) | ❌ | ❌ (use cache) |
| helpers::_curl() | ✅ | ⚠️ allowlist domains | ❌ (cache-only) | ⚠️ allowlist |
| 26-providers (cloud register) | ✅ all | ⚠️ allowlist | ❌ | ⚠️ allowlist |
| Telemetry (Ollama analytics, health pings) | ✅ | ❌ | ❌ | ❌ |
| Autoupdate systemd timer | ✅ | ❌ | ❌ | ❌ |

---

## 2. Model Access Control

### 2.1 Model Allowlist/Blocklist
```json
// opencode.json → provider.{name}.access
{
  "provider": {
    "deepseek": {
      "access": {
        "mode": "allowlist",
        "models": ["deepseek-v4-pro", "deepseek-v4-flash"],
        "max_tokens_per_request": 64000,
        "max_requests_per_hour": 100
      }
    },
    "openai": {
      "access": {
        "mode": "blocklist",
        "models": ["*"],
        "reason": "Corporate policy: no external US-hosted models"
      }
    },
    "ollama": {
      "access": {
        "mode": "allowlist",
        "models": ["qwen3:14b", "gemma3:12b", "llama4:latest"],
        "max_tokens_per_request": 32000
      }
    }
  }
}
```

### 2.2 Policy Enforcement Points

| Точка | Механизм |
|-------|----------|
| **opencode.json load** | `41-model-gateway.sh` валидирует access rules при старте |
| **Model switch request** | Gateway перехватывает `/model X` и проверяет allowlist |
| **Provider fallback** | Fallback НЕ должен обходить blocklist (circuit breaker с policy-awareness) |
| **Pre-session check** | `dev doctor` проверяет что все доступные провайдеры — в allowlist |
| **Pre-request hook** | `46-hooks.sh` → `hooks/before-model-request.sh` — валидация перед каждым вызовом |
| **Cost limit** | `OPENCODE_MAX_COST_PER_SESSION=5.00` — счётчик токенов × цены, блокировка при превышении |
| **Data residency** | `OPENCODE_DATA_REGIONS=eu,ru` — запрет провайдеров вне указанных юрисдикций |

---

## 3. PII Sanitization

### 3.1 Sanitizer Proxy (расширение 24-websearch.sh)
```
User Prompt → [SANITIZER] → LLM API
                           ↓
                    Detect + Mask:
                    - Email addresses
                    - Phone numbers  
                    - Credit card numbers (Luhn)
                    - SSN / passport numbers
                    - IP addresses (internal)
                    - API keys / tokens (Bearer, sk-, api-)
                    - Internal hostnames (*.corp.internal, *.intranet.local)
                    - JWT tokens (eyJ... pattern)
```

### 3.2 Новые PII-паттерны (sanitizer-rules.conf)
```ini
[pii_patterns]
# Email
[\w\.\-]+@[\w\-]+\.[\w\.\-]+
# Phone (international)
\+?[\d\s\-\(\)]{7,20}
# Credit card (Luhn-validated)
\b(?:\d[ -]*?){13,16}\b
# SSN (US)
\b\d{3}-\d{2}-\d{4}\b
# IBAN
\b[A-Z]{2}\d{2}[A-Z0-9]{1,30}\b
# JWT tokens
\beyJ[A-Za-z0-9\-_]+\.eyJ[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+
```

### 3.3 Sanitization Modes
| Mode | Описание | Use Case |
|------|----------|----------|
| `redact` | Заменяет на `[REDACTED]` | Production логи |
| `pseudonymize` | Заменяет на `user_<hash>` | Аналитика |
| `passthrough` | Пропускает без изменений | Development |

---

## 4. Audit Trail (SOC2/ISO27001)

### 4.1 Audit Log Schema (JSONL, append-only, tamper-evident)
```jsonl
{"seq":1,"ts":"2026-08-08T14:00:00Z","event":"model.request","actor":"agent:developer","model":"deepseek/deepseek-v4-pro","prompt_hash":"sha256:abc123","token_count":1420,"prev_hash":null,"hash":"sha256:def456"}
{"seq":2,"ts":"2026-08-08T14:00:05Z","event":"model.response","actor":"agent:developer","model":"deepseek/deepseek-v4-pro","response_hash":"sha256:ghi789","token_count":380,"prev_hash":"sha256:def456","hash":"sha256:jkl012"}
```

### 4.2 События аудита
| Event | Поля | Retention |
|-------|------|:---------:|
| `model.request` | actor, model, prompt_hash, token_count | 90 дней |
| `model.response` | actor, model, response_hash, token_count | 90 дней |
| `model.fallback` | actor, from_model, to_model, reason | 90 дней |
| `tool.call` | actor, tool, args_hash, result_hash | 90 дней |
| `file.access` | actor, file_path, operation | 365 дней |
| `auth.change` | actor, change_type | 365 дней |
| `config.change` | actor, key, old_hash, new_hash | Бессрочно |
| `provider.block` | blocked_provider, blocked_model, reason | 365 дней |

### 4.3 Tamper Evidence
- Каждая запись содержит `hash` = SHA-256(content + prev_hash)
- `prev_hash` = хэш предыдущей записи → непрерывная цепочка
- Верификация: `dev audit verify` — проверяет всю цепочку
- GPG signing (corporate/airgap): каждая запись имеет `.sig` detached signature

### 4.4 SOC2 Mapping
| SOC2 Criteria | Наш механизм |
|---------------|-------------|
| CC6.1 (Logical Access) | Model allowlist + provider gate |
| CC6.6 (External Threats) | Prompt injection protection, PII sanitizer |
| CC7.2 (Monitoring) | Audit log + observability signals |
| CC7.3 (Security Incidents) | Audit trail с tamper evidence |
| CC8.1 (Change Management) | Constitution.md enforcement |

---

## 5. Air-Gap Completeness

### 5.1 `_is_isolated()` / `_is_corporate()` — единые gate'ы
```bash
# helpers.sh
_is_isolated() {
  [ "${ISOLATED_CIRCUIT:-false}" = "true" ] || [ "${DEPLOYMENT_PROFILE:-}" = "airgapped" ]
}

_is_corporate() {
  [ "${DEPLOYMENT_PROFILE:-}" = "corporate" ] || [ "${DEPLOYMENT_PROFILE:-}" = "hybrid" ]
}
```

### 5.2 Модули, требующие gate:
| Модуль | Текущее поведение | v3.0 поведение |
|--------|-------------------|----------------|
| `20-autoupdate.sh` | topgrade всегда | `_is_isolated && skip` |
| `version-check.sh` | curl GitHub API | `_is_isolated && use cache` |
| `pre-session-check.sh` | 15 cloud curls | `_is_isolated && skip cloud, keep local` |
| `40-best-practices.sh` | git clone GitHub | `_is_isolated && use local cache` |
| `helpers::_curl()` | network always | `_is_isolated && cache-only` |
| `scripts/provider-check.sh` | cloud pings | `_is_isolated && skip` |
| Ollama analytics | `OLLAMA_NOPRUNE` default | `_is_isolated && OLLAMA_NOPRUNE=true OLLAMA_NUM_PARALLEL=1` |

---

## 6. Key Rotation & Secrets Management

### 6.1 Key Rotation Policy
| Key Type | Rotation Period | Detection | Automation |
|----------|:--------------:|-----------|------------|
| Cloud API Keys (DeepSeek, OpenAI, etc.) | 90 дней | `dev doctor` предупреждает за 7 дней | Ручная (через кабинет провайдера) |
| Local Service Passwords (Qdrant, Redis, Grafana) | 180 дней | `dev health` проверяет age | `dev secrets rotate` — авто-генерация |
| WAL Signing Key (GPG) | 365 дней | `dev audit verify` проверяет expiry | `dev secrets rotate-wal-key` |
| SSH Keys (Git remotes) | 365 дней | `ssh-keygen -lf` проверяет fingerprint | Ручная |

### 6.2 Auto-Generated Secrets
```bash
# При первом install (30-infra.sh, 34-observability.sh):
QDRANT_API_KEY=$(openssl rand -hex 32)         # → secrets.env
REDIS_PASSWORD=$(openssl rand -hex 16)          # → secrets.env
GRAFANA_ADMIN_PASSWORD=$(openssl rand -hex 16)  # → secrets.env
POSTGRES_PASSWORD=$(openssl rand -hex 24)       # → secrets.env
```

### 6.3 GPG Signing for WAL (corporate/airgap)
```bash
# При install с --profile corporate:
gpg --quick-gen-key "opencode-audit@localhost" rsa4096 sign,cert 1y
# WAL записи подписываются:
echo "$record" | gpg --sign --armor --detach-sign >> audit.jsonl.sig
# Верификация: dev audit verify
```

---

## 7. Compliance Checklist

### 7.1 При `dev install --profile corporate`:
- [ ] Model allowlist сконфигурирован (нет open external providers)
- [ ] PII sanitizer включён в режиме `redact`
- [ ] Audit log включён, пишет в `~/.cache/opencode/audit.jsonl`
- [ ] WAL agent — `chmod 600`
- [ ] secrets.env — `chmod 600`, проверен на отсутствие в git
- [ ] GPG key for WAL signing — сгенерирован
- [ ] Trivy scan при PR (CI gate)
- [ ] Qodana code quality (CI gate)

### 7.2 При `dev install --profile airgapped`:
- [ ] ISOLATED_CIRCUIT=true во всех конфигах
- [ ] Все cloud-провайдеры отключены
- [ ] version-check не делает network calls
- [ ] autoupdate отключён
- [ ] Ollama analytics отключены (`OLLAMA_NOPRUNE=true`)
- [ ] Все внешние URLs заменены на local mirrors (если доступны)
- [ ] Pre-session check только для local backends

### 7.3 ISO27001 Controls Mapping
| Control | Requirement | Status | Gap |
|---------|------------|:------:|-----|
| A.9.1 | Access control policy | ✅ | Provider gate + allowlist |
| A.9.4.2 | Secure log-on | ⚠️ | Нет MFA на локальные сервисы (Qdrant, Redis, Grafana) |
| A.12.4 | Event logging | ✅ | WAL + audit.jsonl + hash chain |
| A.12.6 | Vulnerability management | ✅ | Trivy + Qodana + SBOM |
| A.14.2 | Secure development | ✅ | SDD workflow (T3.3) |
| A.17.1 | Business continuity | ⚠️ | Нет документированной backup-стратегии |

### 7.4 GDPR Article 32 (Security of Processing)
| Requirement | Status | Gap |
|-------------|:------:|-----|
| Pseudonymisation | ✅ | Sanitizer `pseudonymize` mode |
| Encryption at rest | ⚠️ | secrets.env chmod 600, но WAL не зашифрован |
| Restoration after incident | ⚠️ | `dev backup` exists, но не tested |
| Regular testing | ✅ | Test suite (37 файлов, 480+ assertions) |

---

## 8. SBOM & Supply Chain Verification

### 8.1 SBOM Generation (CycloneDX)
```bash
# При install (corporate/airgap):
dev sbom generate  # → .opencode/sbom/cyclonedx.json
# Состав: npm packages, pip packages, Go binaries, Docker images, system packages
```

### 8.2 Supply Chain Gates (замена `curl | bash`)
| Current Anti-Pattern | v3.0 Fix | Severity |
|----------------------|----------|:--------:|
| `curl ... \| bash` — Qodana (15-security.sh) | `_curl → verify SHA256 → extract → install` | **HIGH** |
| `curl ... \| sh` — Rust (09-rust.sh) | `rustup-init` с SHA256 check | MEDIUM |
| `curl ... \| bash` — Oh My Zsh (04-zsh.sh) | `git clone` + GPG verify tag | LOW |
| `npm install -g` — MCP (12-mcp-lsp.sh) | `npm pack` + `npm audit` gate | MEDIUM |
| `pip install` — RAG (21-rag.sh) | `pip install --require-hashes` | MEDIUM |
| `git clone` без verify (14-shokunin.sh) | `git verify-commit HEAD` | LOW |

### 8.3 `_verify_checksum()` helper
```bash
_verify_checksum() {
  local file="$1" expected="$2" algo="${3:-sha256}"
  local actual
  actual=$("${algo}sum" "$file" 2>/dev/null | cut -d' ' -f1)
  [ "$actual" = "$expected" ] || { echo "CHECKSUM MISMATCH: $file" >&2; return 1; }
}
```

### 8.4 CI Security Workflow
```yaml
# .github/workflows/security.yml (новый)
- name: SBOM
  run: dev sbom generate --ci
- name: Vulnerability Scan
  run: trivy fs --severity HIGH,CRITICAL --sbom .opencode/sbom/cyclonedx.json .
- name: Dependency Audit
  run: npm audit --audit-level=high && pip-audit
```

---

## 9. Integration Map: Какие модули менять

| Модуль | Тек. строк | Изменения | Нов. строк |
|--------|:---:|-----------|:---:|
| **32-isolated.sh** | 102 | `_is_isolated()` gate, `NO_TELEMETRY`, disable Ollama analytics, skip update checks/autoupdate | ~150 |
| **26-providers.sh** | 93 | Allowlist/blocklist (`OPENCODE_ALLOWED_PROVIDERS`), `_is_isolated` gate, provider health check | ~130 |
| **37-wal.sh** | 62 | JSONL audit schema (seq, hash chain, event types), GPG signing, `_wal_sanitize()`, FR traceability, log rotation | ~120 |
| **18-opencode-json.sh** | 820 | Access rules в `provider.{name}.access`, `OPENCODE_NO_TELEMETRY`, cost limits, data residency | ~850 |
| **15-security.sh** | 16 | Trivy scheduled scan, Qodana SHA256 verify, SBOM trigger, `dev security scan` | ~80 |
| **24-websearch.sh** | 444 | PII patterns (email, phone, CC, SSN, JWT), sanitization modes (redact/pseudonymize), `PII_SANITIZER_MODE` | ~480 |
| **00-core.sh** | ~200 | `DEPLOYMENT_PROFILE` env, `_is_isolated()` + `_is_corporate()` helpers | ~220 |
| **20-autoupdate.sh** | ~40 | `_is_isolated` gate → skip, corporate → security-only mode | ~50 |
| **version-check.sh** | ~30 | `_is_isolated` gate → cache-only, corporate → cached | ~40 |
| **helpers.sh** | ~100 | `_is_isolated()`, `_is_corporate()`, `_verify_checksum()`, `_wal_sanitize()`, `_audit_event()` | ~140 |
| **30-infra.sh** | ~300 | `network_mode: host` → bridge, auto-generate passwords → secrets.env, Qdrant API key | ~330 |
| **34-observability.sh** | ~60 | Gate node_exporter behind `DEPLOYMENT_PROFILE`, docker0 IP fix | ~80 |
| **NEW: 41-model-gateway.sh** | — | Provider/model access control, rate limiting, circuit breaker, cost tracking | ~150 |
| **NEW: 42-pii-sanitizer.sh** | — | PII detection regex engine (Presidio-lite), redact/pseudonymize/passthrough | ~120 |
| **NEW: 43-audit-log.sh** | — | Structured JSONL audit trail, hash chain, GPG signing, log rotation, retention | ~130 |
| **NEW: 44-compliance.sh** | — | SOC2/ISO27001 evidence collection, `dev compliance report`, checklist validation | ~100 |
| **NEW: 45-sbom.sh** | — | CycloneDX SBOM (npm/pip/go/docker/apt), dependency audit, supply chain gates | ~100 |
| **NEW: 46-hooks.sh** | — | Lifecycle hooks: before/after tool exec, before-model-request (PII gate), on-error | ~120 |
| **.github/workflows/security.yml** | — | Trivy + SBOM + npm-audit + pip-audit + shellcheck + grep-P gate | ~60 |

**Итого:** 12 модулей изменены (+342 строки), 6 новых модулей (+720 строк), 1 новый CI workflow.

---

## 10. Миграция v2.0.3 → v3.0

| Фаза | Scope | Estimate |
|:-----|-------|:--------:|
| **Security Gate** | `_is_isolated()` gate → 32-isolated, 20-autoupdate, version-check, pre-session-check, helpers | 2h |
| **Access Control** | Model allowlist/blocklist → 26-providers, 41-model-gateway, 18-opencode-json | 3h |
| **PII Sanitizer** | Расширение 24-websearch PII-паттернов, 42-pii-sanitizer, режимы redact/pseudonymize | 3h |
| **Audit Trail** | 37-wal JSONL schema, hash chain, GPG signing, 43-audit-log, log rotation | 4h |
| **SBOM + Supply Chain** | 45-sbom, `_verify_checksum()`, SHA256 вместо `curl\|bash`, CI security workflow | 3h |
| **Key Rotation + Secrets** | Auto-generate passwords, GPG key gen, `dev secrets rotate` | 2h |
| **Hooks + Compliance** | 46-hooks (pre-request PII gate), 44-compliance, SOC2/ISO27001 evidence | 2h |
| **Integration + Tests** | End-to-end тесты corporate/airgap профилей, smoke-тесты fallback chains | 3h |
| **Всего** | | **~22h** |
