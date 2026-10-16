# Research: Modern Solutions — Adoption List (verified 2026-10-16)

**Scope:** tracks 1–6 from the research brief, filtered down to what is *actionable inside this repo*.
**Method:** every claim below was verified against a primary source (npm registry API, official vendor docs, official spec blog) or a direct file read in this repo. Nothing is inferred from memory.

**Confidence legend:** `HIGH` = official vendor/spec/registry API · `MEDIUM` = GitHub repo/maintainer statement · `LOW` = third-party blog/aggregator.

---

## Corrections to the research brief (verified)

| Brief claim | Verified reality | Source | Confidence |
|---|---|---|---|
| "opencode 1.19.0 V1 runtime (V2 2.0.27 staged)" | npm `opencode-ai` has **0 versions matching `2.*`** across **12,249** published versions. `dist-tags.latest = 1.19.2` (published 2026-10-16). V2 exists only under `beta` / `next` / `dev` snapshot tags (`0.0.0-beta-202608110357`). **V1 remains `latest` and is still shipping patches** (`1.18.32…1.18.35` → `1.19.0` → `1.19.1` → `1.19.2`). | `registry.npmjs.org/opencode-ai` | HIGH |
| "opencode-dcp removed as V2-only" | **False.** `@tarquinen/opencode-dcp` `latest = 3.2.0`, published 2026-09-20, active 1.x→3.x line through 2026-06/08/09. The plugin is alive and installable on V1. | `registry.npmjs.org/@tarquinen/opencode-dcp` | HIGH |
| "ZERO V2 plugin releases exist in the community" | **Contradicted by at least one.** `opencode-snippets` publishes a dedicated `opencode-v2` dist-tag (`3.1.0-opencode-v2.1`) alongside `latest` `3.3.2`. Dual-track publishing is an emerging, not absent, pattern. | `registry.npmjs.org/opencode-snippets` | HIGH |

---

## Ranked adoption list (15)

### ⭐ TOP-5 QUICK WINS

---

### 1. Pin every plugin and MCP server to an exact version; eliminate all `@latest`

| | |
|---|---|
| **What** | Every plugin and MCP server in this repo installs from a floating tag. `src/lib/12-mcp-lsp.sh` installs all 19 plugins with `@latest`; `src/lib/119-ecosystem-integration.sh:42-69` installs 10 MCP packages with `@latest`; `src/lib/00j-auto-sync.sh:167,263,320` re-runs `npm install -g …@latest` on **every** `dev update`. Separately, `opencode.json` contains 4 bare `npx -y <pkg>` entries with no version (`@modelcontextprotocol/server-memory`, `@modelcontextprotocol/server-redis`, `chrome-devtools-mcp`, `@upstash/context7-mcp`, `@notionhq/notion-mcp-server`) — these re-resolve to `latest` on **every agent launch**, so two sessions on the same day can run different binaries. Meanwhile `package.json` correctly pins `@opencode-ai/plugin: "1.19.0"` exactly — proving the repo already knows the right pattern, it just isn't applied to the 40+ globally-installed packages. |
| **Source** | `src/lib/12-mcp-lsp.sh:91-139`, `src/lib/119-ecosystem-integration.sh:42-69`, `src/lib/00j-auto-sync.sh:167,263,320`, `opencode.json` (file read); `https://docs.renovatebot.com/configuration-options/` |
| **Confidence** | **HIGH** (repo file read + registry API) |
| **Impact** | **HIGH** — this is the root cause of items 2, 3, 5 and of unannounced breakage after every upstream release. A harness that cannot be reproduced is not a production harness. |
| **Effort** | **S** — add a `PINNED_VERSIONS` block in `00-core.sh` next to the existing `_mcp_add` calls, replace `@latest` with `@${ver}`, and make `opencode.json` generation emit the same exact spec string it installs. |
| **Integration step for THIS repo** | 1) Convert `_mcp_add "name" "pkg"` (`src/lib/00-core.sh:263-285`) to `_mcp_add "name" "pkg@exact.ver"`. 2) Add `PLUGIN_PINS=(opencode-orchestrator@2.0.15 opencode-token-tracker@2.0.0 opencode-pty@0.4.0 …)` in `12-mcp-lsp.sh`, replacing each `@latest`. 3) Change `00j-auto-sync.sh` auto-sync from `@latest` to `@<pinned>`, and move "bump the pin" to an explicit, PR-gated step rather than a silent nightly refresh. 4) Add a unit test `tests/unit/test_pin_versions.sh` that greps `src/lib/*.sh` and fails if any `npm install -g` line contains `@latest` or a bare spec. |

---

### 2. Retire the 7 npm-deprecated MCP servers currently wired into the harness

| | |
|---|---|
| **What** | Seven `@modelcontextprotocol/server-*` packages this repo installs now carry npm's `"deprecated": "Package no longer supported"` flag. Verified directly from the registry metadata of each package's current `latest`: **`server-github`** (2025.4.8), **`server-redis`** (2025.4.25), **`server-postgres`** (0.6.2), **`server-gitlab`** (2025.4.25), **`server-puppeteer`** (2025.5.12), **`server-slack`** (2025.4.25), **`server-brave-search`** (0.6.2). Five of these are referenced in this repo: `00-core.sh:271,272,273,279`, `18-opencode-json.sh:302,323,334`, `119-ecosystem-integration.sh:51,54,57,60,69`, `pre-session-check.sh:98`, and `opencode.json` ships a **`redis` MCP entry with `"enabled": true`** pointing at the deprecated package. Note the packages are *still installable* (npm deprecation ≠ unpublish), so this fails **silently at runtime** — a hard-to-diagnose class of failure. Contrast: **`server-memory`, `server-filesystem`, `server-sequential-thinking` are alive** — all three shipped `1.0.0` on 2026-08-31 and were last modified 2026-10-11, i.e. they are the actively-maintained line. |
| **Source** | `https://registry.npmjs.org/@modelcontextprotocol%2Fserver-{github,redis,postgres,gitlab,puppeteer,slack,brave-search}` (each `versions[latest].deprecated` field); repo file reads |
| **Confidence** | **HIGH** |
| **Impact** | **HIGH** — 5 dead entries in the generated config, guaranteed-failing health checks (`19-finalize.sh:178-187`, `health.sh:62`), and unbounded future breakage when npm finally unpublishes. |
| **Effort** | **S/M** — replacement per server differs. |
| **Integration step for THIS repo** | - `github` → the GitHub-maintained **remote** server `https://api.githubcopilot.com/mcp/` (remove the local `npx` entry; no local package is a maintained replacement). - `postgres` → `postgres-mcp` (npm `1.0.4`, community) or keep the local Postgres MCP only if it is actually in use; the repo already has `33-services.sh`/`30-infra.sh` for the DB itself. - `redis` → **disable and delete the entry**; the repo has `memorylayer` (npm `0.2.0`, modified 2026-09-09) which is the maintained path. - `puppeteer` → already superseded by `@playwright/mcp` (npm `0.0.83`, 436 versions, modified 2026-09-28) which *is* installed. - `slack`/`gitlab`/`server-brave-search` → not referenced in `00-core.sh`'s active set; drop from `119-ecosystem-integration.sh`. Then update `EXPECTED_MCPS` in `tests/unit/test_mcp_registry.sh:29` and `tests/integration/test_opencode_json_gen.sh:32` so the 137 test files still assert a coherent set. |

---

### 3. Fix the `brave-search` split-brain (unofficial npm package vs. Brave's official one)

| | |
|---|---|
| **What** | The repo references **two different, differently-named packages** for Brave Search, and the generated config and the committed config disagree. `00-core.sh:280` declares `brave-search-mcp`; `18-opencode-json.sh:370-378` emits `brave-search-mcp`; `health.sh:62` health-checks the binary `brave-search-mcp`; `19-finalize.sh:188` checks `npm list -g brave-search-mcp`. But the **committed** `opencode.json:597-603` uses `@brave/brave-search-mcp-server@2.1.4`. These are not aliases: `brave-search-mcp` is an **unofficial community wrapper**, `latest 2.1.0`, **last published 2026-03-02** — 7 months stale, 14 versions. `@brave/brave-search-mcp-server` is the **official Brave package**, `latest 2.1.4`, **93 versions, last published 2026-09-17** — actively shipped. Consequence: a fresh `bash setup.sh` run regenerates a config pointing at the stale unofficial wrapper and *downgrades* a working setup; and the health check validates a binary that `opencode.json` never invokes. |
| **Source** | `registry.npmjs.org/brave-search-mcp` vs `registry.npmjs.org/@brave/brave-search-mcp-server`; `src/lib/00-core.sh:280`, `src/lib/18-opencode-json.sh:370-378`, `src/modes/health.sh:62`, `src/lib/19-finalize.sh:188`, `opencode.json:597-603` |
| **Confidence** | **HIGH** |
| **Impact** | **MEDIUM-HIGH** — silent downgrade of a working setup; a health check that cannot detect a real regression. |
| **Effort** | **S** |
| **Integration step for THIS repo** | Change `00-core.sh:280` to `_mcp_add "brave-search" "@brave/brave-search-mcp-server@2.1.4"`; change `18-opencode-json.sh:372` to resolve that package; change `health.sh:62` and `19-finalize.sh:188` to `_check … "@brave/brave-search-mcp-server"`; change `119-ecosystem-integration.sh:66` from `@latest` to the exact pin. Also flip `opencode.json`'s `"enabled": false` for brave-search to `true`, or remove the entry if the default tier deliberately excludes it — currently it is dead config. |

---

### 4. Delete the duplicate `context7` MCP entry (`context7` vs `context7-official` are the same server)

| | |
|---|---|
| **What** | `opencode.json` registers two MCP servers that resolve to the **identical npm package**. Line 461: `"context7"` → `npx -y @upstash/context7-mcp@4.3.0`, `enabled: true`. Line 622: `"context7-official"` → `npx -y @upstash/context7-mcp` (**unpinned**), `enabled: true`. The deprecated `redis` entry sits at line 503. Both are live: the running agent session lists `context7 (2 tools)` and `context7-official (2 tools)` — four tool schemas in the system prompt for a server with two tools. It also double-downloads on every launch. `_mcp_add` in `00-core.sh:263-264` registers both. Additionally the pinned copy is **3 releases behind** (`@upstash/context7-mcp` latest is `4.4.2`, modified 2026-10-15, 95 versions). |
| **Source** | `opencode.json:461-470,622-636` (file read); live tool catalog in the current session; `registry.npmjs.org/@upstash/context7-mcp` |
| **Confidence** | **HIGH** |
| **Impact** | **MEDIUM** — direct, recurring context-window tax on every session, plus a second supply-chain surface. |
| **Effort** | **S** |
| **Integration step for THIS repo** | Remove `context7-official` from `00-core.sh:264` and `18-opencode-json.sh`; drop it from `EXPECTED_MCPS` in `tests/unit/test_mcp_registry.sh:29` and `tests/integration/test_opencode_json_gen.sh:32`; bump the surviving `context7` pin from `4.3.0` to `4.4.2`. Also delete the unrelated `c7-mcp-server` entry — that is an *unofficial* Context7 wrapper (`latest 1.0.1`, **last published 2025-04-15, 18 months stale**) shadowed by the official `@upstash/context7-mcp` at `4.4.2`.

---

### 5. Remove `opencode-goal-mode` — the npm package is an empty placeholder

| | |
|---|---|
| **What** | `src/lib/12-mcp-lsp.sh:139` runs `npm install -g opencode-goal-mode@latest`. That package name exists on npm but has **zero published versions and no `dist-tags` at all** (placeholder created 2026-06-07, never published). The install therefore fails on every run, and the failure is swallowed by the surrounding `|| { warn …; }` pattern, so a registered plugin in the harness's plugin list is permanently unresolvable. This is a phantom entry that inflates the advertised plugin count. |
| **Source** | `registry.npmjs.org/opencode-goal-mode` (`dist-tags: undefined`, `versions: {}`); `src/lib/12-mcp-lsp.sh:139` |
| **Confidence** | **HIGH** |
| **Impact** | **MEDIUM** — small direct impact, but it is the template for a whole class of "installed → silently missing" plugins; the same check should be run over all 19. |
| **Effort** | **S** |
| **Integration step for THIS repo** | Delete the `opencode-goal-mode` block from `12-mcp-lsp.sh` and from the plugin list in `00m-plugin-discovery.sh` / the `plugin` block of `opencode.json`. Then add `tests/unit/test_plugin_registry.sh`: for each plugin name in `src/lib/12-mcp-lsp.sh`, assert `npm view <pkg> dist-tags.latest` is non-empty — turning the registry itself into the source of truth so phantom packages cannot re-enter. |

---

### 6. Adopt MCP spec `2026-07-28` for every remote MCP server

| | |
|---|---|
| **What** | The current MCP spec (published 2026-07-28) is a **breaking** release that changes what a production client must do: (a) the `initialize`/`initialized` handshake and the `Mcp-Session-Id` header are **retired** — every request is self-describing, and `server/discover` is optional; (b) **Multi Round-Trip Requests** replace server-initiated `elicitation/create`, `sampling/createMessage`, `roots/list`; (c) Streamable HTTP **must** carry `Mcp-Method` and `Mcp-Name` headers (SEP-2243) so gateways/rate-limiters can route without parsing bodies; (d) `tools/list`, `prompts/list`, `resources/list`, `resources/read` now return **`ttlMs` and `cacheScope`** (SEP-2549) — explicitly designed to "keep upstream prompt caches stable across reconnects"; (e) a **formal 12-month minimum deprecation window** now exists, so upgrades can be planned instead of reacted to. Tier 1 SDKs (TS/Python/Go/C#) ship it; Rust is beta. Critically for this repo: **Roots, Sampling, and Logging are deprecated** (SEP-2577). |
| **Source** | https://blog.modelcontextprotocol.io/posts/2026-07-28/ (official, by Lead Maintainers David Soria Parra / Den Delimarsky) |
| **Confidence** | **HIGH** |
| **Impact** | **HIGH** — `ttlMs`/`cacheScope` is a direct, first-class prompt-cache lever and pairs exactly with the repo's existing `src/lib/112-cache-manager.sh` and `src/lib/60-caching.sh`. The 12-month window means acting now is cheap and deferring is also safe. |
| **Effort** | **M** — mostly a client/registry concern, not a per-server rewrite. |
| **Integration step for THIS repo** | 1) In `src/lib/52-*.sh` / the context-budget tooling, read `ttlMs` and `cacheScope` from `tools/list` responses and feed them into `112-cache-manager.sh` instead of the current time-based heuristic. 2) Add a unit test asserting no configured MCP server relies on Roots/Sampling/Logging (the deprecated primitives). 3) Record the 12-month window in `docs/` with the absolute dates for the deprecated primitives so upgrades can be scheduled, not guessed. 4) If any remote servers are proxied, assert `Mcp-Method`/`Mcp-Name` are present on outbound requests. |

---

### 7. Source the MCP roster from the official MCP Registry instead of the hand-maintained `_mcp_add` list

| | |
|---|---|
| **What** | The official MCP Registry (`registry.modelcontextprotocol.io`, the `modelcontextprotocol/registry` repo) is the community-agreed discovery surface — an "app store for MCP servers". Independent pulls in 2026 counted **9,652 latest server records** (May 2026), and the protocol reports **10,000+ servers deployed in production** with **97M+ SDK downloads/month**. This repo instead hand-curates 23 entries in `src/lib/00-core.sh:263-285` and separately re-declares a subset in `18-opencode-json.sh`, in `119-ecosystem-integration.sh`, in `00j-auto-sync.sh`, and in `tests/unit/test_mcp_registry.sh` — **five** places to update when one server is added or deprecated (which is exactly how the drift in items 2–5 accumulated). |
| **Source** | https://registry.modelcontextprotocol.io/ ; https://github.com/modelcontextprotocol/registry ; https://www.digitalapplied.com/blog/mcp-adoption-statistics-2026-model-context-protocol ; https://en.wikipedia.org/wiki/Model_Context_Protocol |
| **Confidence** | **HIGH** for registry existence + scale (official registry + cross-checked); **MEDIUM** for the exact record counts (secondary aggregators). |
| **Impact** | **MEDIUM** — collapses 5 sources of truth into 1 and makes deprecation detection automatic (registry exposes server metadata; combined with the 12-month window from item 6 this becomes a scheduled chore, not a surprise). |
| **Effort** | **M** |
| **Integration step for THIS repo** | Keep `src/data/mcp-profiles.json` as the curated *allowlist* (do not auto-adopt), but add `dev mcp sync-registry` that queries the registry, intersects it with the allowlist, and emits a **PR** (not an install) listing: newly deprecated servers, new official replacements, and version drift. Wire that PR job into `.github/workflows/`. Collapse the duplicated package lists in `00-core.sh` / `119-ecosystem-integration.sh` / `00j-auto-sync.sh` / `pre-session-check.sh` so all four read the same `_mcp_add` table.

---

### 8. Fix model SSOT drift: `mimo-v2.5` → `mimo-v2.6-pro`, and retire the `deepseek-v4-flash` alias

| | |
|---|---|
| **What** | Two concrete staleness bugs in the SSOT files. **(a)** `src/data/providers.json:8` declares `"mimo": {"model": "mimo-v2.5", "free": true}` — but the verified runtime model is `mimo/mimo-v2.6-pro`, and the V2.6 series is live: `MiMo-V2.6-Pro` has a **1M-token context window**, `128K` max output, released **2026-09-22**, priced `$0.435/M` input and `$0.87/M` output with **`$0.0036/M` cache-read** (a **121× cheaper cache-read rate than input**). The `"free": true` flag is also wrong — this is metered API, not free. **(b)** `src/data/routing.json` names `deepseek/v4-flash` in **8+ places** (lines 9, 17, 40, 41, 42, 45, 57, 70). DeepSeek's **official** pricing page states plainly: *"Use `deepseek-flash` as the model name. The legacy names `deepseek-v4-flash` and `deepseek-v4-flash-vision-exp` are still accepted, but the corresponding models have been **retired**."* The repo is routing its entire "simple task" tier through a **retired alias**. |
| **Source** | `src/data/providers.json:8`, `src/data/routing.json:9,17,40-70` (file read); https://api-docs.deepseek.com/quick_start/pricing (official) ; https://mimo.mi.com/models/en-US/mimo-v2.6-pro (official) ; https://openrouter.ai/xiaomi/mimo-v2.6-pro |
| **Confidence** | **HIGH** (official DeepSeek pricing page states the retirement explicitly; official MiMo pricing page for the V2.6 rates) |
| **Impact** | **HIGH** — the retired-alias routing is a latent correctness bug on the highest-frequency code path (every simple task), and the MiMo cache-read economics are 121× better than plain input, which the repo's `60-caching.sh` currently cannot exploit because it doesn't know about cache-read pricing. |
| **Effort** | **S** |
| **Integration step for THIS repo** | 1) `providers.json:8` → `"model": "mimo-v2.6-pro"`, `"free": false`. 2) Global-replace `deepseek-v4-flash` → `deepseek-flash` in `routing.json` and `scripts/ai-router.json`, and add `"cache_read_per_1k": 0.000022` (flash) / `0.0000036` (mimo) as first-class cost fields so the router can score cache hits. 3) Add `tests/unit/test_routing_ssot.sh` asserting no model string in `routing.json` appears in a denylist of retired aliases. |

---

### 9. Exploit DeepSeek off-peak pricing (50% discount) and delete the false "free tier" claim

| | |
|---|---|
| **What** | DeepSeek publishes a **time-of-day tariff**: *"Off-peak rates are half of the peak rates. Peak hours are 01:00–04:00 and 06:00–10:00 UTC, Monday through Friday, excluding Chinese public holidays. All other hours are off-peak, including weekends and Chinese public holidays in full."* For `deepseek-v4-pro` that means **$0.66 → $1.32/M input (cache miss)** and **$1.98 → $3.96/M output**. The repo runs a 48-step orchestrator and **137 test files**, and its Renovate schedule is already deliberately set to `"before 6am on Monday"` — i.e. it is *already* optimizing for this window on the dependency side and not on the model side. Separately, `routing.json:58` justifies DeepSeek V4 Pro as *"best price/performance for coding, 1M context, **free tier**"* — it is **not free**; the cheapest realistic figure is $0.66/M input / $1.98/M output off-peak. A cost model that believes it is free will never make a routing decision. |
| **Source** | https://api-docs.deepseek.com/quick_start/pricing (official, table + footnote 2); `src/data/routing.json:58` (file read) |
| **Confidence** | **HIGH** |
| **Impact** | **HIGH** — a flat 50% cut on the dominant cost line, achievable by scheduling alone, plus removal of a factually wrong claim that is currently embedded in the routing rationale. |
| **Effort** | **S** |
| **Integration step for THIS repo** | 1) Fix the `"free tier"` string in `routing.json:58`. 2) Add an off-peak/peak-aware price table (two cost columns per complexity rule) and have `36-model-router.sh` pick the tier from `date -u +%H%M`. 3) Set `.github/workflows/test.yml` cron for the LLM-dependent jobs into the off-peak window (already inside Renovate's Monday 06:00 MSK slot = 03:00 UTC, which is *peak* — shift it). 4) Surface the realized split in `scripts/oc-metrics.py` so the saving is measurable, not assumed. |

---

### 10. Instrument the harness with OpenTelemetry GenAI semantic conventions

| | |
|---|---|
| **What** | The OTel **GenAI semantic conventions** are the vendor-neutral standard for recording LLM/agent operations — adopted by Google Cloud, AWS, Azure, Datadog (Agent Observability supports it at collector **v1.37+**), Dynatrace and others — and explicitly cover agent orchestration, MCP tool calling, content capture, and token/cost attributes. They live in a dedicated repo (`open-telemetry/semantic-conventions-genai`). This repo's observability modules do none of this: `grep -n "opentelemetry\|otel\|semconv\|gen_ai"` across `77-observability.sh`, `34-observability.sh` and `00r-apm-full.sh` returns **zero matches**. `77-observability.sh` tracks exactly seven hand-rolled counters (`skills_installed`, `skills_executed`, `agents_registered`, `workflows_run`, `tasks_completed`, `errors_count`, `avg_response_time`) — none of which carry model, token, cache-hit or cost dimensions. The repo already has Grafana + Prometheus (`src/lib/34-observability.sh`, `src/systemd/opencode-metrics.service` on :9464, `src/grafana/`), so the ingestion path exists; the *schema* is the gap. |
| **Source** | `grep` over the three modules (no matches); https://opentelemetry.io/blog/2026/genai-observability/ ; https://github.com/open-telemetry/semantic-conventions-genai ; https://www.datadoghq.com/blog/llm-otel-semantic-convention/ |
| **Confidence** | **HIGH** (repo grep is exhaustive over all three observability modules; OTel docs official) |
| **Impact** | **HIGH** — turns "tasks_completed: 412" into "tokens_in / tokens_out / cache_read / cost_usd by model and by task class", which is the input required for items 9 and 11 to be measurable rather than theoretical. |
| **Effort** | **M** |
| **Integration step for THIS repo** | 1) Emit OTel GenAI spans from the single choke point where the repo already proxies model calls — `scripts/embed-proxy.py` / `src/lib/36-model-router.sh` — with `gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens`, and `gen_ai.usage.cache_read_tokens`. 2) Export via OTLP to the existing :9464 Prometheus path. 3) Add two Grafana panels under `src/grafana/`: cache-hit ratio and cost-per-completed-task. 4) Keep the existing seven counters — emit them as OTel attributes rather than replacing the module. |

---

### 11. Let `mise` own the toolchain versions instead of six independent hardcoded modules

| | |
|---|---|
| **What** | The repo installs **six language toolchains through six separate modules with hardcoded versions**: `05-java.sh` (Java 25), `06-node.sh` (Node 24), `07-python.sh` (Python 3.14.6 + uv), `08-go.sh` (Go 1.26.5), `09-rust.sh` (Rust 1.97.1), `10-dotnet.sh` (.NET 10.0.302) — each with its own install path, retry and verification logic. Meanwhile `src/lib/29-mise.sh` **already installs mise** (verified via `_download_verify "https://mise.run"`) but is *not* in the orchestrator's `_run_step` list (`setup.sh:889-924` contains no `29-mise.sh`), and its own header describes it as *"optional alternative to per-language managers"*. So mise is installed but governs nothing. The 2026 consensus pattern is a single committed `mise.toml` as the version SSOT, with mise also absorbing direnv's role (mise manages env vars per project). This directly serves the brief's "auto-update without breaking working setups": bumping six hardcoded version strings across six modules by hand is exactly what breaks machines. |
| **Source** | `setup.sh:889-924` (no `29-mise.sh` entry), `src/lib/29-mise.sh:2-3,9-28` (file read); https://mise.jdx.dev/dev-tools/ ; https://crates.io/crates/mise/2026.3.9 ; https://www.kunalganglani.com/blog/reproducible-terminal-dev-environment |
| **Confidence** | **HIGH** (absence of the `_run_step` line verified by grep) |
| **Impact** | **MEDIUM-HIGH** — collapses ~6 update surfaces into 1 committed file, and gives per-project reproducibility for the *consumer* projects this bootstrap creates. |
| **Effort** | **M** (largest single item on this list; do it last of the S/M items). |
| **Integration step for THIS repo** | 1) Generate a committed `.mise.toml` from `SCRIPT_VERSION` as the single version SSOT. 2) Add `_run_step step_mise "$SCRIPT_DIR/src/lib/29-mise.sh"` to `setup.sh` next to the other toolchain steps. 3) Convert `05`–`10` to *verify* what mise installed rather than fetch it independently — keep the existing per-module code as a fallback path for air-gapped installs, gated on `command -v mise` failing. 4) Commit `.mise.toml` into project templates emitted by `17-project.sh`, so downstream projects inherit the pinning. 5) Extend `scripts/generate-sbom.sh` to record the mise-resolved tool versions. |

---

### 12. Wire SBOM + provenance attestation into the release workflow

| | |
|---|---|
| **What** | `scripts/generate-sbom.sh` exists and does real work (prefers `syft dir:. --output spdx-json=`, falls back to a hand-rolled SPDX-2.3 document with `SPDXID`, `dataLicense: CC0-1.0`, and a `downloadLocation` pointing at the git tag tarball). But **`grep -rn "generate-sbom\|syft\|sbom" .github/workflows/` returns zero matches** — the generator is never invoked by CI, and no SBOM is ever published or attested. Likewise `grep -rn "sign-release\|cosign\|attest" .github/workflows/` returns zero matches, so `scripts/sign-release.sh` is also orphaned from CI. The repo already has `scorecard.yml`, `security.yml` (Trivy), and `.pre-commit-config.yaml`, so the supply-chain posture is otherwise strong — the gap is specifically that the SBOM is generated but never *bound* to a release. GitHub Artifact Attestations makes this keyless (no long-lived secrets) and covers exactly this use case. |
| **Source** | `scripts/generate-sbom.sh:1-40` (file read); `grep` over `.github/workflows/` (no matches); https://docs.github.com/en/actions/concepts/security/artifact-attestations |
| **Confidence** | **HIGH** |
| **Impact** | **HIGH** — turns an existing, unreferenced asset into a published provenance guarantee; also lets downstream `dev bundle` / air-gap consumers verify what they installed. |
| **Effort** | **S** |
| **Integration step for THIS repo** | 1) Add a `sbom` job to `.github/workflows/release.yml` that runs `bash scripts/generate-sbom.sh "$VERSION" sbom.spdx.json` and uploads it as a release asset. 2) Add `actions/attest-build-provenance` with `subject-path: dist/opencode-gui` so the one compiled artifact gets keyless provenance. 3) Add `permissions: contents: read` and `id-token: write`, `attestations: write` (the repo's mandatory-goal-1 code-scanning gate means new workflows must declare permissions explicitly). 4) Add a release checklist assertion in `scripts/post-release.sh` that both assets exist.

---

### 13. Delete the stub `.github/dependabot.yml` — it is a security control that silently does nothing

| | |
|---|---|
| **What** | `.github/dependabot.yml` contains `package-ecosystem: ""` with `directory: "/"` and a weekly schedule, under a template comment block. An **empty ecosystem string with no other entries in `updates:`** means Dependabot is configured to update nothing. The file exists, looks official, and is easy to mistake for active coverage in a security review — while providing exactly zero coverage. Meanwhile `renovate.json` is genuinely configured (`config:best-practices` + `:dependencyDashboard` + `:automergeMinor` + `:automergePatch` + `:enableVulnerabilityAlerts` + `:enableGithubRateLimiting`, grouped by npm / GitHub Actions / Docker / Python / Go / Rust, scheduled `before 6am on Monday`, `prConcurrentLimit: 5`, `prHourlyLimit: 2`) and *is* the real dependency-update mechanism. |
| **Source** | `.github/dependabot.yml` (file read, verbatim); `renovate.json` (file read); https://docs.github.com/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file |
| **Confidence** | **HIGH** |
| **Impact** | **MEDIUM** — no direct runtime impact; removes a misleading artifact and prevents a future reviewer from assuming Dependabot is covering something it isn't. (Note: the *real* coverage gap is item 1 — Renovate cannot see the 40+ `@latest` installs embedded in bash, which is where the actual exposure is.) |
| **Effort** | **S** |
| **Integration step for THIS repo** | Delete `.github/dependabot.yml`. Add a line to `CONTRIBUTING.md` stating that Renovate is the single dependency-update authority, and — critically — extend `renovate.json` with a `customManagers` regex manager that matches `npm install -g ([a-z0-9@/._-]+)@latest` in `src/lib/*.sh` so the bash-embedded installs (item 1) become visible to Renovate as upgradeable dependencies.

---

### 14. Add a real agent-evaluation gate (promptfoo) over the existing `eval-scenarios.json`

| | |
|---|---|
| **What** | The repo has an eval *schema* but no eval *runner*. `src/data/eval-scenarios.json` defines weighted metric sets (`completion_rate` 25, `quality_score` 25, `docs_score` 20, `test_score` 15, `security_score` 15) for scenarios `default`, `code-review`, and more — but `grep -rln "eval-scenarios"` returns exactly **one** consumer: `src/lib/65-skill-eval.sh`, which is a skill-scoring module, not a CI gate. Meanwhile `tests/run_tests.sh` covers syntax + 137 bash/python test files, and **nothing** measures whether the *agent* still behaves. promptfoo ships explicit, documented support for evaluating **OpenCode** (alongside Codex, Claude, Open Interpreter) with sandboxing, tracing and assertions — it is the shortest path from "schema exists" to "regression fails the build". |
| **Source** | `src/data/eval-scenarios.json` (file read); `grep -rln "eval-scenarios"` → `src/lib/65-skill-eval.sh` only; https://www.promptfoo.dev/docs/guides/evaluate-coding-agents/ ; https://github.com/promptfoo/promptfoo |
| **Confidence** | **HIGH** for the repo-state claim (exhaustive grep); **HIGH** for promptfoo's OpenCode support (official docs page). |
| **Impact** | **MEDIUM-HIGH** — this is the gate that would have caught items 2–5 (a phantom plugin, a deprecated server, a split-brain package name) automatically rather than by manual registry audit. |
| **Effort** | **M** |
| **Integration step for THIS repo** | 1) Add `promptfoo` as a devDependency (pin exact, per item 1). 2) Write `tests/eval/agent.eval.config.yaml` mapping each `eval-scenarios.json` scenario to promptfoo assertions; emit a machine-readable result. 3) Add a `tests/eval/` job to `.github/workflows/test.yml` that is `continue-on-error: false` but **nightly/scheduled**, so a flaky model does not block every PR. 4) Add a `dev eval` subcommand to `dev.sh` wired to `src/data/eval-scenarios.json`. 5) Write results into the OTel span from item 10 so eval scores correlate with cost.

---

### 15. Stop Renovate automerging the release toolchain

| | |
|---|---|
| **What** | `renovate.json` applies `:automergeMinor` and `:automergePatch` **globally**, then layers `automergeMinor/automergePatch: true` onto the npm group on top. `package.json`'s `devDependencies` use caret ranges on the software that **publishes this project's releases**: `semantic-release ^25.0.9`, `@semantic-release/commit-analyzer ^13.0.1`, `@semantic-release/exec ^7.1.0`, `@semantic-release/git ^11.0.1`, `@semantic-release/github ^12.0.9`, `@semantic-release/release-notes-generator ^14.1.1`, plus `@ai-hero/sandcastle ^0.12.0`. An automerged minor bump inside the `semantic-release` 25.x line reaches the release pipeline without a human reading it. `renovate.json`'s only brake is `"matchUpdateTypes": ["major"] → automerge: false`, which does **not** protect against minor bumps. By contrast the *runtime* dependency is correctly pinned exactly (`"@opencode-ai/plugin": "1.19.0"`) — the asymmetry is the defect. |
| **Source** | `renovate.json` (file read), `package.json` (file read); https://docs.renovatebot.com/configuration-options/ |
| **Confidence** | **HIGH** |
| **Impact** | **MEDIUM** — a broken automerge can fail `release.yml` and block the project's own versioning, and the mandatory commit-checklist gates in `AGENTS.md` make a failed release pipeline expensive. |
| **Effort** | **S** |
| **Integration step for THIS repo** | Add a package rule ahead of the existing ones: `{"matchPackageNames": ["semantic-release", "@semantic-release/*", "@ai-hero/sandcastle"], "automerge": false, "matchUpdateTypes": ["minor","patch"], "labels": ["release-toolchain"]}` so these are proposed but never auto-merged. Additionally pin all `devDependencies` to exact versions for consistency with the existing exact pin on `@opencode-ai/plugin`.

---

## Summary: what to do first

**Do in this sprint (S effort, HIGH impact):** items **1, 2, 3, 4, 5, 8, 12, 13, 15**. These are all file-level edits in `src/lib/*.sh`, `opencode.json`, `package.json` and `renovate.json`, verifiable by the existing test suite, and together they close every confirmed live defect found in this research.

**Schedule next (M effort):** items **6, 9, 10, 14**, then **11** (largest, touches six modules).

**Deliberately not recommended yet:** wholesale adoption of OpenCode V2 (npm `latest` is still V1 `1.19.2`; zero `2.x` versions are published on npm), and `mimo-v2.6-pro` as the *default* rather than the *complex-tier* model (it is metered at $0.435/$0.87 per M, not free — item 8 corrects the record).

---

## Verification notes

- npm metadata in this document was read from the public registry API (`https://registry.npmjs.org/<urlencoded-pkg>`), reading `dist-tags.latest`, `versions[latest].deprecated`, and `time.modified`. Each figure is reproducible with a single `curl`.
- The OpenCode V1-vs-V2 claim was tested by enumerating all **12,249** versions of `opencode-ai` and filtering for a `2.` prefix → **0 matches**.
- Repository-state claims (counts of `@latest`, presence/absence of `_run_step 29-mise`, absence of `otel|semconv|gen_ai`, absence of `sbom`/`cosign` in workflows, `eval-scenarios` having exactly one consumer) were produced by exhaustive `grep` over the stated paths, not by sampling.
- **NOT FOUND** items, explicitly: (a) an npm-published OpenCode V2 stable line — no `2.x` version exists on npm under any tag; (b) an official or vendor-maintained replacement npm package for `@modelcontextprotocol/server-github`, `server-redis`, or `server-postgres` — only community packages exist (`postgres-mcp@1.0.4` was last published **2025-04-20**, i.e. also stale); (c) any npm dist-tag on `opencode-goal-mode`; (d) `mcp-server-gitlab` is a **zero-version placeholder** on npm despite being referenced at `00-core.sh:273`.