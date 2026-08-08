# Аудит: Provider / Model Layer — абстракция провайдеров, fallback chains, isolated circuit, access control

> **Файлы:** 26-providers.sh (93 строки), 36-model-router.sh (218 строк), 32-isolated.sh (102 строки), 16-llm.sh, 11-opencode.sh, scripts/ai-router.sh, scripts/provider-check.sh, scripts/embed-proxy.py
> **Дата:** 2026-08-08 | **Аудитор:** Worker

---

## 1. Provider Abstraction

### Текущее состояние
- **22 провайдера**: 19 cloud + 3 local (Ollama, vLLM, SGLang)
- Единый интерфейс: `PROVIDER_REGISTRY[name]="API_KEY_ENV|--cli-flag|description|free_tier"` (26-providers.sh:44)
- Конфигурация генерируется в `opencode.json` модулем 18-opencode-json.sh (Python inline)
- Поддержка native и openai-compatible SDK (помечено в AGENTS.md)

### Сильные стороны
- **Единый формат регистра**: `declare -A PROVIDER_REGISTRY` — все провайдеры описываются одной структурой (26-providers.sh:43-62)
- **Авто-конфигурация**: 18-opencode-json.sh генерирует `opencode.json` с baseURL, apiKey, model списком для всех провайдеров
- **Isolated Circuit — чистый switch**: при `ISOLATED_CIRCUIT=true` registry переопределяется на 3 локальных провайдера (26-providers.sh:10-18)

### Слабости
| Severity | Проблема | Файл:строка |
|----------|----------|-------------|
| **MEDIUM** | **provider-check.sh использует RAW curl** без `_curl()` — специально для портативности, но теряет retry/cache/timeout логику helpers.sh | scripts/provider-check.sh:4 |
| **MEDIUM** | **embed-proxy.py hardcoded** Ollama URL + модель `mxbai-embed-large` — нет конфигурации через переменные окружения, нельзя переключить на vLLM/SGLang embeddings | scripts/embed-proxy.py:6,18 |
| **LOW** | **ai-router.sh жёстко зашит** `ORCHESTRATOR="$HOME/Projects/.opencode-orchestrator.json"` — не portable | scripts/ai-router.sh:6 |

---

## 2. Fallback Chains

### Текущее состояние
- **opencode.json fallback chain**: `deepseek → zai → opencode → xai → minimax` (AGENTS.md)
- **Model router fallback**: 8 профилей имеют свои цепочки (36-model-router.sh:23-24)
- **z.ai → deepseek → opencode**: обратная цепочка для RU/CN рынка

### Сильные стороны
- **Многоуровневый fallback**: провайдер-уровень (opencode.json) + модель-уровень (model-router)
- **Free tier aware**: бюджетный профиль использует z.ai GLM-5.2 (free)

### Слабости
| Severity | Проблема | Файл:строка |
|----------|----------|-------------|
| **HIGH** | **Fallback НЕ тестируется**: нет интеграционных тестов на failover цепочки. Circuit breaker, retry logic, таймауты — не проверены в CI | — |
| **MEDIUM** | **Нет fallback для embedding-прокси**: если Ollama недоступен, embed-proxy.py просто упадёт — нет fallback на другие embedding-модели | scripts/embed-proxy.py |
| **MEDIUM** | **Model router статичен**: 8 профилей с hardcoded моделями. При добавлении новых моделей (например, новый провайдер) нужно редактировать JSON вручную | 36-model-router.sh:17-60 |

---

## 3. Isolated Circuit — честность изоляции

### Сильные стороны
- **Провайдеры отключаются полностью**: `ISOLATED_CIRCUIT=true` → registry = только Ollama/vLLM/SGLang (26-providers.sh:10-38)
- **Auto-detection локальных бекендов**: проверка `curl localhost:$port/v1/models` для каждого (26-providers.sh:28)
- **CLI управление**: `dev isolated on|off|status`

### Слабости
| Severity | Проблема | Файл:строка |
|----------|----------|-------------|
| **CRITICAL** | **Утечки при изоляции**: telemetry (OpenCode CLI health pings), version checks (version-check.sh), autoupdate (20-autoupdate.sh systemd timer) — НЕ отключаются при ISOLATED_CIRCUIT. Внешние DNS-запросы всё ещё возможны | 32-isolated.sh, 20-autoupdate.sh |
| **HIGH** | **MCP серверы не фильтруются**: при изоляции внешние MCP (websearch, GitHub, GitLab) остаются в конфиге — модель может попытаться их вызвать и получить network error, а не явный отказ | 18-opencode-json.sh |
| **MEDIUM** | **Нет проверки egress**: не проверяется, что ВООБЩЕ нет исходящих соединений кроме localhost — нет firewall rules/nftables как часть isolated mode | 32-isolated.sh |

---

## 4. Access Control — model allowlist/blocklist

### Текущее состояние
- **НЕТ per-project allowlist**: любой пользователь с ключом может вызвать любую модель
- **НЕТ per-user rate limiting**: нет quotas per model per user
- **НЕТ model governance policy**: администратор не может запретить модели на уровне проекта

### Gap-анализ
| Возможность | Статус | Комментарий |
|-------------|--------|-------------|
| Per-project model allowlist | 🔴 Отсутствует | Не реализовано ни в opencode.json, ни в MCP gateway |
| Per-user quotas | 🔴 Отсутствует | — |
| Cost tracking per model per project | 🟡 Частично | model-router имеет cost table, но без enforcement |
| Admin policy file | 🔴 Отсутствует | — |
| Model version pinning | 🟡 Частично | opencode.json фиксирует model ID, но нет «только эта версия» |

---

## 5. Общая оценка зрелости: 6/10

| Измерение | Оценка | Комментарий |
|-----------|--------|-------------|
| Provider abstraction | 8/10 | Единый интерфейс, 22 провайдера, авто-конфигурация |
| Fallback chains | 6/10 | Многоуровневый fallback, но не тестируется |
| Isolated circuit | 5/10 | Хороший старт, но неполная изоляция (утечки) |
| Access control | 1/10 | Полностью отсутствует |

### Top-3 приоритетных улучшений для v3.0
1. **Полная изоляция air-gap**: `ISOLATED_CIRCUIT=true` → отключение telemetry + update checks + version checks + MCP filtering + egress firewall rules (P0)
2. **Per-project model governance**: `opencode.json` → `models.allow`/`models.deny` + admin policy file (P0)
3. **Fallback integration tests**: CI-тесты на failover цепочек с мок-провайдерами (P1)
