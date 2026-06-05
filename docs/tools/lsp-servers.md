---
layout: default
title: LSP-серверы — автодополнение и навигация
description: 10 Language Server Protocol серверов: gopls, rust-analyzer, typescript, pyright, omnisharp, yaml, marksman, taplo, lua, zls.
---

[Главная](../index.md) · [Справка](../reference.md)

# LSP-серверы

LSP (Language Server Protocol) даёт редактору: автодополнение, подсветку ошибок, навигацию по коду, рефакторинг.

| LSP | Язык | Расширения |
|-----|------|-----------|
| gopls | Go | `.go` |
| rust-analyzer | Rust | `.rs` |
| typescript-language-server | TypeScript/JS | `.ts`, `.tsx`, `.js`, `.jsx` |
| pyright | Python | `.py` |
| omnisharp | C# | `.cs` |
| yaml-language-server | YAML | `.yaml`, `.yml` |
| marksman | Markdown | `.md` |
| taplo | TOML | `.toml` |
| lua-language-server | Lua | `.lua` |
| zls | Zig | `.zig` |

## gopls — Go

Официальный LSP от Google. Автодополнение, навигация (Go to Def, Find Refs), рефакторинг, диагностика.

## rust-analyzer — Rust

Де-факто стандарт. Inlay hints (типы в коде), expand macro, view memory layout.

## typescript-language-server — TypeScript

Автодополнение с полной типизацией, проверка ошибок. Обёртка над tsserver с LSP-совместимостью.

## pyright — Python

От Microsoft. Быстрее и строже Pylance. Статическая типизация (PEP 484). В 3-5x быстрее jedi.

## omnisharp — C#

Стандартный LSP для .NET. Интеграция с .csproj/sln.

## yaml-language-server — YAML

Валидация YAML, автодополнение схем (Kubernetes, Docker Compose, GitHub Actions, GitLab CI, OpenAPI).

## marksman — Markdown

Навигация по заголовкам, проверка ссылок между .md файлами.

## taplo — TOML

Форматирование и валидация (Cargo.toml, pyproject.toml).

## lua-language-server — Lua

Для Neovim-конфигураций.

## zls — Zig

LSP для Zig: автодополнение, проверка ошибок, навигация.
