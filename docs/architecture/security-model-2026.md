# Security Model 2026 — opencode_initializer

> **Status:** Architecture reference (living document)
> **Scope:** The end-to-end security architecture for the opencode_initializer agent harness — threat model, isolation tiers, secret handling, policy enforcement, audit, and zero-trust principles.
> **Canonical version:** v3.3.0
> **Companion docs:** [LLM Fundamentals 2026](llm-fundamentals-2026.md), [Multi-Agent Framework v3 ADR](adr/multi-agent-framework-v3.md), [Hybrid AI Architecture ADR](adr/hybrid-ai-architecture.md)

This document is the single reference for *how the harness protects itself*. It distinguishes three honesty levels throughout:

- **[IMPLEMENTED]** — concrete code paths that exist in this repo today (modules, files, functions).
- **[PARTIAL]** — partially realized: the mechanism exists but the full defense-in-depth tier is not yet wired.
- **[REFERENCE]** — target / planned architecture patterns drawn from industry practice, documented here so the engineering direction is explicit, but not yet built.

Every section ends with "**In opencode_initializer**" — the concrete module where the concept lands, so the theory is never detached from the system.

---

## 1. Threat Model

An agent harness is not a web server, so its attack surface is different. The harness accepts *untrusted text* (prompts, documents, code, web content), holds *private data* (API keys, user files, PII), and makes *external calls* (LLM providers, MCP servers, package registries, tool execution). Three properties combine into what the industry now calls the **Lethal Trinity**:

### 1.1 The Lethal Trinity

> **private data + untrusted content + external communications = remote exploitation**

- **Private data** — the value being protected: API keys, user source, PII, credentials in the environment.
- **Untrusted content** — the attack input: prompt text, fetched web pages, third-party MCP responses, files in the working directory.
- **External communications** — the exfiltration channel: outbound LLM calls, tool subprocesses, package downloads.

Any two of the three are manageable; all three in the same process is the failure condition. The harness's entire security model is a set of controls that **break at least one leg of the trinity** at every trust boundary.

**In opencode_initializer:** the trinity is addressed at three distinct layers — PII is stripped from outbound prompts (`45-pii-guard.sh`), external comms are blocked wholesale in isolated mode (`32-isolated.sh`), and untrusted content is sandboxed before tool execution (`12-mcp.sh` containerizes MCP servers; `49-sandcastle.sh` reviews untrusted diffs).

### 1.2 OWASP AST10 — Agentic Skills Top 10

OWASP's Agentic Security Top 10 (AST10) maps the most common failure classes for LLM agents. Each is paired with its opencode_initializer mitigation:

| # | AST10 Category | Risk | Mitigation (module) |
|---|----------------|------|---------------------|
| 1 | Prompt Injection | Malicious instructions override agent behavior | PII guard pre-LLM gate, policy engine (`45`, `43`) |
| 2 | Tool & Action Abuse | Agent misuses tools on attacker-controlled input | Audit trail of every tool call (`44`) |
| 3 | Data Exfiltration | Private data leaks through prompts or tools | PII redaction, isolated circuit (`45`, `32`) |
| 4 | Supply Chain | Compromised MCP/LSP/plugin dependency | SHA-256 verified downloads (`helpers.sh`), offline bundle manifest (`46`) |
| 5 | Denial of Wallet | Model abuse drives up cost | Cost cap in model policy (`43`) |
| 6 | Model Memory Poisoning | Long-term memory is contaminated | Hash-chained WAL, tamper-evidence (`44`) |
| 7 | Privilege Escalation | Agent gains shell/sudo unexpectedly | Least privilege, `_sudo` wrapper (`helpers.sh`) |
| 8 | Shadow AI | Ungoverned models bypass policy | Provider allowlist/denylist (`43`) |
| 9 | Prompt Data Leakage | Secret-bearing prompt cached/logged | Secret redaction in logs, `chmod 600` |
| 10 | Agent Reputation Risk | Impersonation / brand abuse | Isolated local models in air-gap (`32`, `46`) |

**In opencode_initializer:** the AST10 categories are not a separate checklist — they are folded into the four governance/audit/PII/offline modules described in §7.

### 1.3 Prompt Injection

Prompt injection is the agentic analogue of SQL injection: untrusted text smuggles instructions that the model then *acts on* rather than *reads*. Defenses fall into three families, in order of increasing strength:

1. **Input sanitization** — strip or rewrite suspicious content *before* it reaches the model. Weakest; injection hides in benign-looking text.
2. **Policy gating** — a deterministic (non-LLM) layer decides whether an *output action* is permitted. This is the only reliable boundary, because it does not depend on the model "understanding" the instruction.
3. **Isolation** — run the agent in an environment where even a successful injection can do no damage (no network, read-only FS, no secrets).

The design rule in opencode_initializer: **the model is never the enforcement point**. Models propose; deterministic shell policy disposes.

**In opencode_initializer:**
- `45-pii-guard.sh` — deterministic redaction of secrets before the request leaves the box (§7.3).
- `43-governance.sh` — deterministic allow/deny of providers and models, independent of prompt content (§7.1).
- `32-isolated.sh` — the nuclear option: when `ISOLATED_CIRCUIT=true`, no cloud provider is reachable at all, so exfiltration-by-injection is structurally impossible.

### 1.4 Supply Chain Risk

The harness *installs* a lot of software — 6 toolchains, 24 MCP servers, 12 LSP servers, 21 plugins, 22 LLM providers. Each is a supply-chain edge. opencode_initializer applies a single policy uniformly:

- **No raw `curl | sh`.** Every download is fetched, SHA-256-verified, then executed (`_download_verify` in `helpers.sh`).
- **Pinned keys.** Repository GPG keys are fetched, verified, and used with `signed-by=` (see `47-lynis.sh` for the canonical pattern).
- **Reproducible air-gap bundles.** `46-offline-bundle.sh` builds a tarball with a per-file `manifest.sha256`; `_offline_bundle_verify` re-checks every file before an air-gapped install can run.
- **Pinned submodules.** `upstream/` pins `opencode`, `mcp-servers`, and the skill sources to exact commits.

**In opencode_initializer:** the verification chain lives in `helpers.sh:_download_verify`, and the *air-gap* consumption path is `46-offline-bundle.sh:_offline_bundle_run` → `_offline_bundle_verify`.

---

## 2. Isolation Architecture

Isolation is the strongest leg of the trinity to break. The harness specifies **four isolation tiers**, from heavyweight (full machine isolation) to lightweight (in-process), each with a distinct cost/security trade-off. The principle: **the more untrusted the content, the deeper the isolation.**

### 2.1 Tier 1 — Container Isolation (Docker + seccomp/cgroups)

`[IMPLEMENTED]` — Docker is the default execution boundary for infra and MCP servers.

- **cgroups** bound CPU/memory so a runaway agent cannot take the host down.
- **seccomp** filters syscalls; a compromised container cannot make arbitrary kernel calls.
- **Capability drop** — containers run without `CAP_SYS_ADMIN` and friends.

```yaml
# docker-compose security fragment (infra services)
services:
  mcp-server:
    image: mcp-server:latest
    security_opt:
      - seccomp=./seccomp-profile.json
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    read_only: true
    tmpfs:
      - /tmp
    network_mode: none          # break the exfiltration leg entirely
```

**In opencode_initializer:** `03-docker.sh` provisions Docker with the hardened daemon defaults, and `12-mcp.sh` runs MCP servers as isolated containers. The `network_mode: none` pattern above is the reference configuration for the most hostile MCP sources.

### 2.2 Tier 2 — MicroVM Isolation (Firecracker, Kata Containers)

`[REFERENCE]` — for the highest-risk workloads (executing attacker-authored code), a full VM boundary is the gold standard because it removes the shared kernel — the single largest attack surface of any container.

- **Firecracker** — AWS's microVM supervisor; boots a guest kernel in ~125 ms with ~5 MiB overhead per VM.
- **Kata Containers** — wraps a container runtime so that *each container is a VM*, giving container ergonomics with VM isolation.

```bash
# Reference: run the most untrusted agent tool in a microVM
firecracker \
  --api-sock /tmp/fc.sock \
  --config-file agent-microvm.json
```

```json
// agent-microvm.json (reference)
{
  "boot-source": {
    "kernel_image_path": "/opt/kernels/vmlinux-agent",
    "boot_args": "console=ttyS0 reboot=k panic=1"
  },
  "drives": [
    { "drive_id": "rootfs", "path_on_host": "/opt/rootfs/agent.ext4", "is_root_device": true, "is_read_only": true }
  ],
  "network-interfaces": []   // no network interface = no exfiltration
}
```

**In opencode_initializer:** not built. The seam already exists: `helpers.sh:_run_step` is the single dispatch point, so a Kata/Firecracker runtime could be introduced behind it without touching callers.

### 2.3 Tier 3 — In-process Isolation (BoxLite-style)

`[REFERENCE]` — where a microVM is too heavy, isolate *within* the process. BoxLite-style isolation combines:

- **Language-level sandbox** — run untrusted code in a restricted interpreter (WASI, Deno permissions, `isolated-vm`).
- **Capability object** — the untrusted code is handed only the *functions* it needs (a `fetch`-less object, a read-only file handle), not the ambient environment.
- **Resource quotas** — wall-clock, memory, and op-count budgets enforced in-process.

```
┌─────────────────────────────────────────┐
│ Host process (trusted harness)          │
│  ┌───────────────────────────────────┐  │
│  │ Capability boundary               │  │
│  │  untrusted_code.run(capabilities) │  │
│  │  capabilities = { read: no,       │  │
│  │                   net:  no,       │  │
│  │                   fs:   /tmp only }│ │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

**In opencode_initializer:** not built. The nearest analog is `49-sandcastle.sh`, which *reviews* untrusted content deterministically rather than executing it — review is the chosen control where execution is avoidable.

### 2.4 Read-Only Filesystem

`[PARTIAL]` — read-only filesystems prevent a compromised agent from *persisting* itself or tampering with its own binaries. The audit log (`~/.cache/opencode-setup/audit.jsonl`) is the only writable surface by design.

**In opencode_initializer:** the offline bundle is *served* read-only (`46-offline-bundle.sh`), and container specs use `read_only: true` + `tmpfs` (§2.1). The host-level `chattr +i` hardening of the installed tree is [REFERENCE].

### 2.5 Network Blocking

`[IMPLEMENTED]` — the single most effective anti-exfiltration control. When `ISOLATED_CIRCUIT=true` (`32-isolated.sh`):

- All cloud provider endpoints are disabled; only local OpenAI-compatible backends are reachable.
- Version checks (`version-check.sh`) and auto-update timers (`20-autoupdate.sh`) gate on `ISOLATED_CIRCUIT` and skip.
- The local backends are `Ollama :11434`, `vLLM :8000`, `SGLang :30000` — loopback only.

**In opencode_initializer:** `32-isolated.sh` is the enforcement point; `46-offline-bundle.sh` is how an air-gapped machine gets the software at all. Together they realize a full "no cloud" deployment.

---

## 3. Secret Management

Secrets are the "private data" leg of the trinity. The rules are absolute and enforced in CI (`security.yml`, pre-commit secret scan):

1. **No secrets in code or git.** All API keys arrive via CLI args (`--*-key`) or env vars.
2. **`.env` is gitignored**; the committed `.env.example` contains no real values.
3. **Secret files are `chmod 600`** (see `_audit_init` in `44-audit.sh`).
4. **Secrets never appear in logs** — redacted with `***`.

### 3.1 HashiCorp Vault Integration

`[REFERENCE]` — for corporate deployments, Vault becomes the single source of truth for API keys, replacing `.env` entirely. The agent never holds a long-lived credential; it holds a short-lived token.

```
┌────────────┐  token   ┌─────────┐  dynamic cred  ┌──────────────┐
│  Harness   │ ───────► │  Vault  │ ─────────────► │ Provider API │
│ (agent)    │          │ (secret │   (lease TTL)  │  (short-lived│
└────────────┘          │  engine)│                │   credential)│
                        └─────────┘                └──────────────┘
```

### 3.2 Agent Vault Proxy

`[REFERENCE]` — rather than giving the *model* raw secret material, a proxy sits between the agent and the secret store. The agent requests a *named capability* ("call provider X for task Y") and the proxy resolves it to a credential that is injected server-side and never echoes back into the prompt.

```hcl
# reference: Vault policy limiting an agent role to specific secrets
path "secret/data/llm/openai/*" {
  capabilities = ["read"]
}
path "secret/data/llm/anthropic" {
  capabilities = ["deny"]        # fail-closed: explicit deny
}
```

### 3.3 Short-Lived Credentials

`[REFERENCE]` — credentials are issued with a TTL, auto-expire, and are re-issued on demand. The blast radius of a leaked key is bounded to the lease window.

### 3.4 Secret Rotation

`[PARTIAL]` — rotation is the recovery control: when a key leaks, rotation is the *only* remedy, so it must be automated and tested.

**In opencode_initializer:** the current realization is key *refresh* via the `--*-key` CLI flags and `.env` regeneration (`setup.sh --fix-config` regenerates `opencode.json` without touching secrets). Automated periodic rotation of provider keys is [REFERENCE] and would live in a new module alongside `26-providers.sh`.

---

## 4. Policy Enforcement

Policy enforcement is the deterministic layer that the model cannot override. It answers one question for every action: **is this permitted?** — and it answers it *before* the action executes, in shell, not in the model.

### 4.1 Open Policy Agent (OPA)

`[REFERENCE]` — OPA is a general-purpose policy engine: a standalone binary that evaluates **Rego** policies against structured input. The harness's model-policy engine (`43-governance.sh`) is a *narrow, purpose-built* implementation of the same idea; OPA is the generalization.

```
                    ┌─────────────────────────────┐
  decision request  │          OPA                │
  (provider, model, ├─► Rego policy ─► allow/deny │
   action, cost)    │                             │
                    └─────────────────────────────┘
```

### 4.2 Rego Policy Language

`[REFERENCE]` — Rego is OPA's declarative policy language. Policies are data, not code, so they can be versioned, reviewed, and rotated independently of the harness.

```rego
# reference: agent-tool-policy.rego
package opencode.agent

default allow = false                      # fail-closed

allow {
  input.action == "tool_call"
  input.tool in {"read_file", "grep", "glob"}
}

allow {
  input.action == "llm_request"
  input.provider in data.allowed_providers
  input.model in data.allowed_models
  input.estimated_cost <= data.max_cost_per_1m
}

deny[msg] {
  input.action == "shell"
  not input.allowlisted_command
  msg := "shell command not allowlisted"
}
```

### 4.3 Fail-Closed Mode

`[IMPLEMENTED]` — the single most important property. Fail-closed means **the default is deny**: if the policy engine errors, the file is malformed, or the mode is unknown, the action is *blocked*, not allowed.

The existing engine is fail-closed in exactly one place — `43-governance.sh`:

- Policy file **absent** → `_provider_allowed` returns `0` (allow) for backward compatibility.
- Policy file **present** and mode is `allowlist`/`corporate` → unknown provider is **denied** (returns `1`).
- Unknown mode → currently allows; `_policy_validate` flags it with a warning.

> **Note:** the "absent file → allow" and "unknown mode → allow" branches are *fail-open* compatibility shims. The target posture is fail-closed everywhere: any governance file, once present, should deny unknown input by default. This is the highest-priority hardening gap in the current model.

### 4.4 Policy Examples

`[IMPLEMENTED]` — the live policy file, `~/.config/opencode/model-policy.json`:

```json
{
  "version": 1,
  "mode": "corporate",
  "allowed_providers": ["openai", "anthropic", "ollama"],
  "denied_providers": ["unvetted-provider"],
  "allowed_models": ["gpt-4o-mini", "claude-sonnet-4"],
  "denied_models": ["gpt-4o"],
  "max_cost_per_1m": 15.0,
  "audit": true
}
```

The three modes (`43-governance.sh`):

| Mode | Behavior |
|------|----------|
| `allow-all` | No restrictions (default; personal deployments) |
| `allowlist` | Provider must be in `allowed_providers` and not in `denied_providers` |
| `corporate` | Allowlist + model-level deny + `max_cost_per_1m` budget enforcement |

**In opencode_initializer:** `43-governance.sh` is the policy engine, `_provider_allowed`/`_model_allowed` are the enforcement functions, and `pre-session-check.sh` (`dev doctor`) runs `_policy_validate` before every session.

---

## 5. Audit & Observability

Audit is the *detective* control — it does not prevent compromise, it makes compromise *discoverable* and *provable*. The core property is **tamper-evidence**: an attacker who breaches the harness should not be able to rewrite history to hide it.

### 5.1 Request Logging

`[IMPLEMENTED]` — every LLM request and tool call is a first-class event. `44-audit.sh` defines seven event types:

| Event | Meaning |
|-------|---------|
| `model_call` | LLM request sent (provider, model, tokens, timestamp) |
| `tool_call` | Tool executed (name, args hash, duration, result) |
| `provider_switch` | Fallback triggered (from → to, reason) |
| `pii_redacted` | PII detected and sanitized (detector, count, context hash) |
| `checkpoint` | Session checkpoint (phase, task count, files touched) |
| `error` | Error event (code, module, message hash) |
| `session_boundary` | Session start/end |

### 5.2 Action Tracking — the Hash Chain

`[IMPLEMENTED]` — each event is linked to its predecessor by a SHA-256 hash, forming a **hash chain**. Tampering with any event breaks every subsequent hash.

```
event_N.hash = SHA256(event_{N-1}.hash + ts + type + details)
```

The chain is verified on demand by `_audit_verify_chain`, which recomputes every hash and every `prev` link, reporting `N events, 0 tampered` or the count of failures.

### 5.3 Anomaly Detection

`[REFERENCE]` — anomaly detection consumes the audit stream and flags deviations: a provider switch storm (rapid fallback = possible provider compromise), a burst of `tool_call` events outside known patterns, or `pii_redacted` events with unusually high counts (possible PII exfiltration attempt).

**In opencode_initializer:** `_audit_stats` (`44-audit.sh`) provides the *descriptive* baseline (event counts, last event, total size). Threshold-based *alerting* on those counts is [REFERENCE].

### 5.4 Incident Investigation

`[IMPLEMENTED]` — the hash chain is the forensic artifact. Because it is tamper-evident, it is admissible evidence: an investigator can prove exactly which events occurred and in what order, and that nothing was altered post-incident.

- **Retention:** the WAL rotates at >10 MiB → `gzip` → archived (`_audit_rotate`), preserving history.
- **Kernel-level corroboration:** `48-auditd.sh` adds an *independent* kernel audit stream (identity changes, network config, cron, sudo) that a user-space attacker cannot tamper with — the two logs cross-check each other.
- **Host hardening baseline:** `47-lynis.sh` runs weekly and tracks the CIS hardening index (target ≥80).

**In opencode_initializer:** `44-audit.sh` (WAL), `48-auditd.sh` (kernel), `47-lynis.sh` (host) form the three-layer detective stack.

---

## 6. Zero Trust Architecture

Zero trust is the posture that unifies the controls above. Its four tenets, as applied to the harness:

### 6.1 No Implicit Trust

Nothing is trusted because it *looks* legitimate — a prompt, an MCP response, a package, a model output. Every input crosses a boundary that assumes it is hostile until verified.

**In opencode_initializer:** `_download_verify` (SHA-256), PII guard, and the deterministic policy engine are all "verify, don't assume" controls.

### 6.2 Continuous Verification

Trust is never granted once and remembered. Each action is authorized *at the moment it executes*, against current policy, not against a stale session grant.

**In opencode_initializer:** `pre-session-check.sh` re-validates the policy and provider set at every `dev doctor` / session start.

### 6.3 Least Privilege

An agent holds only the privileges its current task requires — nothing more, and for no longer than needed.

**In opencode_initializer:** `_sudo` in `helpers.sh` is the choke point for privilege; container capability-dropping (`03-docker.sh`, `12-mcp.sh`) extends the principle to subprocesses; `48-auditd.sh` monitors sudo usage so escalation is *visible*.

### 6.4 Micro-Segmentation

Components are separated so a compromise of one does not imply compromise of all. Each MCP server, each provider, each tool runs behind its own boundary.

**In opencode_initializer:** MCP servers are individually containerized (`12-mcp.sh`); isolated circuit segments the *entire* network plane from cloud (`32-isolated.sh`); infra services are each their own container (§2.1).

---

## 7. Implementation in opencode_initializer

This section maps the model to the six numbered modules that actually ship it. Modules `41–51` are **sourced with existence guards but not step-executed** by the orchestrator — they provide functions consumed by `dev.sh`, other modules, and `scripts/pii-guard.py`.

### 7.1 Module 43 — `43-governance.sh` (Policy Engine)

`[IMPLEMENTED]` — deterministic allow/deny of providers and models, independent of prompt content.

```bash
# core enforcement — 43-governance.sh
_provider_allowed() {
  local provider="$1"
  [ -z "$provider" ] && return 1
  [ ! -f "$GOVERNANCE_POLICY_FILE" ] && return 0   # absent → allow (compat)
  local mode
  mode=$(jq -r '.mode // "allow-all"' "$GOVERNANCE_POLICY_FILE" 2>/dev/null) || return 0
  case "$mode" in
    allow-all) return 0 ;;
    allowlist|corporate)
      jq -e --arg p "$provider" '.denied_providers | index($p) != null' \
        "$GOVERNANCE_POLICY_FILE" >/dev/null 2>&1 && return 1   # deny wins
      jq -e --arg p "$provider" '.allowed_providers | index($p) != null' \
        "$GOVERNANCE_POLICY_FILE" >/dev/null 2>&1 && return 0
      return 1                                                    # unknown → deny
      ;;
    *) return 0 ;;
  esac
}
```

Key properties: **deny-list takes priority**, unknown providers are denied in strict modes, and `_policy_validate` sanity-checks the JSON before any session relies on it.

### 7.2 Module 44 — `44-audit.sh` (Audit Trail)

`[IMPLEMENTED]` — the tamper-evident hash chain described in §5.2.

```bash
# hash-chain append — 44-audit.sh
_audit_event() {
  local event_type="$1" details="${2:-{}}"
  local ts; ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local prev_hash="genesis"
  [ -f "$AUDIT_WAL" ] && [ -s "$AUDIT_WAL" ] && \
    prev_hash=$(tail -1 "$AUDIT_WAL" | jq -r '.hash // "genesis"' 2>/dev/null || echo "genesis")
  local event_hash
  event_hash=$(echo -n "${prev_hash}${ts}${event_type}${details}" | _sha256 | awk '{print $1}')
  _wal_locked_append "$AUDIT_WAL" \
    "$(printf '{"ts":"%s","type":"%s","details":%s,"prev":"%s","hash":"%s"}' \
      "$ts" "$event_type" "$details" "$prev_hash" "$event_hash")"
}
```

Every event carries `prev` (the predecessor hash) and `hash` (its own). `_audit_verify_chain` recomputes both; any mismatch is reported as tampering.

### 7.3 Module 45 — `45-pii-guard.sh` (PII Sanitizer)

`[IMPLEMENTED]` — a privacy gate in front of every LLM request, with nine detector classes.

```bash
# detector registry — 45-pii-guard.sh (bash 3.2 compat: indexed arrays, no declare -A)
_pii_pattern_register "inn"          '\b[0-9]{10}\b|\b[0-9]{12}\b'
_pii_pattern_register "snils"        '\b[0-9]{3}-[0-9]{3}-[0-9]{3} [0-9]{2}\b'
_pii_pattern_register "passport_ru"  '\b[0-9]{2} [0-9]{2} [0-9]{6}\b'
_pii_pattern_register "phone_ru"     '\+7[0-9]{10}\b|\b8[0-9]{10}\b'
_pii_pattern_register "email"        '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
_pii_pattern_register "phone_int"    '\+[1-9][0-9]{6,14}\b'
_pii_pattern_register "credit_card"  '\b[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}\b'
_pii_pattern_register "ip_address"   '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b'
_pii_pattern_register "api_key_leak" '\b(sk-[A-Za-z0-9]{32,})\b|...'   # API key leak
```

The `_pii_gate` function scans the outgoing prompt; if it finds PII it logs a `pii_redacted` audit event (via `_audit_event`, when available) and redacts to `[REDACTED]` before the request leaves the box. The same detectors power `scripts/pii-guard.py` for richer, non-ERE detection.

### 7.4 Module 46 — `46-offline-bundle.sh` (Air-Gap Bootstrap)

`[IMPLEMENTED]` — the supply-chain control for air-gapped deployments. Builds a self-contained tarball with a per-file SHA-256 manifest, then verifies every file before an offline install can run.

```bash
# build manifest — 46-offline-bundle.sh
find . -type f | while IFS= read -r f; do _sha256 "$f"; done | sort -k2 > manifest.sha256
```

`_offline_bundle_verify` re-checks the manifest (`_sha256 -c`) and refuses to proceed on corruption. Paired with `32-isolated.sh`, this realizes a machine with **no cloud, no network, verified software**.

### 7.5 Module 47 — `47-lynis.sh` (Host Hardening Scanner)

`[IMPLEMENTED]` — Linux-only. Installs Lynis (CIS benchmark scanner) via a GPG-pinned repo, runs an audit, and schedules a weekly `cron.weekly/lynis-audit`. Target hardening index ≥80.

```bash
# GPG-pinned install — 47-lynis.sh (the canonical supply-chain pattern)
_curl -fsSL "https://packages.cisofy.com/keys/cisofy-software-public.key" | \
  sudo gpg --dearmor -o /usr/share/keyrings/cisofy-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cisofy-archive-keyring.gpg] \
  https://packages.cisofy.com/community/lynis/deb/ stable main" | \
  sudo tee /etc/apt/sources.list.d/cisofy-lynis.list
```

### 7.6 Module 48 — `48-auditd.sh` (Kernel Audit Daemon)

`[IMPLEMENTED]` — Linux-only. Installs `auditd` and loads kernel audit rules that a user-space attacker cannot tamper with:

```
# identity changes
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k identity
# network config
-w /etc/hosts -p wa -k network
-w /etc/resolv.conf -p wa -k network
# cron + sudo usage
-w /etc/crontab -p wa -k cron
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -k sudo_usage
```

The kernel stream independently corroborates the user-space WAL (§7.2): if an attacker edits the WAL, the kernel audit of the *edit* itself remains.

---

## 8. Control-to-Threat Coverage Matrix

| Threat (AST10) | Isolation | Secrets | Policy | Audit | Zero Trust |
|----------------|:---------:|:-------:|:------:|:-----:|:----------:|
| Prompt Injection | ● (isolated) | | ● (gate) | ● | ● |
| Tool Abuse | ● | | ● | ● | ● |
| Data Exfiltration | ● (network off) | ● | | ● | ● |
| Supply Chain | | | | ● (SHA-256) | ● |
| Denial of Wallet | | | ● (cost cap) | ● | |
| Memory Poisoning | | | | ● (hash chain) | |
| Privilege Escalation | ● (cap drop) | | | ● (auditd) | ● |
| Shadow AI | | | ● (allowlist) | ● | ● |
| Prompt Data Leak | | ● (redact) | | ● (600) | ● |

`●` = control present; blank = not the primary mitigation for that threat.

---

## 9. Known Hardening Gaps

1. **[REFERENCE] Fail-closed shims** — "absent policy → allow" and "unknown mode → allow" in `43-governance.sh` are fail-open. A governed deployment should flip these to deny-by-default.
2. **[REFERENCE] Vault / OPA integration** — §3.1, §4.1 are target architecture, not shipped code.
3. **[REFERENCE] MicroVM + in-process isolation** — §2.2, §2.3 are seams-only; the dispatch point exists but the runtimes are not built.
4. **[REFERENCE] Anomaly alerting** — `_audit_stats` is descriptive; threshold alerting on the audit stream is not wired.
5. **[REFERENCE] Automated secret rotation** — key refresh is manual; periodic rotation is not automated.

These gaps are the roadmap for the next security wave; the implemented controls (§7) are the foundation they build on.
