# Hybrid AI Architecture for Air-Gapped Development — ADR

**Status:** ACCEPTED | **Date:** 2026-07-18

## Decision: Hybrid Core + Modular Agents

### Architecture: DevoxxGenie (core) + Cline (VS Code) + Veai (RU, opt) + Tabby (completion)
### LLM: llama.cpp / Ollama — CPU-optimized, OpenAI-compatible API
### MCP: filesystem, git, SAST, jfr, memory — all local
### Memory: Memory Bank (.md) + RAG (Qdrant/ChromaDB)
### Models: Qwen3-Coder-30B, GigaChat-20B, CodeLlama:code, nomic-embed-text
### Observability: Prometheus + Grafana

## Component Selection (weighted analysis v2)

| Component | Role | License | Score |
|-----------|------|---------|-------|
| DevoxxGenie | Core IDE agent | Apache 2.0 | 8.55 |
| Veai | RU-market agent | Proprietary | 8.10 |
| Continue.dev | Archived | Apache 2.0 | 8.20 |
| Cline | VS Code agent | Apache 2.0 | 8.05 |

DevoxxGenie selected as core due to open-source + approve workflow.
Veai recommended for RU organizations requiring geopolitical resilience.

## Russian Ecosystem

| Tool | Type | Air-Gapped |
|------|------|------------|
| Veai | JetBrains plugin | VPC/self-hosting |
| GigaCode | Multi-IDE plugin | GitVerse on-prem |
| GigaIDE | Standalone IDE | Local install |
| GigaChat-20B | LLM (GGUF) | llama.cpp |
| SourceCraft | JetBrains+VS Code | Verify |

All IDE plugins in 38-ide-plugins.sh are open-source (Apache 2.0/MIT).
Proprietary tools documented but not auto-installed.

