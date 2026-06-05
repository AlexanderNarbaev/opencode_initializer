---
layout: default
title: Языки программирования — версии и менеджеры
description: 8 языков: Java 25, Node.js 22, Python 3.12, Go 1.24+, Rust, .NET 9, Kotlin, Zig. Менеджеры пакетов, сравнение.
---

[Главная](../index.md) · [Справка](../reference.md)

# Языки программирования

| Язык | Версия | Менеджер | Метод установки |
|------|--------|----------|----------------|
| Java | 25 LTS | SDKMAN | Adoptium API (GitHub CDN) |
| Node.js | 22 LTS | n | npx n 22 |
| Python | 3.12 | uv | uv python install 3.12 |
| Go | 1.24+ | go toolchain | go.dev/dl |
| Rust | stable | rustup | sh.rustup.rs |
| .NET | 9.0 | dotnet-install | dotnet-install.sh |
| Kotlin | 2.1+ | SDKMAN | sdk install kotlin |
| Zig | 0.14 | — | ziglang.org |

## Java 25 — Adoptium API

Почему Adoptium: стабильнее SDKMAN в WSL2 (SDKMAN падает по DNS). GitHub CDN.

Дополнительно через SDKMAN: Gradle, Maven, Kotlin, jbang.

## Node.js 22 — n

Почему n: легче nvm (без shell-хуков), быстрее fnm (без Rust-зависимости). 22 — LTS до апреля 2027.

## Python 3.12 — uv

Почему uv: в 10-100x быстрее pip. Rust-based. Управляет версиями Python и пакетами. 3.12 — стабильный, все библиотеки совместимы.

## Go 1.24+ — прямая загрузка

Почему не apt: даёт старую версию. Прямая загрузка с go.dev — всегда свежая.

## Rust — rustup

Официальный инсталлятор. Переключение каналов (stable/beta/nightly), компоненты (rust-analyzer, clippy).

## .NET 9 — dotnet-install.sh

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
