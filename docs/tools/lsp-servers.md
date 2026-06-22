---
layout: default
title: LSP-серверы — автодополнение и навигация
description: 13 LSP-пакетов (15 серверов): gopls, rust-analyzer, typescript, pyright, omnisharp, yaml, marksman, taplo, lua, zls, bash, dockerfile, css+html+json.
---

[Главная](../index.md) · [Справка](../reference.md)

# LSP-серверы

LSP (Language Server Protocol) даёт редактору: автодополнение, подсветку ошибок, навигацию по коду, рефакторинг.

| LSP | Язык | Расширения | Установка |
|-----|------|-----------|-----------|
| gopls | Go | `.go` | `go install golang.org/x/tools/gopls@latest` |
| rust-analyzer | Rust | `.rs` | `rustup component add rust-analyzer` |
| typescript-language-server | TypeScript/JS | `.ts`, `.tsx`, `.js`, `.jsx` | npm global |
| pyright | Python | `.py` | npm global |
| omnisharp / csharp-ls | C# | `.cs` | `dotnet tool install -g csharp-ls` |
| yaml-language-server | YAML | `.yaml`, `.yml` | npm global |
| marksman | Markdown | `.md` | GitHub binary → `~/.local/bin` |
| taplo | TOML | `.toml` | npm global |
| lua-language-server | Lua | `.lua` | GitHub tar → `~/.local/bin` |
| zls | Zig | `.zig` | GitHub tar → `~/.local/bin` |
| bash-language-server | Bash | `.sh`, `.bash` | npm global |
| dockerfile-language-server | Dockerfile | `Dockerfile` | npm global |
| vscode-langservers-extracted | CSS/HTML/JSON | `.css`, `.html`, `.json`, `.jsonc` | npm global (3 сервера в 1 пакете) |

## gopls — Go

Официальный LSP от Google. Автодополнение, навигация (Go to Def, Find Refs), рефакторинг, диагностика.
[Документация](https://pkg.go.dev/golang.org/x/tools/gopls)

## rust-analyzer — Rust

Де-факто стандарт. Inlay hints (типы в коде), expand macro, view memory layout.
[Документация](https://rust-analyzer.github.io/)

## typescript-language-server — TypeScript

Автодополнение с полной типизацией, проверка ошибок. Обёртка над tsserver с LSP-совместимостью.
[GitHub](https://github.com/typescript-language-server/typescript-language-server)

## pyright — Python

От Microsoft. Быстрее и строже Pylance. Статическая типизация (PEP 484). В 3-5x быстрее jedi.
[GitHub](https://github.com/microsoft/pyright)

## omnisharp / csharp-ls — C#

Стандартный LSP для .NET. Интеграция с .csproj/sln.
[GitHub](https://github.com/OmniSharp/omnisharp-roslyn)

## yaml-language-server — YAML

Валидация YAML, автодополнение схем (Kubernetes, Docker Compose, GitHub Actions, GitLab CI, OpenAPI).
[GitHub](https://github.com/redhat-developer/yaml-language-server)

## marksman — Markdown

Навигация по заголовкам, проверка ссылок между .md файлами.
[GitHub](https://github.com/artempyanykh/marksman)

## taplo — TOML

Форматирование и валидация (Cargo.toml, pyproject.toml).
[GitHub](https://github.com/tamasfe/taplo)

## lua-language-server — Lua

Для Neovim-конфигураций и Lua-скриптов.
[GitHub](https://github.com/LuaLS/lua-language-server)

## zls — Zig

LSP для Zig: автодополнение, проверка ошибок, навигация.
[GitHub](https://github.com/zigtools/zls)

## bash-language-server — Bash

Автодополнение, проверка синтаксиса, переход к определениям для shell-скриптов.
[GitHub](https://github.com/bash-lsp/bash-language-server)

## dockerfile-language-server — Dockerfile

Валидация Dockerfile, автодополнение инструкций, подсветка ошибок.
[GitHub](https://github.com/rcjsuen/dockerfile-language-server-nodejs)

## vscode-langservers-extracted — CSS, HTML, JSON

Три сервера в одном пакете: `vscode-css-language-server`, `vscode-html-language-server`, `vscode-json-language-server`.
[GitHub](https://github.com/hrsh7th/vscode-langservers-extracted)
