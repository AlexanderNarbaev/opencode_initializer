# Профили развёртывания

v3.0.0 вводит 4 профиля развёртывания с enforced-правилами для разных требований безопасности.

## Конфигурация

Установите профиль в `~/.config/opencode-setup/setup.conf`:

```bash
DEPLOYMENT_PROFILE="personal"   # по умолчанию
```

Или при установке:

```bash
bash setup.sh --full --profile corporate
```

## Справочник профилей

| Профиль | Автообновление | Телеметрия | Provider Allowlist | Аудит | Сеть |
|---------|:--------------:|:----------:|:------------------:|:-----:|:----:|
| **personal** | вкл | вкл | выкл (все разрешены) | выкл | открыта |
| **corporate** | вкл | выкл | вкл (`model-policy.json`) | вкл | ограничена |
| **airgapped** | выкл | выкл | вкл (только локальные) | вкл | нет |
| **hybrid** | вкл (dev) / выкл (CI) | выкл | вкл | вкл | dev открыта, CI ограничена |

### Personal

Полный автомат для рабочей станции разработчика. Все провайдеры разрешены, без аудита, автообновление включено.

```json
{
  "version": 1,
  "mode": "allow-all",
  "allowed_providers": [],
  "denied_providers": [],
  "allowed_models": [],
  "denied_models": [],
  "max_cost_per_1m": null,
  "audit": false,
  "note": "modes: allow-all | allowlist | corporate"
}
```

### Corporate

Командная рабочая станция с governance. Только одобренные провайдеры/модели, полный аудит, PII-санитайзер включён, автообновление по расписанию (weekly).

```json
{
  "version": 1,
  "mode": "corporate",
  "allowed_providers": ["deepseek", "opencode", "openai"],
  "denied_providers": ["ollama", "vllm", "sglang"],
  "allowed_models": [],
  "denied_models": ["*"],
  "max_cost_per_1m": 30.0,
  "audit": true
}
```

### Air-Gapped

Без доступа к сети. Только локальные провайдеры (Ollama, vLLM, SGLang). Все внешние вызовы блокируются на pre-request hook. `ISOLATED_CIRCUIT` блокирует version-check, autoupdate, unattended-upgrades. Supply-chain: только SHA-256 verify.

```json
{
  "version": 1,
  "mode": "allowlist",
  "allowed_providers": ["ollama", "vllm", "sglang"],
  "denied_providers": ["deepseek", "opencode", "openai", "anthropic", "google", "xai", "mistral", "groq", "together", "cohere", "fireworks", "perplexity", "zai", "openrouter", "alibaba", "deepinfra", "mimo", "minimax", "cerebras"],
  "allowed_models": [],
  "denied_models": [],
  "max_cost_per_1m": null,
  "audit": true,
  "note": "air-gapped — без внешних провайдеров"
}
```

### Hybrid

Онлайн-машина разработчика + офлайн CI-пайплайн. `setup.sh --full` для dev, `setup.sh --airgap` для CI. Отдельный `model-policy.json` на каждое окружение.

## ISOLATED_CIRCUIT Gate'ы

При `ISOLATED_CIRCUIT=true`:

- `version-check.sh` — пропускается (нет сети)
- `20-autoupdate.sh` — topgrade + unattended-upgrades отключены
- `00-core.sh: _set_dns()` — соблюдает флаг `DRY_RUN`

## Supply-Chain Hardening

Все `curl|sh` заменены на `_download_verify()`:

```bash
_download_verify "https://example.com/tool.sh" "tool.sh" "expected_sha256"
```

Скачивание с ретраем, проверка SHA-256, жёсткий fail при несовпадении.

## См. также

- [Model Governance](../reference/governance.md) — схема политик и enforcement
- [Air-Gap & Offline](airgap-offline.md) — `dev bundle` и офлайн-установка
- [Security & Compliance](../reference/security-compliance.md) — аудит, PII, SBOM
- [SOC2 Checklist](../compliance/soc2-checklist.md) — CC5.2/CC7.2/CC8.2 маппинг
