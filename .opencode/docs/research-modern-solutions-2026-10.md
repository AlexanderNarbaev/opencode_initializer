# Modern Solutions — Adoption List (October 2026)

> Research subagent, 2026-10-16. All claims carry a source and a confidence level
> (HIGH = official docs/registry, MEDIUM = GitHub, LOW = blog). "NOT FOUND" where unverifiable.
> Method caveat: web search was unavailable in-lane; findings come from direct fetches of
> primary-source URLs, which raises per-claim confidence but skews the list toward
> verification of reachable sources rather than exhaustive discovery.

## Premises corrected during research

| Claim in the brief | Verdict |
|---|---|
| "Zero V2 plugin releases exist" | **False.** V2 plugins ship against a *different package*: `@opencode/plugin` 2.0.30 vs `@opencode-ai/plugin` 1.19.2. `opencode-dcp` 2.x, `opencode-supermemory` 2.x, `opencode-token-tracker` 2.0.0 are live V2 plugins. |
| "`opencode-dcp` is V2-only, so pruning is unavailable on V1" | **False.** The V1-compatible build is **`@tarquinen/opencode-dcp@3.2.0`** (published 2026-09-20, peer `@opencode-ai/plugin >=1.18.29`). The repo removed pruning over a package-name collision. (AGPL: runtime use fine, vendoring not.) |
| "V1 1.19.0 is the current release" | Superseded: V1 `latest` is **1.19.2** (2026-10-16), still shipping. `opencode-ai` has **0 versions matching `2.*`** across 12 249 published versions — V2 exists only under `beta`/`next`/`dev` tags. |
| Dual `server()` + `setup()` export is a community convention | **NOT FOUND.** No documented dual-export convention in the V1 or V2 plugin docs; no package observed using it. Documented only as an option — so do not plan on it. |

## TOP-5 QUICK WINS

| # | Action | Why | Status |
|---|---|---|---|
| 1 | **Pin all plugins + MCP servers** | every entry installed `@latest`; four config entries re-resolved on *every* launch → silent overnight breakage. `package.json` already pinned exactly; the pattern existed but was never applied to `opencode.json`. | **applied** (`apply-adoption-quickwins.py`, `apply-audit-fixes.py`) |
| 2 | **Retire 7 npm-deprecated MCP servers** | `@modelcontextprotocol/server-{github,redis,postgres,gitlab,puppeteer,slack,brave-search}` all carry *"Package no longer supported"*; the config shipped `redis` **enabled** on a dead package. | **applied** (github → official `github-mcp-server`; redis/postgres dropped) |
| 3 | **Fix the brave-search split-brain** | shell modules installed the unofficial `brave-search-mcp` (stale since 2026-03-02) while the config used `@brave/brave-search-mcp-server@2.1.4`; health checks the binary the config never invokes | module fix delegated |
| 4 | **Delete duplicate `context7` / `context7-official`** | both resolve to `@upstash/context7-mcp`; a live session showed 4 tool schemas for 2 tools | **applied** |
| 5 | **Remove `opencode-goal-mode`** | npm placeholder, zero published versions, install failure swallowed by `\|\| warn` | **applied** |

## Full adoption list (15)

| # | Item | What | Confidence | Impact | Effort |
|---|---|---|---|---|---|
| 6 | MCP spec 2026-07-28 | `tools/list` now returns `ttlMs` / `cacheScope` explicitly to *"keep upstream prompt caches stable across reconnects"* — pairs directly with `112-cache-manager.sh`; 12-month deprecation window makes it safe to schedule | HIGH | HIGH | M |
| 7 | Model metadata reconcile | `cost_table` drifted three ways: `gpt-5.5` flagged `free: true` while Console lists $5/$30 per 1M; `zai/glm-5-turbo` sits in a family deprecated 2026-05-14; `minimax.small_model` is an empty string | HIGH | HIGH | S |
| 8 | Free-tier retention as a routing key | GLM/DeepSeek free = zero-retention; MiMo/Big Pickle/Exo free **train on your data**; Nemotron free = logged trial endpoints. Must be a routing key given the PII guard and air-gap profile | MED | HIGH | M |
| 9 | `mise.lock` | commit the resolved toolchain so a fresh machine reproduces exactly | HIGH | MED | S |
| 10 | MCP archive cleanup | `modelcontextprotocol/servers` now holds only **7 reference servers**; 13 moved to `servers-archived`. Redis has an official successor (`redis/mcp-redis`); **Postgres and SQLite have none** → remove, don't migrate | HIGH | MED | S |
| 11 | Dependabot real schedule | `.github/dependabot.yml` has `package-ecosystem: ""` — a security control that silently updates nothing | HIGH | HIGH | XS |
| 12 | OpenTelemetry wiring | zero `otel|semconv|gen_ai` matches across all three observability modules | MED | MED | M |
| 13 | SBOM + release signing into CI | `generate-sbom.sh` and `sign-release.sh` are both orphaned (zero workflow matches) | HIGH | MED | S |
| 14 | Plugin compatibility gate | CI check: every configured plugin must resolve an entrypoint and load under the pinned binary | HIGH | HIGH | S |
| 15 | DeepSeek routing correctness | the whole "simple task" tier routes through `deepseek-v4-flash`, a **retired legacy alias**; V4 Pro is **not free** ($0.66/M in, $1.98/M out), but off-peak (01:00–04:00, 06:00–10:00 UTC weekdays) halves cost — a scheduling win the repo isn't using despite Renovate already being scheduled | HIGH | HIGH | S |

## Plugin audit (16 configured, as of 2026-10-16)
5 actively maintained on V1 · 2 V2-only (will not load on V1) · 6 stale ≥ 2 months · 3 abandoned.
Last-publish dates taken from npm for each. Only `opencode-worktree` and `opencode-cache-switch`
had *no resolvable entrypoint* and were removed.

## Two honest negatives
- No vendor-official Postgres or SQLite MCP replacement exists.
- No documented `server()` + `setup()` dual-export convention (see premise table) — item #5's
  config-emitter approach is used instead because it is documented behaviour.

## Sources
`registry.npmjs.org/opencode-ai` (12 249 versions, `latest` 1.19.2) · `registry.npmjs.org/@tarquinen/opencode-dcp` (3.2.0, 2026-09-20) · `registry.npmjs.org/@opencode/plugin` (2.0.30) · `registry.npmjs.org/modelcontextprotocol/servers` (7 servers; 13 archived) · DeepSeek official pricing page · MCP spec changelog 2026-07-28 · npm per-package publish dates.