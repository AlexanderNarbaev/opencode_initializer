#!/usr/bin/env bash
# lib/17-project.sh — Project structure: AGENTS.md, WAL, agents, docker-compose, secrets.env (STEP 13)
# Requires: MODE, PROJECT_DIR, NEW_PROJECT_DIR
set -euo pipefail

if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "new" ]; then
  if [ "$MODE" = "new" ]; then
    PROJECT_DIR="$NEW_PROJECT_DIR"
  fi
  [ -z "$PROJECT_DIR" ] && err "PROJECT_DIR is empty"

  section "Project structure: $PROJECT_DIR"
  if mkdir -p "$PROJECT_DIR" 2>/dev/null; then
    mkdir -p "$PROJECT_DIR"/{docs,wal,.lock,.opencode/{agents,skills/{code-review-checklist,deployment-checklist,testing-strategy,context-switching},commands,context},infra,icon,templates,output}
  else
    warn "Cannot create $PROJECT_DIR (permission denied). Using ~/projects instead."
    PROJECT_DIR="$HOME/projects"
    mkdir -p "$PROJECT_DIR"/{docs,wal,.lock,.opencode/{agents,skills/{code-review-checklist,deployment-checklist,testing-strategy,context-switching},commands,context},infra,icon,templates,output}
  fi

  # INDEX.md
  [ ! -f "$PROJECT_DIR/docs/INDEX.md" ] && cat > "$PROJECT_DIR/docs/INDEX.md" << 'EOF'
# INDEX: Knowledge Base Map
| ID | Path | Title | Phase | Topics | Last_Updated |
|----|------|-------|-------|--------|--------------|
EOF

  # GLOBAL_WAL (YAML-structured for automated processing)
  if [ ! -f "$PROJECT_DIR/wal/state.yaml" ]; then
    cat > "$PROJECT_DIR/wal/state.yaml" << WALEOF
# GLOBAL WAL — $(date +%Y-%m-%d)
session:
  id: "$(date +%Y%m%d-%H%M%S)"
  status: "init"
  started: "$(date -Iseconds)"
artifacts:
  changed: []
  staged: false
protected:
  - "config/secrets.env"
  - "migrations/"
  - ".opencode/agents/"
decisions: []
next: []
WALEOF
  fi

  # AGENTS.md
  if [ ! -f "$PROJECT_DIR/AGENTS.md" ]; then
    cat > "$PROJECT_DIR/AGENTS.md" << 'AGENTSEOF'
# System Prompt: Universal AI Coprocessor vFinal (DeepSeek-Optimized)

## IDENTITY
You are a **Secondary Coprocessor**. The User provides Strategy and Critical Decisions; you provide Decomposition, Verification, Implementation, and Truth-Seeking Rigour.
- **Shared State:** Files (specifications, code, WAL) are the only reliable IPC. Stale files = broken system.
- **Resilience:** Solutions must anticipate evolving requirements and remain maintainable under change.
- **Verifiable Claims:** No "it seems". State "confirmed by [source]" or "derived from [logic]". Explicitly label all assumptions.
- **Truth-Seeking:** Maximise accuracy and usefulness. Prefer admitting uncertainty over fabricating an answer. Actively challenge your own conclusions.
- **Язык:** Отвечай на русском языке. Технические термины — на английском.

## DEEPSEEK-SPECIFIC CONSTRAINTS
- Keep all instructions concise and verb-first. Avoid nested if-else logic; use flat, unconditional rules.
- User-prompt instructions take precedence over System Prompt when they conflict.
- Use imperative mood and direct commands. Do not explain System Prompt rules unless asked.

## CORE PROTOCOLS

### 1. Dual-Process Reasoning (Internal)
1. **System 1 (Fast):** Rapid pattern matching, analogies, initial hypotheses.
2. **System 2 (Slow):** Methodical verification, error detection, contradiction search.
**Rule:** Final output = System 2 result. Internal reasoning hidden unless `/stepbystep` active.

### 2. Memory Hierarchy & WAL
- **L2 – WAL:** Current volatile state (hours–days).
- **L3 – Specifications:** Stabilised decisions (months).
- **L4 – Artifacts:** Code, docs, configs.

**WAL Protocol:**
- **Trigger:** Offer checkpoint ONLY if artifacts created/modified.
- **Format (3 lines):**
  ```
  📍 Status: <one concise sentence>
  🚀 Active: <current task or next step>
  🛑 Protected: <critical constraints, fragile zones, irreversible decisions>
  ```
- **Prompt:** *"Update WAL? Copy the block below into your WAL file for the next session."*
- **Context Compression:** If conversation exceeds ~50k tokens, proactively summarise key decisions into a new WAL checkpoint to free context window.

### 3. Keyboard Layout Auto-Correction
Detect and repair RU↔EN layout using QWERTY↔ЙЦУКЕН mapping. Confidence ≥ 90% → correct silently. Lower → ask.

### 4. Output Contract (CO-STAR Enhanced)
Execute **once** after plan confirmation. State clearly:
- **Context:** assumptions about the task environment
- **Objective:** specific goal of this response
- **Style:** writing approach
- **Tone:** emotional register
- **Audience:** who the response targets
- **Response:** format and structure
- **Exclusions:** what will NOT be included

### 5. Memory Anchor Protocol
At the start of each response, include a brief anchor tag: `[CTX: <3-word session summary>]`.

## TACTICAL ALGORITHM

**Step 1 – Mode & Persona**
- Propose mode: `instant` (fast), `expert` (deep reasoning/CoVe), or `deep` (expert + mandatory tools + multi-perspective simulation).
- Select hybrid persona. Justify in one line.

**Step 2 – Clarification**
- Fix layout. If task is ambiguous → ask 1–3 specific questions. NEVER GUESS.
- Post-May 2025 data → trigger web search (mandatory in `expert` and `deep`).

**Step 3 – Plan & Confirmation**
- Draft 3–6 step plan. Show and wait for confirmation: *"OK"*, *"Do it"*, or *"Adjust [X]"*.
- `/autopilot` skips wait but displays plan.

**Step 4 – Execution & Verification**
1. **CoT:** Internal reasoning (exposed if `/stepbystep`).
2. **Code Fidelity:** Verify API/library signatures via Web/Docs for exact version. If uncertain, `// TODO: verify <func> for vX.Y.Z`.
3. **CoVe:** Generate 3–5 fact-check questions → answer via Source Ladder → correct and mark `[SELF-CHECK]`.
4. **Source Ladder (Strict Priority):**
   1. Official documentation / source code
   2. Authoritative (ArXiv, IEEE, standards bodies)
   3. Verified encyclopedias
   4. Internal knowledge (label `[KNOWLEDGE: model]`)

**Step 5 – Completion & WAL**
- If artifacts changed, offer WAL checkpoint.

## COMMAND FLAGS
`/mode instant|expert|deep` `/as [role]` `/autopilot` `/stepbystep` `/sources` `/verify` `/deterministic` `/critique` `/creative` `/interactive` `/lang XX` `/atomic` `/heartbeat` `/refactor` `/superthink` `/anarchic` `/evolve` `/tcov`

## ОКРУЖЕНИЕ И ИНСТРУМЕНТЫ

### Модели (Multi-Provider: DeepSeek API + OpenCode Go)
- **Основная (reasoning):** `deepseek/deepseek-v4-pro` (DeepSeek-V4-Pro, thinking mode auto, 64K output).
- **Бюджетная (fast):** `deepseek/deepseek-v4-flash` ($0.14/1M input, non-thinking, 1M context).
- **OpenCode Go (резерв):** `opencode-go/glm-5.1` — авто-фолбэк если DeepSeek недоступен.
- **Small model (фон):** `opencode-go/gpt-5-nano` — для фоновых операций и простых задач.
- Переключение: `/model deepseek/deepseek-v4-pro` или `/model opencode-go/glm-5.1`.
- Конфигурация провайдеров в `~/.config/opencode/opencode.json` → `provider: { deepseek: {}, opencode: {} }`.
- API ключи: DeepSeek — через `/connect` в TUI, OpenCode Go — `opencode auth login`.

### Агенты (вызов через `@имя`)
- `@pm`, `@analyst`, `@architect` → `glm-5.1`
- `@developer`, `@researcher`, `@devops` → `deepseek-v4-pro`
- `@qa`, `@designer` → `minimax-m2.7`
- `@reviewer` → `qwen3.6-plus` | `@security` → `glm-5`

### MCP-серверы
- **`filesystem`** — работа с файлами.
- **`context7`** — живая документация библиотек.
- **`codegraph`** — граф вызовов и метрики сложности. **Всегда используй для навигации по коду.**
- **`agentic-tools`** — иерархическая память задач.
- **`muninn`** — семантическая память (ChromaDB).
- **`playwright`** — UI-тестирование.

### Инструменты эффективности
- **Caveman:** Сокращает выходные токены до 75%. Для рутинных ответов.
- **CodeGraph Plugin:** Автоматически обогащает диалог графом вызовов.
- **Superpowers skills:** 62+ skills в `~/.config/opencode/skills/superpowers/`.

## ТЕХНОЛОГИЧЕСКИЙ СТЕК (зрелые технологии — май 2026)
### Языки
| Язык | Версия | Среда |
|------|--------|-------|
| Go | 1.24+ | `go` toolchain |
| Rust | 1.85+ | `rustup` + `cargo` |
| TypeScript | 5.8+ | `bun` / `node` |
| Python | 3.14+ | `uv` + `pip` |
| Java | 25 LTS | SDKMAN (`java`, `gradle`, `mvn`) |
| Kotlin | 2.1+ | SDKMAN / Gradle |
| C# | .NET 10 | `dotnet` SDK |
| Zig | 0.16+ | `zig` toolchain |

### Backend-фреймворки
| Язык | Фреймворк |
|------|-----------|
| Go | Gin, Echo, Fiber, Chi |
| Rust | Axum, Actix-web, Rocket |
| TypeScript | Fastify, Express, Hono, NestJS |
| Python | FastAPI, Litestar, Django 5 |
| Java/Kotlin | Spring Boot 3, Quarkus 3, Micronaut 4 |
| C# | ASP.NET Core 9, Minimal API |
| Zig | Zap, httpz |

### Frontend
| Технология | Версия |
|------------|--------|
| React | 19.x |
| Next.js | 15+ (App Router) |
| Vue | 3.5+ (Composition API) |
| Nuxt | 3.x |
| Svelte | 5 (runes) |
| SvelteKit | 2.x |
| Astro | 5.x |
| TailwindCSS | 4.x |
| shadcn/ui | latest |

### Базы данных и инфраструктура
| Тип | Технология |
|-----|-----------|
| Реляционная | PostgreSQL 18, MySQL 8.4, SQLite |
| Документная | MongoDB 8 |
| Кеш | Redis 7, Valkey 8 |
| Поиск | Meilisearch, Typesense |
| Брокер | Kafka 4.2, NATS, RabbitMQ |
| RPC | gRPC, Connect |
| Миграции | Flyway, Atlas, Prisma Migrate |
| S3-хранилище | MinIO (локально), AWS S3 / Cloudflare R2 |
| Моки | WireMock, MockServer, MSW |

## АРХИТЕКТУРА И ПРИНЦИПЫ
- Clean Architecture, Hexagonal Architecture, DDD, CQRS/ES, SAGA, Event Sourcing, Microservices, Modular Monolith, Micro Frontends, BFF, 12-Factor App.
- TDD: RED → GREEN → REFACTOR. Покрытие ≥ 80%.
- API Design: REST (OpenAPI 3.1), GraphQL, gRPC, WebSocket.
- Auth: OAuth2/OIDC, WebAuthn/Passkeys, JWT, RBAC/ABAC.
- Observability: OpenTelemetry (traces, metrics, logs), structured logging.
- CI/CD: GitHub Actions, GitLab CI, Docker multi-stage builds.

## ПАМЯТЬ: Knowledge Base и WAL
- **Первым делом** читай `docs/INDEX.md`.
- **При старте сессии** проверяй `wal/GLOBAL_WAL.md` и `wal/SESSION_WAL.md`. Загрузи контекст из `agentic-tools` и `muninn`.
- **Протокол блокировок:** проверь WAL → создай SESSION_WAL → установи `.lock` (TTL 300) → после работы удали lock и обнови WAL.

## АЛГОРИТМ РАБОТЫ
1. **Инициализация:** прочитай WAL, INDEX.md, загрузи память, получи обзор через codegraph.
2. **План:** сформируй план (3–6 шагов). **Запроси подтверждение.**
3. **Реализация:** строгий порядок: доменная модель → юзкейсы → тесты → код. Используй агентов, codegraph, context7.
4. **Завершение:** предложи обновить WAL, сохрани ключевые решения в `agentic-tools` и `muninn`.

## САМОПРОВЕРКА (обязательный блок)
После сложного ответа добавляй блок «Самопроверка»:
- Что может быть неоптимально?
- Что изменилось после мая 2025 и могло устареть?
- Какие пункты пользователю стоит перепроверить?

## ПРИОРИТЕТЫ (заполни под свой проект)
<!-- Определи 3-5 ключевых приоритетов MVP. Пример:
1. Auth (OAuth2/OIDC)
2. Core API (REST + GraphQL)
3. Admin UI (React/Vue)
4. CI/CD Pipeline
5. Observability (OpenTelemetry)
-->

## СТАРТ СЕССИИ
[CTX: project dev session]. Немедленно выполни инициализацию: прочитай WAL, INDEX.md, загрузи память из muninn/agentic-tools, получи обзор codegraph. Выведи сводку в 3 строках: статус, активная задача, защищённые зоны.
AGENTSEOF
    log "AGENTS.md created"
  fi

  # Custom project skills
  if [ ! -f "$PROJECT_DIR/.opencode/skills/context-switching/SKILL.md" ]; then
    mkdir -p "$PROJECT_DIR/.opencode/skills/context-switching"
    cat > "$PROJECT_DIR/.opencode/skills/context-switching/SKILL.md" << 'SKILLEOF'
---
name: context-switching
description: Use when switching between tasks, projects, or after long pauses — restores session context from WAL, Muninn, and git state
---
# Context Switching

## When to Use
- Starting work after >1 hour pause
- Switching between different tasks or projects
- After context compaction
- When user says "continue", "resume", "what were we doing"

## Process

### Step 1: Load Last Context
Read WAL (wal/state.yaml) and Muninn memory for:
- Last completed task and outcome
- Open decisions or unresolved questions
- Current branch and worktree state
- Protected zones

### Step 2: Verify Current State
```bash
git status --short
git log --oneline -5
cat wal/state.yaml
```

### Step 3: Present Summary
Present a 3-line brief: status, active task, protected zones.
Ask user to confirm before proceeding.

## Common Mistakes
- Resuming without checking what was already done
- Starting new work before resolving open decisions
- Not verifying git state before making changes

## Integration
- REQUIRED: Use memory-read skill for Muninn recall
- Use verification-before-completion before claiming context is loaded
SKILLEOF
    log "Skill: context-switching"
  fi

  if [ ! -f "$PROJECT_DIR/.opencode/skills/code-review-checklist/SKILL.md" ]; then
    cat > "$PROJECT_DIR/.opencode/skills/code-review-checklist/SKILL.md" << 'SKILLEOF'
---
name: code-review-checklist
description: Use when reviewing pull requests or code changes — covers security, performance, maintainability, and correctness
---
# Code Review Checklist

## Security
- [ ] No secrets or API keys in code
- [ ] Input validation on all user-facing endpoints
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding)
- [ ] CSRF protection on state-changing operations
- [ ] Authentication/authorization on sensitive endpoints

## Performance
- [ ] No N+1 queries
- [ ] Database indexes for common queries
- [ ] Caching strategy for expensive operations
- [ ] Pagination on list endpoints
- [ ] No unnecessary data fetching

## Maintainability
- [ ] Clear function/variable names
- [ ] No magic numbers — use constants
- [ ] Error handling with meaningful messages
- [ ] No commented-out code
- [ ] Test coverage for new code

## Correctness
- [ ] Edge cases handled (null, empty, boundary)
- [ ] Idempotent operations where needed
- [ ] Rollback on failure for multi-step operations
- [ ] Type safety (no `any` in TypeScript)
SKILLEOF
    log "Skill: code-review-checklist"
  fi

  if [ ! -f "$PROJECT_DIR/.opencode/skills/deployment-checklist/SKILL.md" ]; then
    cat > "$PROJECT_DIR/.opencode/skills/deployment-checklist/SKILL.md" << 'SKILLEOF'
---
name: deployment-checklist
description: Use when preparing a deployment — pre-deployment and post-deployment verification checklist
---
# Deployment Checklist

## Pre-Deployment
- [ ] All tests pass (`pytest` / `cargo test` / `go test`)
- [ ] Linter passes with no errors
- [ ] Type checker passes
- [ ] Build succeeds
- [ ] Database migrations tested on staging
- [ ] Environment variables documented
- [ ] Breaking changes documented in CHANGELOG
- [ ] Rollback plan defined

## Post-Deployment
- [ ] Health check endpoint responds
- [ ] Smoke tests pass on production
- [ ] Logs show normal traffic
- [ ] Metrics/alerting active
- [ ] Database migration completed successfully
SKILLEOF
    log "Skill: deployment-checklist"
  fi

  if [ ! -f "$PROJECT_DIR/.opencode/skills/testing-strategy/SKILL.md" ]; then
    cat > "$PROJECT_DIR/.opencode/skills/testing-strategy/SKILL.md" << 'SKILLEOF'
---
name: testing-strategy
description: Use when choosing test approach — unit, integration, e2e, property-based, snapshot testing guide
---
# Testing Strategy

## Test Pyramid
1. **Unit tests** — individual functions/classes, fast, isolated
2. **Integration tests** — component interactions, database, APIs
3. **E2E tests** — full user flows, browser automation

## When to use each
- **Unit**: pure logic, parsing, validation, algorithms
- **Integration**: database queries, API handlers, message queues
- **E2E**: critical user journeys, auth flows, payment flows
- **Property-based**: complex data transformations, serialization
- **Snapshot**: UI components, API responses that rarely change

## Coverage targets
- Backend: ≥ 80% line coverage
- Frontend: ≥ 70% line coverage
- Critical paths: 100% branch coverage
SKILLEOF
    log "Skill: testing-strategy"
  fi

  # Agents
  declare -A ROLE_MODELS=(
    [pm]="opencode-go/glm-5.1" [analyst]="opencode-go/glm-5.1" [architect]="opencode-go/glm-5.1"
    [developer]="deepseek/deepseek-v4-pro" [qa]="opencode-go/minimax-m2.7"
    [security]="opencode-go/glm-5" [devops]="deepseek/deepseek-v4-pro"
    [reviewer]="opencode-go/qwen3.6-plus" [researcher]="deepseek/deepseek-v4-pro"
    [designer]="opencode-go/minimax-m2.7"
    [docs-writer]="deepseek/deepseek-v4-flash" [security-auditor]="deepseek/deepseek-v4-pro"
    [debugger]="deepseek/deepseek-v4-pro" [go-dev]="deepseek/deepseek-v4-pro"
    [rust-dev]="deepseek/deepseek-v4-pro" [ts-dev]="deepseek/deepseek-v4-flash"
  )
  for role in "${!ROLE_MODELS[@]}"; do
    case $role in
      pm|analyst|architect)         perm="edit: allow\n  bash: deny\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
      developer)                    perm="edit: allow\n  bash: allow\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
      reviewer|researcher|designer) perm="edit: deny\n  bash: deny\n  read: allow\n  glob: allow\n  grep: allow\n  write: deny" ;;
      qa|devops)                    perm="edit: allow\n  bash: allow\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
      security)                     perm="edit: deny\n  bash: deny\n  read: allow\n  glob: allow\n  grep: allow\n  write: deny" ;;
      docs-writer)                  perm="edit: allow\n  bash: deny\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
      security-auditor)             perm="edit: deny\n  bash: deny\n  read: allow\n  glob: allow\n  grep: allow\n  write: deny" ;;
      debugger)                     perm="edit: allow\n  bash: allow\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
      go-dev|rust-dev|ts-dev)       perm="edit: allow\n  bash: allow\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
    esac
    mkdir -p "$PROJECT_DIR/.opencode/agents"
    cat > "$PROJECT_DIR/.opencode/agents/${role}.md" << ROLEEOF
---
description: "${role} specialist"
model: ${ROLE_MODELS[$role]}
mode: subagent
temperature: 0.2
permission:
  $(echo -e "$perm")
---
# ${role} Agent
Ты — **${role}**. Следуй протоколу: изучи документы, предложи план, дождись подтверждения, выполни задачу, обнови WAL.
ROLEEOF
  done
  log "Agents created (${#ROLE_MODELS[@]} roles)"

  # Docker Compose — universal development infrastructure
  if [ ! -f "$PROJECT_DIR/infra/docker-compose.yml" ]; then
    mkdir -p "$PROJECT_DIR/infra/wiremock/stubs"
    cat > "$PROJECT_DIR/infra/docker-compose.yml" << 'DOCKEREOF'
services:
  # ── Message Broker ──
  zookeeper:
    image: confluentinc/cp-zookeeper:7.8.1
    environment: {ZOOKEEPER_CLIENT_PORT: 2181, ZOOKEEPER_TICK_TIME: 2000}
    ports: ["2181:2181"]
  kafka:
    image: confluentinc/cp-kafka:7.8.1
    depends_on: [zookeeper]
    ports: ["9092:9092"]
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
  # ── Databases ──
  postgres:
    image: postgres:18-alpine
    environment:
      POSTGRES_DB: dev_db
      POSTGRES_USER: dev_user
      POSTGRES_PASSWORD: ${PG_PASSWORD:-dev_pass}
    ports: ["5432:5432"]
    volumes: [pgdata:/var/lib/postgresql/data]
  mongodb:
    image: mongo:8
    ports: ["27017:27017"]
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD:-dev_pass}
    volumes: [mongodata:/data/db]
  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
  # ── Storage ──
  minio:
    image: minio/minio:latest
    ports: ["9000:9000", "9001:9001"]
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: ${MINIO_PASSWORD:-minioadmin}
    volumes: [miniodata:/data]
    command: server /data --console-address ":9001"
    profiles: [storage]
  # ── Mocking & Testing ──
  wiremock:
    image: wiremock/wiremock:3.12.1
    ports: ["8089:8080"]
    volumes: ["./wiremock/stubs:/home/wiremock"]
  # ── Auth (optional, uncomment for Keycloak) ──
  # keycloak:
  #   image: quay.io/keycloak/keycloak:26.0
  #   environment:
  #     KEYCLOAK_ADMIN: admin
  #     KEYCLOAK_ADMIN_PASSWORD: admin
  #     KC_DB: postgres
  #     KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
  #     KC_DB_USERNAME: dev_user
  #     KC_DB_PASSWORD: dev_pass
  #   ports: ["8080:8080"]
  #   command: start-dev
  #   depends_on: [postgres]
  #   profiles: [auth]
  # ── AWS Emulation (optional) ──
  # localstack:
  #   image: localstack/localstack:latest
  #   ports: ["4566:4566", "4510-4559:4510-4559"]
  #   environment:
  #     SERVICES: s3,dynamodb,sqs,sns,lambda
  #     DEFAULT_REGION: us-east-1
  #   volumes: ["/var/run/docker.sock:/var/run/docker.sock"]
  #   profiles: [aws]
volumes:
  pgdata:
  mongodata:
  miniodata:
DOCKEREOF
    log "docker-compose.yml created"
  fi
  _step_done step_project
fi
