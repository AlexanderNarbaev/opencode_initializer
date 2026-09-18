# LLM Fundamentals 2026 — and Their Application in opencode_initializer

> **Status:** Architecture reference (living document)
> **Scope:** How transformer-era language models actually work, what changed in 2026, what the hardware/economics look like, and — most importantly — how every concept maps onto a concrete module in `opencode_initializer`.
> **Canonical version:** v3.3.0
> **Companion docs:** [AIPDLC Integration](../AIPDLC-INTEGRATION.md), [Multi-Agent Framework v3 ADR](adr/multi-agent-framework-v3.md), [Hybrid AI Architecture ADR](adr/hybrid-ai-architecture.md)

This document is written for an engineer who needs to *reason* about LLM cost/latency/quality trade-offs when running an agent harness. Every section ends with "**In opencode_initializer**" — the concrete place in this repo where the concept is implemented, so the theory is never detached from the system.

---

## 1. LLM Fundamentals

A modern LLM is a function that maps a token sequence into a probability distribution over the next token. Everything downstream — agents, RAG, model routing, prompt caching — is engineering built on top of that single primitive. Understanding the four fundamentals below is what lets you predict *why* a request is slow or expensive and *where* to intervene.

### 1.1 Embeddings — tokens become vectors

**Concept.** The input string is tokenized (BPE, SentencePiece, or a byte-level scheme), and each token ID is looked up in an embedding matrix `W_e ∈ ℝ^{V×d}` where `V` is vocab size and `d` is the model dimension. The result is a sequence of dense vectors `[e_1, e_2, …, e_n]`. Embeddings are *learned*, not hand-crafted, and the geometry of the embedding space is what makes retrieval ("similar meaning → nearby vector") and classification work.

**Why it matters to us.** Two distinct uses:

1. **Context/token embeddings** — the first layer of the transformer. Purely internal; you never see it directly.
2. **Retrieval embeddings** — a *separate, smaller* model (e.g. `bge-m3`, `text-embedding-3`, `nomic-embed`) produces a vector for semantic search. This is what feeds a vector store.

**In opencode_initializer:**
- `13-chromadb.sh` installs ChromaDB — the vector database that stores document and memory embeddings for RAG and the memory layer.
- `21-rag.sh` and the RAG hybrid stack (`107-rag-hybrid.sh`, `108-rag-bm25.sh`, `109-rag-vector.sh`, `110-rag-fusion.sh`) split retrieval into *sparse* (BM25 lexical) and *dense* (vector embedding) branches and fuse them — an architectural acknowledgment that embeddings capture semantics but BM25 captures exact IDs, code symbols, and rare tokens that embeddings blur.
- `71-memory-layer.sh` persists long-horizon agent memory; embeddings are the similarity key used to recall relevant prior context.

### 1.2 Transformers — self-attention over the sequence

**Concept.** A transformer block has two core sub-layers, each wrapped in residual connections + layer-norm:

1. **Multi-head self-attention.** Every token attends to every other token, computing:

   ```
   Q = X·W_Q,  K = X·W_K,  V = X·W_V        # d → d_k projections
   Attention(Q,K,V) = softmax(QKᵀ / √d_k) · V
   ```

   `√d_k` is the scaling factor that keeps softmax from saturating at large dimension. Multi-head means this is done `h` times in parallel, each head learning a different relationship (syntax, coreference, positional, semantic).

2. **Feed-forward network (FFN).** A position-wise `MLP(d → 4d → d)`, typically SwiGLU/GeLU. Most of the model's *parameters* live here, and in MoE models this is where the experts sit (§2.1).

Position information is injected either as positional embeddings (learned or sinusoidal) or, in modern models, **RoPE** (Rotary Position Embedding) — rotation matrices applied to Q and K that encode relative distance in a way that generalizes beyond the training length.

**In opencode_initializer:** the transformer itself is upstream (OpenCode, vLLM, Ollama). What we control is how the *sequence* is assembled and how long it is — because attention cost grows as `O(n²)` in sequence length and linear in layers. This is exactly why the context-management stack exists:

- `00n-context-mgr.sh`, `70-context-engine.sh`, `83-context-engineering.sh` manage context budget.
- `52-context-selector.sh` + `src/data/mcp-profiles.json` load only the MCP/LSP servers a task actually needs — every unused tool definition is dead tokens that still cost `O(n²)` attention.
- The context guard (compression) module truncates/summarizes history to keep `n` small, directly cutting attention cost.

### 1.3 Attention — the mechanics that drive cost and caching

Three practical consequences of the attention formula govern everything in this project:

1. **Quadratic prefill.** Computing attention over a fresh `n`-token prompt costs `O(n²)` FLOPs. This is the *prefill* phase — compute-bound, parallel.
2. **Linear decode.** Generating token `i` only needs the query of token `i` and the keys/values of all *prior* tokens — `O(n)` per step, but it's memory-bound because you're reading the KV cache (§1.4). Decode is *serial*: each token depends on the previous.
3. **KV cache.** The K and V tensors for every past token are cached so they aren't recomputed each step. Cache size scales as `2 × layers × d_kv × n`. At long context this becomes the dominant memory consumer (§2.3).

**In opencode_initializer:** `36-model-router.sh` + `src/data/routing.json` encode these mechanics as *policy*. The `complexity_rules` tiers (`simple`/`medium`/`complex`) map directly to prefill/decode economics:

| Tier | max_tokens | model | cost_per_1k | When |
|------|-----------|-------|-------------|------|
| simple | 2 000 | `deepseek-v4-flash` | $0.00014 | typo fix, rename, comment |
| medium | 8 000 | `deepseek-v4-pro` | $0.00055 | feature, refactor, tests, docs |
| complex | 64 000 | `deepseek-v4-pro` + thinking | $0.00219 | system design, debug, security audit |

Small tasks are routed to cheap models because a 2 000-token prefill on a small model is nearly free, while an architecture review that needs reasoning is routed to a thinking model where the higher per-token cost buys measurably better output.

### 1.4 Prefill vs. Decode — the two phases you pay for

| | **Prefill** | **Decode** |
|---|---|---|
| Trigger | prompt + full context arrives | each generated token |
| Compute | compute-bound (`O(n²)`) | memory-bound (KV read) |
| Parallelism | high (all tokens at once) | serial (one token → next) |
| Hardware bound | FLOPs (tensor cores) | HBM bandwidth |
| Latency profile | "time to first token" (TTFT) | "tokens per second" (TPS) |
| Cost | one-time per request | per output token |

**Why it matters:** long-context agents (like ours) pay prefill on *every turn* because the full conversation + tool results + system prompt is re-sent. Two mitigations:

- **Prompt caching** — cache the KV for the *static* prefix (system prompt, tool definitions, skill instructions) so repeated turns only prefill the *dynamic* suffix. `60-caching.sh` implements this, and it's why the [harness principles](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/.config/opencode/instructions/harness-principles.md) mandate "static blocks first, dynamic input last."
- **Context compression** — reduce `n` so the cached prefix is smaller and the uncached suffix is shorter.

---

## 2. Architecture Evolution 2026

### 2.1 Mixture of Experts (MoE)

**Concept.** Instead of one dense FFN, an MoE layer has `E` experts (each a small FFN), and a router (a learned gate) selects the top-`k` experts per token:

```
y = Σ_{j ∈ top-k(router(x))} softmax(gate_j) · Expert_j(x)
```

The model can have *huge* total parameter counts (e.g. 671B for DeepSeek-V3) while only *activating* a fraction per token (e.g. 37B active). This decouples **knowledge capacity** (all params) from **compute cost** (active params). `k=1` (DeepSeek-style) is cheaper than `k=2` (Mixtral-style) but harder to load-balance.

**Implications:**
- Large MoE models are *memory-hungry* (all experts must reside in VRAM) but *compute-light* per token.
- Routing is a source of instability — expert collapse/oversubscription must be monitored.
- MoE pairs naturally with speculative decoding (§2.2) because the "draft" model can be a single expert or a tiny dense model.

**In opencode_initializer:** the default provider `deepseek/deepseek-v4-pro` (see `src/data/providers.json`) is an MoE-class model. The cost numbers in `routing.json` reflect the MoE economics — very low `cost_per_1k` for a frontier-capable model, which is *why* DeepSeek is the default rather than a denser, pricier frontier model. The `fallback` chains (`deepseek → zai → minimax`) are ordered MoE-first for exactly this reason.

### 2.2 Speculative Decoding

**Concept.** Decode is serial, but a small, cheap "draft" model can propose `γ` tokens ahead, which the large model then verifies *in parallel* in one forward pass. Correct prefixes are accepted; on the first mismatch the draft is discarded and re-drafted. Net effect: 2–3× decode speedup at zero quality loss, because verification is exact (the target model's own probabilities are used).

- **Draft source:** a small dense model, a single MoE expert, or a trained "medusa" head (multiple future-token predictions).
- **Key metric:** acceptance rate — the average number of draft tokens accepted per verification pass.

**In opencode_initializer:** not something we implement (the serving engine does it), but something we *select for*. vLLM and SGLang — both installed by `16-llm.sh` for self-hosting — ship speculative decoding. When the Isolated Circuit routes to a *local* backend (§5), speculative decoding is how a single consumer GPU achieves interactive decode rates. The routing layer (`36-model-router.sh`) doesn't need to know about it; it's a property of the endpoint.

### 2.3 KV Cache Optimization

The KV cache is the single biggest lever on serving cost and context length. 2026 techniques:

| Technique | Idea | Effect |
|-----------|------|--------|
| **GQA / MQA** | Grouped/multi-query attention — share one KV head across several query heads | 4–8× smaller cache |
| **FP8 KV cache** | store K/V in 8-bit | 2× smaller cache |
| **Sliding window** | only attend to last `w` tokens (Mistral-style) | bounded memory, lossy for long-range |
| **PagedAttention / paged KV** | KV blocks paged like OS virtual memory (vLLM) | near-zero fragmentation, higher batch |
| **Prefix caching** | share KV across requests with common prefixes | deduplicates prefill (see §1.4) |
| **KV eviction / compression** | drop or summarize old tokens | extends effective context |

**In opencode_initializer:**
- **vLLM** (installed by `16-llm.sh`) is *the* PagedAttention implementation — paged KV is the reason it sustains high batch throughput on local hardware.
- `60-caching.sh` implements prompt-cache discipline at the *client* layer (OpenCode), which complements server-side prefix caching.
- The context guard (compression) module is our *lossy* KV-equivalent: rather than evicting KV entries, we compress history *before* it is ever tokenized, so the model never pays for redundant context.

### 2.4 FP4 / FP8 Quantization

**Concept.** Weights and activations stored at reduced precision shrink memory and speed up matrix math on tensor cores that natively support the format.

| Format | Bits | Typical use | Trade-off |
|--------|------|-------------|-----------|
| FP16 / BF16 | 16 | training, reference | baseline accuracy |
| FP8 (E4M3/E5M2) | 8 | inference weights + KV | near-lossless (2025+) |
| INT8 | 8 | activations, weights | small quality drop |
| FP4 | 4 | weights (with FP8 activations) | larger drop; needs calibration |
| INT4 | 4 | weights (GPTQ/AWQ) | aggressive; common for local |

**Microscaling (MX formats)** and block quantization (scale factors shared per block rather than per-tensor) are what made FP4 viable in 2026 — per-tensor FP4 loses too much dynamic range.

**In opencode_initializer:**
- `16-llm.sh` detects GPU hardware (NVIDIA/AMD/Intel/NPU) and installs Ollama + vLLM + SGLang. Quantized models (GGUF Q4_K_M / Q8 for Ollama; AWQ/FP8 for vLLM) are the default *local* inference path — an FP4/INT4 model is the only way a consumer GPU fits a useful model in VRAM.
- The Isolated Circuit (§5) explicitly favors local quantized backends over cloud when `ISOLATED_CIRCUIT=true`.

---

## 3. Hardware & Economics

### 3.1 GPU Landscape

| Accelerator | Class | Memory | Bandwidth (≈) | Notes |
|-------------|-------|--------|---------------|-------|
| **H100 SXM** | prior-gen datacenter | 80 GB HBM3 | ~3.35 TB/s | 2023 workhorse; FP8 native |
| **H200** | prior-gen datacenter | 141 GB HBM3e | ~4.8 TB/s | more memory, same silicon family |
| **B200** | current-gen datacenter | 192 GB HBM3e | ~8 TB/s | FP4 native; ~2× H100 compute |
| **GB200 (NVL72)** | Grace-Blackwell superchip | 2× B200 + 72-core Grace | — | NVLink-C2C; rack-scale |
| **TPU v7 (Trillium)** | Google datacenter | ~32 GB HBM/TPU | — | sparse-core, matrix units |
| **RTX 5090 / consumer** | local | 32 GB GDDR7 | ~1.8 TB/s | the self-host ceiling |
| **Apple Silicon / NPU** | local edge | unified | — | low-power, low-throughput |

> Figures are approximate and illustrative — treat them as order-of-magnitude planning inputs, not procurement specs.

**Reading the table for our use case:**
- **KV capacity** is what determines max context on a single GPU. B200's 192 GB is *why* 64K+ context with large batch is now a cloud commodity.
- **Bandwidth** is what determines decode speed — decode is memory-bound (§1.4). This is why B200's ~8 TB/s matters more than its raw FLOPs for *agent* workloads (lots of serial token generation, little batch).
- **Consumer ceiling:** 32 GB VRAM means an FP4 model of ~60–70B params or an FP8 model of ~30B is the practical self-host limit. Beyond that you need quantization (§2.4), MoE offload, or a cloud API.

### 3.2 Model Pricing (illustrative, 2026)

| Provider | Model | Input $/1M tok | Output $/1M tok | Notes |
|----------|-------|----------------|-----------------|-------|
| DeepSeek | `deepseek-v4-pro` | ~$0.55 | ~$2.19 | **project default**; MoE economics |
| DeepSeek | `deepseek-v4-flash` | ~$0.14 | ~$0.55 | fast/cheap tier |
| OpenAI | `gpt-5.5` | ~$1.25 | ~$10 | frontier, dense |
| Anthropic | `claude-opus-4.8` | ~$5 | ~$25 | frontier, reasoning-heavy |
| Google | `gemini-3.5-flash` | ~$0.10 | ~$0.40 | cheap + long context |
| xAI | `grok-4.3` | ~$2 | ~$10 | UI/graphic tasks |

> These are order-of-magnitude figures; the *authoritative* numbers for this project live in `src/data/routing.json` (`cost_per_1k`) and `src/data/providers.json`. The project's own numbers are what `36-model-router.sh` and cost tracking actually enforce.

**Cost structure of a single agent turn:**

```
cost = prefill_tokens × input_$/1k + output_tokens × output_$/1k

prefill_tokens = system prompt + skill instructions + tool definitions
               + conversation history + tool results + user message
output_tokens  = reasoning tokens (thinking models) + tool calls + final answer
```

Two lessons encoded in the project:
1. **Output is 4–20× the price of input.** A thinking model that emits 4 000 reasoning tokens before answering costs more than a plain 500-token answer from a bigger model. `routing.json` gates `thinking: true` behind `complex` tasks only.
2. **Prefill is dominated by *context we keep re-sending*.** This is the entire argument for prompt caching (`60-caching.sh`) and MCP/LSP thinning (`mcp-profiles.json`).

### 3.3 Self-Hosting vs. API — decision matrix

| Criterion | Self-host (Ollama/vLLM/SGLang) | Cloud API |
|-----------|-------------------------------|-----------|
| Upfront cost | GPU capex ($2k–$40k) | $0 |
| Marginal cost | electricity only | per-token |
| Latency (small) | excellent (no network) | network-bound |
| Throughput (batch) | poor (1 GPU) | excellent |
| Model size ceiling | ~30B (FP8) / ~70B (FP4) | frontier (>1T MoE) |
| Quality ceiling | mid-tier | frontier |
| Privacy / air-gap | **complete** | depends on provider |
| Compliance | full control | shared responsibility |
| Ops burden | you own the stack | provider owns it |

**In opencode_initializer — the hybrid answer:** the project does *both*, selected per mode.

- **`16-llm.sh`** installs all three local runtimes: **Ollama** (:11434), **vLLM** (:8000), **SGLang** (:30000), with hardware auto-detection (NVIDIA/AMD/Intel/NPU).
- **`32-isolated.sh`** — the **Isolated Circuit** — flips the whole harness to *local-only* when `ISOLATED_CIRCUIT=true` (or `--airgap`). Cloud calls are blocked; only local OpenAI-compatible backends are reachable. This is the air-gapped / high-sensitivity profile.
- **`src/data/providers.json`** defines the 22 cloud providers with fallback chains, so the *default* path is cloud (frontier quality at near-zero marginal cost), while isolated mode is one flag away.

The pragmatic 2026 default: **cloud API for reasoning + local quantized models for privacy/sandbox/air-gap**, with the model router choosing per task.

---

## 4. AIPDLC Integration

AIPDLC = **AI-Product Development Life Cycle** — the governing methodology that turns a raw LLM into a *supervised, auditable, isolated* engineering workforce. The full treatment is in [AIPDLC-INTEGRATION.md](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/docs/AIPDLC-INTEGRATION.md) and [agent-system.en.md](agent-system.md); this section maps the LLM mechanics to the control structure.

### 4.1 Control Plane

The Control Plane is the *non-LLM* authority layer: it decides **what** gets executed, **by whom**, **with what model**, **in what sandbox**, and records everything.

| Component | Module | Responsibility |
|-----------|--------|----------------|
| Orchestrator | `setup.sh`, `dev.sh` | parse CLI, dispatch modes, run 48 numbered steps |
| Model router | `36-model-router.sh` + `src/data/routing.json` | task → model/provider selection (§1.3) |
| Provider registry | `26-providers.sh` + `src/data/providers.json` | 22 providers, fallback chains, API keys |
| Config generator | `18-opencode-json.sh` | render `opencode.json` from SSOT |
| Context selector | `52-context-selector.sh` + `mcp-profiles.json` | thin MCP/LSP per task |
| Agent orchestrator | `66-agent-orchestrator.sh`, `67-agent-pipeline.sh`, `68-agent-mesh.sh` | multi-agent fan-out/coordination |
| Observability | `34-observability.sh`, `00u-telemetry.sh` | Prometheus/Grafana metrics |

The key architectural principle (from the v3 ADR): **the Control Plane is deterministic code, not an LLM.** Models propose; the plane disposes. An LLM never holds root, never owns the progress file, and never writes to the WAL directly — it goes through `_run_step`, `_step_done`, and `_wal_locked_append`.

### 4.2 Agent Roles & Autonomy Levels

| Role | Human or AI | Autonomy | Gates |
|------|-------------|----------|-------|
| **Administrator** | Human | full | — |
| **Architect** | Human (AI-assisted) | approve plans | critic-gate, council |
| **Planner** | AI | propose, no execute | plan approval |
| **Coder / Worker** | AI | implement in sandbox | reviewer, tests |
| **Reviewer** | AI | advisory only | findings → human |
| **Critic** | AI | challenge, no write | verdict recorded |

**In opencode_initializer:** the multi-agent harness (`100-harness-subagents.sh`, `66–69-*.sh`) plus the `.opencode/skills/*` protocol skills (`plan`, `specify`, `execute`, `critic-gate`, `council`, `phase-wrap`) implement this ladder. Autonomy is *bounded by gate*, not by prompt. A coder can edit files inside a declared scope (`declare_scope`); it cannot approve its own work — that requires an independent reviewer verdict that is itself persisted as evidence.

### 4.3 Isolation

Two orthogonal isolation layers:

1. **Container isolation** — each agent runs in a sandbox (Docker/`86-sandbox.sh`) with a declared file scope, no network by default, and resource limits.
2. **Model/network isolation** — the Isolated Circuit (`32-isolated.sh`) blocks *all* cloud LLM calls in air-gap mode, so the model itself is the isolation boundary (local backend only).

```
# sandbox-policy.yaml (illustrative — rendered by 89-security-policies.sh)
sandbox:
  network: none            # no egress by default
  writable_scope: ["./src", "./tests", "./docs"]
  read_only: [".opencode", "src/data"]
  resources: { cpu: "2", mem: "4Gi" }
  allow_list: ["bash", "git", "go", "node", "python3"]
```

### 4.4 MCP Protocol

**MCP** (Model Context Protocol) is the JSON-RPC contract between the agent and external tools — filesystem, git, browser, code-graph, databases. The project registers **24 MCP servers** and **12 LSP servers** (see `18-opencode-json.sh` + `12-mcp-lsp.sh`).

Two LLM-relevant design decisions:

1. **Context cost.** Every enabled MCP server injects its tool schema into the system prompt — real prefill tokens (§1.4). Hence `mcp-profiles.json` `disabled_by_default` list (chrome-devtools, playwright, excalidraw, agent-browser) and per-task profiles: a `coding` task loads filesystem/codegraph/git/memory, a `reasoning` task loads sequential-thinking/fetch/memory — nothing more.
2. **Contract discipline.** "Pipeline layers speak JSON contracts only" (harness principle). MCP responses are structured, which keeps tool results parseable and cacheable — unstructured text would defeat both the router and the cache.

```jsonc
// src/data/mcp-profiles.json (excerpt)
"task_profiles": {
  "coding": {
    "mcp": ["filesystem", "codegraph", "context7", "git", "memory"],
    "lsp": ["typescript", "pyright", "gopls", "rust-analyzer", "bash"]
  },
  "reasoning": {
    "mcp": ["sequential-thinking", "fetch", "memory"],
    "lsp": []
  }
}
```

### 4.5 Git Workflow

The agent harness is Git-native: every logical unit of work is a branch, a scope, and a checkpoint.

- **Progress files + git checkpoints** = multi-session continuity (`checkpoint` tool, `~/.cache/opencode-setup/progress`).
- **Conventional commits**, PRs to `main` (GitHub) mirrored to GitVerse.
- **Review gates are Git-anchored:** the `code-review` and `swarm-pr-review` skills diff against a merge-base, so review context is bounded and deterministic — which keeps the reviewer model's prefill small and its output focused.

```bash
# the agent loop, Git-native (illustrative)
git checkout -b feature/x
# coder edits within declared scope
git add src/lib/ && git commit -m "feat: ..."
# reviewer diffs against merge-base and records verdict
bash tests/run_tests.sh    # evidence before claims
```

---

## 5. Security & Isolation

Security in an agent harness is *not* just "don't leak keys" — it's that an LLM is an untrusted actor with a compiler, a shell, and network access. The model is inside the trust boundary; treat it accordingly.

### 5.1 Container Isolation

`86-sandbox.sh` + `15-security.sh` (Trivy/Qodana) + `89-security-policies.sh` provide the enforcement:

- **Least privilege by default** — no network egress, declared writable scope, read-only system data.
- **Resource limits** — a runaway agent can't OOM the host or fork-bomb.
- **Image hygiene** — Trivy scans images at CRITICAL-blocking severity (CI `security.yml`).

### 5.2 Secret Management (HashiCorp Vault)

`90-secrets-manager.sh` wraps secret storage with the `_secrets_*` API, backed by Vault in corporate profile:

```bash
_secrets_store  "openai"  "sk-..."      # write (chmod 600, never in git)
_secrets_get    "openai"                 # read into env at runtime
_secrets_rotate "openai"                 # rotate without touching code
_secrets_list                           # inventory (redacted)
```

**Hard rules (enforced in CI + pre-commit):**
- No secrets in code or logs; `.env` is gitignored; secret files are `chmod 600`.
- `security-rules.json` `SEC002` pattern-detects `AKIA…`, `sk-…`, `ghp_…`, `-----BEGIN PRIVATE KEY-----` and scores them `-25` — the single heaviest penalty in the security scoring table.
- All API keys reach the harness via CLI flags (`--*-key`) or env only.

### 5.3 OPA Policies

Open Policy Agent (OPA) is the policy-as-code layer in the corporate profile. `89-security-policies.sh` (`_security_policy_create/list/check/toggle`) and `src/data/security-rules.json` express policy declaratively, so "may this agent do X" is a versioned, auditable decision, not an `if` buried in bash.

```rego
# policy.rego (illustrative)
package opencode.agents

default allow = false

allow {
  input.role == "coder"
  input.action == "edit"
  glob.match(input.scope, ["/"], input.path)
}

allow {
  input.role == "reviewer"
  input.action == "read"
}
```

The `security-rules.json` scoring model is the lightweight, dependency-free version of the same idea — every suspicious pattern subtracts from a trust score, and the result maps to a `CRITICAL/HIGH/MEDIUM/LOW` level:

| Rule | Class | Severity | Score |
|------|-------|----------|-------|
| SEC001 | prompt injection | critical | −15 |
| SEC002 | secret leakage | critical | −25 |
| SEC003 | permission escalation | high | −20 |
| SEC004 | unsafe execution | high | −10 |
| SEC005 | network access | medium | −3 |

### 5.4 OWASP AST10 (LLM Top-10) Coverage

The OWASP Top-10 for LLM applications, mapped to the modules that mitigate each:

| OWASP LLM risk | Mitigation in opencode_initializer |
|----------------|-------------------------------------|
| LLM01 Prompt Injection | `security-rules.json` SEC001; sandbox no-egress; never run model output as root |
| LLM02 Insecure Output Handling | structured JSON contracts (MCP); output parsed, not `eval`'d |
| LLM03 Training Data Poisoning | N/A (we don't train); model registry pinned |
| LLM04 Model DoS | resource limits in `86-sandbox.sh`; rate/retry in `_curl` |
| LLM05 Supply Chain | `_download_verify()` SHA-256; no raw `curl \| sh`; Trivy/Qodana |
| LLM06 Sensitive Info Disclosure | PII guard (`45-pii-guard.sh`, 9 detector classes) *before* requests |
| LLM07 Insecure Plugin Design | plugin allowlist; MCP disabled-by-default |
| LLM08 Excessive Agency | role ladder (§4.2); `declare_scope`; human gates |
| LLM09 Overreliance | independent reviewer + critic verdicts; evidence-before-claims |
| LLM10 Model Theft | Isolated Circuit for local models; Vault-managed keys |

**PII guard** (`45-pii-guard.sh` + `scripts/pii-guard.py`) is the standout — 9 detector classes (email, phone, INN, SNILS, passport, credit card, IP, API key) run *before* any LLM request, so sensitive data never leaves the boundary at all. That's LLM06 handled at the root rather than at the response.

---

## 6. Unit Economics

You can't manage an agent harness without a cost/latency/quality model per unit of work. The observability stack (`34-observability.sh`, Prometheus :9090, Grafana, `00u-telemetry.sh`, `src/systemd/opencode-metrics.service`) emits the raw events; this section defines the *derived* metrics that matter.

### 6.1 Metric Definitions

| Metric | Definition | Target (indicative) |
|--------|-----------|---------------------|
| **Cycle time** | time from task acceptance to merged PR | shrink, not zero |
| **Throughput** | tasks completed / unit time | increase |
| **Agent success rate** | tasks passing all gates on first run | ≥ 80% |
| **Cost per task** | tokens × price, summed across turns | budgeted per tier (§1.3) |
| **Human attention** | minutes of human review per task | minimize |
| **Quality** | escaped defects / task; review-gate pass rate | zero escaped critical |

### 6.2 Cost per Task — the number that ties it together

```
cost_per_task = Σ_turns (prefill_tokens_t × input_$ + output_tokens_t × output_$)
              + tool_cost (MCP/LSP/browser) + compute (self-hosted GPU-hrs)
```

The levers, in order of leverage:

1. **Right-size the model per task** (`routing.json`) — a typo fix on `deepseek-v4-flash` is ~15× cheaper than on a thinking frontier model. This is *the* highest-leverage, lowest-effort intervention.
2. **Shrink prefill** — prompt caching (`60-caching.sh`) + MCP/LSP thinning (`mcp-profiles.json`) + context compression.
3. **Bound output** — disable `thinking` except for `complex`; cap `max_tokens` per tier.
4. **Cache + reuse** — `_curl` 24h cache, `112-cache-manager.sh`, `60-caching.sh`.

### 6.3 Quality vs. Cost — the routing trade-off, made explicit

`routing.json` already encodes the trade-off as a *default policy*; the unit-economics view is what justifies changing it:

| Task class | Model | Relative cost | Quality rationale |
|------------|-------|---------------|-------------------|
| trivial (typo/rename) | flash | 1× | correctness is mechanical; cheap model suffices |
| standard (feature/refactor) | pro | ~4× | needs real code synthesis |
| hard (design/debug/audit) | pro + thinking | ~16× | reasoning tokens pay for themselves in review time saved |

**The human-attention angle:** spending 16× on a thinking model for an architecture review is *cheap* if it saves a human 20 minutes of review. Human attention is the scarcest resource in the AIPDLC — every metric above ultimately reduces to "does this save a human from re-doing or re-verifying work?"

### 6.4 Instrumenting the Loop

```bash
# what to watch (illustrative)
dev metrics          # Prometheus metrics on :9464
dev observability    # Grafana dashboards
dev models <task>    # route a task class and see chosen model + est. cost
```

The harness already emits per-turn token counts and per-provider cost (context/token/cost stack, modules 53–60). The discipline is: **measure prefill and decode separately** (§1.4) — a task with high TTFT is a caching/context problem; a task with high total cost is a routing/model problem. Diagnose against the right phase, not the aggregate.

---

## 7. References

### Project modules

| Concern | Module(s) |
|---------|-----------|
| Local LLM runtimes + hardware detect | `src/lib/16-llm.sh` |
| Isolated Circuit (air-gap) | `src/lib/32-isolated.sh` |
| Model routing | `src/lib/36-model-router.sh`, `src/data/routing.json` |
| Providers | `src/lib/26-providers.sh`, `src/data/providers.json` |
| MCP/LSP selection | `src/lib/12-mcp-lsp.sh`, `52-context-selector.sh`, `src/data/mcp-profiles.json` |
| Config generation | `src/lib/18-opencode-json.sh` |
| Vector DB / RAG | `src/lib/13-chromadb.sh`, `21-rag.sh`, `107–110-rag-*.sh` |
| Prompt caching / context | `src/lib/60-caching.sh`, `00n-context-mgr.sh`, `70-context-engine.sh` |
| Memory | `src/lib/71-memory-layer.sh` |
| Security policies / rules | `src/lib/89-security-policies.sh`, `src/data/security-rules.json` |
| Secrets (Vault) | `src/lib/90-secrets-manager.sh` |
| Sandbox | `src/lib/86-sandbox.sh` |
| RBAC / governance | `src/lib/72-rbac.sh`, `73-governance.sh`, `43-governance.sh` |
| PII guard | `src/lib/45-pii-guard.sh`, `scripts/pii-guard.py` |
| Audit trail | `src/lib/44-audit.sh` |
| Observability / telemetry | `src/lib/34-observability.sh`, `00u-telemetry.sh` |
| Agent orchestration | `src/lib/66–69-*.sh`, `100-harness-subagents.sh` |

### Companion docs

- [AIPDLC Integration](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/docs/AIPDLC-INTEGRATION.md)
- [Agent System (EN)](agent-system.md) / [(RU)](agent-system.md)
- [Multi-Agent Framework v3 ADR](adr/multi-agent-framework-v3.md)
- [Hybrid AI Architecture ADR](adr/hybrid-ai-architecture.md)

### External

- *Attention Is All You Need* (Vaswani et al., 2017) — the transformer.
- *DeepSeek-V3 Technical Report* — MoE + multi-token prediction + FP8 training.
- *vLLM / PagedAttention* — paged KV cache.
- *Fast Inference from Transformers via Speculative Decoding* (Leviathan et al., 2023).
- OWASP Top-10 for LLM Applications (AST10).
