# [15.0.0](https://github.com/AlexanderNarbaev/opencode_initializer/compare/v14.0.0...v15.0.0) (2026-09-16)

### Features

* **Phase 0:** Skill Management System (modules 62-65)
  - 62-skill-registry.sh: Skill discovery, install, publish
  - 63-skill-manager.sh: Version management, rollback, updates
  - 64-skill-security.sh: Security scanning (6 checks, scoring)
  - 65-skill-eval.sh: Evaluation framework (5 metrics)

* **Phase 0:** Agent Orchestration (modules 66-71)
  - 66-agent-orchestrator.sh: Workflow execution engine
  - 67-agent-pipeline.sh: Pipeline management
  - 68-agent-mesh.sh: Agent networking & service discovery
  - 69-agent-protocol.sh: Communication protocol
  - 70-context-engine.sh: Context management & optimization
  - 71-memory-layer.sh: Memory persistence (WAL, long-term, short-term)

* **Phase 1:** Enterprise Features (modules 72-77)
  - 72-rbac.sh: Role-based access control (5 default roles)
  - 73-governance.sh: Policy enforcement & audit logging
  - 74-compliance.sh: SOC2/ISO27001/GDPR compliance reporting
  - 75-security-posture.sh: Security assessment & vulnerability scan
  - 76-analytics.sh: Event tracking & analytics dashboard
  - 77-observability.sh: Metrics, alerts, health checks

* **Phase 2:** Ecosystem Expansion (modules 78-82)
  - 78-marketplace.sh: Marketplace client (search, install, list)
  - 79-plugin-manager.sh: Plugin lifecycle (enable/disable, config)
  - 80-templates.sh: Agent template management
  - 81-integrations.sh: Integration framework (GitHub, GitLab, Slack)
  - 82-connectors.sh: Service connectors (HTTP, Postgres, Redis)

* **Phase 3:** Agent Harness Advanced (modules 83-90)
  - 83-context-engineering.sh: Context optimization, SCEI pattern
  - 84-learning.sh: Continuous learning from feedback
  - 85-automation.sh: Task automation engine
  - 86-sandbox.sh: Agent isolation (Docker, MicroVM)
  - 87-cicd-integration.sh: CI/CD pipeline integration
  - 88-workflow-engine.sh: Workflow orchestration
  - 89-security-policies.sh: OPA/Rego policy enforcement
  - 90-secrets-manager.sh: Vault/secrets integration

* **Phase 4:** Agent Harness Core (modules 91-100)
  - 91-harness-core.sh: TAO/ReAct orchestration loop
  - 92-harness-tools.sh: Tool registration & execution
  - 93-harness-memory.sh: Memory hierarchy (WAL, files, vectors)
  - 94-harness-context.sh: Context management & compaction
  - 95-harness-prompt.sh: Prompt construction (SCEI pattern)
  - 96-harness-state.sh: State management & checkpoints
  - 97-harness-errors.sh: Error handling (4 types)
  - 98-harness-guardrails.sh: Input/output/tool guardrails
  - 99-harness-verify.sh: Verification loops (tests, lint, types)
  - 100-harness-subagents.sh: Subagent orchestration

* **Phase 5:** PLA & RAG (modules 101-110)
  - 101-pla-orchestrator.sh: Pipeline micro-prompts orchestration
  - 102-pla-extract.sh: Extraction layer
  - 103-pla-analyze.sh: Analysis layer
  - 104-pla-verify.sh: Verification layer
  - 105-pla-synthesize.sh: Synthesis layer
  - 106-pla-coordinate.sh: Coordination layer
  - 107-rag-hybrid.sh: Hybrid search (BM25 + Vector)
  - 108-rag-bm25.sh: BM25 search
  - 109-rag-vector.sh: Vector search
  - 110-rag-fusion.sh: RRF fusion

* **Phase 6:** Production Hardening (modules 111-116)
  - 111-perf-optimizer.sh: Performance benchmarking & optimization
  - 112-cache-manager.sh: Cache management
  - 113-security-hardening.sh: Security hardening checks
  - 114-vulnerability-scan.sh: Vulnerability scanning
  - 115-scalability.sh: Scalability checks & recommendations
  - 116-load-balancer.sh: Load balancer status

### Documentation

* **docs:** Strategic Development Plan 2027
* **docs:** AIPDLC Integration Plan
* **docs:** Deep Integration Plan (50+ sources)
* **docs:** Master Implementation Plan

### Tests

* **tests:** 129 new test assertions (was 337, now 444)
* **tests:** 10 new test files
* **tests:** All tests passing

### Metrics

* **Modules:** 141 (was 86, +55)
* **Tests:** 444 assertions (was 337, +107)
* **Features:** 102 (was 47, +55)

---

# [2.1.0](https://github.com/AlexanderNarbaev/opencode_initializer/compare/v2.0.0...v2.1.0) (2026-09-12)


### Bug Fixes

* **15-security:** restore Trivy timer guard lost during landstrip insert ([e3c2ee9](https://github.com/AlexanderNarbaev/opencode_initializer/commit/e3c2ee9e3fe0c711cf835875d3c02d147a13e6e5))
* 17-project.sh syntax + remove stale audit test ([9ff482c](https://github.com/AlexanderNarbaev/opencode_initializer/commit/9ff482c26c352b8234ecfc5a77a926b470585ee0))
* **18-opencode-json:** register opencode-context + opencode-router in default plugin tier ([fe04857](https://github.com/AlexanderNarbaev/opencode_initializer/commit/fe048571ea7ec8d45cadb4695eb8d4a5d3a4ce4a))
* **51-opencode-desktop:** no-sudo user-space .deb extraction fallback ([42c43e6](https://github.com/AlexanderNarbaev/opencode_initializer/commit/42c43e6471683fea516dc9554463fbebd478faa7))
* **55-context-bundle:** wire module into setup.sh orchestrator ([8eba897](https://github.com/AlexanderNarbaev/opencode_initializer/commit/8eba8975fbe44f831d670f43f210c3d2e35dac54))
* add DRY_RUN guard to 19-finalize.sh (v3.0 hardening) ([6574a4c](https://github.com/AlexanderNarbaev/opencode_initializer/commit/6574a4c5d372ce593f68a631ac27220800478a1b))
* add Node Exporter to docs/index.ru.md (6→7 services, parity with EN) ([0bfcb22](https://github.com/AlexanderNarbaev/opencode_initializer/commit/0bfcb2250633c5f672fc74d3eeb0f033b279a340))
* **ci.sh:** export INTERACTIVE_DO_* variables for sourced modules + simplify context.md ([c808d79](https://github.com/AlexanderNarbaev/opencode_initializer/commit/c808d79df1bf37ea413af8ba15727fb095f71d3f))
* correct hardcoded test paths for CI portability ([321525a](https://github.com/AlexanderNarbaev/opencode_initializer/commit/321525a562efe3bfd67b2b0ff5982b9b45ab65de))
* direct API kimi.sh workaround + clean moonshotai config ([e2cbf35](https://github.com/AlexanderNarbaev/opencode_initializer/commit/e2cbf35b6bc8fde54c7e92b4cf836a6ce6af80f3))
* **docs:** all 14 mkdocs link warnings resolved ([2c9b45d](https://github.com/AlexanderNarbaev/opencode_initializer/commit/2c9b45d4d21356e9113cee4e39ad2f9440fa66a9))
* **gates:** assert providers/lsp claims in doc-counts gate ([e684622](https://github.com/AlexanderNarbaev/opencode_initializer/commit/e684622d77b24dd0bab3d48e176f97492fc6d4d5))
* GUI version bump v3.2.0 + docs reference sync ([49ef8b7](https://github.com/AlexanderNarbaev/opencode_initializer/commit/49ef8b7f7462094b698d4088b9d2c5e63a559bc7))
* **install:** heal post-install health failures exposed by full run ([d8cbdef](https://github.com/AlexanderNarbaev/opencode_initializer/commit/d8cbdef4c70ef115a398c3332db9c88a50c28e26))
* integration tests — short flags patterns match setup.sh format ([253bcf4](https://github.com/AlexanderNarbaev/opencode_initializer/commit/253bcf4b29695d7a1f03357ba6d4d4993f4aec48))
* **kimi-proxy:** proper HTTP/1.1 chunked transfer encoding for AI SDK ([f34b572](https://github.com/AlexanderNarbaev/opencode_initializer/commit/f34b5724de666df084606692b65ced3bb5d1b1ed))
* **kimi-proxy:** remove Transfer-Encoding: chunked on streaming responses ([7684c48](https://github.com/AlexanderNarbaev/opencode_initializer/commit/7684c4833cbd4546eed8547f96a9c32ca0de2753))
* **kimi-proxy:** streaming now works (was missing stream:true in Anthropic body) ([7ac38e4](https://github.com/AlexanderNarbaev/opencode_initializer/commit/7ac38e470036659412c57b41a54b721dc4e1b02e))
* LOG_FILE→SETUP_LOG unbound var + dryrun_dns dynamic line detection + pii_guard test ([de51d68](https://github.com/AlexanderNarbaev/opencode_initializer/commit/de51d68d70a5958a16ff932e331db1a357dd67a8))
* make opencode_desktop test more robust for CI ([60afc11](https://github.com/AlexanderNarbaev/opencode_initializer/commit/60afc11fc57a7eefb9d6efb97b70cf923ed6e6a0))
* metrics exporter always-on, dev.sh fallback paths, %h in systemd, +x restore ([4c0db47](https://github.com/AlexanderNarbaev/opencode_initializer/commit/4c0db479c0702ba952a6a667d92e9e10d9542e44))
* MiniMax base_url api.minimax.chat -> api.minimax.io (verified working) ([55836e4](https://github.com/AlexanderNarbaev/opencode_initializer/commit/55836e4319ef2f75ab1e51d2a76f0468c53c1d54))
* Moonshot base_url api.moonshot.cn -> api.moonshot.ai (platform.kimi.ai) ([ba53f8c](https://github.com/AlexanderNarbaev/opencode_initializer/commit/ba53f8cb2580240827e3f237b938932444242dd6))
* **orchestrator:** wire 60-caching and grace-semantics, fix step accounting ([ce2f8bb](https://github.com/AlexanderNarbaev/opencode_initializer/commit/ce2f8bbc863f11541ec6558095b0124311a809f7))
* **P0:** sudo hang fix + docs sync + 47-lynis + 48-auditd + comparison.md ([44ad1e2](https://github.com/AlexanderNarbaev/opencode_initializer/commit/44ad1e26f7f721dfeb798dbc18584db2b84e9dab))
* provider-check — HTTP status-based verification, 402=PAYMENT REQUIRED ([91cf5d7](https://github.com/AlexanderNarbaev/opencode_initializer/commit/91cf5d77fe069013b05d752cfd3fed17613b6ec6))
* provider-check — shorter timeouts, no hang on dead servers ([839e917](https://github.com/AlexanderNarbaev/opencode_initializer/commit/839e917f91722a06d31363d951357e83277877b7))
* remaining CI test failures (cockpit build + XDG config path) ([e6dc478](https://github.com/AlexanderNarbaev/opencode_initializer/commit/e6dc4780342bd1d1c2631145c70765ecdc57e7dc))
* remove invalid opencode.json keys, fix WAL resume, add Grafana provisioning, fix Cockpit WAL path, fix SPA isolated toggle ([50985a9](https://github.com/AlexanderNarbaev/opencode_initializer/commit/50985a9a5f14b0a9cb109a66e8264485c378743a))
* remove spurious fi in 17-project.sh:769 ([353e0ae](https://github.com/AlexanderNarbaev/opencode_initializer/commit/353e0aeb74d5f784b5e7d40d5d2fd0434e19e988))
* restore README.md + add framework reference (was corrupted by sed) ([44ea59f](https://github.com/AlexanderNarbaev/opencode_initializer/commit/44ea59f8f5f9523bc8ec1ea0060cf20cb363feb9))
* **security:** bump golang.org/x/text v0.3.8->v0.39.0 (CVE-2026-56852) ([cc5c7f6](https://github.com/AlexanderNarbaev/opencode_initializer/commit/cc5c7f60de3cc8884114a1c9431d1a15402ca9f3))
* test_download_verify.sh — robust wc -l fallback and arithmetic ([c3a83f3](https://github.com/AlexanderNarbaev/opencode_initializer/commit/c3a83f38558a3fe3732a66b731dbc951f196ac91))
* **test:** critical_path accepts >=5 mode scripts (v3.1.1 new.sh) ([c708c7a](https://github.com/AlexanderNarbaev/opencode_initializer/commit/c708c7a6b81d446fac711cef8c81951945b2d85f))
* **tests:** hermetic context-bundle assertions — no machine-state deps ([8c6ff95](https://github.com/AlexanderNarbaev/opencode_initializer/commit/8c6ff952259b4dd20ff50c090c1c55fe8d23d524))
* update E2E test assertions — version pattern, line count 500+, module ref count ([f8b77d6](https://github.com/AlexanderNarbaev/opencode_initializer/commit/f8b77d689649f7a0ecd1b1920432ca036a4c20e8))
* update setup.sh line count assertion (615→651, v3.0.0 growth) ([54d3f87](https://github.com/AlexanderNarbaev/opencode_initializer/commit/54d3f877e7baedce4ffe2e48ba887ed1b86f0c37))
* **v2.0.3:** add shellcheck SC1090 disables for sourced config files in dev.sh ([708703a](https://github.com/AlexanderNarbaev/opencode_initializer/commit/708703ab93a3e7f9ea754aebfa02d5f3271bb63e))
* **v2.0.3:** export all provider API keys from setup.sh args ([379af07](https://github.com/AlexanderNarbaev/opencode_initializer/commit/379af075d11a059e7ef54247eee5c4af95bb1c77))
* **v2.0.3:** export interactive mode gates for sourced modules ([ff47cc5](https://github.com/AlexanderNarbaev/opencode_initializer/commit/ff47cc5f4fca2830aaa011009bf2924412cb199d))
* **v2.0.3:** export IS_WSL in chrome module, remove SC2034 suppress ([4515385](https://github.com/AlexanderNarbaev/opencode_initializer/commit/4515385250e5cd7d540bd61aa4cd1b06cf806601))
* **v2.0.3:** update setup.sh line count test 589→615 ([db476e6](https://github.com/AlexanderNarbaev/opencode_initializer/commit/db476e693aad9f34ce7f1fceff871e9076918caf))
* **v3.1.0:** restore .opencode/skills + architecture.md deleted by rogue background agents ([ee2ab96](https://github.com/AlexanderNarbaev/opencode_initializer/commit/ee2ab96332dce72e6f8f8d58ee6c5185594adf65))
* **v3.1.1:** add --new mode handler + non-interactive DNS guards ([c5d5709](https://github.com/AlexanderNarbaev/opencode_initializer/commit/c5d5709258356aaba47df2f4ba6434078ffb2c70))


### Features

* 38-ide-plugins.sh — Veai, GigaIDE, CPU-only models, air-gapped notes ([2077b06](https://github.com/AlexanderNarbaev/opencode_initializer/commit/2077b06c77e4871ca920dea4e9ecc42f9eaae2a2))
* 55-context-bundle — opencode-context + opencode-router integration ([ba3a7c2](https://github.com/AlexanderNarbaev/opencode_initializer/commit/ba3a7c2f5cc240ef2c458b7b8a5ce936a1d816eb))
* 8 new unit tests + test coverage & docs audit ([9898708](https://github.com/AlexanderNarbaev/opencode_initializer/commit/989870805099c337154307433a9e5a9d51c6e96a))
* add 4 unit tests (pre-session-check, webui-service, shokunin, devbox) + coverage/docs audits ([1a726c8](https://github.com/AlexanderNarbaev/opencode_initializer/commit/1a726c81f3fd2b9b242c27f53a23932ede1201b1))
* add Kimi/K3 Anthropic-compatible proxy + best-practices skills ([b7e016b](https://github.com/AlexanderNarbaev/opencode_initializer/commit/b7e016b56c694357a94f82e6c24ce4ae2821714a))
* add Moonshot kimi-k2.7-code-highspeed variant, verified against official API docs ([7950ebd](https://github.com/AlexanderNarbaev/opencode_initializer/commit/7950ebd94b3c4f76748eb43b0c0a898eb92b5953))
* add upstream tracking (.gitmodules + docs/VERSIONS.md + sync module) ([e29cf1d](https://github.com/AlexanderNarbaev/opencode_initializer/commit/e29cf1dd6cea109d974f4a074533c9b4dc37b580))
* adopt Multi-Agent Continuous Development Framework v3.0 ([2f92b91](https://github.com/AlexanderNarbaev/opencode_initializer/commit/2f92b9157fdf0f9fa997b368cb911f6d90112ef8))
* agent-system.md + system prompts for all 15 agents + deep research report ([fa16e6d](https://github.com/AlexanderNarbaev/opencode_initializer/commit/fa16e6dbc42e4c15682610de8dc4fc1483ce864e))
* auto-start kimi-proxy on boot (systemd + zshrc fallback) ([2422857](https://github.com/AlexanderNarbaev/opencode_initializer/commit/2422857167a75ecb3085db2ea2420c4d7554baae))
* CI add go vet/test + pytest, dynamic MCP verification, fix dead code ([2c8916d](https://github.com/AlexanderNarbaev/opencode_initializer/commit/2c8916da71e1584b13ed5e574c5f69c201864bf7))
* Complete development plan — ADR docs, runbook, integration tests ([7376027](https://github.com/AlexanderNarbaev/opencode_initializer/commit/7376027fd55c98cdd5ffe2509ee86817f831b999))
* context-aware MCP selector, auto-skills, task distributor ([e9ca7d9](https://github.com/AlexanderNarbaev/opencode_initializer/commit/e9ca7d9cc32fec26b8f362a111750320c7a998ba))
* **context:** model-aware context-budget monitoring (dev context) ([1b54bcf](https://github.com/AlexanderNarbaev/opencode_initializer/commit/1b54bcfbaa3b6ae57a4e07730776a9aeb61b09a2))
* cross-project sync utility (scripts/sync-projects.sh) ([0474ca2](https://github.com/AlexanderNarbaev/opencode_initializer/commit/0474ca2c173b4276ec6b8cc08ea3617f96f3eda0))
* **daytona:** module 61 — Daytona environment practice (CLI + declarative config) ([504449b](https://github.com/AlexanderNarbaev/opencode_initializer/commit/504449b58b28165c56b3e97ebd3ad77890aa6728))
* deep system audit - context selector, auto-skills, task distributor ([adb2ddd](https://github.com/AlexanderNarbaev/opencode_initializer/commit/adb2ddd6dda9b760278ff4f3fee073a9b399ff57))
* deepen websearch/model_router tests + translate compliance docs ([ac2d083](https://github.com/AlexanderNarbaev/opencode_initializer/commit/ac2d0839179a30f6eeb8aa91fc281d9f37acf78f))
* DeepSeek Harness + Sandcastle + Matt Pocock skills ([352882a](https://github.com/AlexanderNarbaev/opencode_initializer/commit/352882a2a99cdf9c59e3ab1ddb92cf56b1964696))
* **gates:** self-sync doc-counts + CI portability guards ([1f0717c](https://github.com/AlexanderNarbaev/opencode_initializer/commit/1f0717cdd0a2a1390f887d0fc970f2f50fe6b1df))
* GRACE semantics + har grace subcommand + Polomodov/turboplanner research ([73b9321](https://github.com/AlexanderNarbaev/opencode_initializer/commit/73b9321535ca789d020e67adfea275a9abd6eda4))
* **har:** meta-harness CLI v1.0.1 unifying opencode + dsh + sandcastle ([d65880a](https://github.com/AlexanderNarbaev/opencode_initializer/commit/d65880a560b124f2b28f5d8d2c4d29b55454f793))
* **har:** ralph subcommand v1.1.0 — bounded health-convergence loop ([947985b](https://github.com/AlexanderNarbaev/opencode_initializer/commit/947985babe7e0d9d80542084436eab6a743699e8))
* Hybrid AI Architecture ADR + IDE plugins unit test ([10781ea](https://github.com/AlexanderNarbaev/opencode_initializer/commit/10781eae491c8f488c8c37f773a153de1f12c82f))
* IDE AI plugin auto-install module (38-ide-plugins.sh) ([b7b8874](https://github.com/AlexanderNarbaev/opencode_initializer/commit/b7b8874155082df6e1fde086fc1115d3e1f0bbee))
* kimi-proxy v9 (non-stream upstream, SSE wrap) + clean state ([ba7078a](https://github.com/AlexanderNarbaev/opencode_initializer/commit/ba7078a5ae378a57480e43b24f22fe1bbd237804))
* **kimi-proxy:** v14.2 dynamic payload compression for Moonshot 20KB limit ([ac84ff0](https://github.com/AlexanderNarbaev/opencode_initializer/commit/ac84ff03d9f504464bca90e8d2d3bd360387f1b5))
* link upstream projects via git submodules ([2adc529](https://github.com/AlexanderNarbaev/opencode_initializer/commit/2adc529e7410abbfa8b63d3ea62c09fb834b2dce))
* **linux-platform:** v3.1.1 — Linux platform optimizations from DeepSeek chat history patterns ([5d543d0](https://github.com/AlexanderNarbaev/opencode_initializer/commit/5d543d0f8d617e21409e934945f91f2d2ff92765))
* M7 context/token/cost management stack ([5a31c91](https://github.com/AlexanderNarbaev/opencode_initializer/commit/5a31c918125a14824803d7153778635c33c854c8))
* **macos:** first-class macOS support — launchd services, brew branches, portable coreutils ([1d9fd67](https://github.com/AlexanderNarbaev/opencode_initializer/commit/1d9fd67805c62dd7fd219f3e6c4b013998d6cd9f))
* MCP/LSP profiles + pre-session automation + dev docs generator ([6657316](https://github.com/AlexanderNarbaev/opencode_initializer/commit/665731673f0afe35e16ea9359e6febb948737e35))
* MCP/LSP profiles manifest + M5 automation (pre-session hook, dev docs) ([ab78f40](https://github.com/AlexanderNarbaev/opencode_initializer/commit/ab78f40a0a76290905017a8c686ab8ca7ec6d376))
* Moonshot maximum config — highspeed in coding fallback, endpoint docs ([0b9993d](https://github.com/AlexanderNarbaev/opencode_initializer/commit/0b9993dc92299b9a2fb4185d825fcfb286a202c2))
* observability stack, port management, unified service layer ([1aaac59](https://github.com/AlexanderNarbaev/opencode_initializer/commit/1aaac5911fe1f010424d98f832de435c8a194e47))
* OpenCode Desktop module + tests for DeepSeek Harness & Sandcastle ([c7c8c37](https://github.com/AlexanderNarbaev/opencode_initializer/commit/c7c8c37eba7cfce1665d35b75c2d3d02a5966fe9))
* provider health-check script + .env.example template ([a8b4e7c](https://github.com/AlexanderNarbaev/opencode_initializer/commit/a8b4e7c75a206d19a07c772476511ef623195030))
* **S3:** upstream OpenCode sync — 5→23 providers ([e1403e2](https://github.com/AlexanderNarbaev/opencode_initializer/commit/e1403e209ba17440ff627548fe3b13d9c045361e))
* **skills:** skill-audit tool — actualize skills against real usage ([8c6acab](https://github.com/AlexanderNarbaev/opencode_initializer/commit/8c6acab0c8596a587ad315650daa3f3c8cb919a1))
* test_project.sh (100 assertions) + README.ru.md translation ([31e07e3](https://github.com/AlexanderNarbaev/opencode_initializer/commit/31e07e3ac202000d8a201d80d2134f0eb7b32b5b))
* use opencode-go/kimi-k3 (works) + direct Moonshot API via env ([da3afb7](https://github.com/AlexanderNarbaev/opencode_initializer/commit/da3afb70a45963b588e5150044732875e2754288))
* **v2.0.2:** remove Moonshot/LiteLLM, restore test gates, wire dead modules ([0eff737](https://github.com/AlexanderNarbaev/opencode_initializer/commit/0eff737395ce7e8b39b7f706cb46b8b33847fe36))
* **v3.2:** docs sync + AI Gateway proxy + GUI upgrade + research ([c22dd40](https://github.com/AlexanderNarbaev/opencode_initializer/commit/c22dd409b73a1957701b0a4a861e5d1234fe091d))
* v4.0.0 — APM Integration + Multi-Agent Targets + Parallel Install ([317b16a](https://github.com/AlexanderNarbaev/opencode_initializer/commit/317b16aae7535c5436793127492e6852f2ed7bdd))
* v4.1.0 — GitVerse Mirrors + Auto-Sync + Continuous Updates ([2320c6a](https://github.com/AlexanderNarbaev/opencode_initializer/commit/2320c6afd6adaca02ea70823d981308bbb4c7d70))
* v4.3.0 — Security Scanner + Performance Benchmark + Auto-Sync ([1601d09](https://github.com/AlexanderNarbaev/opencode_initializer/commit/1601d0919372e6111fe706587cb698dd51593f13))
* v4.4.0 — Plugin Discovery + Context Manager + Workflow Automation ([1a0720d](https://github.com/AlexanderNarbaev/opencode_initializer/commit/1a0720dc0433a8b4b9ff83b2a4d3a5ea6552fea2))
* v4.5.0 — Environment Manager + Template Engine ([15295f8](https://github.com/AlexanderNarbaev/opencode_initializer/commit/15295f800a6c59e4ad55a1c74175e4759911ac20))
* v7.0.0 — Full APM + Cloud Sync + GUI Dashboard ([178442b](https://github.com/AlexanderNarbaev/opencode_initializer/commit/178442be3e70aa86c2ac4651b3e76555d3efe5d6))
* v8.0.0 — APM manifest, mise, shell completions, SBOM, cosign ([0a2dfdb](https://github.com/AlexanderNarbaev/opencode_initializer/commit/0a2dfdbe1f88fbd8e0b779d52248ab488f1e1792))
* WAL system + Open-Orchestra + Cockpit actions + Coprocessor skill ([b25d665](https://github.com/AlexanderNarbaev/opencode_initializer/commit/b25d66564b411af14b1a486d08ce05fb7291611e))
* автостарт Grafana/Prometheus, GUI Metrics tab, Cockpit Grafana drill-down, внешняя observability ([5954385](https://github.com/AlexanderNarbaev/opencode_initializer/commit/59543851fb8108565b385845b74c1c2d9521a30e))

# Changelog

## [3.3.0] — 2026-08-24

### Added
- **Daytona environment practice** — `61-daytona.sh`: current Daytona platform CLI (legacy workspace-manager archived June 2026 is never used), declarative environments registry `~/.config/opencode/daytona/environments.json` (managed_by), `daytona-env` wrapper (list/create/status/delete/prune translating registry entries into CLI flags), `dev daytona`, health check, SKIP_DAYTONA opt-out; guides EN+RU
- **Skills audit** — `scripts/skill-audit.sh` + `dev skills`: installed-vs-registered drift (broken/unregistered/stale-config), oversize SKILL.md >400L hints, duplicate detection, optional usage evidence from recent opencode logs (`--since N`), `--json/--strict`; guide EN+RU
- **Context budget** — `scripts/context-budget.py` + `dev context`: per-model context limits consumed from routing.json cost_table SSOT; status/check/models subcommands report session usage vs the session model's maximum with WARN 77% / ACT 90% thresholds; 57-context-guard.json enriched with budget block; guide EN+RU
- **Docs IA gate** — `scripts/check-docs-parity.sh` wired into docs CI: locale-pair completeness, fatal bare-vs-suffixed conflicts; mkdocs nav Operations + Working Documents sections with generated plans/research/superpowers indexes (EN+RU); zero nav orphans

### Changed
- Version canonicalized to 3.3.0 (package.json, SCRIPT_VERSION, README×2, docs/index×2)

## Unreleased

### Added
- `har ralph` — bounded health-convergence loop (initializer/coding-agent pattern, Anthropic-style); unit test

### Changed
- Harness-engineering doctrine added to coprocessor skill; error-handling & token-efficiency conventions in CONTRIBUTING; research synthesis docs/research/2026-08-23-harness-patterns.md — adopted from industry harness literature (Habr / STRATUM / Meta-Harness / Hashimoto)

## [3.2.0] — 2026-08-22

### Context, Token & Cost Management (M7)
- 55-context-bundle.sh: context/token/cost bundle — opencode-context + opencode-router integration (installed via npm, loaded on explicit invocation)
- 56-grace-semantics.sh: GRACE semantic contracts, wired into the orchestrator as `step_grace_semantics`
- 57-context-guard.sh: context guard (compression)
- 58-provider-discovery.sh: provider auto-discovery
- 59-local-memory.sh: local memory layer
- 60-caching.sh: prompt caching stack (renumbered from 56-caching.sh to resolve the duplicate module number)

### Added
- scripts/har: meta-harness CLI v1.0.1 unifying opencode + dsh (DeepSeek Harness) + sandcastle + opencode-* plugins, incl. `har grace` subcommand
- `setup.sh --skip-caching` flag (SKIP_CACHING)
- Full macOS support: `_service_install/_service_start/_service_stop/_service_status` dispatch (systemd user units on Linux, LaunchAgents on macOS) across GUI, metrics, ChromaDB, WebUI, Ollama and DeepSeek Harness modules; `dev gui`/`dev metrics`/`dev isolated status` work on macOS; brew branches for previously apt-only fallbacks (Docker, Chrome, ZSH, Java, Node, Go, .NET, Trivy, Ollama, ...)

### Fixed
- Orchestrator: `step_caching` pointed to removed `56-caching.sh` (failed on every run); `56-grace-semantics.sh` was never sourced or step-executed; `TOTAL_STEPS` corrected 41 → 48
- Idempotency: `_step_done` added to 55-context-bundle, 58-provider-discovery, 60-caching; `_run_step` key unified with `38-ide-plugins.sh` (`step_ide_plugins`)
- opencode.json: stray `opencode-go` key removed — 22 providers, aligned with the `src/data/providers.json` SSOT
- macOS blockers eliminated: portable `_md5`/`_sha256`/`_timeout`/`_sed_i`/`_file_mtime`/`_file_size`/`_readlink_f` wrappers in helpers.sh; GNU-only sed expressions rewritten (00-core, 24-websearch, 34-observability); `${var,,}` replaced (dev.sh, oc-rpc.sh); `grep -oP` removed; OS guards in 47-lynis/48-auditd
- Canonical version aligned: README, CHANGELOG, package.json and `SCRIPT_VERSION` now all read 3.2.0 (git ground truth: latest tag was v2.0.0, 3.x line untagged)

### Docs
- All module/provider/MCP/plugin/LSP/test counts synchronized across README (EN/RU), docs site (EN/RU) and mkdocs.yml (64 modules, 726-line orchestrator, 22 providers, 24 MCPs, 21 plugins, 12 LSPs, 91 test files / 257 checks)
- Legacy `docs/ru/` pages (contradicting numbers, broken links) removed; stale `docs/comparison.md` duplicate removed; `mcpServers` → `mcp` in reference docs

## [3.1.0] — 2026-08-08

### Core Hardening (Wave A)
- WAL race protection: `_wal_locked_append()` — flock-based atomic append in helpers.sh, applied to 37-wal.sh and 44-audit.sh
- Safe-rm guard: `_safe_rm()` — blocks rm -rf on ~/.cache/opencode, HOME, /; logs blocked attempts to WAL
- Unified error strategy: `_trap_cleanup()` — canonical ERR-trap with _CLEANUP_FILES[] support, configurable via _SETUP_ERROR_STRICT
- trap ERR applied to 5 download-heavy modules (05-java, 08-go, 09-rust, 10-dotnet, 16-llm)
- DNS DRY_RUN guard in setup.sh — skips sudo tee in drun-run mode

### macOS bash 3.2 Compatibility (Wave C)
- Eliminated ALL `declare -A` from codebase: MCP_PACKAGES → parallel indexed arrays + `_mcp_lookup()`, SERVICE_PORTS → `_get_service_port()` case-dispatch, PROVIDER_REGISTRY → `_provider_reg_get()`
- Bash version detection: `_check_bash_version()` warns for bash < 4 and suggests brew install
- All 46+ modules pass `bash -n` cleanly

### Tests
- New: test_wal_race.sh (5 assertions), test_safe_rm.sh (8), test_error_strategy.sh (6), test_bash32_compat.sh (55)
- Extended: test_dryrun_dns.sh (+4 tests), test_core.sh (MCP registry migrated)

## [3.0.0] — 2026-08-08

### Breaking Changes
- Air-gap completeness: ISOLATED_CIRCUIT now gates version-check, topgrade, unattended-upgrades
- Model governance: new model-policy.json with allowlist/blocklist per deployment profile
- Audit trail: 7 WAL event types (model_call, tool_call, provider_switch, pii_redacted, ...)

### Added
- 41-constitution.sh: Constitution + spec format generator — `memory/constitution.md` at project init
- 42-hooks.sh: Lifecycle hooks framework — pre-request, post-response, pre-commit, on-error
- 43-governance.sh: Model Governance — `model-policy.json` allowlist/blocklist per deployment profile
- 44-audit.sh: Audit trail — 7 WAL event types, SHA-256 hash-chain, rotation >10MB → gzip+Qdrant
- 45-pii-guard.sh: PII Sanitizer — 9 detectors (email, phone, INN, SNILS, passport, credit card, IP, API key)
- 46-offline-bundle.sh: Air-gap offline bootstrap — `dev bundle create|list|verify`, `setup.sh --airgap`
- scripts/pii-guard.py: PII scan CLI — standalone Python script for file scanning and redaction
- Scheduled Trivy/Qodana security scanning
- 4 deployment profiles (personal/corporate/airgapped/hybrid) with enforced rules
- SBOM generation (CycloneDX)

### Fixed
- Supply-chain: 6 curl|bash → download+verify SHA256
- Dry-run: _set_dns() now respects DRY_RUN flag
- Idempotency: rm -rf ~/.cache/opencode removed from bootstrap
- WAL race condition in parallel module execution
- TOTAL_STEPS unified to 39

### Security
- SOC2 CC5.2/CC7.2/CC8.2 compliance mapping
- ISO27001 A.9.2.1/A.12.4.1/A.14.2.5 compliance mapping
- GDPR Art.32/Art.35 readiness



All notable changes to opencode_initializer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.3] — 2026-08-08

### Fixed
- **Plugins regression on clean install** — 17-project.sh now writes default `~/.config/opencode/plugins.json` with 25 plugins in tiers (5 always / 9 conditional / 11 on-demand) when registry is absent
- **Missing v2.0.2 migration** — new `migrations/20260808-v2.0.2-remove-moonshot.sh`: stops kimi-proxy/litellm systemd services, pipx uninstall, config cleanup, opencode.json regeneration
- **Sudo password CLI flag deprecated** — `-s`/`--sudo-pass` marked deprecated; `SUDO_PASS` env var as preferred path; docs updated (ru+en)
- **macOS grep -P + bash4 support** — all `grep -oP` (PCRE) patterns migrated to `grep -oE` (ERE) with `sed`/`awk` fallbacks across 8 files; macOS requirements documented in README + AGENTS.md
- **Trivy CI exit-code** — `.github/workflows/security.yml`: blocking job with `exit-code: '1'` + non-blocking advisory job with `continue-on-error: true`
- **OPencode_* env naming unified** — canonical `OPENCODE_*` prefix with `OPencode_*` as deprecated backward-compat fallback across 5 modules
- **Uncovered module tests** — 9 new test files: java, chromadb, rag, dotfiles, mise, best-practices, upstream-sync, sync-providers (Python), sync-agents (Python)
- **Health mode coverage** — +2 new checks: model router, embed proxy; total 128+ checks in 12 sections
- **dev doctor** — `cmd_doctor()` wired for pre-session provider & model validation
- **ShellCheck sweep** — 24 SC2034 (unused variables) eliminated; 4 SC1090 (non-constant source) suppressed; `shellcheck -S warning` = 0 across all modules

### Added
- `dev doctor` CLI command for pre-session checks
- macOS documentation: bash>=4 + GNU grep requirements, `declare -A` known limitation


### Security
- Sudo password no longer accepted via CLI flag (prevents `ps`/history leakage)

## [2.0.2] — 2026-08-03

### Removed
- **Moonshot/Kimi provider and kimi-proxy** — dropped along with the LiteLLM local gateway (wave v2.0.2)
  - Deleted modules `25-litellm.sh`, `39-kimi-proxy.sh` and scripts `kimi-anthropic-proxy.py`, `litellm-force-temp.py`, `kimi.sh`
  - Removed Moonshot/LiteLLM from provider registry, opencode.json configs, health checks, and docs
  - Local isolated-circuit backends are now: Ollama (:11434), vLLM (:8000), SGLang (:30000)

### Fixed
- **Test harness gate** — 23 test files defined their own `assert()` and never exited non-zero, so `run_tests.sh` and CI reported PASS despite real failures; all test files now exit non-zero on failure
- 7 previously silent test failures: stale kimi assertions in `test_model_router.sh`, dangling `zai` fallback refs in root `opencode.json` (caught by `test_providers.sh`), stale `/v1/models` literal in `test_isolated.sh`
- Dead modules wired into the orchestrator: `31-cockpit.sh` (Cockpit TUI), `32-isolated.sh` (Isolated Circuit), `33-services.sh` (Service Configuration Layer) were never sourced by `setup.sh`
- Documentation drift: module/provider/test counts in AGENTS.md and README, `docs/VERSIONS.md` endpoints, LiteLLM references across docs (en+ru)

### Changed
- Provider registry: 22 providers (19 cloud + 3 local: Ollama, vLLM, SGLang)
- `dist/` build artifacts now git-ignored

## [2.0.1] — 2026-07-27

### Added
- **kimi-proxy v14.2**: dynamic payload compression for Moonshot API's undocumented ~20KB request body limit
  - Sticky tools (bash/read/write/edit/grep/glob) always included first
  - Progressive trimming: max 10 tools, 15 messages, truncated descriptions
  - IPv4-only upstream workaround, SSE streaming, `reasoning_content` stripping
  - Tunable via `KIMI_PROXY_*` environment variables
  - VPN requirement documented for RU networks

> **Note:** Moonshot/Kimi support (including kimi-proxy) was subsequently removed in v2.0.2.

## [2.0.0] — 2026-07-03

### Added
- `30-infra.sh`: Infrastructure provisioning — PostgreSQL + Qdrant + Redis + Prometheus + Grafana + MemoryLayer via Docker Compose
- `31-cockpit.sh`: Cockpit TUI server management daemon (7-tab TUI + web GUI)
- `32-isolated.sh`: **Isolated Circuit Mode** — air-gapped / offline-first LLM operation
  - Flag: `--isolated` / `--no-isolated` CLI, `ISOLATED_CIRCUIT=true` config, env var
  - Local OpenAI-compatible backends: Ollama (:11434), LiteLLM (:4000), vLLM (:8000), SGLang (:30000)
  - Auto-detection of running backends at `/v1/models`
  - Config persist: `~/.config/opencode-setup/setup.conf`
  - `dev isolated on|off|status` CLI command
  - Cockpit TUI: `[ISOLATED]` indicator in header
- **z.ai (GLM-5.2)** provider — critical for RU/CN markets, OpenAI-compatible API
- **OpenRouter** provider — aggregator access to 100+ models via single API key
- **Alibaba Qwen3.7** provider — native SDK in opencode
- **DeepInfra** provider — fast inference, competitive pricing
- **Model Routing Intelligence** (`36-model-router.sh`) — task-based model selection
  - 8 task profiles: coding, reasoning, fast, agentic, budget, vision, isolated, ru_cn
  - Cost table with per-1M-token prices from models.dev
  - `dev models <task>` CLI command for recommendations
  - `dev models install <model>` for local model download via Ollama
  - `dev models list-local` for installed local models
- **Web GUI** — full management interface (port 4200)
  - 9 sections: Overview, Providers, Model Router, MCP, LSP, Infrastructure, Isolated Circuit, Backup, Logs
  - Real-time status of all providers, MCP/LSP servers, infrastructure services
  - Toggle Isolated Circuit, create backups from browser
- MemoryLayer AI memory: Docker backend + Ollama embed proxy (mxbai-embed-large, 1024-dim) + systemd auto-start
- Embed proxy: `scripts/embed-proxy.py` — bridges Ollama embeddings to MemoryLayer API format
- `opencode-embed-proxy.service`: systemd user service for Ollama embedding proxy
- Observability stack: Prometheus (:9090) + Grafana (:3001) with auto-provisioning
  - Infrastructure overview dashboard (container status, PostgreSQL, Redis, Qdrant, uptime)
  - Agent performance dashboard (token usage, cost by provider, model success rate)
- **Corporate proxy support** — HTTP_PROXY, HTTPS_PROXY, CURL_CA_BUNDLE in _curl()
- **Config backup/restore** — `dev backup create|list|restore`
- **Pre-session check** — all 24 providers, local backends, model recommendations, infra status
- **MCP/LSP post-install verification** — reports installed vs missing counts
- Go apt fallback in `08-go.sh`: if direct download fails, use ppa:longsleep/golang-backports
- Unit tests: `test_infra.sh`, `test_cockpit.sh`, `test_isolated.sh`, `test_providers.sh`, `test_observability.sh`, `test_embed_proxy.sh` (105+ new assertions)
- CI: Python syntax check, Go format check, opencode.json validity check, cross-distro matrix (Fedora, Debian, Ubuntu)
- Critical audit + provider/LLM ecosystem analysis + requirements specification (`docs/research/`)

### Changed
- Module count: 29 → 39
- Module numbering fixed: 22-mise→29-mise, 32-observability→34-observability, 33-gui→35-gui
- `26-providers.sh`: 15→20 cloud + 4 local OpenAI-compatible providers (24 total)
- `18-opencode-json.sh`: `_build_providers()` supports ISOLATED_CIRCUIT mode + z.ai/OpenRouter/Alibaba/DeepInfra
- `00-core.sh`: ISOLATED_CIRCUIT auto-load from config, version v2.0.0
- `setup.sh`: version v2.0.0, 561 lines
- opencode.json: z.ai provider added with fallback chain
- Model IDs verified against models.dev: Grok 4→4.3, Kimi K2→K2.7 Code, Claude→Opus 4.8, GPT-5→5.5, Gemini→3.5 Flash, Qwen3→3.7 Plus
- `pre-session-check.sh`: expanded from 5 to 24 providers + local backends + model recommendations
- `helpers.sh`: corporate proxy support (HTTP_PROXY, HTTPS_PROXY, CURL_CA_BUNDLE)
- `12-mcp-lsp.sh`: post-install MCP/LSP verification
- `34-observability.sh`: Grafana provisioning volumes mounted
- AGENTS.md: full rewrite with all 39 modules, 24 providers, model routing, v2.0.0
- Cockpit: 7-tab TUI (F1 System, F2 Plugins, F3 GPU/Models, F4 Sessions, F5 Tasks, F6 Logs, F7 Infra) + `[ISOLATED]` indicator
- Cockpit: Web GUI with 9 management sections
- GUI: rewritten from stub to full management interface (server.js + index.html)

### Fixed
- MemoryLayer: backend not running — deployed Docker container + Ollama embed proxy pipeline
- `test_infra.sh`: isolated from real config (uses temp dir), +4 new assertions
- `test_core.sh`: version assertion updated for v2.0.0
- `test_helpers.sh`: version assertion updated for v2.0.0
- `test_modules.sh`: line count bounds adjusted for 561-line orchestrator
- Duplicate module numbers resolved (22 and 32)

## [Unreleased]

### Added
- GPU workload benchmarks for backend selection tuning
- Cross-platform CI matrix expansion (macOS, ARM)

## [1.1.0] — 2026-06-26

### Added
- **Hardware auto-detection**: multi-vendor GPU (NVIDIA, AMD ROCm, Intel Arc) + NPU (Ryzen AI, Meteor Lake) + Apple Silicon detection
- **LiteLLM API Gateway**: OpenAI-compatible `/v1` endpoint unifying Ollama, vLLM, SGLang backends with auto-routing and fallback chains
- **SearXNG Web Search**: self-hosted private search engine + sanitizer proxy (strips internal hosts/IP/PII)
- **CI/CD Headless Mode**: `--ci` flag for lightweight OpenCode CLI + essential MCPs (5 steps, no GUI, no Docker, no ZSH)
- `22-webui-service.sh`: Open WebUI systemd user service for auto-start on login
- `23-just.sh`: just task runner with default justfile
- `24-websearch.sh`: SearXNG + sanitizer proxy
- `25-litellm.sh`: LiteLLM OpenAI-compatible local API gateway
- `26-providers.sh`: 15+ LLM provider registry (OpenAI, Anthropic, Google, Mistral, Groq, Together, Cohere, Fireworks, Cerebras, Perplexity) with session switching
- `27-dotfiles.sh`: chezmoi dotfiles manager for team config sharing
- `28-devbox.sh`: Devbox Nix-based isolated dev environments
- `22-mise.sh`: mise-en-place universal tool version manager
- WebUI auto-install via `uv tool install open-webui` (Docker-less alternative)
- Multimodal support: whisper.cpp (speech-to-text), stable-diffusion.cpp (image generation), llava (vision)
- Multiple interaction modes: TUI (terminal UI), JSON output, RPC server, Python SDK
- ONNX Runtime cross-platform model portability
- Env-var substitution for token/credential propagation
- `--mimo-key`, `--moonshot-key`, `--minimax-key` CLI flags
- `--gitlab-token`, `--gitverse-token`, `--google-maps-key` CLI flags
- RAG System module (`21-rag.sh`) as optional component
- Architecture-aware LSP downloads (arm64 + amd64)

### Changed
- Module count: 24 → 33 (21-rag, 22-mise, 22-webui-service, 23-just, 24-websearch, 25-litellm, 26-providers, 27-dotfiles, 28-devbox)
- Step count: 23 → 29 in orchestrator
- `16-llm.sh`: rewritten with multi-vendor GPU/NPU detection and optimal backend selection
- Health checks: 60+ → 65+

### Fixed
- ChromaDB systemd service: proper working directory and restart policy
- Ollama systemd service: WantedBy=default.target for auto-start
- Open WebUI: runs as systemd user service, survives reboots
- Version consistency: all files now v1.1.0
- CI test.yml: fixed paths `lib/` → `src/lib/`, `modes/` → `src/modes/`
- Removed dangling `WALEOF` word in 17-project.sh
- `sudo apt-get` → `_sudo` in 05-java.sh
- `cmd.exe` proxy detection guarded behind WSL check
- `return 1` crash in 15-security.sh replaced with safe `return 0`
- All curl calls: added `--retry 3 --retry-delay 2`
- Secrets: added GITLAB_TOKEN, GITVERSE_TOKEN, GOOGLE_MAPS_KEY
- topgrade systemd service: flexible path detection
- 17-project.sh backup dir `~/agi` → `~/projects`

## [1.0.0] — 2026-06-22

### Added
- Initial public release of OpenCode Initializer
- 8 programming languages (Java 25, Node.js 24, Python 3.14, Go 1.26, Rust 1.96, .NET 10, Kotlin, Zig)
- 21 MCP servers for AI-assisted development
- 15+ OpenCode plugins (token-tracker, dcp, swarm, goal-mode, vibeguard, orchestrator, notify, pty, snip, snippets, envsitter-guard, command-inject, ignore, auto-fallback)
- 13 LSP servers (gopls, rust-analyzer, tsserver, pyright, omnisharp, yaml, marksman, taplo, lua, zls, bash, dockerfile, css/html/json)
- Infrastructure: Docker, ChromaDB + Muninn, GPU/LLM runtimes (Ollama, vLLM, SGLang, Open WebUI)
- ZSH + Oh My Zsh + Powerlevel10k with 18 plugins
- Google Chrome + ChromeDriver (WSL2-aware)
- CLI `dev` tool for post-install management
- Auto-update via systemd weekly timer + topgrade
- Cross-distro support (apt/dnf/pacman/apk/zypper/brew)
- Russian mirrors for network-constrained environments
- Progress tracking with retry logic and exponential backoff
- WSL2 optimization (DNS fix, memory limits, mirrored networking)
- Comprehensive test suite (unit, integration, E2E)
- ShellCheck CI on every push/PR
- Full open source documentation (README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, CHANGELOG)
- GitVerse mirror

[Unreleased]: https://github.com/AlexanderNarbaev/opencode_initializer/compare/v2.0.0...main
[2.0.0]: https://github.com/AlexanderNarbaev/opencode_initializer/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/AlexanderNarbaev/opencode_initializer/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/AlexanderNarbaev/opencode_initializer/releases/tag/v1.0.0
