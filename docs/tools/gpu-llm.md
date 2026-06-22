---
layout: default
title: GPU и локальные LLM — инференс на своём железе
description: Ollama, vLLM, SGLang, Open WebUI, LlamaEdge, GPUStack. Сравнение GPU, модели, конфигурация.
---

[Главная](../index.md) · [Справка](../reference.md)

# GPU и локальные LLM

[Ollama](https://ollama.com/) · [vLLM](https://docs.vllm.ai/) · [SGLang](https://sglang.readthedocs.io/) · [GPUStack](https://docs.gpustack.ai/)

Локальный запуск языковых моделей на своём железе.

## Сравнение GPU

| GPU | VRAM | BW | Цена ($) | Модели |
|-----|------|-----|----------|--------|
| RTX 4060 | 8GB | 272 GB/s | 300-400 | Qwen-7B, Yi-9B |
| RTX 4070 | 12GB | 504 GB/s | 600-800 | Qwen-14B |
| RTX 4090 | 24GB | 1008 GB/s | 2500-3500 | Qwen-30B |
| RTX 5090 | 32GB | 1792 GB/s | 3000-4000 | Qwen-72B (Q3) |
| A100 | 80GB | 2039 GB/s | 15K-25K | Qwen-72B (FP16) |

## Ollama — основной движок

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
cat > Modelfile.128k << 'EOF'
FROM qwen3-coder:14b-q4_K_M
PARAMETER num_ctx 131072
EOF
ollama create qwen3-coder-128k -f Modelfile.128k
```

## vLLM — высокопроизводительный сервер

Для мощных GPU (A100, RTX 4090+) и максимальной пропускной способности.

```bash
pipx install vllm
vllm serve Qwen/Qwen3-30B-A3B-Instruct --host 0.0.0.0 --port 8000
```

## SGLang — структурная генерация

Для строгого JSON/схемы на выходе, single-GPU.

```bash
pipx install "sglang[all]"
sglang.launch_server --model Qwen/Qwen3-30B-A3B-Instruct --chunked-prefill-size 4096
```

## Open WebUI — чат-интерфейс

```bash
docker run -d --name open-webui --restart unless-stopped \
  -p 3300:8080 -v open-webui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main
```

URL: http://localhost:3300

## GPUStack — оркестрация кластера

Для нескольких GPU на разных машинах. Авто-распределение моделей.

[GPUStack docs](https://docs.gpustack.ai/)
