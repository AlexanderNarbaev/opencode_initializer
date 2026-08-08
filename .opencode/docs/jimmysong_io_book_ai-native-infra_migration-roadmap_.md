# Migration Roadmap: From Cloud Native to AI Native | Jimmy …

> Source: https://jimmysong.io/book/ai-native-infra/migration-roadmap/
> Cached: 2026-08-08T11:05:07.010Z

---

**
Home
**
Books
**
AI Native Infra
**
Migration Roadmap# Migration Roadmap: From Cloud Native to AI Native

**
Published
****
Table of content
**
**
Search in this book...
- The North Star: From Platform Delivery to Governance Loops
- Migration Prerequisites: Build Three Foundations First, Then Scale Applications
- Migration Path Selection: Layered by Organizational Risk and Technical Debt
- 90-Day Actionable Plan: AI Landing Zone + Minimum Governance Loop
- Operating Model: The &ldquo;Contract&rdquo; Between Platform Teams and Workload Teams
- Migration Anti-Patterns
- Summary
- References

> Migration is not &ldquo;rebuilding the platform,&rdquo; but using governance loops and organizational contracts to transform uncertainty into controllable engineering capabilities.

The previous five chapters have established: **AI-native infrastructure is Uncertainty-by-Default**. Therefore, the architectural starting point must be **compute governance loops**, not &ldquo;connect a model and call migration complete.&rdquo; Otherwise, systems easily spiral out of control in three dimensions: **cost** (runaway cost), **risk** (unauthorized actions/side effects), and **tail performance** (P95/P99 and queue tail behavior).

This explains why the FinOps Foundation emphasizes: running AI/ML on Kubernetes, &ldquo;elasticity&rdquo; easily evolves into uncontrollable cost overflow. **FinOps must be incorporated into architecture and organization upfront as a shared operating model, not as an after-the-fact reconciliation exercise.**

This article presents an **actionable migration roadmap**, covering both technical evolution paths and organizational implementation approaches. You don&rsquo;t need to &ldquo;rebuild an AI platform&rdquo; all at once, but you must establish working **governance loops** at each stage: budget/admission, metering/attribution, sharing/isolation, topology/networking, and context assetization.

## The North Star: From Platform Delivery to Governance Loops

The diagram below shows the migration path from bypass pilot to AI-first refactoring.

Figure 1: AI-native migration roadmapCloud-native migration typically centers on &ldquo;capability delivery&rdquo;: CI/CD, self-service platforms, service governance, and auto-scaling. Its default assumptions: systems are deterministic, costs grow linearly with requests, and scaling doesn&rsquo;t significantly alter system boundaries.

**AI-native migration must center on &ldquo;governance loops&rdquo;**, focusing on cost, risk, tail performance, and state assets. Its default assumptions are precisely the opposite: systems are inherently uncertain, and the &ldquo;actions and consequences&rdquo; of inference/agents drive costs and risks into nonlinear territory.

North Star Definition**AI-Native Migration = Establish an AI Landing Zone + Compute Governance Loop + Context Tier, and ensure all agents/APIs/runtimes operate within this loop.**Elevating &ldquo;Landing Zone&rdquo; to North Star level here isn&rsquo;t chasing trends—it&rsquo;s because it naturally serves an organizational-level task: **delineating responsibility boundaries between platform teams and workload teams**. Major cloud providers universally use Landing Zones to host &ldquo;shared governance baselines&rdquo; (networking, identity, policies, auditing, quota/budget), while business teams iteratively build applications within controlled boundaries. For AI, this boundary is the carrier of the governance loop.

## Migration Prerequisites: Build Three Foundations First, Then Scale Applications

You can run PoCs and build applications in parallel, but if these three foundations are missing, any &ldquo;application explosion&rdquo; can easily transform into platform firefighting and financial disputes.

**Foundation A: FinOps / Quotas as Control Plane (Finance and Quotas as Control Plane)**

The first migration step is not &ldquo;launch the first agent,&rdquo; but incorporating **budgets, alerts, showback/chargeback, and quotas** into the infrastructure control plane:

- Budgets and alerts are not just financial reports, but triggers for runtime policies (rate limiting, degradation, queuing, preemption).
- showback/chargeback is not just accounting, but binding &ldquo;cost consequences&rdquo; to organizational decisions and product boundaries.
- Quotas are not static limits, but evolvable governance instruments (dynamic budgets and priorities by tenant/team/use-case).

Migration ThresholdIf you cannot attribute the primary consumption of each agent/job to team/project/model/use-case (at minimum covering tokens, GPU time, KV footprint, key network/storage), you haven&rsquo;t reached the &ldquo;scale&rdquo; starting line. Piloting is acceptable, but expansion is not advisable.**Foundation B: Resource Governance (GPU Sharing/Isolation and Orchestration Capabilities)**

The &ldquo;elasticity&rdquo; of AI-native infrastructure is constrained by how scarce compute is governed. Treating GPUs as ordinary resources typically results in **low utilization** and **uncontrolled contention**. Therefore, you need viable combinations of sharing/isolation and orchestration capabilities:

- **Sharing/partitioning**: MIG/MPS/vGPU paths transform &ldquo;exclusive&rdquo; into &ldquo;pooled.&rdquo;
- **Scheduling upgrades**: Introduce explicit modeling of topology, queues, fairness, preemption, and cost tiers.
- **Orchestration loop**: Solidify isolation, preemption, and priority policies into executable rules.

The key is not which partitioning technology you choose, but whether you can elevate GPUs from &ldquo;machine assets&rdquo; to **first-class governance resources** and incorporate them into budget and admission systems.

**Foundation C: Fabric as a First-Class Constraint (Network/Interconnect as First-Class Constraint)**

Training and high-throughput inference are extremely sensitive to congestion, packet loss, and tail latency. Ignoring networking and topology leads to &ldquo;seemingly sporadic but actually structural&rdquo; problems:

- Training JCT is amplified by tail behavior, invalidating capacity planning;
- Inference P99 and queue tails are amplified, making SLOs difficult to honor.

Therefore, you need to build reusable AI-ready network baselines: capacity assumptions, lossless strategies, isolation domain partitioning, measurement and acceptance criteria. Networking is not &ldquo;optimize later,&rdquo; but baseline engineering that must land in Days 31–60.

## Migration Path Selection: Layered by Organizational Risk and Technical Debt

Migration isn&rsquo;t &ldquo;pick one path and see it through,&rdquo; but mapping organizations with different risk appetites and debt structures to different starting approaches and exit criteria. Paths can advance in parallel, but each needs defined **applicable conditions** and **exit criteria**.

**Path 1: Bypass Pilot / Skunkworks**

Applicable when cloud-native platforms are running stably, but AI demand is just emerging, organizational uncertainty is high, and governance mechanisms are not yet mature.

The approach is establishing an &ldquo;AI minimum closed-loop sandbox&rdquo; alongside the existing platform. The goal is not &ldquo;feature completeness,&rdquo; but &ldquo;making the loop work&rdquo;:

- Independent GPU pool (or at least independent queue) + basic admission and budget
- Minimal token/GPU metering and attribution
- Controlled inference/agent entry points (max context / max steps / max tool calls)
- &ldquo;Failure-acceptable&rdquo; SLOs and cost caps (define boundaries first, then discuss experience)

Exit criteria:

- Cost curve is explainable (at minimum attributable to team/use-case)
- GPU utilization and isolation strategies form reusable templates
- Pilot capabilities can be absorbed into platform capabilities (enter Path 2)

**Path 2: Domain-Isolated Platform**

Applicable when AI has entered multi-team, multi-tenant stages, requiring &ldquo;pilot assets&rdquo; to be solidified into platform capabilities to prevent cost and risk from spreading across domains.

The approach is building an AI Landing Zone, where the platform team centrally manages shared governance capabilities, and workload teams iteratively build applications within controlled boundaries.

Platform-side essential modules (recommend organizing by &ldquo;governance loop&rdquo;):

- **Identity/Policy**: Unified identity, policy distribution, and auditing (policy-as-intent)
- **Network/Fabric baseline**: AI-ready network baseline and automated acceptance
- **Compute governance**: Quotas, budgets, preemption, fairness, isolation/sharing
- **Observability & Chargeback**: End-to-end metering, alerts, showback/chargeback
- **Runtime catalog**: &ldquo;Golden paths&rdquo; and templated delivery for inference/training runtimes

Exit criteria: Platform provides &ldquo;replicable AI workload landing approaches&rdquo; and can scale use case count under budget constraints, rather than relying on manual firefighting to maintain stability.

**Path 3: AI-First Refactor (AI Factory / Replatform)**

Applicable when AI is core business, requiring infrastructure to be treated as a &ldquo;production line&rdquo; rather than a &ldquo;cluster,&rdquo; and optimization objectives to switch from &ldquo;shipping features&rdquo; to &ldquo;throughput/unit cost/energy efficiency.&rdquo;

The approach centers on &ldquo;state assets + unit cost&rdquo; refactoring:

- **Context/state** of inference/agents is explicitly governed and reused (no longer application-level tricks)
- Introduce **Context Tier** architectural assumptions: long context and agentic inference require inference state / KV cache to be reusable across nodes and sessions
- Drive platform evolution with &ldquo;unit token cost, tail latency, throughput/energy efficiency,&rdquo; not &ldquo;number of new components&rdquo;

Exit criteria: Can consistently make engineering decisions using &ldquo;unit cost and tail performance,&rdquo; and treat context reuse as a platform capability rather than application team trick caching.

## 90-Day Actionable Plan: AI Landing Zone + Minimum Governance Loop

The goal is to establish &ldquo;AI Landing Zone + minimum governance loop&rdquo; within 90 days, forming a replicable template. The key is not covering all scenarios, but connecting the **admission—metering—enforcement—feedback** loop.

**Day 0–30: Establish the Ledger (Cost & Usage Ledger)**

First, define attribution dimensions, establish budgets/alerts and baseline reports, and implement quotas/usage controls.

- Attribution dimensions: tenant/team/project/model/use-case/tool
- Establish budgets and alerts, baseline reports (cost + business value metrics)
- Implement quotas and usage controls (at minimum covering GPU quotas and key service quotas)

Deliverables:

- Cost and usage dashboard (weekly-level, traceable)
- &ldquo;Admission Policy v0&rdquo; (max context / max steps / max budget)

**Day 31–60: Establish Resource Governance (GPU Governance + Scheduling)**

This phase requires evaluating GPU sharing/isolation strategies, introducing topology/networking constraints, and forming two golden paths for inference and training.

- GPU sharing/isolation strategy: MIG/MPS/vGPU/DRA path evaluation and PoC (executable strategy as acceptance criteria)
- Introduce topology/networking constraints, form AI-ready network baseline and capacity assumptions (including acceptance criteria)
- Form two templated delivery paths for inference/training

Deliverables:

- Workload templates (1 each for inference and training)
- Scheduling and isolation strategies (whitelisted, auditable)

**Day 61–90: Establish the Loop (Enforcement + Feedback)**

The final phase requires executing budget policies, migrating pilot use cases to the landing zone, and solidifying organizational interfaces.

- Execute budgets: rate limiting/queuing/preemption/degradation strategies, linked to SLOs
- Migrate pilot use cases to landing zone (or service landing zone capabilities)
- Solidify &ldquo;organizational interface&rdquo;: platform team vs workload team responsibility boundaries (forming executable contracts)

Deliverables:

- &ldquo;AI Platform Runbook v1&rdquo; (including oncall, changes, cost auditing)
- Two replicable use case landing paths (new use cases <= 30 minutes to golden path)

## Operating Model: The &ldquo;Contract&rdquo; Between Platform Teams and Workload Teams

Migration success depends on establishing clear, executable &ldquo;organizational contracts.&rdquo; The contract essence: who is responsible for &ldquo;capability provision,&rdquo; who is responsible for &ldquo;behavioral consequences.&rdquo;

**Platform teams provide (must be stable)**

Landing zone, network baseline, identity and policies, budget/quota systems, metering/attribution, GPU governance capabilities, runtime golden paths

**Workload teams own (must be self-service)**

Model selection, prompt/agent logic, tool integration, SLO definition, business value measurement, use case risk classification and rollback paths

This is also why the FinOps Framework emphasizes operating model (personas, capabilities, maturity) rather than just tools: without &ldquo;contracts,&rdquo; budgets are difficult to execute; if budgets cannot execute, loops cannot form.

## Migration Anti-Patterns

Below are common migration anti-patterns and their consequences:

Anti-PatternTypical ConsequencesBuild only API/Agent platform, without ledger and budgetrunaway cost (most common, and difficult to remediate afterwards)Treat GPUs as ordinary resources, without sharing/isolation and scheduling upgradesLow utilization + uncontrolled contention, platform forced to allocate compute via &ldquo;administrative means&rdquo;Ignore networking and topologyTail latency and training JCT amplified, capacity planning fails, SLOs difficult to honorContext not assetized (only &ldquo;tricky caching&rdquo; within applications)Unit cost out of control in long context/agentic era, reuse capabilities difficult to solidify as platform capabilitiesTable 1: Common Migration Anti-Patterns and Consequences## Summary

The core of AI-native migration is not a &ldquo;migration checklist,&rdquo; but **under uncertainty premises, incorporating cost, risk, and tail performance into a unified governance loop, using Landing Zone to carry organizational contracts, and using Context Tier to implement state reuse infrastructure capabilities**. Only in this way can platform and business maintain controllability and efficiency during scaled evolution.

## References

- McKinsey on AI Strategy - mckinsey.com
- Thoughtworks Technology Radar - thoughtworks.com
- Google Cloud Adoption Framework - cloud.google.com

**
Previous Page
Organization and CultureNext Page
**
Glossary**Created on Jan 18, 2026
**Updated on Jan 18, 2026
**1697 words
**about 8 MinuteSubmit Corrections/Suggestions

**
Loading comments...
0