# Provider & LLM Ecosystem Analysis — 2026-07

**Date:** 2026-07-03
**Source:** opencode source code (GitHub dev branch), provider documentation, market analysis

## 1. z.ai (Zhipu AI) — GLM Series

### Current Models (July 2026)
| Model | Context | Strengths | API |
|-------|---------|-----------|-----|
| **GLM-5.2** | 200K tokens | Flagship. Multimodal, reasoning, tool use. Top-tier coding. | openai-compatible |
| **GLM-4.6** | 128K tokens | Cost-effective. Strong coding. | openai-compatible |
| **GLM-4-Flash** | 128K tokens | Fast, cheap. Good for small_model. | openai-compatible |

### API Endpoint
```
Base URL: https://api.z.ai/api/paas/v4
Auth: Bearer token (ZAI_API_KEY)
Compatible: OpenAI API format
```

### Integration
```json
{
  "provider": {
    "zai": {
      "options": {
        "baseURL": "https://api.z.ai/api/paas/v4",
        "apiKey": "{ZAI_API_KEY}"
      }
    }
  },
  "model": "zai/glm-5.2",
  "small_model": "zai/glm-4-flash"
}
```

### Why Critical
- Best price/performance for coding in RU/CN markets
- OpenAI-compatible — works with `@ai-sdk/openai-compatible`
- GLM-5.2 rivals Claude 4 Sonnet in coding benchmarks
- Free tier available

## 2. Moonshot — Kimi Series

### Current Models (July 2026)
| Model | Context | Strengths | API |
|-------|---------|-----------|-----|
| **Kimi K2** | 256K tokens | Agentic tool use, long context. Strong reasoning. | openai-compatible |
| **Kimi K2-Flash** | 256K tokens | Faster variant. | openai-compatible |

### API Endpoint
```
Base URL: https://api.moonshot.ai/v1
Auth: Bearer token (MOONSHOT_API_KEY)
Compatible: OpenAI API format
```

### Integration
```json
{
  "provider": {
    "moonshot": {
      "options": {
        "baseURL": "https://api.moonshot.ai/v1"
      }
    }
  }
}
```

### Notes
- Project already has moonshot provider, but model name "K2.6" is incorrect
- Should be "Kimi K2" or "moonshot/kimi-k2"

## 3. Anthropic — Claude Series

### Current Models (July 2026)
| Model | Context | Strengths | API |
|-------|---------|-----------|-----|
| **Claude 4 Opus** | 200K tokens | Most capable. Deep reasoning, coding. | native SDK |
| **Claude 4 Sonnet** | 200K tokens | Balanced. Best value. | native SDK |
| **Claude 4 Haiku** | 200K tokens | Fast, cheap. Good for small_model. | native SDK |
| **Claude 3.5 Sonnet** | 200K tokens | Legacy, still capable. | native SDK |

### Integration
opencode has native `@ai-sdk/anthropic` SDK. No baseURL needed.
```json
{
  "provider": {
    "anthropic": {}
  },
  "model": "anthropic/claude-4-opus",
  "small_model": "anthropic/claude-4-haiku"
}
```

### Notes
- Project says "Claude 4" — should specify "Claude 4 Opus" or "Claude 4 Sonnet"
- Anthropic has special headers for interleaved thinking + fine-grained tool streaming

## 4. OpenRouter — Aggregator

### Why Important
- Single API key → access to 100+ models
- Fallback chains across providers
- Price optimization
- Works with `@openrouter/ai-sdk-provider` (native in opencode)

### Integration
```json
{
  "provider": {
    "openrouter": {}
  },
  "model": "openrouter/anthropic/claude-4-opus",
  "small_model": "openrouter/deepseek/deepseek-v4-flash"
}
```

## 5. Alibaba — Qwen Series

### Current Models (July 2026)
| Model | Context | Strengths | API |
|-------|---------|-----------|-----|
| **Qwen3 235B** | 128K tokens | Top open-source model. Strong coding. | native SDK |
| **Qwen3 32B** | 128K tokens | Mid-size. Good balance. | native SDK |
| **Qwen3 14B** | 128K tokens | Small. Fast. | native SDK |

### Integration
opencode has native `@ai-sdk/alibaba` SDK.
```json
{
  "provider": {
    "alibaba": {}
  }
}
```

## 6. opencode Plugin Ecosystem

### Plugin Architecture (from opencode docs)
Plugins are JS/TS modules that hook into events:
- **Tool events:** `tool.execute.before`, `tool.execute.after`
- **Session events:** `session.created`, `session.idle`, `session.compacted`
- **File events:** `file.edited`, `file.watcher.updated`
- **Message events:** `message.updated`, `message.part.updated`
- **TUI events:** `tui.prompt.append`, `tui.command.execute`, `tui.toast.show`
- **Shell events:** `shell.env`
- **Permission events:** `permission.asked`, `permission.replied`
- **LSP events:** `lsp.client.diagnostics`, `lsp.updated`
- **Compaction hooks:** `experimental.session.compacting`

### Plugin Loading
1. Global config (`~/.config/opencode/opencode.json`) — npm packages
2. Project config (`opencode.json`) — npm packages
3. Global plugin dir (`~/.config/opencode/plugins/`) — local files
4. Project plugin dir (`.opencode/plugins/`) — local files

### Custom Tools
Plugins can add custom tools via `tool()` helper with Zod schema.

### Best Practices
1. Use `client.app.log()` instead of `console.log()` for structured logging
2. Use Bun shell API (`$`) for command execution
3. TypeScript plugins get type safety via `@opencode-ai/plugin`
4. Local plugins need `package.json` in config dir for npm dependencies
5. Plugins can inject env vars into all shell executions via `shell.env` hook

## 7. Recommended Provider Updates

### Add to registry
```bash
[zai]="ZAI_API_KEY|--zai-key|z.ai GLM-5.2|yes"
[openrouter]="OPENROUTER_API_KEY|--openrouter-key|OpenRouter (100+ models)|yes"
[alibaba]="ALIBABA_API_KEY|--alibaba-key|Alibaba Qwen3|yes"
[deepinfra]="DEEPINFRA_API_KEY|--deepinfra-key|DeepInfra (fast inference)|yes"
```

### Update model names
```bash
[xai]="XAI_API_KEY|--xai-key|xAI Grok 4|no"           # Grok 3 → Grok 4
[moonshot]="MOONSHOT_API_KEY|--moonshot-key|Moonshot Kimi K2|no"  # K2.6 → K2
[anthropic]="ANTHROPIC_API_KEY|--anthropic-key|Anthropic Claude 4 Opus|no"  # Claude 4 → Claude 4 Opus
```

### Default model recommendation
```json
{
  "model": "zai/glm-5.2",
  "small_model": "zai/glm-4-flash",
  "provider": {
    "zai": {
      "options": {
        "baseURL": "https://api.z.ai/api/paas/v4"
      },
      "fallback": ["deepseek", "opencode"]
    }
  }
}
```

## 8. Local LLM Backends (Isolated Circuit)

Already well-covered in project:
- Ollama (:11434) — primary
- LiteLLM (:4000) — proxy/gateway
- vLLM (:8000) — high-throughput
- SGLang (:30000) — structured generation

### Recommended local models
| Model | Size | Use case |
|-------|------|----------|
| qwen3:32b | 20GB | General coding |
| qwen3:14b | 9GB | Light coding |
| deepseek-v4:16b | 10GB | Coding specialist |
| llama3.3:70b | 40GB | General purpose |
| gemma3:27b | 17GB | Google ecosystem |
