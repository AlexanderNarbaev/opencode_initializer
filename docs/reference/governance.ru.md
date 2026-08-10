# Model Governance

v3.0.0 вводит `model-policy.json` — per-project файл governance, который контролирует разрешённых провайдеров и модели.

## Быстрый старт

```bash
# Показать текущую политику
dev governance show

# Установить корпоративный режим
dev governance policy corporate

# Редактировать вручную
dev config  # открывает setup.conf
```

## Схема policy-файла

`model-policy.json` находится в корне проекта и генерируется модулем `43-governance.sh`:

```json
{
  "version": 1,
  "mode": "allow-all",
  "allowed_providers": [],
  "denied_providers": [],
  "allowed_models": [],
  "denied_models": [],
  "max_cost_per_1m": null,
  "audit": false
}
```

### Поля

| Поле | Тип | Описание |
|------|-----|----------|
| `version` | int | Версия схемы (сейчас 1) |
| `mode` | string | `allow-all`, `allowlist` или `corporate` |
| `allowed_providers` | string[] | Allowlist провайдеров (пустой = все в режиме allow-all) |
| `denied_providers` | string[] | Blocklist провайдеров |
| `allowed_models` | string[] | Allowlist моделей (`"*"` = все модели разрешённых провайдеров) |
| `denied_models` | string[] | Blocklist моделей |
| `max_cost_per_1m` | number | Максимальная стоимость за 1M токенов (null = без лимита) |
| `audit` | bool | Включить аудит (44-audit.sh) |

## Режимы

### allow-all

По умолчанию. Все провайдеры разрешены, без ограничений.

```json
{ "mode": "allow-all", "audit": false }
```

### allowlist

Только явно перечисленные провайдеры разрешены.

```json
{
  "mode": "allowlist",
  "allowed_providers": ["deepseek", "opencode"],
  "allowed_models": [],
  "audit": false
}
```

### corporate

Строгий режим с allowlist + blocklist, лимитами стоимости и включённым аудитом.

```json
{
  "mode": "corporate",
  "allowed_providers": ["deepseek", "opencode", "openai"],
  "denied_providers": ["ollama", "vllm", "sglang"],
  "denied_models": ["*"],
  "max_cost_per_1m": 30.0,
  "audit": true
}
```

## Enforcement

Политика применяется на нескольких уровнях:

1. **18-opencode-json.sh** — фильтрует провайдеров в генерируемом `opencode.json`
2. **pre-session-check.sh** — валидирует политику перед каждой сессией
3. **43-governance.sh** `_provider_allowed()` — проверка во время выполнения при каждом API-вызове
4. **42-hooks.sh** — pre-request hook блокирует запрещённых провайдеров

## Audit Trail

При `"audit": true` каждый вызов модели логируется в `~/.cache/opencode/audit.jsonl`:

```jsonl
{"ts":"2026-08-08T12:00:00Z","event":"model_call","provider":"deepseek","model":"deepseek-v4-pro","tokens_in":1234,"tokens_out":567,"cost":0.0032}
{"ts":"2026-08-08T12:00:05Z","event":"tool_call","tool":"bash","args_hash":"abc123"}
{"ts":"2026-08-08T12:00:10Z","event":"provider_switch","from":"deepseek","to":"zai","reason":"rate_limit"}
{"ts":"2026-08-08T12:00:15Z","event":"pii_redacted","detector":"email","count":3}
```

7 типов событий: `model_call`, `tool_call`, `provider_switch`, `pii_redacted`, `config_change`, `policy_violation`, `session_boundary`.

### Ротация

При превышении `audit.jsonl` 10MB:
- Сжимается в `audit-YYYY-MM-DD.jsonl.gz`
- Архивируется в Qdrant (семантический поиск)
- Новый `audit.jsonl` начинается с чистого листа
- SHA-256 hash-chain связывает последовательные файлы

## Команды

```bash
# Показать текущую политику
dev governance show

# Установить режим политики
dev governance policy allow-all
dev governance policy allowlist
dev governance policy corporate

# Посмотреть аудит-лог
dev audit log
dev audit log --provider deepseek --today

# Статистика аудита
dev audit stats

# Принудительная ротация
dev audit rotate
```

## См. также

- [Профили развёртывания](../guides/deployment-profiles.md) — дефолтные политики по профилям
- [Security & Compliance](security-compliance.md) — PII, hash-chain аудита, SBOM
- [SOC2 Checklist](../compliance/soc2-checklist.md)
- [ISO27001 Mapping](../compliance/iso27001-mapping.md)
