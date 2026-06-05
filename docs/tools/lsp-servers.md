[← На главную](../index.md) · [Все инструменты](../index.md#навигация) · [Справка](../reference.md)

# LSP-серверы — автодополнение и навигация

> 🟢 Начинающим &nbsp; 🟡 Практикующим

LSP (Language Server Protocol) даёт редактору: автодополнение, подсветку ошибок, навигацию по коду, рефакторинг.

## Установленные LSP

| LSP | Язык | Расширения | Команда |
|-----|------|-----------|---------|
| gopls | Go | `.go` | `gopls` |
| rust-analyzer | Rust | `.rs` | `rust-analyzer` |
| typescript-language-server | TypeScript/JS | `.ts`, `.tsx`, `.js`, `.jsx` | `typescript-language-server --stdio` |
| pyright | Python | `.py` | `pyright-langserver --stdio` |
| omnisharp | C# | `.cs` | `omnisharp --stdio` |
| yaml-language-server | YAML | `.yaml`, `.yml` | `yaml-language-server --stdio` |
| marksman | Markdown | `.md` | `marksman server` |
| taplo | TOML | `.toml` | `taplo lsp stdio` |
| lua-language-server | Lua | `.lua` | `lua-language-server` |
| zls | Zig | `.zig` | `zls` |

---

## gopls — Go

Официальный LSP от Google. Самое полное покрытие языка Go.

**Возможности:**
- Автодополнение с учётом типов
- Навигация (Go to Definition, Find References)
- Рефакторинг (Rename, Extract Function)
- Диагностика (ошибки компиляции, линтер)

---

## rust-analyzer — Rust

Де-факто стандарт для Rust. Показывает типы переменных, автодополнение, clippy-подсказки.

**Уникальные фичи:**
- Inlay hints (показывает типы прямо в коде)
- Expand macro (разворачивает макросы)
- View memory layout (раскладка struct в памяти)

---

## typescript-language-server — TypeScript

Автодополнение с полной типизацией, проверка ошибок на лету.

**Почему не tsserver напрямую:** typescript-language-server — обёртка над tsserver с LSP-совместимостью.

---

## pyright — Python

От Microsoft. Быстрее и строже чем Pylance.

**Почему не Pylance:** Pylance — проприетарный, pyright — open-source. Качество сопоставимо.

**Преимущества над jedi:**
- Статическая типизация (PEP 484)
- Type checking на лету
- В 3-5× быстрее на больших проектах

---

## omnisharp — C#

Стандартный LSP для .NET. Интеграция с .csproj/sln.

---

## yaml-language-server — YAML

Валидация YAML-файлов, автодополнение схем.

**Поддерживаемые схемы:**
- Kubernetes (k8s)
- Docker Compose
- GitHub Actions
- GitLab CI
- OpenAPI / Swagger

**Пример:** редактируете `docker-compose.yml` — сервер подсказывает доступные ключи (`services`, `volumes`, `networks`).

---

## marksman — Markdown

Навигация по заголовкам, проверка ссылок между `.md` файлами.

**Пример:** в проекте с документацией marksman проверяет что все `[ссылки](file.md)` ведут на существующие файлы.

---

## taplo — TOML

Форматирование и валидация TOML-файлов.

**Где используется TOML:**
- `Cargo.toml` (Rust)
- `pyproject.toml` (Python)
- `go.mod` альтернативы

---

## lua-language-server — Lua

Для Neovim-конфигураций и скриптов.

---

## zls — Zig

LSP для Zig. Автодополнение, проверка ошибок, навигация.
