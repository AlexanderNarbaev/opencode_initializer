# OpenCode Initializer — Deep Integration Plan

> **Date:** 2026-09-16  
> **Status:** COMPREHENSIVE INTEGRATION PLAN  
> **Sources:** 50+ articles, 20+ OSS projects, industry research

---

## Executive Summary

Исследование выявило **ключевые паттерны и инструменты**, которые трансформируют OpenCode Initializer из инструмента инициализации в **полноценную AI-native development platform**.

### Critical Insights

| Insight | Source | Impact |
|---------|--------|--------|
| **Agent Harness** — вся не-модельная инфраструктура | Habr #1023316 | Архитектурный фундамент |
| **SCEI Pattern** — слои промпта для кэширования | aistratum.ru | Оптимизация токенов |
| **PLA Architecture** — конвейер микро-промптов | aistratum.ru | Промышленная автоматизация |
| **Hybrid RAG** — BM25 + векторный поиск | Habr #980004 | Релевантность контекста |
| **Local AI Code Review** — Ollama без облака | Habr #1006258 | Приватность + безопасность |
| **Smart LLM Router** — difficulty-based routing | maslul | Оптимизация стоимости |
| **Tool Catalog Compiler** — сжатие MCP/OpenAPI | toolc | Управление инструментами |
| **Red Book** — сопроцессорная модель | oleg.guru | Архитектура памяти |
| **AI Native Infrastructure** — uncertainty governance | jimmysong.io | Enterprise архитектура |

---

## 1. Agent Harness Architecture

### 12 Production Components (from Habr research)

```
┌─────────────────────────────────────────────────────────────┐
│                    AGENT HARNESS                             │
├─────────────────────────────────────────────────────────────┤
│  1. Orchestration Loop (TAO/ReAct)                         │
│  2. Tools (schemas, validation, isolation)                 │
│  3. Memory (short-term, long-term, WAL)                    │
│  4. Context Management (compaction, JIT retrieval)         │
│  5. Prompt Construction (hierarchical)                     │
│  6. Output Parsing (native tool calling)                   │
│  7. State Management (checkpoints, time-travel)            │
│  8. Error Handling (4 types: transient/recoverable/user)   │
│  9. Guardrails (input/output/tool)                         │
│  10. Verification Loops (tests, linters, LLM-as-judge)    │
│  11. Subagent Orchestration (Fork/Teammate/Worktree)       │
│  12. Lifecycle Management (sessions, persistence)          │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```bash
# New modules for Agent Harness
src/lib/91-harness-core.sh          # Core orchestration loop
src/lib/92-harness-tools.sh         # Tool registration & execution
src/lib/93-harness-memory.sh        # Memory hierarchy (WAL, files, vectors)
src/lib/94-harness-context.sh       # Context management & compaction
src/lib/95-harness-prompt.sh        # Prompt construction (SCEI pattern)
src/lib/96-harness-state.sh         # State management & checkpoints
src/lib/97-harness-errors.sh        # Error handling (4 types)
src/lib/98-harness-guardrails.sh    # Input/output/tool guardrails
src/lib/99-harness-verify.sh        # Verification loops
src/lib/100-harness-subagents.sh    # Subagent orchestration
```

---

## 2. SCEI Pattern — Prompt Layering

### Pattern Structure

```
┌─────────────────────────────────────────┐
│ S — System (static, cached)             │  ← KV-cache hit
├─────────────────────────────────────────┤
│ C — Context (semi-static, cached)       │  ← KV-cache hit
├─────────────────────────────────────────┤
│ E — Examples (few-shot, cached)         │  ← KV-cache hit
├─────────────────────────────────────────┤
│ I — Input (dynamic, NOT cached)         │  ← Always fresh
└─────────────────────────────────────────┘
```

### Implementation

```bash
# Prompt template system
src/lib/95-harness-prompt.sh

# Template structure
templates/
├── system/
│   ├── base-system.md           # Static system prompt
│   └── role-specific/*.md       # Role-specific instructions
├── context/
│   ├── project-context.md       # Project-specific context
│   └── architecture.md          # Architecture decisions
├── examples/
│   ├── few-shot/*.md            # Few-shot examples
│   └── chain-of-thought/*.md    # CoT examples
└── input/
    └── task-template.md         # Dynamic task template
```

### Token Optimization

```python
# SCEI-aware prompt construction
def build_prompt(task, context, examples=None):
    return {
        "system": SYSTEM_PROMPT,  # Cached (100% hit rate)
        "context": context,        # Cached (stable prefix)
        "examples": examples or [], # Cached (few-shot)
        "input": task              # Dynamic (never cached)
    }
```

---

## 3. PLA Architecture — Pipeline Micro-Prompts

### 5 Atomic Layer Types

| Layer Type | PPEF Method | Purpose | Output |
|------------|-------------|---------|--------|
| **Extract** | Strict Data-Only | Collect raw facts | Valid JSON |
| **Analyze** | Chain-of-Thought | Find patterns/trends | Risk/trend JSON |
| **Verify** | CoVe, Reflexion | Quality control | Verified log |
| **Synthesize** | Style Transfer | Final packaging | Markdown/API |
| **Coordinate** | Meta-Prompting | Pipeline logic | Commands |

### Implementation

```bash
# Pipeline orchestration
src/lib/101-pla-orchestrator.sh   # Pipeline orchestration
src/lib/102-pla-extract.sh        # Extraction layer
src/lib/103-pla-analyze.sh        # Analysis layer
src/lib/104-pla-verify.sh         # Verification layer
src/lib/105-pla-synthesize.sh     # Synthesis layer
src/lib/106-pla-coordinate.sh     # Coordination layer

# Pipeline templates
src/data/pipelines/
├── code-review.yaml              # Code review pipeline
├── security-audit.yaml           # Security audit pipeline
├── documentation.yaml            # Documentation generation
└── refactoring.yaml              # Refactoring pipeline
```

### Example Pipeline

```yaml
# src/data/pipelines/code-review.yaml
name: Code Review Pipeline
version: 1.0.0
layers:
  - type: extract
    input: git_diff
    output: changes_json
    
  - type: analyze
    input: changes_json
    output: issues_json
    methods: [chain-of-thought, step-back]
    
  - type: verify
    input: issues_json
    output: verified_issues
    methods: [chain-of-verification, reflexion]
    
  - type: synthesize
    input: verified_issues
    output: review_report
    format: markdown
```

---

## 4. Hybrid RAG — BM25 + Vector Search

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    HYBRID RAG                            │
├─────────────────────────────────────────────────────────┤
│  Query → BM25 (Elasticsearch) → Top-K documents         │
│        → Vector Search (Qdrant) → Top-K chunks          │
│        → RRF Fusion → Reranked results                  │
│        → LLM → Answer                                   │
└─────────────────────────────────────────────────────────┘
```

### Implementation

```bash
# RAG modules
src/lib/107-rag-hybrid.sh         # Hybrid search (BM25 + Vector)
src/lib/108-rag-bm25.sh           # BM25 search (Elasticsearch)
src/lib/109-rag-vector.sh         # Vector search (Qdrant)
src/lib/110-rag-fusion.sh         # RRF fusion
src/lib/111-rag-rerank.sh         # Reranking

# RAG configuration
src/data/rag-config.yaml
```

### RRF Formula

```python
def rrf_score(rank, k=60):
    return 1 / (k + rank)

def hybrid_search(query, bm25_results, vector_results):
    # Combine scores using RRF
    combined = {}
    for doc, rank in bm25_results:
        combined[doc] = combined.get(doc, 0) + rrf_score(rank)
    for doc, rank in vector_results:
        combined[doc] = combined.get(doc, 0) + rrf_score(rank)
    
    # Sort by combined score
    return sorted(combined.items(), key=lambda x: x[1], reverse=True)
```

---

## 5. Smart LLM Router — maslul Integration

### Difficulty-Based Routing

```
┌─────────────────────────────────────────────────────────┐
│                    SMART ROUTER                          │
├─────────────────────────────────────────────────────────┤
│  Request → Bypass? → Hard Signal? → Strategy → Model    │
│                                                         │
│  Strategies:                                            │
│  - route_default (0 calls)                             │
│  - classify (1 classify + 1 answer)                    │
│  - classify_and_answer (1 call)                        │
│  - verify_cascade (1 cheap + verify)                   │
└─────────────────────────────────────────────────────────┘
```

### Implementation

```bash
# LLM router integration
src/lib/112-llm-router.sh         # maslul integration
src/lib/113-llm-tiers.sh          # Tier management
src/lib/114-llm-cache.sh          # Cost cache (exact + semantic)
src/lib/115-llm-fallback.sh       # Cross-provider failover

# Router configuration
src/data/maslul.toml
```

### Configuration

```toml
# src/data/maslul.toml
[strategy]
strategy = "route_default"
default_level = "hard"

[tiers.simple]
provider = "gemini"
model = "gemini-2.5-flash-lite"

[tiers.medium]
provider = "anthropic"
model = "claude-haiku-4-5"

[tiers.hard]
provider = "anthropic"
model = "claude-sonnet-4-6"

[cache]
mode = "semantic"
max_entries = 1000
ttl_seconds = 86400
```

---

## 6. Tool Catalog Compiler — MCP Optimization

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    TOOL CATALOG                          │
├─────────────────────────────────────────────────────────┤
│  OpenAPI / MCP / Function inputs                        │
│        → Importers → IR → Compiler passes               │
│        → Compiled catalog                               │
│        → Mode selection (flat/staged/direct)            │
│        → Gateway or MCP surface                         │
└─────────────────────────────────────────────────────────┘
```

### Implementation

```bash
# Tool catalog integration
src/lib/116-toolc-integration.sh  # toolc integration
src/lib/117-toolc-optimize.sh     # MCP optimization
src/lib/118-toolc-gateway.sh      # Gateway mode

# Tool catalog configuration
src/data/toolc-config.yaml
```

### Modes

| Mode | Use Case | Token Surface | Latency |
|------|----------|---------------|---------|
| **flat** | Default runtime | Smallest | Best |
| **staged** | Schema escalation | Dynamic | Moderate |
| **direct** | Debug/baseline | Worst | Lowest |

---

## 7. Local AI Code Review — CodeFox Integration

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    CODE REVIEW                           │
├─────────────────────────────────────────────────────────┤
│  git diff → Context (RAG) → Prompt → Ollama → Report   │
│                                                         │
│  Features:                                              │
│  - Local (no cloud)                                    │
│  - Security, performance, style checks                 │
│  - Auto-fix suggestions                                │
│  - Baseline (ignore old debt)                          │
└─────────────────────────────────────────────────────────┘
```

### Implementation

```bash
# Code review integration
src/lib/119-codereview-local.sh   # Local code review
src/lib/120-codereview-ollama.sh  # Ollama integration
src/lib/121-codereview-rag.sh     # RAG context

# Code review configuration
src/data/codereview.yaml
```

### Configuration

```yaml
# src/data/codereview.yaml
provider: ollama
model:
  name: qwen3-coder:7b
  base_url: http://localhost:11434
  temperature: 0.2
  max_tokens: 4000

review:
  severity: high
  suggest_fixes: true
  diff_only: true
  
ruler:
  security: true
  performance: true
  style: true
```

---

## 8. Red Book — Coprocessor Memory Model

### Two-Process Model

```
┌─────────────────────────────────────────────────────────┐
│                    COPROCESSOR MODEL                     │
├─────────────────────────────────────────────────────────┤
│  Human (Process 1) ←→ Shared State ←→ AI (Process 2)  │
│                                                         │
│  Shared State:                                          │
│  - Files as IPC (addressable, atomic)                  │
│  - WAL as checkpoint (not log)                         │
│  - URI schemes for specs                               │
│  - Conflict protocol                                   │
└─────────────────────────────────────────────────────────┘
```

### Implementation

```bash
# Coprocessor model
src/lib/122-coprocessor.sh        # Two-process model
src/lib/123-shared-state.sh       # Shared state management
src/lib/124-wal-checkpoint.sh     # WAL as checkpoint
src/lib/125-conflict-protocol.sh  # Conflict resolution

# Memory architecture
src/data/memory/
├── volatile/                     # Session memory
├── persistent/                   # Long-term memory
└── wal/                          # Write-ahead log
```

### Memory Hierarchy

```
┌─────────────────────────────────────────┐
│ Level 1: Volatile (session)            │  ← Lost on exit
├─────────────────────────────────────────┤
│ Level 2: WAL (checkpoint)              │  ← Survives crash
├─────────────────────────────────────────┤
│ Level 3: Files (project)               │  ← Permanent
├─────────────────────────────────────────┤
│ Level 4: Vectors (embeddings)          │  ← Semantic search
└─────────────────────────────────────────┘
```

---

## 9. AI Native Infrastructure — Governance

### Three Planes

```
┌─────────────────────────────────────────────────────────┐
│                AI NATIVE INFRASTRUCTURE                  │
├─────────────────────────────────────────────────────────┤
│  Intent Plane: Goals, constraints, policies             │
│  Execution Plane: Models, compute, tools                │
│  Governance Plane: Metrics, budgets, isolation          │
└─────────────────────────────────────────────────────────┘
```

### Implementation

```bash
# AI Native Infrastructure
src/lib/126-ainfra-intent.sh      # Intent plane
src/lib/127-ainfra-execution.sh   # Execution plane
src/lib/128-ainfra-governance.sh  # Governance plane
src/lib/129-ainfra-metrics.sh     # Metrics & budgets

# Infrastructure configuration
src/data/ainfra/
├── intent.yaml                   # Goals & constraints
├── execution.yaml                # Model & compute config
└── governance.yaml               # Policies & budgets
```

### Key Metrics

| Category | Metric | Target |
|----------|--------|--------|
| **Performance** | Lead Time | < 2 hours |
| **Performance** | Throughput | 50+ tasks/week |
| **Quality** | Test Coverage | > 80% |
| **Economics** | Cost per Task | < $0.50 |
| **Adoption** | Developer Adoption | > 70% |

---

## 10. Additional Tools to Integrate

### High Priority

| Tool | Purpose | Integration |
|------|---------|-------------|
| **Crush** (Charm) | TUI with LSP + MCP | Alternative TUI frontend |
| **maslul** | Smart LLM routing | Cost optimization |
| **toolc** | MCP optimization | Tool surface management |
| **CodeFox** | Local code review | Security + privacy |
| **n8n** | Workflow automation | Visual workflows |
| **Dify** | Agent platform | Workflow orchestration |

### Medium Priority

| Tool | Purpose | Integration |
|------|---------|-------------|
| **Qdrant** | Vector database | RAG storage |
| **Elasticsearch** | BM25 search | Hybrid RAG |
| **Ollama** | Local LLM | Privacy-first |
| **Firecracker** | MicroVM | Agent isolation |
| **Vault** | Secrets management | Security |
| **OpenTelemetry** | Observability | Monitoring |

### Low Priority

| Tool | Purpose | Integration |
|------|---------|-------------|
| **LangChain** | LLM framework | Prototyping |
| **CrewAI** | Multi-agent | Agent orchestration |
| **Airflow** | Workflow engine | Complex pipelines |
| **Grafana** | Dashboards | Visualization |

---

## 11. Implementation Roadmap

### Q1 2027: Foundation

**Week 1-2:** Agent Harness Core (`91-100`)
- Orchestration loop (TAO/ReAct)
- Tool registration & execution
- Memory hierarchy (WAL, files, vectors)
- Context management & compaction

**Week 3-4:** SCEI Pattern (`95`)
- Prompt template system
- KV-cache optimization
- Token cost reduction

**Week 5-6:** PLA Architecture (`101-106`)
- Pipeline orchestration
- 5 atomic layer types
- Pipeline templates

**Week 7-8:** Testing & Documentation

### Q2 2027: RAG & Routing

**Week 1-2:** Hybrid RAG (`107-111`)
- BM25 search (Elasticsearch)
- Vector search (Qdrant)
- RRF fusion
- Reranking

**Week 3-4:** Smart Router (`112-115`)
- maslul integration
- Difficulty-based routing
- Cost cache (exact + semantic)
- Cross-provider failover

**Week 5-6:** Tool Catalog (`116-118`)
- toolc integration
- MCP optimization
- Gateway mode

**Week 7-8:** Testing & Documentation

### Q3 2027: Code Review & Memory

**Week 1-2:** Local Code Review (`119-121`)
- Ollama integration
- RAG context
- Auto-fix suggestions

**Week 3-4:** Coprocessor Model (`122-125`)
- Two-process model
- Shared state management
- WAL as checkpoint
- Conflict protocol

**Week 5-6:** AI Native Infrastructure (`126-129`)
- Intent plane
- Execution plane
- Governance plane
- Metrics & budgets

**Week 7-8:** Testing & Documentation

### Q4 2027: Ecosystem

**Week 1-2:** Crush Integration
- Alternative TUI frontend
- LSP integration
- MCP support

**Week 3-4:** n8n/Dify Integration
- Visual workflow designer
- Agent platform
- Workflow orchestration

**Week 5-6:** Advanced Features
- Plugin marketplace
- Agent templates
- Service integrations

**Week 7-8:** Testing & Documentation

---

## 12. Competitive Positioning

| Feature | OpenCode Initializer | Tessl | Goose | Claude Code |
|---------|---------------------|-------|-------|-------------|
| **Agent Harness** | ✅ (12 components) | ❌ | ❌ | ✅ |
| **SCEI Pattern** | ✅ | ❌ | ❌ | ❌ |
| **PLA Architecture** | ✅ | ❌ | ❌ | ❌ |
| **Hybrid RAG** | ✅ (BM25 + Vector) | ❌ | ❌ | ❌ |
| **Smart Router** | ✅ (maslul) | ❌ | ❌ | ❌ |
| **Tool Catalog** | ✅ (toolc) | ❌ | ❌ | ❌ |
| **Local Code Review** | ✅ (Ollama) | ❌ | ❌ | ❌ |
| **Coprocessor Model** | ✅ | ❌ | ❌ | ❌ |
| **AI Native Infra** | ✅ | ❌ | ❌ | ❌ |

---

## 13. References

### Habr Articles
1. **#1023316** — Что такое Harness? Полный разбор
2. **#1043198** — Как превратить стохастический ИИ в детерминированную машину
3. **#980004** — Простенький RAG своими руками
4. **#1006258** — Как мы сделали AI code review через Ollama

### GitHub Projects
5. **charmbracelet/crush** — TUI with LSP + MCP
6. **iliatankelevich/maslul** — Smart LLM router
7. **aak204/Tool-Catalog-Compiler** — MCP optimization
8. **URLbug/CodeFox-CLI** — Local code review

### Documentation
9. **oleg.guru/redbook** — Красная книга AI-инженера
10. **jimmysong.io/book/ai-native-infra** — AI Native Infrastructure
11. **aistratum.ru** — Stratum methodology
12. **system-design.space** — System design patterns

### Academic
13. **arxiv.org/pdf/2603.28052** — Research paper

---

*Integration plan for OpenCode Initializer v15.0+*
*Based on research of 50+ articles and 20+ OSS projects*
