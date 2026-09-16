# AIPDLC Integration Guide

> **AIPDLC** — AI-Powered Development Lifecycle. A methodology for running the full software
> lifecycle (specify → plan → implement → review → ship) as an *orchestrated, auditable, isolated
> agent pipeline* rather than a human-triggered code editor.
>
> This guide maps each AIPDLC pillar to the concrete opencode_initializer implementation: which
> modules realize it, which file is the single source of truth (SSOT), and what the integration
> surface looks like in code. Where AIPDLC prescribes a mechanism the repo does not yet ship
> (Firecracker microVMs, HashiCorp Vault, OPA), the guide marks it explicitly as a recommended
> integration point rather than claiming it exists.

---

## 1. Control Plane Architecture

The control plane is the **always-on coordination layer** that turns a collection of LLM calls into
a lifecycle. It owns three things: *state*, *task topology*, and *evidence*. opencode_initializer
implements it as a set of **append-only journals plus idempotent step gates**, not a central daemon.

### 1.1 State management — WAL, checkpoints, progress

Three state tiers, each with a distinct durability contract:

| Tier | File | Module | Semantics |
|------|------|--------|-----------|
| Session journal | `~/.cache/opencode/wal.jsonl` | `37-wal.sh` | Append-only JSONL; hash-chained; every ~10 turns or on tool error/model switch |
| Bootstrap progress | `~/.cache/opencode-setup/progress` | `00-core.sh` | Idempotent step completion; re-runs skip completed steps |
| Human-readable state | `~/.cache/opencode-setup/wal.md` | `37-wal.sh` | Markdown mirror, resumed on re-run |

The **agent WAL** is the control plane's ground-truth state. Each entry is tamper-evident — it
links to the previous entry's hash, so the chain can be re-verified end-to-end:

```bash
# src/lib/37-wal.sh — hash-chained agent journal
_wal_agent_log() {
  local domain="${1:-unknown}" decision="${2:-}" rationale="${3:-}"
  local confidence="${4:-0.85}" mode="${5:-S1}"

  # Hash-chain: get previous hash
  prev_hash="genesis"
  if [ -f "$WAL_AGENT_FILE" ] && [ -s "$WAL_AGENT_FILE" ]; then
    prev_hash=$(tail -1 "$WAL_AGENT_FILE" | jq -r '.hash // "genesis"' 2>/dev/null || echo "genesis")
  fi

  # entry hash = SHA-256(prev + ts + domain + decision + confidence)
  entry_hash=$(echo -n "${prev_hash}${now}${domain}${decision}${confidence}" \
    | _sha256 | awk '{print $1}')

  entry_line=$(printf '{"ts":"%s","domain":"%s","decision":"%s","rationale":"%s",'
    '"impact":%s,"confidence":%s,"mode":"%s","prev_hash":"%s","hash":"%s"}' \
    "$now" "$domain" "$decision" "$rationale" "$impact_json" "$confidence" \
    "$mode" "$prev_hash" "$entry_hash")
  _wal_locked_append "$WAL_AGENT_FILE" "$entry_line"
}
```

Checkpoint policy is defined in the operating protocol (see `AGENTS.md`, WAL Protocol):

> Checkpoint on: tool errors, model/provider switches, architectural decisions, compaction
> events, every ~10 turns.

### 1.2 Task graph and dependency tracking

Task topology lives in **declarative JSON**, consumed by a single embedded classifier so the CLI
and the sourceable wrappers can never disagree. The dependency edges are explicit (`depends` arrays)
and the pipeline is a DAG from research → plan → implement → verify:

```bash
# src/lib/54-task-distributor.sh — embedded Python worker (pipeline_for)
def pipeline_for(t, c):
    skill = cfg["distribution_rules"].get(t, {}).get("skill")
    if c == "simple":
        return [{"step": "implement", "agent": "Worker", "skill": skill, "depends": []}]
    if c == "medium":
        return [
            {"step": "research",  "agent": "Planner", "skill": "research", "depends": []},
            {"step": "implement", "agent": "Worker",   "skill": skill,     "depends": ["research"]},
        ]
    return [
        {"step": "research",  "agent": "Planner",  "skill": "deep-research", "depends": []},
        {"step": "plan",      "agent": "Planner",  "skill": "plan",          "depends": ["research"]},
        {"step": "implement", "agent": "Worker",   "skill": skill,           "depends": ["plan"]},
        {"step": "verify",    "agent": "Reviewer", "skill": "code-review",   "depends": ["implement"]},
    ]
```

The orchestrator layer (`66-agent-orchestrator.sh` → `69-agent-protocol.sh`) generalizes this into
workflow/pipeline/mesh/protocol primitives: workflows load a YAML definition, pipelines sequence
stages with state under `~/.local/share/opencode/pipelines`, the mesh registers agents in a service
registry, and the protocol layer provides inbox/outbox message passing between agents.

### 1.3 Audit logging

The audit trail is a **second, dedicated** hash chain (`44-audit.sh`) with seven typed events —
`model_call`, `tool_call`, `provider_switch`, `pii_redacted`, `checkpoint`, `error`,
`session_boundary` — rotation at 10 MB into gzip archives, and a verifier that recomputes every
hash:

```bash
# src/lib/44-audit.sh — tamper-evident event append + verification
_audit_event() {
  local event_type="$1" details="${2:-{}}"
  local prev_hash="genesis"
  if [ -f "$AUDIT_WAL" ] && [ -s "$AUDIT_WAL" ]; then
    prev_hash=$(tail -1 "$AUDIT_WAL" | jq -r '.hash // "genesis"' 2>/dev/null || echo "genesis")
  fi
  local event_hash
  event_hash=$(echo -n "${prev_hash}${ts}${event_type}${details}" | _sha256 | awk '{print $1}')
  entry_line=$(printf '{"ts":"%s","type":"%s","details":%s,"prev":"%s","hash":"%s"}' \
    "$ts" "$event_type" "$details" "$prev_hash" "$event_hash")
  _wal_locked_append "$AUDIT_WAL" "$entry_line"
}
```

`_audit_verify_chain` replays the file, recomputing `hash` and checking `prev` continuity, and
reports `VERIFIED: N events, 0 tampered` or `TAMPERED: k/N events fail verification`.

### Control-plane summary

| AIPDLC control-plane concern | opencode_initializer implementation |
|------------------------------|-------------------------------------|
| Orchestration | `54-task-distributor.sh`, `66-agent-orchestrator.sh`, `67-agent-pipeline.sh` |
| State / WAL | `37-wal.sh`, `00-core.sh` progress gate |
| Task graph + deps | `config.json` `distribution_rules` + `depends` arrays in `distribute.sh` |
| Inter-agent IPC | `68-agent-mesh.sh`, `69-agent-protocol.sh`, `.opencode/state/` |
| Audit | `44-audit.sh` hash-chained `audit.jsonl` |

---

## 2. Agent Role Definitions

AIPDLC defines four canonical roles. opencode_initializer's task-distributor registry is the SSOT
for the **Commander → Planner → Worker → Reviewer** architecture:

```json
{
  "architecture": "Commander → Planner → Worker → Reviewer",
  "agents": {
    "Commander": {
      "capabilities": ["orchestration", "delegation", "verification", "mission_control"],
      "delegates_to": ["Planner", "Worker", "Reviewer"],
      "best_for": ["complex", "multi_agent", "end_to_end"]
    },
    "Planner": {
      "capabilities": ["research", "analysis", "planning", "decomposition"],
      "delegates_to": ["Worker"],
      "skill": "plan"
    },
    "Worker": {
      "capabilities": ["implementation", "testing", "documentation", "fixes"],
      "delegates_to": [],
      "skill": "implement"
    },
    "Reviewer": {
      "capabilities": ["verification", "validation", "quality_checks"],
      "delegates_to": [],
      "skill": "code-review"
    }
  }
}
```

### Role mapping

| AIPDLC role | opencode_initializer agent | Responsibility | Complexity trigger |
|-------------|----------------------------|----------------|--------------------|
| **AI Manager Agent** (orchestrator) | **Commander** | Decomposition, delegation, mission control, end-to-end verification | `complex` (multi-agent, end-to-end) |
| **AI Researcher / Analyst Agent** | **Planner** | Codebase analysis, research, planning, decomposition | `medium` (needs research/plan first) |
| **AI Engineer / Implementation Agent** | **Worker** | Code writing, testing, docs, fixes | `simple` (single file, mechanical) |
| **AI Reviewer Agent** | **Reviewer** | Adversarial review, validation, QA gates | `review` task type |

### Selection rules

Classification is priority-ordered so high-signal intents win, and every task maps to exactly one
agent. The classifier is a single embedded Python worker — no drift between the CLI and the
sourceable wrappers:

```bash
# distribute.sh agent "implement login feature" → Worker
TYPE_PRIORITY = ["orchestration", "review", "debug", "research", "planning",
                 "testing", "refactor", "docs", "coding"]

def agent_for(t, c):
    if c == "complex":
        return "Commander"
    if t in ("research", "planning"):
        return "Planner"
    if t == "review":
        return "Reviewer"
    return cfg["distribution_rules"].get(t, {}).get("agent", "Worker")
```

For parallel independent units, `distribute.sh parallel` emits one dispatch per lane:

```bash
$ distribute.sh parallel "fix login bug" "add unit tests" "write migration doc"
# ── Parallel dispatch (background=true) ──
delegate_task(agent="Worker",   prompt="fix login bug", background=true)  # lane 1
delegate_task(agent="Worker",   prompt="add unit tests", background=true) # lane 2
delegate_task(agent="Worker",   prompt="write migration doc", background=true) # lane 3
```

### Relationship to the 15-agent taxonomy

The four AIPDLC roles are the *dispatch layer*. The richer 15-agent taxonomy in
`docs/architecture/agent-system.en.md` (`build`, `plan`, `compaction`, `explore`, `reviewer`,
`critic`, `sme`, `orchestrator`, …) is the *execution layer* those roles fan out into. The mapping
is: **Commander** ~ orchestrator, **Planner** ~ plan + researcher + sme, **Worker** ~ build +
test-engineer + docs, **Reviewer** ~ reviewer + code-reviewer + critic + security-auditor.

---

## 3. Isolation Architecture

AIPDLC requires that untrusted agent work runs in an isolated environment. opencode_initializer
implements this at three escalating trust levels:

| Level | Mechanism | Module / profile | Network | Filesystem |
|-------|-----------|------------------|---------|------------|
| 1 — Process | Shell sandbox + readonly config | `37-wal.sh`, `32-isolated.sh` | local | `~/.cache` journals |
| 2 — Container | Docker (seccomp/apparmor profile) | `02-docker.sh`, `30-infra.sh` | per-service | compose volumes |
| 3 — Air-gap | Isolated Circuit + offline bundle | `32-isolated.sh`, `46-offline-bundle.sh` | **blocked** | SHA-256 verified tarball |

### 3.1 Container isolation (Docker with seccomp)

Docker is installed via `02-docker.sh` and infra services (PostgreSQL, Qdrant, Redis, Prometheus,
Grafana, MemoryLayer) run as `docker compose` stacks via `30-infra.sh`. Agent workloads are expected
to run in containers with a default seccomp profile; the recommended hardening is a custom
`--security-opt seccomp=` profile and `--read-only` rootfs (see §3.4).

### 3.2 MicroVM isolation (Firecracker / Kata Containers)

> **Recommended integration point — not yet implemented.** AIPDLC's strongest isolation tier is a
> per-task microVM. The repo currently has no Firecracker or Kata Containers module. The intended
> seam is module `61-daytona.sh` (development environment orchestration): a Daytona/Firecracker
> backend would give each `Worker` lane a kernel-isolated VM with a cold-start budget instead of a
> shared container. Until then, Level 3 (air-gap) is the strongest shipped isolation.

### 3.3 BoxLite-style in-process isolation

> **Recommended integration point.** The BoxLite pattern (an in-process, capability-restricted
> evaluator for untrusted code) maps to running agent tool output through `scripts/pii-guard.py`
> before it re-enters the pipeline, and to the Cockpit TUI (`src/cockpit/`, Go) as a
> capability-gated process supervisor. Full in-process sandboxing (e.g. WASM or `gVisor`) is out of
> scope today.

### 3.4 Readonly filesystem + network blocking

The **Isolated Circuit** (`32-isolated.sh`) is the canonical network-blocking mode. When enabled,
all model traffic is confined to local OpenAI-compatible backends; there are no cloud API keys and
no outbound calls:

```bash
# src/lib/32-isolated.sh — local endpoint registry (air-gap)
_get_local_endpoint() {
  case "${1:-}" in
    ollama) echo "http://localhost:11434/v1" ;;
    vllm)   echo "http://localhost:8000/v1" ;;
    sglang) echo "http://localhost:30000/v1" ;;
    *)      echo "" ;;
  esac
}

# Auto-detect available local backends
for backend in ollama vllm sglang; do
  if curl -s "$(_get_local_endpoint "$backend")/models" --max-time 2 >/dev/null 2>&1; then
    AVAILABLE_LOCAL_BACKENDS="$AVAILABLE_LOCAL_BACKENDS $backend"
  fi
done
```

The model router routes the `isolated` task profile to local-only models (`ollama/qwen3:32b`),
never to cloud providers. Config is persisted to `~/.config/opencode-setup/setup.conf`.

### 3.5 Git-based change workflow

Every agent change is a Git delta, not a direct mutation of ground truth. `19-finalize.sh` configures
Git identity and the bootstrap itself runs from a Git checkout; `44-audit.sh`'s hash chain gives
non-repudiation on top of the Git commit graph. The offline bundle (`46-offline-bundle.sh`) produces
a SHA-256-manifested tarball so even the *delivery* of code into an air-gapped machine is
integrity-verified:

```bash
# src/lib/46-offline-bundle.sh — integrity-verified air-gap delivery
_offline_bundle_run() {
  # Verify SHA256 integrity
  if [ -f "$manifest" ]; then
    if (cd "$bundle_path/bundle" && _sha256 -c "$manifest" --quiet 2>/dev/null); then
      log "Bundle integrity: VERIFIED"
    else
      warn "Bundle integrity check FAILED — some files may be corrupted"
    fi
  fi
}
```

---

## 4. MCP Protocol Integration

MCP is the tool-and-context surface every agent role reads from. opencode_initializer treats MCP
selection as a **context-budget decision**, not a static registry dump: servers are installed once
(`12-mcp-lsp.sh`) but *loaded per task* (`52-context-selector.sh`) from a single SSOT.

### 4.1 MCP server registry (SSOT)

`src/data/mcp-profiles.json` is the single source of truth for the task → MCP/LSP mapping. Browser,
UI, and diagram servers carry large tool surfaces and high cold-start cost, so they are disabled by
default and enabled only when the task profile demands them:

```json
{
  "disabled_by_default": ["chrome-devtools", "playwright", "excalidraw", "agent-browser"],
  "full_mode_all_on": true,
  "task_profiles": {
    "coding": {
      "mcp": ["filesystem", "codegraph", "context7", "git", "memory"],
      "lsp": ["typescript", "pyright", "gopls", "rust-analyzer", "bash"]
    },
    "agentic": {
      "mcp": ["filesystem", "codegraph", "github", "memory", "agentic-tools", "playwright"],
      "lsp": ["typescript"]
    },
    "research": {
      "mcp": ["fetch", "websearch", "context7", "memory", "chrome-devtools"],
      "lsp": []
    }
  }
}
```

### 4.2 Context providers

| Provider class | MCP server | Purpose |
|----------------|------------|---------|
| Filesystem | `filesystem` | Read/write/list within allowed dirs |
| Code intelligence | `codegraph` | AST-indexed symbol/call-path/blast-radius |
| Documentation | `context7` | Up-to-date library docs (L1 source) |
| Search | `websearch`, `fetch` | External retrieval for `Planner`/`researcher` |
| Git | `mcp-server-git` | Repo state, diffs, history |
| Memory | `memory`, `muninn-remembers` | Durable recall across sessions |
| DB / data | `mcp-server-sqlite`, `agentic-tools` | Structured queries, task tracking |

### 4.3 LSP integration

LSP servers are selected in the same manifest (`lsp` arrays per task profile). `12-mcp-lsp.sh`
installs 12 LSP servers; `52-context-selector.sh` reads `task_profiles.lsp` to attach only the
relevant language servers, keeping token/context overhead low.

### 4.4 Tool execution

Tools execute through MCP with the same governance envelope as models: a call is audited
(`tool_call` event in `44-audit.sh`), PII-scanned when it carries untrusted text
(`45-pii-guard.sh`), and routed through the model selected for that task profile by
`36-model-router.sh`. Installation goes through `_npm_install` (npm pack → bun fallback) so the
registry is reproducible and survives re-runs.

---

## 5. Security Model

### 5.1 Secret management (HashiCorp Vault / Agent Vault)

> **Recommended integration point.** The repo's stated posture is *no secrets in code*: all API
> keys arrive via CLI args (`--*-key`) or environment, `.env` is gitignored, and secret files are
> `chmod 600`. There is no Vault client today. The intended seam is `26-providers.sh` +
> `18-opencode-json.sh`: a Vault/Agent-Vault backend would replace the `--*-key` args with a
> short-lived-token fetch, keeping the same redaction contract. Pre-commit scans already block key
> patterns.

### 5.2 Policy enforcement (OPA/Rego)

The governance engine (`43-governance.sh`) is a **policy decision point** in the OPA sense —
allowlist/denylist evaluation over providers and models, with modes `allow-all | allowlist |
corporate`:

```bash
# src/lib/43-governance.sh — provider/model policy engine
_provider_allowed() {
  case "$mode" in
    allow-all) return 0 ;;
    allowlist|corporate)
      if jq -e --arg p "$provider" '.denied_providers | index($p) != null' \
          "$GOVERNANCE_POLICY_FILE" >/dev/null 2>&1; then return 1; fi
      if jq -e --arg p "$provider" '.allowed_providers | index($p) != null' \
          "$GOVERNANCE_POLICY_FILE" >/dev/null 2>&1; then return 0; fi
      return 1 ;;
  esac
}
```

The policy document is `~/.config/opencode/model-policy.json` (also `.opencode/model-policy.json`
per deployment profile). The OPA/Rego mapping is straightforward: Rego rules would express the same
allowlist/denylist semantics; the bash PDP is the zero-dependency fallback. In `corporate` mode,
governance also enables audit + PII guard.

### 5.3 Zero Trust architecture

Zero trust is realized as *default-deny with explicit, audited allow*:

1. **Provider deny-by-default** — `allowlist`/`corporate` modes require an explicit allow entry.
2. **Network deny-by-default** — Isolated Circuit blocks all cloud calls.
3. **PII gate before every LLM request** — 9 detector classes sanitize untrusted text
   (`45-pii-guard.sh`):

```bash
# src/lib/45-pii-guard.sh — pre-LLM privacy gate
_pii_gate() {
  findings=$(_pii_scan "$prompt")
  if [ "$findings" -gt 0 ]; then
    warn "PII Guard: $findings PII instance(s) detected in LLM request"
    if declare -f _audit_event &>/dev/null; then
      _audit_event "pii_redacted" "{\"detectors\":$findings,\"action\":\"redacted\"}"
    fi
    _pii_redact "$prompt"   # email, phone, INN, SNILS, passport, credit card, IP, API keys
    return 0
  fi
  echo "$prompt"
}
```

4. **Non-repudiation** — hash-chained WAL + audit trail.
5. **Continuous hardening** — Lynis CIS audit (weekly cron, `47-lynis.sh`) and auditd kernel rules
   (`48-auditd.sh`).

### 5.4 OWASP AST10 compliance

OWASP Application Security Top 10 (AST10) is the control checklist. The relevant modules map as:

| OWASP AST10 area | opencode_initializer control |
|------------------|------------------------------|
| Prompt injection | PII guard (`45-pii-guard.sh`) as an input sanitizer; untrusted content never reaches prompts unredacted |
| Data leakage | No secrets in code; `.env` gitignored; `chmod 600`; pre-commit secret scan |
| Supply chain | `_download_verify()` SHA-256 on every download; no raw `curl \| sh`; offline bundle manifest |
| Excessive agency | Agent role scoping (`54-task-distributor.sh`) — Worker cannot orchestrate, Reviewer has no write path |
| Dependency vulns | Trivy (blocking on CRITICAL) + Qodana (`15-security.sh`) |

---

## 6. Team Topologies

Team Topologies is the *human organizational* lens AIPDLC borrows to decide who owns what in an
agent-assisted team. opencode_initializer's deployment profiles and role registry mirror the four
team types:

| Team Topology type | What it is | opencode_initializer mapping |
|--------------------|------------|------------------------------|
| **Stream-aligned team** | Owns an end-to-end value stream | The `Commander` + `Planner` + `Worker` + `Reviewer` quartet is a self-contained stream for one feature/PR |
| **Platform team** | Provides internal infrastructure as a product | `setup.sh`/`dev.sh` + `src/lib/` modules — the bootstrap itself is the internal platform (`dev infra`, `dev health`, `dev update`) |
| **Enabling team** | Coaches stream teams to adopt tools | Skills + plugins tier (`14-shokunin.sh`, superpowers, `.opencode/skills/`) — enablement as reusable capability, not shared headcount |
| **Complicated-subsystem team** | Owns a high-expertise subsystem | `Planner` + `sme` + `critic` for deep subsystems (RAG `21-rag.sh`, model router `36-model-router.sh`, isolated circuit `32-isolated.sh`) |

### Mapping to opencode_initializer roles

```text
Stream-aligned  ──  Commander (owns outcome) → Planner → Worker → Reviewer (one PR)
Platform        ──  setup.sh + dev.sh + src/lib/  ("internal platform as a product")
Enabling        ──  .opencode/skills/ + plugins + superpowers (adoption coaching)
Complicated     ──  Planner + sme + critic owning RAG / router / isolation subsystems
```

The interaction mode is *X-as-a-Service*: stream teams consume the platform (`dev` CLI) and
enablement (skills) as services rather than owning their maintenance. This keeps the human team
topology isomorphic to the agent topology — the same four roles describe both.

---

## 7. Unit Economics

AIPDLC justifies agent-driven development through **unit economics**: every lifecycle task must be
cheaper than its human equivalent when total cost of attention is counted.

### 7.1 Metrics

| Metric | Definition | Source |
|--------|-----------|--------|
| **Cycle time** | Idea → merged, per task | WAL timestamps (`37-wal.sh`), `checkpoint` events (`44-audit.sh`) |
| **Throughput** | Tasks completed / unit time | `checkpoint` + `session_boundary` event counts |
| **Agent success rate** | Tasks passing Review gate on first attempt | `Reviewer` verdicts → `_audit_event` |
| **Cost per task** | (tokens + compute + cloud) / tasks completed | `36-model-router.sh` cost table + `routing.json` |
| **Human attention** | Human touch-points per task (reviews, approvals) | `[STRATEGIC_NEEDED]` gates + Reviewer dispatches |
| **Quality** | Post-merge defects, test coverage, security findings | `15-security.sh` (Trivy/Qodana), `tests/run_tests.sh` |

Observability is wired for these: `34-observability.sh` provisions Prometheus + Grafana,
`00u-telemetry.sh` exports via OpenTelemetry when `OTEL_EXPORTER_OTLP_ENDPOINT` is set, and
`src/grafana/dashboards/agent-performance.json` is the dashboard for agent throughput/latency/cost.

### 7.2 Cost formula

```text
cost_per_task = (tokens + compute + cloud) / tasks_completed

tokens  = Σ (input_tokens × input_price + output_tokens × output_price)   per model
compute = GPU/CPU-hours for local backends (Ollama/vLLM/SGLang), if isolated
cloud   = infra spend (Postgres, Qdrant, Redis, observability) amortized per task
```

The cost table is SSOT in `src/data/routing.json`; complexity buckets carry a precomputed
`cost_per_1k` used for estimation:

```json
"complexity_rules": {
  "simple":  { "max_tokens": 2000,  "model": "deepseek/deepseek-v4-flash", "cost_per_1k": 0.00014 },
  "medium":  { "max_tokens": 8000,  "model": "deepseek/deepseek-v4-pro",   "cost_per_1k": 0.00055 },
  "complex": { "max_tokens": 64000, "model": "deepseek/deepseek-v4-pro",   "cost_per_1k": 0.00219 }
}
```

The repo's cost posture is deliberately free-tier-first: `36-model-router.sh` marks
`deepseek-v4-pro`, `deepseek-v4-flash`, `glm-5.2`, `claude-opus-4-8`, `grok-4.3` as `"free": true`,
so the *token* term is frequently zero and the dominant cost is human attention, not model spend.

### 7.3 ROI calculation

```text
ROI = (human_hours_saved × human_hour_rate) − (cost_per_task × tasks_completed)
      ──────────────────────────────────────────────────────────────────────────
                              (cost_per_task × tasks_completed)

human_hours_saved = (manual_cycle_time − agent_cycle_time) × tasks_completed
```

A concrete worked example (simple bug fix):

```text
Manual:     cycle 45 min, 1 human touch-point            → $0.75 attention @ $100/h
Agent:      cycle 6 min, tokens 2,000 (flash, free tier) → $0.00 tokens + $0.01 compute
cost_per_task ≈ $0.01
ROI ≈ (($0.75 − $0.01) / $0.01) ≈ 74×   per simple task
```

The lever is not token price — it is **human attention per task**. The Reviewer gate is the single
non-automated touch-point; every other stage (research, plan, implement, verify automation) runs
without a human in the loop, which is what the four-role pipeline and its task graph are engineered
to maximize.

---

## Appendix: Module → AIPDLC pillar index

| Pillar | Primary modules |
|--------|-----------------|
| Control plane | `00-core.sh`, `37-wal.sh`, `44-audit.sh`, `54-task-distributor.sh`, `66–69-agent-*.sh` |
| Agent roles | `54-task-distributor.sh` (SSOT `config.json`), `36-model-router.sh`, `.opencode/opencode-swarm.json` |
| Isolation | `02-docker.sh`, `32-isolated.sh`, `46-offline-bundle.sh`, `61-daytona.sh` (seam) |
| MCP / LSP | `12-mcp-lsp.sh`, `18-opencode-json.sh`, `52-context-selector.sh`, `src/data/mcp-profiles.json` |
| Security | `15-security.sh`, `43-governance.sh`, `44-audit.sh`, `45-pii-guard.sh`, `47-lynis.sh`, `48-auditd.sh` |
| Team topologies | deployment profiles (`personal`/`corporate`/`air-gapped`/`hybrid`), `14-shokunin.sh` skills |
| Unit economics | `36-model-router.sh`, `34-observability.sh`, `00u-telemetry.sh`, `src/data/routing.json` |

---

**See also:**
- [Agent System Architecture](./agent-system.en.md) — the 15-agent execution taxonomy
- [Architecture Index](./index.en.md) — C4 diagrams and module layout
- [ADR: Multi-Agent Framework v3](./adr/multi-agent-framework-v3.md) — operating model decision
