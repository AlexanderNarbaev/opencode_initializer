[← На главную](../index.md) · [Все инструменты](../index.md#навигация)

# GPU и локальные LLM

Локальный запуск языковых моделей на своём железе.

## Сравнение GPU (июнь 2026)

| GPU | VRAM | BW | Цена ($) | Модели | Для кого |
|-----|------|-----|----------|--------|----------|
| RTX 4060 8GB | 8GB | 272 GB/s | 300-400 | Qwen-7B, Yi-9B | Старт |
| RTX 4070 12GB | 12GB | 504 GB/s | 600-800 | Qwen-14B | Оптимум |
| RTX 4090 24GB | 24GB | 1008 GB/s | 2500-3500 | Qwen-30B, DS-33B | Профи |
| RTX 5090 32GB | 32GB | 1792 GB/s | 3000-4000 | Qwen-72B (Q3) | Топ |
| A100 80GB | 80GB | 2039 GB/s | 15K-25K | Qwen-72B (FP16) | Сервер |
| H100 80GB | 80GB | 3350 GB/s | 30K-50K | Тренировка | Enterprise |

---

## Ollama — основной локальный движок

### Установка (автоматически)

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen3:1.8b  # лёгкая модель для старта
```

### Рекомендуемые модели

| Модель | Размер | VRAM | Контекст | Для чего |
|--------|--------|------|----------|----------|
| `qwen3-coder:14b-q4_K_M` | 9GB | 8-12GB | 32K | Кодинг (основная) |
| `deepseek-coder-v2:16b-lite-q4_K_M` | 10GB | 8-12GB | 128K | Длинный контекст |
| `qwen3:30b-a3b-q4_K_M` | 18GB | 16-24GB | 32K | Сложный анализ |
| `qwen3-coder:7b-q6_K` | 5.5GB | 6-8GB | 32K | Слабые GPU |
| `yi-coder:9b-q5_K_M` | 6GB | 6-8GB | 128K | Быстрые ответы |

### Расширение контекста

```bash
# Создать Modelfile
cat > Modelfile.128k << 'EOF'
FROM qwen3-coder:14b-q4_K_M
PARAMETER num_ctx 131072
EOF

# Создать модель с расширенным контекстом
ollama create qwen3-coder-128k -f Modelfile.128k
```

**Важно:** расширение контекста увеличивает потребление VRAM. 128K контекст для 14B модели требует дополнительно 6-8GB на KV-кэш.

---

## vLLM — высокопроизводительный сервер

### Когда использовать

- Мощная GPU (A100, RTX 4090/5090)
- Нужна максимальная пропускная способность (много пользователей/агентов)
- Production-нагрузка

### Установка

```bash
pipx install vllm
```

### Запуск

```bash
vllm serve Qwen/Qwen3-30B-A3B-Instruct \
  --host 0.0.0.0 \
  --port 8000 \
  --max-model-len 32768 \
  --gpu-memory-utilization 0.85
```

---

## SGLang — структурная генерация

### Когда использовать

- Нужен строгий JSON/схема на выходе
- Single-GPU инференс
- Сложные constrained generation задачи

### Установка

```bash
pipx install "sglang[all]"
```

### Запуск с чанкированным prefill (для 8GB GPU)

```bash
sglang.launch_server \
  --model Qwen/Qwen3-30B-A3B-Instruct \
  --mem-fraction-static 0.85 \
  --max-total-tokens 32768 \
  --chunked-prefill-size 4096
```

**Chunked prefill** обрабатывает контекст частями по 4K токенов, не требуя всей памяти на KV-кэш сразу. Критично для 8GB GPU с длинным контекстом.

---

## Open WebUI — чат-интерфейс

### Установка (Docker, автоматически)

```bash
docker run -d --name open-webui \
  --restart unless-stopped \
  -p 3300:8080 \
  -v open-webui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main
```

**URL:** http://localhost:3300

**Возможности:**
- Чат с Ollama-моделями
- Встроенный RAG (загрузка документов)
- Multi-user с регистрацией
- Web-поиск

---

## LlamaEdge — лёгкий runner

### Когда использовать

- Нет GPU (CPU-only)
- 8-16GB RAM
- Нужна простая модель (до 7B)

### Установка

```bash
curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash -s -- -v 0.14.1
```

Работает на WasmEdge — изолированная среда выполнения (песочница). Медленнее Ollama, но безопаснее.

---

## GPUStack — оркестрация кластера

### Когда использовать

- Несколько GPU на одной или разных машинах
- Нужно распределять модели по GPU автоматически
- Multi-tenant доступ

### Архитектура

```
Manager (1× GPU) — оркестрация, мониторинг, API
   ├── Worker 0 (2× GPU) — Qwen3-Coder-14B
   ├── Worker 1 (2× GPU) — DeepSeek-Coder-V2-Lite
   └── Worker 2 (1× GPU) — Qwen3-30B-A3B
```

### Установка

```bash
# Manager
curl -sfL https://gpustack.ai/install.sh | sh -s -- --server

# Worker
curl -sfL https://gpustack.ai/install.sh | sh -s -- --server-url http://manager:8080 --token <TOKEN>
```
