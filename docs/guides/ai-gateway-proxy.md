# Corporate AI Gateway Proxy

## Overview

For enterprise environments where direct access to external AI providers is restricted, opencode_initializer supports routing all LLM traffic through a corporate AI Gateway (Envoy, Kong, NGINX, etc.).

## Architecture

```
Developer IDE (Cursor/VS Code/OpenCode)
    ↓
Corporate AI Gateway (Envoy/Kong)
    ↓ DLP + PII + Compliance
    ↓
External AI Providers (DeepSeek/OpenAI/Anthropic/...)
```

## Configuration

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `OPENCODE_PROXY_URL` | Global proxy URL for all providers | `https://ai-gateway.corp.com/v1` |
| `OPENCODE_PROXY_DEEPSEEK` | Per-provider override | `https://ai-gateway.corp.com/deepseek/v1` |
| `OPENCODE_PROXY_OPENAI` | Per-provider override | `https://ai-gateway.corp.com/openai/v1` |
| `OPENCODE_PROXY_ANTHROPIC` | Per-provider override | `https://ai-gateway.corp.com/anthropic/v1` |
| `OPENCODE_PROXY_GOOGLE` | Per-provider override | `https://ai-gateway.corp.com/google/v1` |

### Quick Start

```bash
# Set in .env or export
export OPENCODE_PROXY_URL="https://ai-gateway.corp.example.com/v1"

# Run setup — all providers will route through the proxy
bash setup.sh --full
```

### opencode.json Configuration

The proxy can also be configured directly in `opencode.json`:

```json
{
  "provider": {
    "deepseek": {
      "options": {
        "baseURL": "https://ai-gateway.corp.example.com/deepseek/v1"
      }
    }
  }
}
```

## Compliance Framework

The gateway should implement:

1. **DLP Pipeline**: PII detection, secret scanning, code detection
2. **Data Classification**: Д-0 (public) to Д-5 (restricted)
3. **Audit Trail**: Log all prompts/responses to SIEM
4. **Tokenization**: Replace PII with tokens before sending to external providers
5. **Anti-Jailbreak**: NVIDIA NeMo Guardrails or similar

## Russian Compliance

- **152-ФЗ**: Personal data protection — PII must be tokenized
- **98-ФЗ**: Commercial secrets — code and business data must not leave perimeter
- **Kaspersky Guidelines**: Follow the corporate AI security checklist
