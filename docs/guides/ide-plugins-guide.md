## IDE AI Plugins Guide

### Installed by 38-ide-plugins.sh

| Plugin | IDE | License | Key Feature |
|--------|-----|---------|-------------|
| DevoxxGenie | JetBrains | Apache 2.0 | Local LLMs, RAG, MCP, agent mode, SDD |
| Cline | VS Code + JB | Apache 2.0 | AI coding agent, Ollama, multi-model |
| Tabby | VS Code + JB | Apache 2.0 | Self-hosted completion, no cloud |
| Llama Coder | VS Code | MIT | Ollama-only FIM completion |
| Aide | VS Code | MIT | Code transformations, batch AI |
| GPT Runner | VS Code | MIT | AI preset manager, custom endpoints |
| Aider | CLI | Apache 2.0 | Git-aware multi-file AI edits |

### Russian Ecosystem (optional)
| Tool | Type | Air-Gapped |
|------|------|------------|
| Veai | JetBrains plugin | VPC/self-hosting |
| GigaCode | Multi-IDE | GitVerse on-prem |
| GigaIDE | Standalone IDE | Local install |

### CPU-Only Models (via Ollama)
```bash
ollama pull codellama:code    # FIM completion (7B)
ollama pull qwen3:8b         # Fast coding (8B)
ollama pull qwen3:32b        # Advanced reasoning (32B)
ollama pull nomic-embed-text # Local embeddings
# GGUF via llama.cpp: Qwen3-Coder-30B-A3B, GigaChat-20B
```

### Air-Gapped Setup
```bash
bash setup.sh --full --isolated
dev isolated on
ollama pull qwen3:8b
```

