# Why Start with Compute Governance, Not API Design | Jimmy …

> Source: https://jimmysong.io/book/ai-native-infra/compute-governance/
> Cached: 2026-08-08T11:04:58.901Z

---

**
Home
**
Books
**
AI Native Infra
**
Compute Governance# Why Start with Compute Governance, Not API Design

**
Published
****
Table of content
**
**
Search in this book...
- The Purpose of Layering: Engineering the Binding Between &ldquo;Intent&rdquo; and &ldquo;Resource Consequences&rdquo;
- AI-Native Infrastructure Five-Layer Structure and &ldquo;Three Planes&rdquo; Mapping
- MCP/Agent is the &ldquo;New Control Plane,&rdquo; But Must Be Constrained by the Governance Layer
- &ldquo;Context&rdquo; Is Rising to a New Infrastructure Layer
- The Foundation of AI-Native Infrastructure: Reference Designs and Delivery Systems
- &ldquo;Layered Responsibility Boundaries&rdquo; from a CTO/CEO Perspective
- Conclusion
- References

> Compute and governance boundaries are the true foundation of AI-native infrastructure architecture.

The previous chapter presented a &ldquo;Three Planes + One Closed Loop&rdquo; reference architecture. This chapter focuses on a core CTO/CEO-level question:

> **How should AI-native infrastructure be layered? What belongs in the &ldquo;control plane&rdquo; of APIs/Agents, what belongs in the &ldquo;execution plane&rdquo; of runtime, and what must be pushed down to the &ldquo;governance plane (compute and economic constraints)&rdquo;?**

This question is critical because over the past year, many platform companies &ldquo;pivoting to AI&rdquo; have fallen into a common trap: **treating AI as an API morphology change rather than a system constraint change**. When your system shifts from &ldquo;serving requests&rdquo; to &ldquo;model behavior&rdquo; (multi-step Agent actions with side effects), what truly determines system boundaries is often not the elegance of API design, but rather: **whether compute, context, and economic constraints are institutionalized as enforceable governance boundaries**.

The core argument of this chapter can be summarized as:

> **AI-native infrastructure must be designed starting from &ldquo;Consequence&rdquo; rather than stacking capabilities from &ldquo;Intent&rdquo;; the control plane is responsible for expressing intent, but the governance plane is responsible for bounding consequences.**

## The Purpose of Layering: Engineering the Binding Between &ldquo;Intent&rdquo; and &ldquo;Resource Consequences&rdquo;

In AI-native infrastructure, mechanisms like MCP, Agents, and Tool Calling enhance system capabilities while also introducing higher risks. These risks are not abstract &ldquo;uncontrollability,&rdquo; but rather engineering &ldquo;unbudgetable consequences&rdquo;:

- Path explosion in behavior, long contexts, and multi-round reasoning bring long-tail resource consumption;
- The same &ldquo;intent&rdquo; can lead to orders-of-magnitude differences in tokens, GPU time, and network/storage pressure;
- Without governance closed loops, systems will move toward &ldquo;cost and risk runaway&rdquo; while becoming &ldquo;more capable.&rdquo;

Therefore, the fundamental purpose of layering is not abstract aesthetics, but achieving a hard constraint goal:

> **Ensure each layer can translate upper-layer &ldquo;intent&rdquo; into executable plans and produce measurable, attributable, and constrainable resource consequences.**

In other words, layering is not about making architecture diagrams clearer, but about encoding &ldquo;who expresses intent, who executes, and who bears consequences&rdquo; into system structure.

## AI-Native Infrastructure Five-Layer Structure and &ldquo;Three Planes&rdquo; Mapping

To help understand the layering logic, the diagram below refines the &ldquo;Three Planes&rdquo; architecture from the previous chapter, proposing a more actionable &ldquo;five-layer structure&rdquo;:

Figure 1: Layered governance relationship from intent to consequence
- Top two layers = **Intent Plane**
- Middle two layers = **Execution Plane**
- Bottom layer = **Governance Plane**

Below is a detailed expansion of the five-layer architecture, showing the primary responsibilities and typical capabilities of each layer:

Figure 2: Five-layer architecture diagramIt is important to note that **MCP belongs to Layer 4 (Intent and Orchestration Layer), not Layer 1**. The reason is that MCP primarily defines &ldquo;how capabilities are exposed to models/Agents and how they are invoked,&rdquo; addressing control plane consistency and composability, but does not directly take responsibility for &ldquo;how the resource consequences of capability invocations are metered, constrained, and attributed.&rdquo;

## MCP/Agent is the &ldquo;New Control Plane,&rdquo; But Must Be Constrained by the Governance Layer

MCP/Agent is called the &ldquo;new control plane&rdquo; because it moves system &ldquo;decisions&rdquo; from static code to dynamic processes:

- &ldquo;Tool catalogs + schemas + invocations&rdquo; form a composable capability surface;
- Agents complete tasks by selecting tools, invoking tools, and iterating reasoning;
- &ldquo;Policy&rdquo; is no longer just in code branches but expressed as routing, priorities, budgets, and compliance intent.

However, it is crucial to emphasize an infrastructure stance, which is also the foundation of this chapter:

> **MCP/Agent can express intent, but the key to AI-native is: intent must be translated into governable execution plans and metered and constrained within economically viable boundaries.**

This statement aims to correct two common misconceptions:

- **Control plane is not the starting point**: Treating MCP/Agent as &ldquo;the entry point for AI platform upgrades&rdquo; easily leads systems down a &ldquo;capability-first&rdquo; path;
- **Governance plane is the baseline**: When compute and tokens become capacity units, any unconstrained &ldquo;intent expression&rdquo; will leak as cost, latency, or risk.

Therefore, system layering should be clear: Layer 4 is responsible for &ldquo;expression,&rdquo; Layers 1/2/3 are responsible for &ldquo;fulfillment and bearing consequences,&rdquo; and the governance loop is responsible for &ldquo;correction.&rdquo;

## &ldquo;Context&rdquo; Is Rising to a New Infrastructure Layer

In traditional cloud-native systems, request states are mostly short-lived, relying more on application-layer state management. Infrastructure typically only handles &ldquo;computation and networking&rdquo; without needing to understand the economic value of &ldquo;request context.&rdquo;

AI-native infrastructure is different. Long-context, multi-turn dialogue, and multi-agent reasoning mean **inference state often survives across requests** and directly determines throughput and cost. In particular, KV cache and context reuse are evolving from &ldquo;performance optimization techniques&rdquo; to &ldquo;platform capacity structures.&rdquo;

This can be summarized as an infrastructure law:

> **When a state asset (context/state) becomes a determinant variable of system cost and throughput, it rises from application detail to infrastructure layer.**

This trend is gradually appearing in the industry: inference context and KV reuse are explicitly elevated to &ldquo;infrastructure layer&rdquo; capability development directions. Future expansion will include distributed KV, parameter caching, inference routing state, Agent memory, and a series of &ldquo;state assets.&rdquo;

## The Foundation of AI-Native Infrastructure: Reference Designs and Delivery Systems

AI-native infrastructure is far more than &ldquo;buying a few GPUs.&rdquo; Compared to traditional internet services, AI workloads have three characteristics that make the &ldquo;foundation&rdquo; more engineered and productized:

- **Stronger topology dependencies**: Network fabric, interconnects, storage tiers, and GPU affinity determine available throughput;
- **Harder scarcity constraints**: GPU and token throughput boundaries are less &ldquo;elastic&rdquo; than CPU/memory;
- **Higher delivery complexity**: Multi-cluster, multi-tenant, multi-model/multi-framework coexistence means only &ldquo;replicable delivery&rdquo; can scale.

Therefore, AI Infra is not just a component list, but must include &ldquo;scalable delivery and repeatable operation&rdquo; system capabilities:

**Reference Designs (validated designs)**

- Codify &ldquo;correct topology and ratios&rdquo; into reusable solutions.

**Automated Delivery**

- Institutionalize deployment, upgrade, scaling, rollback, and capacity planning.

**Governance Implementation**

- Make budgeting, isolation, metering, and auditing default capabilities rather than after-the-fact patches.

From a CTO/CEO perspective, this means: what you purchase is not &ldquo;hardware&rdquo; but a &ldquo;delivery system for predictable capacity.&rdquo;

## &ldquo;Layered Responsibility Boundaries&rdquo; from a CTO/CEO Perspective

To facilitate internal alignment on &ldquo;who is responsible for what and what is the cost of failure,&rdquo; the table below maps &ldquo;technical layers&rdquo; to &ldquo;organizational responsibilities,&rdquo; avoiding the scenario where platform teams only build control planes while no one bears consequence boundaries.

LayerTypical CapabilitiesPrimary Owner (Recommended)Cost of FailureLayer 5 Business InterfaceSLA, product experience, business goalsProduct / BusinessCustomer experience and revenue impactLayer 4 Intent/Orchestration (MCP/Agent)Capability catalogs, workflow, policy expressionApp / Platform / AI EngBehavior runaway, tool abuseLayer 3 Execution (Runtime)Serving, batching, routing, caching policiesAI Platform / InfraInsufficient throughput, latency jitterLayer 2 Context/StateKV/cache/context tierInfra + AI PlatformToken cost spike, throughput collapseLayer 1 Compute/GovernanceQuotas, isolation, topology scheduling, meteringInfra / FinOps / SREBudget explosion, resource contention, incident spilloverTable 1: AI-Native Infrastructure Layer and Organizational Responsibility MappingAs you can see, **the organizational challenge of AI-native is not in &ldquo;whether we have agents,&rdquo; but in &ldquo;whether inter-layer closed loops are established&rdquo;**. When model-driven amplification of consequences occurs, organizations must institutionalize governance mechanisms as platform capabilities: executable budgets, explainable consequences, attributable anomalies, and rewritable policies. This is the true meaning of &ldquo;starting from compute governance&rdquo; rather than &ldquo;starting from API design.&rdquo;

## Conclusion

The layered design of AI-native infrastructure centers on engineering the binding between &ldquo;intent&rdquo; and &ldquo;resource consequences.&rdquo; The control plane is responsible for expressing intent, while the governance plane is responsible for bounding consequences. Only by institutionalizing governance mechanisms as platform capabilities can we ensure cost, risk, and capacity remain controllable while enhancing capabilities. As context, state assets, and other new variables become infrastructure, AI Infra delivery systems will continue to evolve, becoming the foundation for sustainable enterprise innovation.

## References

- Google SRE - Capacity Planning - sre.google
- AWS Well-Architected - Cost Optimization - aws.amazon.com
- Microsoft FinOps for AI - learn.microsoft.com

**
Previous Page
One-Page Reference ArchitectureNext Page
**
Metrics and Budget**Created on Jan 18, 2026
**Updated on Jan 18, 2026
**1292 words
**about 7 MinuteSubmit Corrections/Suggestions

**
Loading comments...
0