# AI Gateway Best Practices — Research 2026-08-10

> Source: Enterprise AI governance chat analysis + industry research

## Key Findings

### 1. Gateway Architecture Patterns

| Pattern | Pros | Cons | Best For |
|---------|------|------|----------|
| **Envoy + ext_proc** | High performance, Go/Python plugins | Complex setup | Large enterprises |
| **Kong API Gateway** | Plugin ecosystem, Lua/Go | Higher latency | Mid-size teams |
| **NGINX + Lua** | Lightweight, fast | Limited AI-specific features | Small teams |
| **Custom Go proxy** | Full control | Maintenance burden | Specialized needs |

### 2. DLP Pipeline Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| Secret Scanner | TruffleHog, detect-secrets | Block API keys, tokens |
| PII Detector | Presidio, custom regex | Tokenize ФИО, паспорта |
| Code Detector | AST parser (Semgrep) | Route code to local LLM |
| Prompt Injection | NeMo Guardrails, DeBERTa | Block jailbreaks |
| License Checker | Scancode, FOSSology | Prevent GPL contamination |

### 3. Data Classification (Russian Framework)

| Level | Description | AI Access |
|-------|-------------|-----------|
| Д-0 | Public data | Any provider |
| Д-1 | Internal data | Tokenized external OK |
| Д-2 | Confidential | Local LLM only |
| Д-3 | Commercial secret (98-ФЗ) | Local LLM + audit |
| Д-4 | Personal data (152-ФЗ) | Tokenized + audit |
| Д-5 | State secret | Absolute prohibition |

### 4. Compliance Checklist

- [ ] 152-ФЗ: PII tokenization before external send
- [ ] 98-ФЗ: Commercial secrets never leave perimeter
- [ ] Kaspersky: Follow corporate AI security guide
- [ ] Audit: Log all prompts/responses to SIEM
- [ ] DLP: Block secrets, PII, code in prompts
- [ ] Anti-jailbreak: NeMo Guardrails or equivalent
- [ ] License: SCA scan on generated code
- [ ] Quotas: Per-department token budgets

### 5. Recommended Stack for opencode_initializer

Based on the analysis, the recommended enterprise stack is:

1. **Gateway**: Envoy Proxy with `ext_proc` filter (Go plugin)
2. **DLP**: Presidio (PII) + TruffleHog (secrets) + Semgrep (code)
3. **Anti-Jailbreak**: NVIDIA NeMo Guardrails
4. **Audit**: Langfuse or Arize Phoenix
5. **SIEM**: MaxPatrol SIEM or RuSIEM
6. **Auth**: Keycloak (OIDC) + Active Directory (Kerberos)
7. **RAG**: Qdrant with ACL-aware indexing
