# opencode_platform v2.0 — Enterprise Dev Machine Design

> **Date:** 2026-06-29 | **Status:** design-approved | **Based on:** opencode_initializer v1.1.0

## Executive Summary

Превращение opencode_initializer из "установщика пакетов" в **платформу управления dev-машиной** с пятью независимыми слоями: инфраструктура, память и знания, условные плагины, наблюдаемость, GUI.

**Текущая проблема:** 70% компонентов установлены, но не работают — нет фундамента (БД, память, оркестрация, наблюдаемость). Платформа на бумаге мощная, по факту — ванильный opencode.

**Решение:** Всё — сервис. Всё — опционально. Всё — наблюдаемо.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  opencode_cockpit                     │
│          TUI (фаза 1) / SPA (фаза 2)                 │
│    ┌───────────────────────────────────────────┐    │
│    │  Статус сервисов │ Плагины │ Модели │ БД  │    │
│    │  Графики GPU/RAM │ Задачи  │ Сессии │ ... │    │
│    └──────────────┬────────────────────────────┘    │
├───────────────────┼─────────────────────────────────┤
│         cockpit CLI  (говорит через API)            │
│   cockpit status│start postgres│stop kafka│health   │
├───────────────────┼─────────────────────────────────┤
│            INFRA LAYER (Docker Compose)              │
│  ┌─────────┐ ┌───────┐ ┌──────┐ ┌─────┐ ┌───────┐ │
│  │PostgreSQL│ │Qdrant │ │Redis │ │Kafka│ │ Neo4j │ │
│  │  :5432  │ │ :6333 │ │:6379 │ │:9092│ │ :7474 │ │
│  └────┬────┘ └──┬────┘ └──┬───┘ └──┬──┘ └───┬───┘ │
│       │         │         │        │        │       │
│  ┌────┴────┬────┴────┬────┴───┬────┴───┬────┴────┐ │
│  │ Muninn  │ CodeGr. │Session │Orchestr│Plugins  │ │
│  │(memory) │(search) │Memory  │Tasks   │(data)   │ │
│  └─────────┴─────────┴────────┴────────┴─────────┘ │
├─────────────────────────────────────────────────────┤
│          Observability (Prometheus + Grafana)        │
│    :9090/metrics  ←  cAdvisor + node_exporter       │
│    :3001          ←  Grafana dashboards              │
└─────────────────────────────────────────────────────┘
```

---

## Phase 0: Stabilization

**Goal:** Починить всё, что задокументировано, но не работает.

### Tasks

| # | Task | Current State | Target |
|---|------|--------------|--------|
| 0.1 | Go upgrade | 1.22.5 | 1.26 |
| 0.2 | Zig install | not installed | 0.15.1 |
| 0.3 | Ollama models | 0 models | qwen3:14b, qwen3:1.8b, llava:7b |
| 0.4 | Muninn install | not installed | installed + initialized |
| 0.5 | CodeGraph init | no .codegraph/ | indexed for current project |
| 0.6 | LiteLLM install | binary missing | installed + config + systemd |
| 0.7 | Autoupdate fix | service failed | working systemd timer |
| 0.8 | Session memory | no sessions dir | JSON fallback working |

---

## Phase 1: Infra Layer

**Goal:** Docker Compose стек с PostgreSQL, Qdrant, Redis, Kafka, Neo4j, MinIO. Управление через cockpit CLI.

### Subsystem Design

**New module:** `src/lib/30-infra.sh`
**Config file:** `~/.config/opencode/infra.yml`

### Docker Compose Services

| Service | Image | Port | Volume | Purpose |
|---------|-------|------|--------|---------|
| PostgreSQL | `postgres:18-alpine` | 5432 | `opencode_pgdata` | Muninn, Orchestrator, plugin data |
| Qdrant | `qdrant/qdrant:latest` | 6333 | `opencode_qdrant_data` | CodeGraph vectors, Knowledge Base |
| Redis | `redis:7-alpine` | 6379 | `opencode_redis_data` | Sessions cache, PubSub |
| Kafka | `bitnami/kafka:latest` | 9092 | `opencode_kafka_data` | Event streaming, audit logs |
| Neo4j | `neo4j:5-community` | 7474 | `opencode_neo4j_data` | Knowledge graph |
| MinIO | `minio/minio:latest` | 9000 | `opencode_minio_data` | S3-compatible artifact storage |

### Management

```bash
cockpit infra up [pg|qdrant|redis|kafka|neo4j|minio|all]
cockpit infra down [service]
cockpit infra status
```

### Smart Detection

При повторных прогонах `setup.sh`:
1. Проверяет `docker ps` — какие сервисы уже запущены
2. Проверяет Docker volumes — какие данные есть
3. Предлагает: доставить недостающее, пропустить имеющееся
4. Единый конфиг `~/.config/opencode/infra.yml` — source of truth

### Interactive Mode

```
PostgreSQL для памяти сессий и плагинов? [Y/n]: y
Qdrant для векторного поиска по коду? [Y/n]: y
Redis для кэша и PubSub? [Y/n]: y
Kafka для потоковой обработки? [Y/n]: n
Neo4j для графа знаний? [Y/n]: n
MinIO для хранения артефактов? [Y/n]: n
```

### CLI Flags

```bash
setup.sh --with-postgres --with-qdrant --with-redis
setup.sh --with-all-infra
```

---

## Phase 2: Plugin Framework v2

**Goal:** Плагины с conditional enable, per-project конфигами, данными в БД.

### Plugin Tiers

| Tier | Description | Auto-enable? | Examples |
|------|-------------|-------------|----------|
| **always** | Критичны для платформы | Всегда | codegraph, dcp, auto-fallback, vibeguard, goal-mode |
| **conditional** | Включаются при условиях | Да, если deps ok | swarm (PG), daytona (daemon), devcontainers (Docker), orchestrator (PG) |
| **on-demand** | Только руками | Нет | scheduler, conductor, firecrawl, otel, morph-plugin |

### Plugin Matrix

```
ALWAYS:
  opencode-codegraph
  opencode-dcp
  opencode-auto-fallback
  opencode-vibeguard
  opencode-goal-mode

CONDITIONAL:
  opencode-swarm          — depends: postgresql
  opencode-daytona        — depends: daytona_daemon, auto_enable: false
  opencode-devcontainers  — depends: docker
  opencode-worktree       — depends: git_worktree
  opencode-background-agents — depends: redis
  opencode-orchestrator   — depends: postgresql
  opencode-supermemory    — depends: postgresql, qdrant
  opencode-goal-plugin    — depends: goal-mode
  opencode-zellij-namer   — depends: zellij

ON-DEMAND:
  opencode-scheduler
  opencode-conductor
  opencode-morph-plugin
  opencode-firecrawl
  opencode-plugin-otel
  opencode-websearch-cited
```

### Configuration: plugins.yml

```yaml
# ~/.config/opencode/plugins.yml (global defaults)
tiers:
  always:
    - opencode-codegraph
    - opencode-dcp
    - opencode-auto-fallback
    - opencode-vibeguard
    - opencode-goal-mode

  conditional:
    opencode-swarm:
      enabled: false
      auto_enable: true
      depends: [postgresql]
    opencode-daytona:
      enabled: false
      auto_enable: false
      depends: [daytona_daemon]
    opencode-background-agents:
      enabled: false
      auto_enable: true
      depends: [redis]

  on_demand: []
```

Per-project override: `.opencode/plugins.yml`

### opencode.json Generation

`18-opencode-json.sh` переписывается:
1. Читает `plugins.yml` (global merge project)
2. Проверяет `depends` (доступна ли БД? запущен ли Docker?)
3. Формирует `"plugin": [...]` только с enabled плагинами

### Management

```bash
cockpit plugins list              # таблица: имя, тир, статус, depends
cockpit plugins enable daytona    # включить глобально
cockpit plugins disable swarm     # выключить
cockpit plugins config daytona    # редактировать параметры
cockpit plugins status            # почему плагин conditional не включён
```

---

## Phase 3: Memory & Knowledge

**Goal:** Работающая сессионная память, поиск по коду, база знаний.

### 3.1 Muninn — Session Memory

**Tiers:**
- **Tier 1 (hot):** Redis — текущая сессия, кэш
- **Tier 2 (warm):** PostgreSQL — история сессий, decisions, next steps
- **Tier 3 (cold):** JSON files — fallback без БД

**Auto-detect:** При старте проверяет PostgreSQL → если есть → полный режим; нет → JSON-фолбек.

### 3.2 CodeGraph — Code Index & Search

- `cockpit codegraph init` при создании проекта
- Индекс → Qdrant (если доступен) или локальный
- `cockpit codegraph status` — статус индексации
- В opencode.json: `codegraph` MCP только если индекс существует

### 3.3 Knowledge Base — Qdrant

- Два неймспейса: `global` (кросспроектные) и `<project>` (проектные)
- `cockpit knowledge search "как настроен auth"`

### 3.4 Feature Matrix: with/without Infra

| Feature | With Infra (PG+Qdrant) | Without Infra (fallback) |
|---------|----------------------|-------------------------|
| Session memory | PostgreSQL — all sessions | JSON files — last only |
| Code search | Qdrant — instant | Local index — slow |
| Knowledge Base | Qdrant — full | Not available |
| Knowledge Graph | Neo4j — relations | Not available |

---

## Phase 4: Observability

**Goal:** TUI-панель управления + Grafana дашборды.

### 4.1 Cockpit TUI

**Technology:** Go + [bubbletea](https://github.com/charmbracelet/bubbletea) + [bubbles](https://github.com/charmbracelet/bubbles)

**Binary:** `~/.local/bin/cockpit` (single static binary, no dependencies)

**Screens (F1-F10):**

| Key | Screen | Content |
|-----|--------|---------|
| F1 | Services | Docker containers status, CPU/RAM per container |
| F2 | Plugins | Plugin list, tier, status, depends, enable/disable |
| F3 | Models | Ollama/vLLM models, load status, VRAM usage |
| F4 | Sessions | Active opencode sessions, memory, WAL state |
| F5 | Tasks | Orchestrator tasks, progress |
| F6 | Logs | System log stream |
| F7 | Infra | DB management: start/stop/restart |
| F8 | Config | View/edit plugins.yml, infra.yml |
| F9 | Grafana | Quick open in browser |
| F10 | Help | Key bindings reference |

**Data sources (all localhost, read-only):**
- `docker ps --format json`, `docker stats --no-stream`
- `systemctl --user list-units`
- `ollama list`
- `curl localhost:8000/api/v2/heartbeat` (ChromaDB)
- `curl localhost:3000/api/version` (Open WebUI)
- `~/.config/opencode/plugins.yml`, `~/.config/opencode/infra.yml`
- `nvidia-smi`

### 4.2 Grafana + Prometheus

**Exporters:**
- `node_exporter` (:9100) — CPU, RAM, disk, network
- `cAdvisor` (:8080) — Docker containers
- NVIDIA GPU Prometheus exporter — GPU metrics
- `postgres_exporter` (:9187) — queries, connections
- `redis_exporter` (:9121) — cache hits

**Pre-configured dashboards:**
- Dev Machine Overview
- GPU Dashboard (VRAM, utilization, temperature)
- OpenCode Sessions (active sessions, token usage)
- Infra Health (DB status, latency)

**Launch:** `cockpit observability up` — Prometheus + Grafana in Docker, `:3001` with pre-configured dashboards.

### 4.3 New modules

| File | Purpose |
|------|---------|
| `src/lib/31-cockpit.sh` | Build/install cockpit TUI binary |
| `src/lib/32-observability.sh` | Prometheus + Grafana setup |

---

## Phase 5: GUI / SPA

**Goal:** Полноценный веб-интерфейс управления (фаза 2).

- API server (Go/Node) on `:4200`
- SPA frontend (React/Svelte)
- WinForms-like controls (property grids, toggle panels, wizards)
- Same screens as TUI + additional charts
- Embed Grafana iframes for dashboards

---

## CLI Surface

### setup.sh — New Flags

```bash
--with-postgres / --with-qdrant / --with-redis   # individual infra services
--with-kafka / --with-neo4j / --with-minio
--with-all-infra                                   # all DB services
--skip-plugins "daytona,firecrawl,scheduler"       # exclude plugins
--plugin-tier on-demand                            # install only always+conditional
--cockpit                                          # install cockpit TUI
--observability                                    # install Prometheus+Grafana
--enterprise                                       # = all-infra + cockpit + observability
```

### dev.sh — New Commands

```bash
dev infra up [pg|qdrant|redis|kafka|neo4j|all]
dev infra down [service]
dev infra status
dev cockpit install|update
dev cockpit health
dev plugins list|enable|disable|config
dev observability up|down|status
```

### cockpit CLI — New Binary

```bash
cockpit                              # launch TUI
cockpit status                       # one-line health summary
cockpit infra up --all               # start all infra
cockpit infra down kafka             # stop Kafka
cockpit plugins enable swarm         # enable plugin globally
cockpit plugins list                 # plugin table
cockpit models pull qwen3:14b        # pull model to Ollama
cockpit health                       # full diagnostic
cockpit memory status                # Muninn + sessions + KB status
cockpit knowledge search "auth"      # search knowledge base
```

---

## New Configuration Files

```
~/.config/opencode/
├── opencode.json          # generated (as before)
├── plugins.yml            # NEW: plugin tiers and settings
├── infra.yml              # NEW: Docker Compose config
├── cockpit.yml            # NEW: TUI settings (theme, keybinds)
└── auth.json              # unchanged

<project>/.opencode/
├── plugins.yml            # NEW: per-project plugin override
└── opencode.json          # generated with plugins.yml consideration
```

---

## Backward Compatibility

**Ничего не ломаем:**
- `setup.sh` без новых флагов работает как раньше
- `opencode.json` без `plugins.yml` генерируется со всеми плагинами (current behavior)
- Все существующие тесты продолжают проходить
- Новые модули следуют существующим конвенциям: `NN-name.sh`, `set -euo pipefail`, `_step_skip/_step_done`

---

## Constraints

- No secrets in code — all API keys via CLI args or env
- `bash -n` passes on all modified files
- ShellCheck passes on all `.sh` files
- All new installs use `|| true` to tolerate failures
- New tests cover new component counts
- Existing test suite must still pass
