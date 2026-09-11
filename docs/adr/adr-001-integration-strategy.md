# ADR-001: Integration Strategy for Competing Tools

## Status
Accepted

## Context
The developer tooling landscape includes several competing projects:
- **VibeVM** — AI-powered VM provisioning
- **Microsoft APM** — AI Package Manager standard
- **AgentRC** — Agent runtime configuration
- **Omakub** — Opinionated Ubuntu setup

These tools overlap with opencode_initializer's goals but each has unique strengths.

## Decision
**Integrate, don't compete.** opencode_initializer is a meta-project that:
1. **Forks** and customizes useful components (e.g., Omakub's Ubuntu patterns)
2. **Imports** as subprojects where licensing allows
3. **Uses as dependencies** where APIs are stable
4. **Draws inspiration** from design patterns

## Consequences
- **Positive:** Users get the best of all worlds without choosing
- **Positive:** Faster development by leveraging existing work
- **Positive:** Community goodwill — we contribute back
- **Negative:** Maintenance burden tracking upstream changes
- **Negative:** Potential licensing complexity

## Related
- Microsoft APM integration: `src/lib/00g-apm-integration.sh`
- Multi-agent targets: `src/lib/00h-multi-agent.sh`
