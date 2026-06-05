# Языки программирования — версии и менеджеры

## Сводка

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

---

## Java 25 — Adoptium API

**Почему не SDKMAN:** SDKMAN часто падает по DNS в WSL2. Adoptium использует GitHub CDN — стабильно.

**Почему не apt:** `apt openjdk-25-jdk` может дать старую версию.

**Дополнительно через SDKMAN:**
- Gradle — система сборки
- Maven — система сборки
- Kotlin — JVM-язык
- jbang — запуск Java-скриптов

**Почему 25 а не 21 LTS:** Java 25 добавляет string templates, unnamed patterns, virtual threads улучшения.

---

## Node.js 22 — n

**Почему n:** легче nvm (без shell-хуков), быстрее fnm (без Rust-зависимости).

**Почему 22 а не 24:** 22 — LTS до апреля 2027. 24 ещё не LTS.

```bash
n 22           # установить Node 22
n lts          # последняя LTS
n latest       # последняя версия
```

---

## Python 3.12 — uv

**Почему uv:** в 10-100× быстрее pip. Написан на Rust. Управляет и пакетами, и версиями Python.

```bash
uv python install 3.12    # установить Python 3.12
uv pip install requests   # установить пакет
uv venv                   # создать venv
```

**Почему 3.12 а не 3.13:** TensorFlow/PyTorch ещё не полностью совместимы с 3.13.

---

## Go 1.24+ — прямая загрузка

**Почему не apt:** `apt golang-go` даёт устаревшую версию. Прямая загрузка с go.dev — всегда свежая.

**Почему не gvm:** gvm нестабилен в WSL2.

---

## Rust — rustup

**Почему rustup:** официальный инсталлятор. Переключение каналов (stable/beta/nightly), компоненты (rust-analyzer, clippy).

```bash
rustup update              # обновить
rustup component add clippy  # добавить линтер
```

---

## .NET 9 — dotnet-install.sh

**Почему не apt:** `apt dotnet-sdk-9.0` может отставать от релизов Microsoft.

```bash
dotnet-install.sh --channel 9.0
```

---

## Менеджеры пакетов — сравнение

| Менеджер | Язык | Скорость | Особенности |
|----------|------|----------|-------------|
| Gradle | Java/Kotlin | Средняя | Гибкость, Kotlin DSL |
| Maven | Java | Медленная | Стандарт enterprise |
| npm | Node.js | Медленная | Де-факто стандарт |
| bun | Node.js | Быстрая | All-in-one toolkit |
| uv | Python | Очень быстрая | Rust-based, 10-100× pip |
| pip | Python | Медленная | Стандарт, но устарел |
| go mod | Go | Быстрая | Встроен в Go |
| cargo | Rust | Средняя | Встроен в Rust |
| dotnet | .NET | Средняя | NuGet-based |
