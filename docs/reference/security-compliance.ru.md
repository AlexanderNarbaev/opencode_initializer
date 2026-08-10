# Безопасность и комплаенс

v3.0.0 добавляет PII-санитайзер, аудит с SHA-256 hash-chain, hardening цепочки поставок и документацию по комплаенсу.

## PII Sanitizer (45-pii-guard.sh)

9 детекторов срабатывают перед каждым LLM-запросом:

| Детектор | Паттерн | Пример |
|----------|---------|--------|
| Email | `user@domain.tld` | `john@example.com` |
| Телефон (RU) | `+7 \d{10}` | `+7 999 123-45-67` |
| ИНН | `\d{10}\|\d{12}` | `7707083893` |
| СНИЛС | `\d{3}-\d{3}-\d{3} \d{2}` | `123-456-789 01` |
| Паспорт (RU) | `\d{4} \d{6}` | `4510 123456` |
| Банковская карта | `\d{13,19}` (проверка Луна) | `4111 1111 1111 1111` |
| IP-адрес | `\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}` | `192.168.1.1` |
| API-ключ | `sk-[a-zA-Z0-9]{32,}` | `sk-abc123...` |
| Пароль в коде | `password\s*=\s*['\"]` | `password = "secret"` |

### Использование

```bash
# Сканировать файл
dev pii scan ~/projects/myapp/src/main.py

# Сканировать с редкацией
dev pii scan --redact ~/projects/myapp/src/main.py

# Отдельный Python-скрипт
python3 scripts/pii-guard.py scan file.txt
python3 scripts/pii-guard.py scan --redact file.txt
```

Редкация заменяет найденные значения на `[REDACTED:email]`, `[REDACTED:phone]` и т.д.

## Аудит (44-audit.sh)

### Типы событий

| Событие | Триггер |
|---------|---------|
| `model_call` | Каждый вызов LLM API |
| `tool_call` | Каждый вызов инструмента |
| `provider_switch` | Автоматический fallback или ручное переключение |
| `pii_redacted` | Сработал PII-детектор |
| `config_change` | Изменён `model-policy.json` или `opencode.json` |
| `policy_violation` | Заблокирован доступ к провайдеру/модели |
| `session_boundary` | Начало/конец сессии |

### Hash-Chain

Каждая запись аудита содержит `prev_hash`, связывающий с предыдущей:

```jsonl
{"ts":"...","event":"model_call","prev_hash":"000000...","hash":"abc123..."}
{"ts":"...","event":"tool_call","prev_hash":"abc123...","hash":"def456..."}
```

Подделка любой записи делает всю цепочку невалидной.

### Ротация

```bash
# Автоматически: >10MB → сжатие + архивация
# Вручную:
dev audit rotate
```

Файлы после ротации: `audit-2026-08-08.jsonl.gz` архивируются в Qdrant для семантического поиска.

## Hardening цепочки поставок

Все `curl|sh` заменены:

| Было | Стало |
|------|-------|
| `curl ... \| bash` | `_download_verify url file sha256 && bash file` |
| `curl ... \| sh` | `_download_verify url file sha256 && sh file` |
| `wget ... -O - \| bash` | `_download_verify url file sha256 && bash file` |

`_download_verify()` (helpers.sh):
- Скачивает с 5 ретраями (exponential backoff)
- Проверяет SHA-256 с ожидаемым значением
- Жёсткий fail при несовпадении
- Соблюдает флаг `DRY_RUN`

## SBOM (Software Bill of Materials)

Формат CycloneDX, генерируется по требованию:

```bash
dev bundle create --sbom /path/to/sbom.json
```

Включает все зависимости: npm-пакеты, Go-модули, Python-пакеты, Docker-образы.

## Сканирование безопасности

```bash
# Trivy — сканер уязвимостей контейнеров
trivy fs --scanners vuln,secret,misconfig /path/to/project

# Qodana — анализ качества кода
qodana scan --project-dir /path/to/project

# CI-интеграция (.github/workflows/security.yml)
# Запускается на push/schedule, блокирует на CRITICAL/HIGH
```

## Документация по комплаенсу

- [SOC2 Checklist](../compliance/soc2-checklist.md) — CC5.2 (allowlist провайдеров), CC7.2 (WAL мониторинг), CC8.2 (аудит)
- [ISO27001 Mapping](../compliance/iso27001-mapping.md) — A.9 (контроль доступа), A.12 (безопасность операций), A.14 (приобретение систем), A.18 (комплаенс)

## См. также

- [Model Governance](governance.md) — схема `model-policy.json`
- [Профили развёртывания](../guides/deployment-profiles.md) — безопасность по профилям
- [Air-Gap & Offline](../guides/airgap-offline.md) — режим isolated circuit
