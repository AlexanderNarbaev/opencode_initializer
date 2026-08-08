#!/usr/bin/env bash
# src/lib/41-constitution.sh — Project Constitution Generator
# Generates memory/constitution.md at project initialization.
# Used by 17-project.sh when creating new projects.
set -euo pipefail

# ── Generate constitution.md ─────────────────────────────────────────────────
# _constitution_generate <project_dir> [project_name]
# Creates memory/constitution.md with project principles, tech decisions, and SDD lifecycle.
_constitution_generate() {
  local project_dir="${1:-$PROJECT_DIR}"
  local project_name="${2:-$(basename "$project_dir")}"
  local output="$project_dir/memory/constitution.md"

  [ -z "$project_dir" ] && { warn "constitution: no project dir"; return 1; }
  mkdir -p "$(dirname "$output")"

  # Idempotent: don't overwrite existing constitution
  [ -f "$output" ] && { log "constitution.md already exists — skipping"; return 0; }

  info "Generating constitution.md for $project_name..."

  cat > "$output" << CONSTEOF
# Project Constitution — $project_name

> Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ") | Version: 1.0

## 1. Project Identity

**Name:** $project_name
**Purpose:** [Describe the primary goal of this project]
**Audience:** [Who is this for?]

## 2. Core Principles (MUST)

These principles are non-negotiable. All design and implementation decisions MUST align with them.

1. **Correctness over speed.** Code must be correct first. Performance optimizations come after correctness is verified.
2. **Explicit over implicit.** Behavior must be predictable from reading the code. No hidden side effects.
3. **Testable by design.** Every feature must have a clear testing strategy BEFORE implementation.
4. **Documented decisions.** All architectural decisions are recorded as ADRs in \`docs/architecture/adr/\`.

## 3. Recommended Practices (SHOULD)

These practices SHOULD be followed unless there is a documented reason not to.

1. **Use the SDD lifecycle:** constitution → specify → clarify → plan → tasks → implement → verify → converge
2. **Spec-first:** Write specs before code. Specs live in \`specs/\` and are the source of truth.
3. **Small PRs:** Pull requests should be small (<400 lines) and focused on one concern.
4. **Automated verification:** Every PR must pass lint, type-check, tests, and security scan.

## 4. Technology Decisions

| Decision | Rationale | Date | ADR |
|----------|-----------|------|-----|
| [Language/Platform] | [Why chosen] | $(date +%Y-%m-%d) | [ADR-001] |

## 5. SDD Lifecycle

This project follows the Specification-Driven Development (SDD) lifecycle:

\`\`\`
constitution → specify → clarify → plan → tasks → implement → verify → converge
     ↑                                                                        │
     └────────────────────── feedback loop ────────────────────────────────────┘
\`\`\`

| Phase | Purpose | Artifact |
|-------|---------|----------|
| **Constitution** | Establish principles and constraints | \`memory/constitution.md\` |
| **Specify** | Define what to build | \`specs/<feature>.md\` |
| **Clarify** | Resolve ambiguities | \`specs/<feature>.clarifications.md\` |
| **Plan** | Break down into tasks | \`.opencode/todo.md\` |
| **Tasks** | Write atomic sub-tasks | \`.opencode/todo.md\` (M/T/S structure) |
| **Implement** | Build the code | Source files + tests |
| **Verify** | Test and review | Test results + review evidence |
| **Converge** | Polish and harden | \`CHANGELOG.md\` + release |

## 6. Governance Rules

- All code changes must go through the SDD lifecycle.
- Specs are reviewed BEFORE implementation begins.
- Constitution amendments require an ADR and review.
- Breaking changes require a migration plan.

## 7. Success Metrics

1. [Metric 1 — e.g., test coverage >80%]
2. [Metric 2 — e.g., PR review turnaround <24h]
3. [Metric 3 — e.g., zero P0 bugs in production]

---

> **Next:** Run \`specify\` phase to create your first spec.
CONSTEOF

  chmod 644 "$output"
  log "constitution.md created: $output"
}

# ── Export ───────────────────────────────────────────────────────────────────
export -f _constitution_generate
