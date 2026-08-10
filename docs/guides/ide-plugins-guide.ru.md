# Руководство по IDE AI-плагинам

> [EN](ide-plugins-guide.md) | [RU](ide-plugins-guide.ru.md)

### Устанавливается модулем 38-ide-plugins.sh

| Плагин | IDE | Лицензия | Ключевая возможность |
|--------|-----|---------|-------------|
| DevoxxGenie | JetBrains | Apache 2.0 | Локальные LLM, RAG, MCP, режим агента, SDD |
| Cline | VS Code + JB | Apache 2.0 | AI-агент для кодинга, Ollama, мульти-модель |
| Tabby | VS Code + JB | Apache 2.0 | Self-hosted автодополнение, без облака |
| Llama Coder | VS Code | MIT | FIM-автодополнение только через Ollama |
| Aide | VS Code | MIT | Трансформации кода, пакетный AI |
| GPT Runner | VS Code | MIT | Менеджер AI-пресетов, пользовательские endpoints |
| Aider | CLI | Apache 2.0 | Git-aware мульти-файловые AI-правки |

### Российская экосистема (опционально)
| Инструмент | Тип | Автономность |
|------|------|------------|
| Veai | Плагин JetBrains | VPC / self-hosting |
| GigaCode | Мульти-IDE | GitVerse on-prem |
| GigaIDE | Отдельная IDE | Локальная установка |

### Модели для CPU (через Ollama)
```bash
ollama pull codellama:code    # FIM-автодополнение (7B)
ollama pull qwen3:8b         # Быстрый кодинг (8B)
ollama pull qwen3:32b        # Продвинутое рассуждение (32B)
ollama pull nomic-embed-text # Локальные эмбеддинги
# GGUF через llama.cpp: Qwen3-Coder-30B-A3B, GigaChat-20B
```

### Настройка автономного режима (Air-Gapped)
```bash
bash setup.sh --full --isolated
dev isolated on
ollama pull qwen3:8b
```
