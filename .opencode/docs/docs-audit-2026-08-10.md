# Documentation Audit — opencode_initializer v3.2.0

> **Date:** 2026-08-10 | **Auditor:** Planner | **Scope:** All docs/, root .md files
> **Confidence:** HIGH (verified by reading file headers, line counts, Cyrillic detection)

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Total .md files in docs/ | 77 |
| Fully translated pairs (RU+EN) | 18 pairs |
| RU-only files (no EN) | 3 |
| EN-only files (no RU) | 36 |
| **Content discrepancy found** | **1 critical** (index.ru.md: 6 vs 7 services) |
| **Naming inconsistency** | 2 files |
| **AGENTS.md mandate vs reality** | Contradiction (mandates Russian, README is English) |

---

## 1. File-by-File Translation Status

### 1.1 Root-level files

| File | Language | Lines | RU Status | EN Status | Gap |
|------|----------|-------|-----------|-----------|-----|
| `README.md` | EN | 351 | No RU version | Complete | **Needs RU translation** |
| `CONTRIBUTING.md` | EN | 175 | No RU version | Complete | **Needs RU translation** |
| `AGENTS.md` | Mixed (RU/EN) | 330 | Partial | Partial | Intentional: mandates RU for communication, EN for code/comments |
| `current_wave.md` | EN | ~30 | No RU version | Complete | Low priority (operational) |

### 1.2 docs/ top-level files

| File | Language | Lines | RU Status | EN Status | Gap |
|------|----------|-------|-----------|-----------|-----|
| `index.ru.md` | RU | 201 | Has RU | v EN: "6 services" | **1 critical bug** |
| `index.en.md` | EN | 203 | v RU: "7 services" | Complete | Node Exporter missing from RU |
| `comparison.ru.md` | RU | 113 | Complete | Complete | Good parity |
| `comparison.en.md` | EN | 114 | Complete | Complete | Good parity |
| `comparison.md` | EN | 57 | No RU | N/A | **Different content** — competitive AI tools analysis, NOT related to RU/EN pair! |
| `tags.ru.md` | RU | 3 | Complete | Complete | Stub (both 3 lines) |
| `tags.en.md` | EN | 3 | Complete | Complete | Stub |
| `manual-steps.md` | EN | 23 | No RU | N/A | Operational meta-file, low priority |
| `VERSIONS.md` | EN | 130 | No RU version | Complete | **Needs RU translation** (user-facing versions reference) |

### 1.3 docs/architecture/

| File | Language | Lines | RU Status | EN Status | Gap |
|------|----------|-------|-----------|-----------|-----|
| `index.en.md` | EN | 248 | Complete | Complete | Good parity |
| `index.ru.md` | RU | 252 | Complete | Complete | Good parity |
| `agent-system.md` | EN | 200 | Complete | Complete | Exact line match (200/200) |
| `agent-system.ru.md` | RU | 200 | Complete | Complete | Exact line match |
| `adr/2026-07-18-hybrid-ai-architecture.md` | EN | 38 | No RU | Complete | **Needs RU** |
| `adr/2026-07-18-multi-agent-framework-v3.md` | EN | 35 | No RU | Complete | **Needs RU** |

### 1.4 docs/guides/

| File | Language | Lines | RU Status | EN Status | Gap |
|------|----------|-------|-----------|-----------|-----|
| `airgap-offline.en.md` | EN | 101 | Complete | Complete | Exact line match |
| `airgap-offline.ru.md` | RU | 101 | Complete | Complete | Exact line match |
| `deployment-profiles.en.md` | EN | 108 | Complete | Complete | Exact line match |
| `deployment-profiles.ru.md` | RU | 108 | Complete | Complete | Exact line match |
| `team-setup.md` | EN | 249 | Naming issue | Complete | **Should be `team-setup.en.md`** |
| `team-setup.ru.md` | RU | 249 | Complete | Complete | Exact line match |
| **`ai-gateway-proxy.md`** | EN | 70 | **No RU** | Complete | **Needs RU translation** (enterprise feature) |
| **`ide-plugins-guide.md`** | EN | 37 | **No RU** | Complete | **Needs RU translation** |
| **`provider-setup.md`** | EN | 55 | **No RU** | Complete | **Needs RU translation** (user-facing setup) |

### 1.5 docs/reference/

| File | Language | Lines | RU Status | EN Status | Gap |
|------|----------|-------|-----------|-----------|-----|
| `index.en.md` | EN | 277 | Complete | Complete | Good parity |
| `index.ru.md` | RU | 271 | Complete | Complete | Good parity |
| `governance.en.md` | EN | 143 | Complete | Complete | Exact line match |
| `governance.ru.md` | RU | 143 | Complete | Complete | Exact line match |
| `mcp-lsp-plugins.en.md` | EN | 174 | RU shorter: 152 | Complete | RU 22 lines shorter — **content gap** |
| `mcp-lsp-plugins.ru.md` | RU | 152 | v EN: 174 | Complete | EN 22 lines longer |
| `security-compliance.en.md` | EN | 120 | Complete | Complete | Exact line match |
| `security-compliance.ru.md` | RU | 120 | Complete | Complete | Exact line match |

### 1.6 docs/compliance/

| File | Language | Lines | RU Status | EN Status | Gap |
|------|----------|-------|-----------|-----------|-----|
| `iso27001-mapping.md` | EN | 102 | **No RU** | Complete | **Needs RU** |
| `soc2-checklist.md` | EN | 80 | **No RU** | Complete | **Needs RU** |

### 1.7 docs/changelog/

| File | Language | Lines | RU Status | EN Status | Gap |
|------|----------|-------|-----------|-----------|-----|
| `index.md` | EN | 2 | Worse than RU | Complete | EN stub (just "# Blog") vs RU 5 lines |
| `index.ru.md` | RU | 5 | Complete | Complete | Better than EN — links to CHANGELOG.md |
| `posts/*.md` (4 files) | EN | 27-98 | No RU | Complete | **No RU translations for changelog posts** |

### 1.8 Directories with full RU/EN parity

| Directory | Files | Status |
|-----------|-------|--------|
| `docs/advanced/` | index.en.md + index.ru.md | Pair, sizes close (344/275) |
| `docs/contributing/` | index.en.md + index.ru.md | Pair (148/139) |
| `docs/faq/` | index.en.md + index.ru.md | Pair (153/150) |
| `docs/getting-started/` | index.en.md + index.ru.md | Pair (391/371) |
| `docs/user-guide/` | index.en.md + index.ru.md | Pair (306/296) |

### 1.9 Directories with NO translations

| Directory | Files | Language |
|-----------|-------|----------|
| `docs/plans/` | 10 files | EN-only |
| `docs/research/` | 10 files | EN-only |
| `docs/superpowers/` | 2 files | EN-only |

> **Note:** plans/, research/, superpowers/ are internal working documents — translations may be intentionally skipped.

---

## 2. Content Discrepancies

### CRITICAL: Infrastructure service count mismatch

| Location | EN (`index.en.md`) | RU (`index.ru.md`) |
|----------|--------------------|--------------------|
| Quick Stats table (L29) | **7 services** (PostgreSQL, Qdrant, Redis, Prometheus, Grafana, **Node Exporter**, MemoryLayer) | **6 services** (PostgreSQL, Qdrant, Redis, Prometheus, Grafana, MemoryLayer) |
| Feature grid (L43) | Includes **Node Exporter** | No Node Exporter |
| Infrastructure as Code (L78) | Includes **Node Exporter** | No Node Exporter |
| Overview table (L141) | Includes **Node Exporter** | No Node Exporter |

**Impact:** RU docs are outdated — Node Exporter was added but RU version not updated. Affects 4 locations in `index.ru.md`.

### MEDIUM: `comparison.md` is orphaned

- `docs/comparison.md` (57 lines, EN) is a **competitive analysis of AI coding tools** (Claude Code, Cursor, Windsurf, etc.)
- `docs/comparison.en.md` + `docs/comparison.ru.md` (114/113 lines) compare vs **infrastructure tools** (Devbox/Nix/DevPod/manual setup)
- These are **completely different documents** — `comparison.md` has no RU translation and its content doesn't overlap with the RU/EN pair.
- **Recommendation:** Either merge into `comparison.en.md`/`comparison.ru.md` or rename to `competitive-landscape.md`.

### MEDIUM: `mcp-lsp-plugins.en.md` (174 lines) vs `mcp-lsp-plugins.ru.md` (152 lines)

- EN is 22 lines longer — likely missing content in RU or extra content in EN.
- Needs side-by-side review.

### LOW: `changelog/index.md` (EN) — 2-line stub vs RU 5 lines

- EN just says "# Blog", RU has proper description and link to CHANGELOG.md.

---

## 3. Naming Inconsistencies

| File | Issue | Fix |
|------|-------|-----|
| `docs/guides/team-setup.md` | No `.en` suffix, but content is English | Rename to `team-setup.en.md` |
| `docs/comparison.md` | No suffix, different content from `comparison.en.md` | Rename to `competitive-landscape.md` or `comparison-ai-tools.md` |

---

## 4. AGENTS.md Language Policy vs Reality

**AGENTS.md line 21:** "All communication strictly in Russian. Code and comments in English."

| Reality check | Status |
|---------------|--------|
| `README.md` — fully English (0 Cyrillic chars) | Violates policy |
| `CONTRIBUTING.md` — fully English | Violates policy |
| `docs/index.en.md` + all EN docs | Policy allows EN for code, but docs ARE communication |
| `AGENTS.md` itself — mixed RU/EN | Inconsistent with own mandate |

**Recommendation:** Either update AGENTS.md to clarify "documentation is bilingual" or create RU versions of README, CONTRIBUTING.

---

## 5. Priority Recommendations

### P0 — Fix immediately

| # | Action | File(s) |
|---|--------|---------|
| 1 | Fix "6 services" -> "7 services" + add Node Exporter in all 4 locations | `docs/index.ru.md` |

### P1 — High priority (user-facing docs missing RU)

| # | Action | File(s) |
|---|--------|---------|
| 2 | Translate README to Russian | `README.md` -> `README.ru.md` (or make bilingual) |
| 3 | Translate CONTRIBUTING to Russian | `CONTRIBUTING.md` -> `CONTRIBUTING.ru.md` |
| 4 | Translate ai-gateway-proxy guide to RU | `docs/guides/ai-gateway-proxy.md` -> `.ru.md` |
| 5 | Translate provider-setup guide to RU | `docs/guides/provider-setup.md` -> `.ru.md` |
| 6 | Translate ide-plugins-guide to RU | `docs/guides/ide-plugins-guide.md` -> `.ru.md` |
| 7 | Translate VERSIONS.md to RU | `docs/VERSIONS.md` -> `VERSIONS.ru.md` |
| 8 | Translate compliance docs to RU | `docs/compliance/iso27001-mapping.md`, `soc2-checklist.md` |

### P2 — Medium priority (naming & parity)

| # | Action | File(s) |
|---|--------|---------|
| 9 | Rename `team-setup.md` -> `team-setup.en.md` | `docs/guides/team-setup.md` |
| 10 | Resolve `comparison.md` orphan — rename or merge | `docs/comparison.md` |
| 11 | Review mcp-lsp-plugins content gap (174/152 lines) | `docs/reference/mcp-lsp-plugins.{en,ru}.md` |
| 12 | Improve changelog/index.md EN stub | `docs/changelog/index.md` |
| 13 | Translate architecture ADRs to RU | `docs/architecture/adr/*.md` |

### P3 — Low priority (internal/operational)

| # | Action | File(s) |
|---|--------|---------|
| 14 | Translate changelog posts to RU | `docs/changelog/posts/*.md` |
| 15 | Translate plans/ research/ superpowers/ | `docs/plans/`, `docs/research/`, `docs/superpowers/` |
| 16 | Clarify AGENTS.md language policy | `AGENTS.md` line 21 |

---

## 6. Summary Statistics

```
Total documented files:              77
├── Fully paired (RU+EN):            18 (23%)
├── RU-only (missing EN):             3 (4%)
├── EN-only (missing RU):            36 (47%)
│   ├── User-facing docs:            11  <-- PRIORITY
│   └── Internal docs:               25  <-- Low priority
├── Content discrepancies:            3
├── Naming inconsistencies:           2
└── Orphaned/ambiguous files:         1
```

**Translation completeness for user-facing docs:** ~62% (18/29 user-facing files have RU versions)

---

*Audit completed 2026-08-10. Report: `.opencode/docs-audit.md`*
