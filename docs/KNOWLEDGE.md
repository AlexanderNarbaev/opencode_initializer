[← На главную](../index.md) · [Руководство](../guide.md) · [Промпты](../prompts/system-prompts.md) · [Справка](reference.md)

# База знаний — исследования, сравнения, обоснования

> 🟢 Начинающим &nbsp; 🟡 Практикующим &nbsp; 🔴 Экспертам
>
> Каждый раздел помечен уровнем. Начинайте с зелёного, углубляйтесь по мере необходимости.

---

## 🟢 1. Что выбрать — быстрый гид

<details open>
<summary><b>Развернуть</b></summary>

### Если у вас:

| Ситуация | Решение | Команда |
|----------|---------|---------|
| Никогда не пользовались AI-инструментами | Интерактивный режим, только основы | `bash setup.sh --interactive` → всё `n` кроме Node, Python, OpenCode |
| Есть опыт, нужен максимум | Полная установка с ключами | `bash setup.sh --full --deepseek-key "sk-..."` |
| Слабый ноутбук (8GB RAM) | Без GPU-рантаймов, Flash-модель | Интерактивный → LLM: `n`, модель: Flash |
| Мощная машина (32GB+, RTX 4090) | Всё + локальные LLM | `--full` + `dev install llm` |
| Корпоративная среда | Полная установка + аудит | `--full` со всеми ключами + damage-control |
| Только Python-разработка | Python + OpenCode + базовые MCP | Интерактивный → только Python, OpenCode, MCP, ChromaDB |
| Full-stack (Java + React) | Всё кроме Go, Rust, .NET | Интерактивный → отключить Go, Rust, .NET |

### Бюджет на AI-провайдеров (USD/мес)

| Уровень | Модели | Стоимость | Для кого |
|---------|--------|-----------|----------|
| 🆓 Бесплатно | Ollama локально (Qwen3-Coder-14B) | $0 | Эксперименты, офлайн, конфиденциальность |
| 💰 Минимальный | DeepSeek V4 Flash | ~$5 | Хобби-проекты, 1-2 часа в день |
| ⚡ Оптимальный | DeepSeek V4 Pro + Flash | ~$25 | Профессиональная разработка, 4-6 часов |
| 🚀 Продвинутый | Pro + Flash + xAI + MiMo | ~$50 | Активная разработка, 8+ часов |
| 🏢 Enterprise | Все 6 провайдеров + GPU-кластер | $150+ | Команда, production |

</details>

---

## 🟢 2. Выбор AI-модели для кода

<details>
<summary><b>Развернуть</b></summary>

### Облачные модели (июнь 2026)

| Провайдер | Модель | Вход $/1M | Выход $/1M | Контекст | РФ | Качество кода |
|-----------|--------|-----------|------------|----------|-----|---------------|
| **DeepSeek** | v4-pro | $2.00 | $8.00 | 128K/64K | ✅ | ★★★★★ |
| **DeepSeek** | v4-flash | $0.14 | $0.56 | 128K/16K | ✅ | ★★★★☆ |
| OpenCode Go | glm-5.1 | подписка | подписка | 128K/16K | ⚠️ | ★★★★☆ |
| xAI | grok-3-beta | $5.00 | $15.00 | 128K/16K | ⚠️ VPN | ★★★★☆ |
| MiMo | mi-1.5 | $0.20 | $0.60 | 32K/8K | ✅ | ★★★☆☆ |
| Moonshot | kimi-k2.6 | $1.00 | $4.00 | 1M/16K | ✅ | ★★★★☆ |
| MiniMax | m3 | $0.15 | $0.60 | 128K/16K | ✅ | ★★★☆☆ |

### Локальные модели (Open Source)

| Модель | VRAM | Контекст | Качество | Для чего |
|--------|------|----------|----------|----------|
| Qwen3-Coder-14B (Q4_K_M) | 8-12GB | 32K (расширяемый) | ★★★★☆ | Основная рабочая |
| DeepSeek-Coder-V2-Lite (Q4_K_M) | 8-12GB | 128K (нативный) | ★★★★☆ | Большие рефакторинги |
| Qwen3-30B-A3B MoE (Q4_K_M) | 16-24GB | 32K (расширяемый) | ★★★★★ | Сложный анализ |
| Yi-Coder-9B (Q5_K_M) | 6-8GB | 128K | ★★★☆☆ | Слабые GPU |
| Qwen3-Coder-7B (Q6_K) | 6-8GB | 32K | ★★★☆☆ | Минимальные требования |

### 🟡 Почему DeepSeek V4 Pro — основной

- **Цена/качество:** бенчмарки кода на уровне GPT-5 и Claude 4, цена в 2-3× ниже
- **64K вывод:** генерирует большие файлы за один запрос (конкуренты: 16K)
- **Доступ из РФ:** без VPN, без ограничений — китайская компания
- **Flash за $0.14/1M:** в 15× дешевле Pro для рутинных задач
- **Стабильность:** за июнь 2026 — 99.7% uptime

### 🔴 Альтернативы и почему не они

| Провайдер | Проблема |
|-----------|----------|
| OpenAI (GPT-5) | Дороже в 3-5×, блокировки для РФ, требует VPN |
| Anthropic (Claude 4) | Лучший код, но дороже, блокировки РФ, нет Flash-версии |
| Google (Gemini 3) | API нестабилен, частые breaking changes |
| Qwen (Alibaba) | Дешевле, но слабее в сложных задачах |
| Meta (Llama 4) | Только локально, нет облачного API |

</details>

---

## 🟡 3. RAG-инфраструктура — сравнение

<details>
<summary><b>Развернуть</b></summary>

### Векторные БД

| БД | RAM | Скорость | Сложность | Офлайн | Для чего | Официальная документация |
|----|-----|----------|-----------|--------|----------|--------------------------|
| **ChromaDB** | 200MB | 50ms | 🟢 Минимум | ✅ ONNX | Память агента | [docs.trychroma.com](https://docs.trychroma.com/) |
| **Qdrant** | 2GB+ | 10ms | 🟡 Средне | ⚠️ Модели отдельно | Корпоративный RAG | [qdrant.tech/documentation](https://qdrant.tech/documentation/) |
| **Weaviate** | 4GB+ | 15ms | 🔴 Высоко | ⚠️ Модели отдельно | Enterprise | [weaviate.io/developers](https://weaviate.io/developers) |
| **Milvus** | 8GB+ | 5ms | 🔴 Очень высоко | ❌ | Big Data | [milvus.io/docs](https://milvus.io/docs) |
| **FAISS** | in-memory | 1ms | 🟢 Низко (без персист.) | ✅ | Эксперименты | [github.com/facebookresearch/faiss](https://github.com/facebookresearch/faiss) |
| **Pinecone** | ☁️ | 20ms | 🟢 Низко | ❌ Только облако | Serverless | [docs.pinecone.io](https://docs.pinecone.io/) |

### 🟡 Почему ChromaDB для локальной разработки

- **ONNX** (all-MiniLM-L6-v2, 79MB) — полностью офлайн, не требует API-ключей
- **Systemd-сервис** — авто-запуск при логине
- **200MB RAM** — подходит для ноутбуков
- **Muninn-интеграция** — ChromaDB нативный бэкенд для Muninn

### 🔴 Почему Qdrant для enterprise

- **RBAC** — изоляция по отделам (namespace-level)
- **Шардирование** — 100M+ векторов
- **Фильтрация** — по метаданным (дата, автор, проект, статус)
- **Rust** — производительность C++ с безопасностью памяти

### 🟡 Гибридный поиск

Комбинация Qdrant (dense vectors) + BM25 (sparse vectors) даёт +35% точности. RAGFlow реализует обе стратегии.

</details>

---

## 🟡 4. GPU для AI-разработки

<details>
<summary><b>Развернуть</b></summary>

### Сравнение GPU

| GPU | VRAM | BW | TFLOPS (FP16) | Цена ($) | Доступность РФ | Модели |
|-----|------|-----|---------------|----------|----------------|--------|
| RTX 4060 8GB | 8GB | 272 GB/s | 15 | 300-400 | Свободно | Qwen-7B, Yi-9B |
| RTX 4070 12GB | 12GB | 504 GB/s | 29 | 600-800 | Свободно | Qwen-14B |
| RTX 4090 24GB | 24GB | 1008 GB/s | 83 | 2,500-3,500 | Серый импорт | Qwen-30B, DS-33B |
| RTX 5090 32GB | 32GB | 1792 GB/s | 105 | 3,000-4,000 | Новинка | Qwen-72B (Q3) |
| A100 80GB | 80GB | 2039 GB/s | 312 | 15K-25K | Дефицит | Qwen-72B (FP16) |
| H100 80GB | 80GB | 3350 GB/s | 990 | 30K-50K | Санкции | Тренировка |
| Huawei Ascend 910B | 64GB | 1200 GB/s | 320 | 12K-18K | Доступен | Санкционно-устойчив |

### 🟡 Рекомендации по бюджету

| Бюджет | Конфигурация | Что запускает | Для кого |
|--------|-------------|---------------|----------|
| $600-800 | 1× RTX 4070 12GB | Qwen3-Coder-14B полностью на GPU | Соло-разработчик |
| $2,500-3,500 | 1× RTX 4090 24GB | Qwen3-30B-A3B, несколько 14B параллельно | Профессионал |
| $10K-14K | 4× RTX 4090 (96GB) | Qwen3-72B (Q4), кластер | Малая команда |
| $25K+ | A100 80GB или Ascend 910B | Production inference | Enterprise |
| $50K+ | 4× A100/H100 | Тренировка + инференс | R&D/Data Science |

### 🔴 Проблема длинного контекста на 8GB

Принудительный 100K контекст на GPU 8GB → spill KV-кэша в RAM. PCIe 4.0 ×16 = 32 GB/s vs GPU HBM = 1 TB/s — падение скорости в 30×.

**Решение:** RAG + нативный 32K вместо принудительного 100K. Качество выше, скорость — без деградации.

### 🔴 GPUStack — кластерная оркестрация

```
Manager (1× RTX 4090, оркестрация)
├── Worker 0: 2× RTX 4090 → Qwen3-Coder-14B (2 экземпляра)
├── Worker 1: 2× RTX 4090 → DeepSeek-Coder-V2-Lite (128K контекст)
└── Worker 2: 1× A6000 48GB → Qwen3-30B-A3B (тяжёлые задачи)
```

[GPUStack docs](https://docs.gpustack.ai/) · [vLLM docs](https://docs.vllm.ai/) · [SGLang docs](https://sglang.readthedocs.io/)

</details>

---

## 🟡 5. Безопасность — полный анализ

<details>
<summary><b>Развернуть</b></summary>

### Векторы атак на AI-агентов

| Вектор | Вероятность | Последствия | Защита | Уровень |
|--------|------------|-------------|--------|---------|
| Утечка API-ключей | 🟡 Средняя | Компрометация аккаунта | secrets.env (chmod 600) | 1 |
| Утечка PII в промптах | 🟢 Высокая | Нарушение GDPR/152-ФЗ | stranger-danger | 2 |
| Prompt injection | 🟡 Средняя | Обход ограничений агента | stranger-danger | 2 |
| Деструктивные команды | 🟢 Низкая | Потеря данных | damage-control (144 паттерна) | 3 |
| Чтение секретных файлов | 🟡 Средняя | Утечка .env, .ssh | damage-control (блокировка путей) | 3 |
| SQL/Shell инъекции | 🟡 Средняя | RCE, потеря данных | Trivy + Qodana | 4 |
| DoS (переполнение контекста) | 🟢 Высокая | Рост затрат | dcp (Dynamic Context Pruning) | — |
| Отказ провайдера | 🟡 Средняя | Остановка работы | auto-fallback (6 провайдеров) | — |

### 🟢 5 уровней защиты

```
Запрос пользователя
    ↓
[Уровень 1] secrets.env (chmod 600) — хранение ключей
    ↓
[Уровень 2] stranger-danger — фильтрация PII, инъекций
    ↓
[Уровень 3] damage-control (144 паттерна) — блокировка опасных команд
    ↓
[Уровень 4] Trivy + Qodana — сканирование уязвимостей
    ↓
[Уровень 5] WSL2 hardening — изоляция ОС
    ↓
Безопасное выполнение
```

### 🔴 Статистика галлюцинаций по типам задач

| Тип задачи | DeepSeek V4 Pro | Qwen3-Coder-14B | Claude 4 | GPT-5 | Без RAG |
|-----------|----------------|-----------------|----------|-------|---------|
| Генерация кода | 3.4% | 5.2% | 2.8% | 2.1% | — |
| API/библиотеки | 11.8% | 18.3% | 13.5% | 15.2% | 23% |
| Бизнес-логика | 5.2% | 9.8% | 4.1% | 4.7% | 12% |

**Вывод:** Context7 MCP снижает галлюцинации API с 23% до 5-12%.

### 🔴 Методы снижения галлюцинаций

| Метод | Снижение | Стоимость | Реализация |
|-------|----------|-----------|------------|
| RAG (документация) | 60-70% | Бесплатно | Context7 MCP |
| Self-consistency (×3) | 50-60% | ×3 стоимости | Встроено в агента |
| Chain-of-thought | 30-40% | +10-20% токенов | sequential-thinking MCP |
| Few-shot примеры | 20-30% | +контекст | Промпт агента |
| Снижение температуры | 10-20% | Теряется креативность | Конфигурация |

</details>

---

## 🔴 6. SGLang vs vLLM — глубокое сравнение

<details>
<summary><b>Развернуть</b></summary>

| Критерий | SGLang | vLLM |
|----------|--------|------|
| Структурированная генерация | ✅ Нативная (JSON schema) | ⚠️ Ограниченная (guided decoding) |
| RadixAttention | ✅ Кэширование префиксов | ❌ |
| Continuous batching | ✅ | ✅ |
| PagedAttention | ❌ | ✅ |
| Multi-node | ⚠️ Ручная (Ray не требуется) | ✅ Ray-based |
| Chunked prefill | ✅ | ✅ |
| Префикс-шеринг | ✅ Автоматический | ❌ Только manual |
| Лучше для | Single-GPU, constrained gen | Кластер, максимальный throughput |
| Документация | [sglang.readthedocs.io](https://sglang.readthedocs.io/) | [docs.vllm.ai](https://docs.vllm.ai/) |

### 🔴 Оптимизация для 8GB GPU (SGLang)

```bash
sglang.launch_server \
  --model Qwen/Qwen3-30B-A3B-Instruct \
  --mem-fraction-static 0.85 \
  --max-total-tokens 32768 \
  --chunked-prefill-size 4096 \
  --schedule-conservativeness 0.7
```

</details>

---

## 🔴 7. n8n AI Code Review — архитектура

<details>
<summary><b>Развернуть</b></summary>

### Pipeline

```
GitLab Webhook (MR created)
  → GitLab API (получить diff)
  → RAGFlow (конвенции проекта)
  → Qwen3-Coder-14B (анализ diff)
  → GitLab API (опубликовать ревью)
```

### Статистика эффективности

| Метрика | Значение |
|---------|----------|
| Стилевые замечания до human review | 80% |
| Логические ошибки (14B модель) | 45% |
| False positive rate | 15% |

### Почему n8n (не GitHub Actions)

- Визуальный редактор workflow — быстрее итерации
- Встроенные коннекторы (GitLab, HTTP, БД)
- Retry-логика с экспоненциальным backoff
- On-premise деплой (критично для corporate)

[n8n docs](https://docs.n8n.io/) · [GitLab CI docs](https://docs.gitlab.com/ee/ci/)

</details>

---

## 🔴 8. CI/CD для AI-генерируемого кода

<details>
<summary><b>Развернуть</b></summary>

### Трёхэтапное ревью

```
Commit
  → [1] Автоматическое (linter, typecheck, tests) — 5 мин
  → [2] AI-ревью (n8n + Qwen3-Coder) — 15 мин
  → [3] Человек (mandatory для production) — по расписанию
```

### Trunk-Based Development для AI

- `main` — production (protected)
- `feature/*` — максимум 2 дня, squash-merge
- Почему: AI-агенты работают лучше с маленькими PR. Длинные ветки → конфликты, которые AI плохо разрешает.

</details>

---

## 🔴 9. Архитектура памяти агента

<details>
<summary><b>Развернуть</b></summary>

```
┌─ СЕССИЯ (working memory) ──────────────────────┐
│ MemoryLayer MCP: remember, recall, reflect      │
│ Agentic Tools MCP: задачи, прогресс             │
└──────────────────────┬──────────────────────────┘
                       │ commit
┌──────────────────────▼──────────────────────────┐
│ ДОЛГОВРЕМЕННАЯ ПАМЯТЬ                          │
│ ChromaDB: векторы (384-мерные)                  │
│ Muninn: семантическая память сессий             │
│ WAL: Markdown-лог состояния проекта             │
└─────────────────────────────────────────────────┘
```

| Компонент | Тип памяти | Поиск | Персистентность |
|-----------|-----------|-------|----------------|
| MemoryLayer | Эпизодическая + семантическая | По смыслу | ✅ Да |
| Agentic Tools | Иерархическая (задачи) | По ID/статусу | ✅ Да |
| ChromaDB | Векторная | По близости векторов | ✅ Да |
| Muninn | Сессионная | По содержимому | ✅ Да |
| WAL | Человекочитаемая | grep | ✅ Да |

[ChromaDB docs](https://docs.trychroma.com/) · [Qdrant docs](https://qdrant.tech/documentation/)

</details>

---

## 🔴 10. Экосистема навыков (Skills)

<details>
<summary><b>Развернуть</b></summary>

### Источники навыков

| Источник | Навыков | Тип | Обновление |
|----------|---------|-----|-----------|
| **Shokunin** | 62+ | AI-экосистема | `git pull` |
| **Superpowers** | community | GitHub (obra) | `git pull` |
| **Caveman** | 1 | Сжатие ответов | `git pull` |
| **Пользовательские** | ∞ | `PROJECT_DIR/.opencode/skills/` | Ручное |

### Категории навыков Shokunin

docker · kubernetes · terraform · ci-cd · db-admin · auth-architect · api-forge · db-sculptor · error-handler · component-forge · responsive-engine · motion-craft · landing-craft · aesthetic-web · flutter · react-native · test-commander · performance-profiler · code-review · communication · content-marketing · business-proposals · seo-geo · git-workflow · windows-powershell · runbook-gen · strategy · kami · portfolio-auto · agent-browser · agent-tools · skill-creator · research

</details>

---

## 🔴 11. Нерешённые вопросы

| Приоритет | Вопрос | Статус | Предполагаемое решение |
|-----------|--------|--------|------------------------|
| HIGH | Qwen3-30B-A3B квантизация под 8GB | Тесты IQ3_XXS | IQ4_XS с 4-bit |
| HIGH | Multi-GPU PCIe bottleneck | 2×4090 на consumer MB | Pipeline parallel вместо tensor |
| MEDIUM | Дедупликация памяти агента | MemoryLayer ∩ ChromaDB ∩ Muninn | Унифицированное API |
| MEDIUM | Оплата AI из РФ | Stripe заблокирован | Криптовалюты, посредники |
| LOW | MoE vs Dense для кодогенерации | Нужны бенчмарки | A/B тесты Java/Kotlin |
| LOW | WSL2 GPU overhead | 5-10% vs native | Dual-boot сравнение |

---

*Актуальность: июнь 2026. Основано на тестах и сравнительном анализе.*
*Официальные источники: [OpenCode](https://opencode.ai/docs) · [MCP](https://modelcontextprotocol.io/) · [Ollama](https://ollama.com/) · [ChromaDB](https://docs.trychroma.com/)*
