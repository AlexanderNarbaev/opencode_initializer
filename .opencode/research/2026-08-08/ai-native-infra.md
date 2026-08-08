# Дайджест: AI-Native Infrastructure — паттерны для opencode_initializer

> **Источники:** Jimmy Song «AI Native Infrastructure» (jimmysong.io/book/ai-native-infra/, Jan 2026),
> System Design Space (system-design.space, разделы AI Engineering + ML Engineering),
> jimmysong.io/blog (посты мая–июля 2026)
> **Дата:** 2026-08-08 | **Автор:** Planner (T2.4)

---

## 1. Три принципа AI-Native инфраструктуры (Jimmy Song)

Книга формулирует три «конституционных допущения», радикально отличающих AI-native от cloud-native:

| Принцип | Суть | Следствие для инфры |
|---------|------|---------------------|
| **Model-as-Actor** | Модели/агенты — не пассивные API, а «субъекты исполнения» | Инфра должна отслеживать *поведение*, а не только latency/errors |
| **Compute-as-Scarcity** | GPU/токены — жёсткий дефицитный ресурс, не эластичный как CPU | Планирование мощностей, квоты, изоляция — first-class citizens |
| **Uncertainty-by-Default** | Поведение и потребление ресурсов агентом стохастично | Governance loop обязателен; без него cost/risk «убегают» |

**Вывод для нас:** opencode_initializer уже частично реализует Model-as-Actor (через AGENTS.md, WAL, ролевую матрицу), но Compute-as-Scarcity и Uncertainty-by-Default не отражены в текущих модулях — это главный gap.

---

## 2. Архитектура «Three Planes + One Loop»

Центральная модель из книги — три плоскости + замкнутый контур управления:

```
[Intent Plane]        API, MCP, Agent workflows, policy expressions
       ↓
[Execution Plane]     Training, inference, serving, runtime, tool calls
       ↓
[Governance Plane]    Quotas, budgets, isolation/sharing, SLO, cost, risk
       ←———— closed loop (metering → enforcement → feedback) ————
```

**Пять слоёв (детализация):**
- **L5 Business Interface** — SLA, продукт, бизнес-цели
- **L4 Intent/Orchestration** — MCP/Agent, каталоги инструментов, политики (это наш 12-mcp-lsp.sh, 36-model-router.sh)
- **L3 Execution/Runtime** — serving, batching, routing, caching (наш 16-llm.sh, 32-isolated.sh)
- **L2 Context/State** — KV-cache, контекст, память агента как инфраструктурный слой (наш 21-rag.sh, 37-wal.sh, MemoryLayer)
- **L1 Compute/Governance** — квоты, изоляция, топология, учёт (у нас НЕТ — gap)

**Ключевой тезис книги:** «MCP/Agent может выражать намерение, но AI-native начинается там, где намерение превращается в управляемый план исполнения с измеряемыми, ограничиваемыми ресурсными последствиями.»

---

## 3. LLM Gateway / Model Routing — что мы упускаем

### Что есть у нас (module 36-model-router.sh)
- 8 профилей маршрутизации (coding, reasoning, fast, agentic, budget, vision, isolated, ru_cn)
- Таблица стоимости моделей
- Базовые рекомендации

### Что рекомендуют источники

**system-design.space «Стоимость и маршрутизация LLM»:**
- **Каскады моделей**: запрос → cheap model → если неуверен → дорогая модель
- **Семантическое кэширование**: одинаковые/похожие запросы не ходят в модель
- **LLM Gateway** как единая точка: rate limiting, retry, circuit breaker, fallback
- **Token reduction**: сжатие контекста перед отправкой

**Jimmy Song «8-Layer Observability Stack» (Jun 2026):**
- 8 слоёв наблюдаемости: GPU hardware → K8s scheduling → inference engine → token cost
- Наблюдаемость должна покрывать всю вертикаль, иначе невозможна атрибуция затрат

**Gap-анализ для 36-model-router.sh:**
- [ ] Каскады (cheap→expensive fallback) — не реализованы
- [ ] Семантическое кэширование — не реализовано
- [ ] LLM Gateway как архитектурный паттерн (единая точка входа с rate limiting/circuit breaker) — не реализован, вместо этого каждый провайдер напрямую
- [ ] Метрики стоимости в реальном времени (bandwidth/rate limiting по бюджету) — не реализованы

---

## 4. Observability — 8 слоёв и три сигнала

### Jimmy Song: 8-Layer Observability Stack
1. GPU hardware (температура, питание, память, ECC)
2. GPU driver / CUDA
3. Kubernetes scheduling (GPU allocation, topology)
4. Container runtime
5. Inference engine (vLLM/SGLang metrics)
6. Model serving (TTFT, TPOT, throughput)
7. Application (prompt/response, tool calls)
8. Token cost & business metrics

### AI-native infra book: три новых класса сигналов
- **Behavior Signals**: какие инструменты вызвала модель, что прочитала/записала, какие side effects
- **Cost Signals**: токены, GPU-время, cache hits, queue wait, interconnect bottlenecks
- **Quality/Safety Signals**: качество ответа, violation risks, частота откатов

### Gap-анализ для 34-observability.sh
- [ ] Поведенческие сигналы (tool calls tracing) — не покрыто (сейчас только Grafana/Prometheus для системных метрик)
- [ ] Cost signals — не интегрированы с 36-model-router (стоимость запроса не метрится)
- [ ] 8-слойная модель — покрыты только уровни 3–4 (системные метрики), нет GPU-level и token-level

---

## 5. Guardrails & Security — что рекомендует индустрия

### system-design.space «Защитные ограничения LLM»:
- **Prompt injection prevention**: санитизация пользовательского ввода, разделение system/user промптов
- **Tool abuse protection**: whitelist инструментов, подтверждение опасных действий, лимиты на вызовы
- **Response verification**: проверка вывода моделью-критиком, constraint checking
- **Policy control**: правила на уровне gateway (не модель)
- **Safe degradation**: при нарушении — не падать, а деградировать с объяснением

### AI-native infra book: Risk Governance Framework
- **System-Level Trustworthiness Goals**: безопасность, прозрачность, объяснимость, подотчётность
- **Frontier Capability Readiness**: tiered assessment высокорисковых возможностей, launch thresholds
- **Budget-triggered policies**: превышение бюджета → rate limiting/degradation; повышение риска → stricter verification

### Gap-анализ для 15-security.sh + 24-websearch.sh
- [ ] Prompt injection protection — не реализовано (24-websearch sanitizer защищает только от PII/внутренних хостов)
- [ ] Tool abuse prevention — частично (MCP конфиг), но нет gateway-level политик
- [ ] Budget-triggered security escalation — не реализовано
- [ ] Response verification / output guardrails — не реализовано

---

## 6. Enterprise / Air-Gapped — паттерны

### AI-native infra «Migration Roadmap»:
- **AI Landing Zone**: networking baseline, identity, policies, auditing, quota/budget — единый «периметр» для AI-нагрузок
- **Domain-Isolated Platform**: multi-tenant с изоляцией на уровне GPU pool, квот, сетей
- **Platform vs Workload contract**: платформа даёт governance (квоты, учёт, изоляция), команды — model selection, prompt/agent logic

### 90-Day план:
| Фаза | Дни | Что строим |
|------|-----|-----------|
| Ledger | 0–30 | Атрибуция затрат (команда/проект/модель/use-case), бюджеты, квоты |
| Resource Gov | 31–60 | GPU sharing/isolation (MIG/MPS/vGPU), network baseline, templated delivery |
| Loop | 61–90 | Budget enforcement → SLO-linked, пилоты в landing zone, организационные контракты |

### Gap-анализ для 32-isolated.sh
- [ ] GPU sharing/isolation стратегии — не специфицированы (просто «включить Ollama/vLLM»)
- [ ] Multi-tenant изоляция — нет (32-isolated рассчитан на одного пользователя)
- [ ] Audit logging для AI-действий — не реализовано
- [ ] Network baseline для AI (lossless, isolation domains) — не покрыто

---

## 7. RAG / Memory / Context — лучшие практики

### system-design.space «RAG-архитектура»:
- **Ingestion pipeline**: chunking strategies, embedding model выбор, метаданные для фильтрации
- **Retrieval**: hybrid search (dense + sparse BM25 + RRF), ACL-aware filtering
- **Generation**: prompt assembly с citations, guardrails на выходе
- **Evaluation**: offline (NDCG, recall@k) + online (user feedback, task completion)

### system-design.space «Векторный поиск и ANN»:
- Индексы: IVF, HNSW, ScaNN
- Сжатие: PQ, IVF-PQ
- Гибридный поиск: dense + BM25 + RRF
- Системы: FAISS, pgvector, Milvus, Qdrant, Weaviate

### AI-native infra: «Context as Infrastructure Layer»
- KV-cache и контекст агента — не «трюк приложения», а инфраструктурный актив
- Долгосрочный контекст и agentic inference требуют переиспользования состояния между нодами и сессиями
- «Context Tier» как самостоятельный архитектурный слой

### Gap-анализ для 21-rag.sh + MemoryLayer
- [ ] ACL-aware retrieval в RAG — не реализовано (корпоративный сценарий)
- [ ] Hybrid search (dense + sparse) — используется только dense (Qdrant)
- [ ] Context reuse / KV-cache как инфраструктурный слой — не реализовано (MemoryLayer — только хранение)
- [x] Базовый RAG pipeline (ingestion → retrieval → generation) — реализован

---

## 8. Организационные паттерны и антипаттерны

### Антипаттерны миграции (Jimmy Song):
| Антипаттерн | Последствия |
|------------|-------------|
| Строить API/Agent-платформу без ledger и бюджета | runaway cost (самый частый, трудно исправить постфактум) |
| Относиться к GPU как к обычным ресурсам | Низкая утилизация + неконтролируемая конкуренция |
| Игнорировать сеть и топологию | Tail latency и training JCT убивают SLO |
| Не «актизировать» контекст | Unit cost неконтролируем в эпоху long-context/agentic |

### Platform vs Workload contract:
- **Платформа даёт**: Landing Zone, network baseline, identity/policies, budget/quota, metering, GPU governance, golden paths
- **Команды владеют**: model selection, prompt/agent logic, tool integration, SLO definition, business value measurement

---

## 9. Резюме: что перенять в opencode_initializer v3.0

### Высокоприоритетные заимствования

1. **Governance Plane (новый модуль?)**: квоты, бюджеты, аудит AI-действий, rate limiting на уровне gateway — сейчас это нулевой coverage
2. **LLM Gateway паттерн**: единая точка входа с circuit breaker, retry, rate limiting, семантическим кэшированием (усилить 36-model-router.sh)
3. **Observability 2.0**: добавить behavior signals (tool call tracing) и cost signals в 34-observability.sh
4. **Context-as-Infrastructure (усилить 21-rag.sh + 37-wal.sh)**: явный Context Tier, переиспользование состояния между сессиями, KV-cache sharing
5. **Air-gap Enterprise profile (усилить 32-isolated.sh)**: multi-tenant изоляция, GPU sharing strategies (MIG/MPS), audit logging

### Среднеприоритетные

6. **Каскады моделей** в 36-model-router.sh: cheap→expensive fallback
7. **Guardrails на выходе** в 15-security.sh: prompt injection protection, output verification
8. **AI Landing Zone** как инсталлируемый профиль: networking, identity, policies, auditing — единый периметр
9. **90-Day миграционный план** как CLI-команда (`dev ai-migrate`) для корпоративных пользователей

### Долгосрочные

10. **FinOps как control plane**: интеграция бюджетов с лимитами моделей в реальном времени
11. **GPU sharing/orchestration** как часть 30-infra.sh (HAMi, MIG, MPS)
12. **ACL-aware RAG** для multi-tenant корпоративных сценариев

---

## Источники

- [AI Native Infrastructure — Systems Designed for Uncertainty](https://jimmysong.io/book/ai-native-infra/) — Jimmy Song, Jan 2026
- [Definition — What Is AI-Native Infrastructure?](https://jimmysong.io/book/ai-native-infra/definition/)
- [Compute Governance](https://jimmysong.io/book/ai-native-infra/compute-governance/)
- [Migration Roadmap: From Cloud Native to AI Native](https://jimmysong.io/book/ai-native-infra/migration-roadmap/)
- [AI Native Landscape — 141 Projects](https://jimmysong.io/ai/) — каталог: IDE/CLI 41, Coding Agents 39, MCP/Tools 32, Browser Automation 10
- [Kubernetes as the GPU Control Plane for AI](https://jimmysong.io/blog/) — Jimmy Song, May 2026
- [From GPU to Token: The 8-Layer Observability Stack for AI Infrastructure](https://jimmysong.io/blog/) — Jimmy Song, Jun 2026
- [System Design Space — AI Engineering (25 глав)](https://system-design.space/theme/ai-engineering)
- [System Design Space — ML Engineering (19 глав)](https://system-design.space/theme/ml-engineering)
- NIST AI Risk Management Framework — nist.gov
- FinOps Framework — finops.org
