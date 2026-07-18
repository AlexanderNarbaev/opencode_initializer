# Provider Setup Guide — opencode_initializer v2.0

## Overview
24 AI providers: 20 cloud + 4 local. All configured via `src/lib/26-providers.sh` and `src/lib/18-opencode-json.sh`.

## Provider Endpoints (verified 2026-07-18)

| Provider | Endpoint | Model | Status |
|----------|----------|-------|--------|
| DeepSeek | api.deepseek.com | deepseek-v4-pro | ✅ Free tier |
| z.ai GLM | api.z.ai/api/paas/v4 | glm-5.2 | ✅ Free tier |
| OpenRouter | openrouter.ai/api/v1 | 100+ models | ✅ Aggregator |
| Moonshot/Kimi | **api.moonshot.ai** | kimi-k3, kimi-k2.7-code | 🔧 Key: platform.kimi.ai |
| MiniMax | **api.minimax.io** | MiniMax-M3 | 🔧 Token Plan credits |
| xAI Grok | api.x.ai | grok-4.3 | ✅ Working |
| Alibaba Qwen | dashscope-intl.aliyuncs.com | qwen3.7-plus | ✅ Free tier |
| DeepInfra | api.deepinfra.com | Llama-4-Maverick | ✅ Free tier |
| Ollama | localhost:11434 | llama3.2, qwen3 | ✅ Local |
| LiteLLM | localhost:4000 | OpenAI-compat proxy | ✅ Local |

## API Key Sources

| Provider | Key Source | Env Variable |
|----------|-----------|-------------|
| DeepSeek | platform.deepseek.com/api_keys | DEEPSEEK_API_KEY |
| Moonshot | platform.kimi.ai/console/projects/api-keys | MOONSHOT_API_KEY |
| MiniMax | platform.minimax.io (Token Plan or PayG) | MINIMAX_API_KEY |
| xAI | console.x.ai | XAI_API_KEY |
| z.ai | open.bigmodel.cn | ZAI_API_KEY |
| OpenRouter | openrouter.ai/keys | OPENROUTER_API_KEY |

## Air-Gapped (Isolated Circuit Mode)

```bash
dev isolated on           # Enable: only local providers
ollama pull qwen3:8b      # Pull coding model
ollama pull llama3.2      # Fast chat model
# CPU-only: use llama.cpp with GGUF models
# Qwen3-Coder-30B-A3B, GigaChat-20B
```

## Provider Health Check

```bash
bash scripts/provider-check.sh   # Tests all configured providers
```

## Model Routing Profiles

| Profile | Model | Use Case |
|---------|-------|----------|
| coding | deepseek-v4-pro | Primary implementation |
| agentic | kimi-k3 | Tool use, agents |
| reasoning | claude-opus-4-8 | Architecture, planning |
| fast | deepseek-v4-flash | Quick answers |
| budget | glm-5.2 | Cost-sensitive |
| ru_cn | glm-5.2 | RU/CN language |

