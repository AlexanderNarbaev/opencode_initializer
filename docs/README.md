---
layout: default
title: Документация — opencode_initializer
description: Карта документации opencode_initializer: руководства, FAQ, troubleshooting, справка
nav_order: 1
---

# Документация opencode_initializer v36.0

## Основные страницы

| Страница | Описание |
|----------|----------|
| [Главная](index.md) | Обзор проекта, быстрый старт, режимы работы |
| [Руководство](guide.md) | Полное руководство: установка, настройка, OpenCode, MCP, плагины, GPU |
| [FAQ](faq.md) | Ответы на частые вопросы: установка, WSL2, API-ключи, ZSH, GPU |
| [Troubleshooting](troubleshooting.md) | Диагностика и пошаговое исправление проблем |
| [Справка](reference.md) | 80+ ссылок на официальную документацию и ресурсы |
| [База знаний](KNOWLEDGE.md) | Глубокий анализ: модели, GPU, RAG, безопасность, CI/CD |

## Инструменты и компоненты

| Страница | Описание |
|----------|----------|
| [Языки](tools/languages.md) | 8 языков: Java, Node.js, Python, Go, Rust, .NET, Kotlin, Zig |
| [MCP-серверы](tools/mcp-servers.md) | 21+ MCP-серверов: описание, примеры, команды |
| [Плагины](tools/plugins.md) | 20+ плагинов: безопасность, оркестрация, мониторинг |
| [Провайдеры](tools/providers.md) | 6 AI-провайдеров: DeepSeek, OpenCode Go, xAI Grok и другие |
| [LSP-серверы](tools/lsp-servers.md) | 13 LSP-пакетов (15 серверов) для автодополнения кода |
| [GPU и LLM](tools/gpu-llm.md) | Локальный инференс: Ollama, vLLM, SGLang, Open WebUI |
| [Безопасность](tools/security.md) | 5 уровней защиты: секреты, фильтрация, сканирование |
| [Агенты](tools/agents.md) | 16 ролей агентов: developer, architect, qa, security и другие |

## Промпты и исследования

| Страница | Описание |
|----------|----------|
| [Системные промпты](prompts/system-prompts.md) | Оптимизированные промпты для моделей и ролей агентов |
| [Исследования](research/) | Материалы глубоких исследований |

## Быстрые ссылки для решения проблем

- Что-то сломалось → [Troubleshooting](troubleshooting.md)
- Не работает после обновления → `bash setup.sh --fix-config` или [FAQ: Обновление](faq.md#обновление)
- Терминал глючит → `bash setup.sh --fix-zshrc` или [Troubleshooting: ZSH](troubleshooting.md#проблемы-с-zsh)
- MCP не стартует → [Troubleshooting: MCP](troubleshooting.md#проблемы-с-mcp-серверами)
- OpenCode не видит ключи → [FAQ: API ключи](faq.md#api-ключи)
- WSL2 проблемы → [FAQ: WSL2](faq.md#wsl2)
