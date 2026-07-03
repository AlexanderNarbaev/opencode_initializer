# Model ID Verification — models.dev cross-check

**Date:** 2026-07-03
**Source:** https://models.dev/api/providers (opencode's authoritative model registry)
**Status:** CRITICAL — multiple model IDs were incorrect

## Verification Results

| Provider | models.dev ID | Project ID (before) | Project ID (after) | Status |
|----------|--------------|--------------------|--------------------|--------|
| z.ai/Zhipu | `zhipuai/glm-5.2` | `zai/glm-5.2` | `zai/glm-5.2` | **PROVIDER ID MISMATCH** — opencode uses `zhipuai` not `zai` |
| Moonshot | `moonshotai/kimi-k2.7-code` | `moonshot/kimi-k2` | `moonshotai/kimi-k2.7-code` | **WRONG** — updated to latest |
| Anthropic | `anthropic/claude-opus-4-8` | `anthropic/claude-opus-4-20250514` | `anthropic/claude-opus-4-8` | **WRONG** — updated to latest |
| xAI | `xai/grok-4.3` | `xai/grok-4` | `xai/grok-4.3` | **WRONG** — updated to latest |
| OpenAI | `openai/gpt-5.5` | `openai/gpt-5` | `openai/gpt-5.5` | **WRONG** — updated to latest |
| Google | `google/gemini-3.5-flash` | `google/gemini-2.5-pro` | `google/gemini-3.5-flash` | **WRONG** — updated to latest |
| DeepSeek | `deepseek/deepseek-v4-pro` | `deepseek/deepseek-v4-pro` | `deepseek/deepseek-v4-pro` | OK |
| DeepSeek Flash | `deepseek/deepseek-v4-flash` | `deepseek/deepseek-v4-flash` | `deepseek/deepseek-v4-flash` | OK |
| Alibaba | `alibaba/qwen3.7-plus` | `alibaba/qwen3-235b` | `alibaba/qwen3.7-plus` | **WRONG** — updated to latest |
| MiniMax | `minimax/MiniMax-M3` | `minimax/minimax-m3` | `minimax/MiniMax-M3` | **WRONG** — case sensitivity |
| Mistral | `mistral/mistral-large-latest` | `mistral/mistral-large-latest` | `mistral/mistral-large-latest` | OK |
| Xiaomi MiMo | `xiaomi/mimo-v2.5` | `mimo/mimo-v2` | `xiaomi/mimo-v2.5` | **WRONG** — provider ID + model |
| Groq | `groq/llama-4-maverick` | `groq/llama-4-maverick` | `groq/llama-4-maverick` | OK |
| Perplexity | `perplexity/sonar-pro` | `perplexity/sonar-pro` | `perplexity/sonar-pro` | OK |

## Latest models discovered (2026-06-2026-07)

| Model | Lab | Released | Context | Free? |
|-------|-----|----------|---------|-------|
| Claude Sonnet 5 | Anthropic | 2026-06-30 | 1M | yes |
| GLM-5.2 | Zhipu AI | 2026-06-13 | 1M | yes |
| Kimi K2.7 Code | Moonshot AI | 2026-06-12 | 256K | yes |
| Claude Fable 5 | Anthropic | 2026-06-09 | 1M | yes |
| MiMo-V2.5-Pro-UltraSpeed | Xiaomi | 2026-06-08 | 1M | yes |
| Claude Opus 4.8 | Anthropic | 2026-05-28 | 1M | yes |
| GPT-5.5 | OpenAI | 2026-04-23 | 1M | yes |
| Grok 4.3 | xAI | 2026-04-17 | 1M | yes |
| Qwen3.7 Plus | Alibaba | 2026-06-02 | 1M | yes |
| Gemini 3.5 Flash | Google | 2026-05-19 | 1M | yes |

## Provider ID corrections

The project uses `zai` as provider key, but opencode/models.dev uses `zhipuai`.
However, since opencode supports custom provider IDs via openai-compatible SDK,
`zai` works IF the baseURL is set correctly. The model ID should still match
what the z.ai API expects, which is `glm-5.2` (without the `zhipuai/` prefix
when using a custom provider key).

For `mimo`, models.dev uses `xiaomi` as the provider ID. The project's `mimo`
key works with openai-compatible, but the model ID should be `mimo-v2.5`.

## Action taken

All model IDs in `18-opencode-json.sh` updated to match models.dev latest.
Provider registry descriptions updated with correct model names.
