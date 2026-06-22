---
layout: default
title: Языки программирования — версии и менеджеры
description: 8 языков: Java 25, Node.js 24, Python 3.14, Go 1.26, Rust, .NET 10, Kotlin, Zig 0.16. Менеджеры пакетов, сравнение.
---

[Главная](../index.md) · [Справка](../reference.md)

# Языки программирования

| Язык | Версия | Менеджер | Метод установки |
|------|--------|----------|----------------|
| Java | 25 LTS | SDKMAN | Adoptium API (GitHub CDN) |
| Node.js | 24 LTS | n | npx n 24 |
| Python | 3.14 | uv | uv python install 3.14 |
| Go | 1.26 | go toolchain | go.dev/dl |
| Rust | stable | rustup | sh.rustup.rs |
| .NET | 10.0 | dotnet-install | dotnet-install.sh |
| Kotlin | 2.1+ | SDKMAN | sdk install kotlin |
| Zig | 0.16 | — | ziglang.org |

## Java 25 — Adoptium API

Почему Adoptium: стабильнее SDKMAN в WSL2 (SDKMAN падает по DNS). GitHub CDN.

Дополнительно через SDKMAN: Gradle, Maven, Kotlin, jbang.

## Node.js 24 — n

Почему n: легче nvm (без shell-хуков), быстрее fnm (без Rust-зависимости). 24 — LTS.

## Python 3.14 — uv

Почему uv: в 10-100x быстрее pip. Rust-based. Управляет версиями Python и пакетами. 3.14 — стабильный, все библиотеки совместимы.

## Go 1.26 — прямая загрузка

Почему не apt: даёт старую версию. Прямая загрузка с go.dev — всегда свежая.

## Rust — rustup

Официальный инсталлятор. Переключение каналов (stable/beta/nightly), компоненты (rust-analyzer, clippy).

## .NET 10 — dotnet-install.sh

Microsoft-скрипт, всегда актуальная версия. apt может отставать.

## Менеджеры пакетов — сравнение

| Менеджер | Язык | Скорость | Особенности |
|----------|------|----------|-------------|
| Gradle | Java/Kotlin | Средняя | Kotlin DSL, гибкость |
| Maven | Java | Медленная | Стандарт enterprise |
| npm | Node.js | Медленная | Де-факто стандарт |
| bun | Node.js | Быстрая | All-in-one |
| uv | Python | Очень быстрая | Rust-based |
| pip | Python | Медленная | Стандарт |
| go mod | Go | Быстрая | Встроен |
| cargo | Rust | Средняя | Встроен |
