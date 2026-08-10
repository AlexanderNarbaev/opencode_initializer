# Documentation Audit: RU/EN Parity — opencode_initializer v3.2.0

> **Date:** 2026-08-10 | **Auditor:** Planner (automated)
> **Scope:** All `.md` files in `docs/` + root-level README/CONTRIBUTING/AGENTS

---

## 1. Executive Summary

| Metric | Value |
|--------|-------|
| Total .md files (excl. plans/research/superpowers) | 62 |
| `.ru.md` files | 18 |
| `.en.md` files | 18 |
| Unsuffixed (no `.ru`/`.en`) | 23 |
| **RU/EN paired files** | 16 pairs |
| **Content gaps found** | 4 (index.ru.md: infrastructure count, module count, v2.0 rows; mcp-lsp-plugins: line delta) |
| **Naming inconsistencies** | 3 (agent-system, comparison, team-setup) |
| **Missing RU translations** | 10 files |

---

## 2. Root-Level Project Files

| File | Lines | Language | Has RU? | Issue |
|------|-------|----------|---------|-------|
| `README.md` | ~350 | EN | NO | No Russian README |
| `CONTRIBUTING.md` | ~120 | EN | NO | No Russian CONTRIBUTING |
| `AGENTS.md` | ~685 | **RU** (21 Cyrillic) | N/A | AGENTS.md in Russian — inconsistent with EN README/CONTRIBUTING |
| `CHANGELOG.md` | — | — | — | **NOT FOUND** at project root |

### Recommendation
- Either translate `AGENTS.md` to EN (matching README/CONTRIBUTING), or create `README.ru.md` + `CONTRIBUTING.ru.md`.
- Create `CHANGELOG.md` at project root.

---

## 3. docs/ Root-Level Files

| File | Lines | EN version | RU version | Status |
|------|-------|------------|------------|--------|
| `index.en.md` | 203 | self | `index.ru.md` (201) | **PAIRED** — minor: RU Δ=-2 |
| `comparison.en.md` | 114 | self | `comparison.ru.md` (113) | **PAIRED** — Δ=-1 |
| `comparison.md` | 57 | ⚠️ EN (2 Cyrillic) | NONE | **ORPHAN** — DIFFERENT content from comparison.en.md |
| `tags.en.md` | 3 | self | `tags.ru.md` (3) | **PAIRED** — identical |
| `manual-steps.md` | 23 | EN | NONE | Untranslated — internal dev notes |
| `VERSIONS.md` | 129 | EN | NONE | Untranslated — version registry |

### CRITICAL: `comparison.md` vs `comparison.en.md`

- **`comparison.md`** (57 lines): "Competitive Comparison" — AI Coding Agent Landscape table (vs Claude Code, Cursor, Windsurf, OpenCode)
- **`comparison.en.md`** (114 lines): "Why OpenCode Initializer?" — general comparison (vs Manual Setup, Devbox, DevPod, Docker)
- **`comparison.ru.md`** (113 lines): Translation of `comparison.en.md` ONLY
- **Result**: `comparison.md` has **NO RU translation** — it's a completely different document that got orphaned

**Fix:** Rename `comparison.md` → `competitive-landscape.en.md`, create `competitive-landscape.ru.md`. OR merge into `comparison.en.md`.

---

## 4. docs/ Subdirectory Audit

### 4.1 `docs/architecture/`

| File | Lines | EN | RU | Status |
|------|-------|----|----|--------|
| `index.en.md` | 248 | ✅ | ✅ `index.ru.md` (252) | **PAIRED** — RU Δ=+4 |
| `agent-system.md` | 200 | ⚠️ EN (NO .en suffix!) | ✅ `agent-system.ru.md` (200) | **NAMING BUG** — should be `agent-system.en.md` |
| `adr/2026-07-18-hybrid-ai-architecture.md` | 38 | EN | NONE | Untranslated (ADR — expected) |
| `adr/2026-07-18-multi-agent-framework-v3.md` | 35 | EN | NONE | Untranslated (ADR — expected) |

**Issue:** `agent-system.md` has EN content but no `.en.md` suffix. All other files use `name.en.md`/`name.ru.md`.

### 4.2 `docs/advanced/`

| File | Lines | EN | RU | Status |
|------|-------|----|----|--------|
| `index.en.md` | 344 | ✅ | ✅ `index.ru.md` (275) | **PAIRED** — RU Δ=-69 lines |

**Gap:** RU is 69 lines (20%) shorter than EN. Needs section-by-section sync.

### 4.3 `docs/getting-started/`

| File | Lines | EN | RU | Status |
|------|-------|----|----|--------|
| `index.en.md` | 148 | ✅ | ✅ `index.ru.md` (139) | **PAIRED** — RU Δ=-9 |

### 4.4 `docs/user-guide/`

| File | Lines | EN | RU | Status |
|------|-------|----|----|--------|
| `index.en.md` | 391 | ✅ | ✅ `index.ru.md` (371) | **PAIRED** — RU Δ=-20 |

### 4.5 `docs/reference/`

| File | Lines | EN | RU | Gap |
|------|-------|----|----|-----|
| `index.en.md` | 277 | ✅ | ✅ `index.ru.md` (271) | Δ=-6 |
| `governance.en.md` | 143 (7 sec) | ✅ | ✅ `governance.ru.md` (143, 7 sec) | **IDENTICAL** |
| `security-compliance.en.md` | 120 (7 sec) | ✅ | ✅ `security-compliance.ru.md` (120, 7 sec) | **IDENTICAL** |
| `mcp-lsp-plugins.en.md` | 174 (4 sec) | ✅ | ✅ `mcp-lsp-plugins.ru.md` (152, 4 sec) | **Δ=-22 lines** — RU less detailed |

### 4.6 `docs/guides/`

| File | Lines | EN | RU | Status |
|------|-------|----|----|--------|
| `airgap-offline.en.md` | 101 | ✅ | ✅ `airgap-offline.ru.md` (101) | **IDENTICAL** |
| `deployment-profiles.en.md` | 108 | ✅ | ✅ `deployment-profiles.ru.md` (108) | **IDENTICAL** |
| `team-setup.md` | 249 | ⚠️ EN (NO .en suffix) | ✅ `team-setup.ru.md` (249) | **NAMING BUG** |
| `ai-gateway-proxy.md` | 70 | EN (3 Cyrillic) | NONE | **NO RU** |
| `ide-plugins-guide.md` | 37 | EN | NONE | **NO RU** |
| `provider-setup.md` | 55 | EN | NONE | **NO RU** |

### 4.7 `docs/contributing/`, `docs/faq/`, `docs/changelog/`

| File | Lines | EN | RU | Status |
|------|-------|----|----|--------|
| `contributing/index.en.md` | 150 | ✅ | ✅ `index.ru.md` (153) | **PAIRED** — RU Δ=+3 |
| `faq/index.en.md` | 306 | ✅ | ✅ `index.ru.md` (296) | **PAIRED** — RU Δ=-10 |
| `changelog/index.md` | 2 | ⚠️ EN (NO .en suffix) | ✅ `index.ru.md` (5) | **NAMING BUG** |
| `changelog/posts/*.md` | ~200 | EN (4 posts) | NONE | Untranslated changelog posts |

### 4.8 `docs/compliance/`

| File | Lines | Language | Has RU? |
|------|-------|----------|---------|
| `iso27001-mapping.md` | 102 | EN | NONE |
| `soc2-checklist.md` | 80 | EN | NONE |

---

## 5. Content Gaps: RU Lags Behind EN

### 5.1 `index.ru.md` vs `index.en.md`

| Gap | RU | EN | Severity |
|-----|----|----|----------|
| **Quick Stats: Infrastructure count** | "6 сервисов" | "7 services" | **MEDIUM** — RU missing Node Exporter |
| **What Gets Installed: Infrastructure row** | PostgreSQL, Qdrant, Redis, Prometheus, Grafana, MemoryLayer | … + **Node Exporter** | **MEDIUM** |
| **v2.0: IaC description** | without Node Exporter | includes Node Exporter | **MEDIUM** |
| **v2.0: Module count** | "39 модулей" | "42 modules" | **HIGH** — RU shows outdated count |
| **v2.0: "Provider Check" row** | MISSING | present | LOW |
| **v2.0: ".env.example" row** | MISSING | present | LOW |

### 5.2 `mcp-lsp-plugins.ru.md` vs `.en.md`

| Metric | RU | EN | Gap |
|--------|----|----|-----|
| Lines | 152 | 174 | Δ=-22 |
| Sections | 4 | 4 | Same structure |
| Issue | Shorter descriptions | More detailed | RU needs expansion |

---

## 6. Naming Convention Inconsistencies

Project uses **3 conflicting naming patterns**:

| Pattern | Example | Used In |
|---------|---------|---------|
| **A: `name.en.md` + `name.ru.md`** | `index.en.md` + `index.ru.md` | Most docs subdirs |
| **B: `name.md` (EN) + `name.ru.md` (RU)** | `agent-system.md` + `agent-system.ru.md` | `docs/architecture/` |
| **C: `name.md` (EN) + `name.ru.md` (RU)** | `index.md` + `index.ru.md` | `docs/changelog/` |

### Recommended Fix
Standardize on **Pattern A** (`name.en.md` + `name.ru.md`):

| Current | → New |
|---------|-------|
| `architecture/agent-system.md` | `architecture/agent-system.en.md` |
| `guides/team-setup.md` | `guides/team-setup.en.md` |
| `changelog/index.md` | `changelog/index.en.md` |
| `comparison.md` | `competitive-landscape.en.md` (or delete — duplicate) |

**IMPORTANT:** After renaming, update ALL cross-references in other docs and `mkdocs.yml`.

---

## 7. Untranslated Files (EN Only — No RU)

| # | File | Lines | Priority | Notes |
|---|------|-------|----------|-------|
| 1 | `README.md` | ~350 | **HIGH** | Main project file |
| 2 | `CONTRIBUTING.md` | ~120 | **MEDIUM** | Contribution guide |
| 3 | `docs/guides/ai-gateway-proxy.md` | 70 | **MEDIUM** | 3 Cyrillic chars (mixed text) |
| 4 | `docs/guides/ide-plugins-guide.md` | 37 | **LOW** | Short reference |
| 5 | `docs/guides/provider-setup.md` | 55 | **MEDIUM** | v2.0 features |
| 6 | `docs/compliance/iso27001-mapping.md` | 102 | **LOW** | Compliance docs |
| 7 | `docs/compliance/soc2-checklist.md` | 80 | **LOW** | Compliance docs |
| 8 | `docs/VERSIONS.md` | 129 | **LOW** | Technical reference |
| 9 | `docs/manual-steps.md` | 23 | **LOW** | Internal notes |
| 10 | `docs/architecture/adr/*.md` | ~73 | **LOW** | 2 ADR files |

---

## 8. AGENTS.md Language Conflict

`AGENTS.md` contains 21 Cyrillic characters — written in Russian. Meanwhile `README.md` and `CONTRIBUTING.md` are English.

### Options
- **Option A:** Translate `AGENTS.md` to English (match README/CONTRIBUTING).
- **Option B:** Create `README.ru.md` and `CONTRIBUTING.ru.md` for Russian parity.

---

## 9. Priority Action Items

### RED (Content Errors)
1. **`index.ru.md`: "6 сервисов" → "7 сервисов"** — add Node Exporter to Quick Stats + What Gets Installed
2. **`index.ru.md`: "39 модулей" → "42 модуля"** — fix outdated module count in v2.0 section
3. **`index.ru.md`: add "Provider Check" + ".env.example" rows** to v2.0 section

### YELLOW (Naming + Missing Translations)
4. **Rename `agent-system.md` → `agent-system.en.md`** + update mkdocs.yml
5. **Rename `team-setup.md` → `team-setup.en.md`** + update mkdocs.yml
6. **Rename `changelog/index.md` → `changelog/index.en.md`** + update mkdocs.yml
7. **Resolve `comparison.md`**: rename to `competitive-landscape.en.md` or merge
8. **Create `README.ru.md`** (main file should have RU version)
9. **Create RU translations** for: `ai-gateway-proxy.ru.md`, `provider-setup.ru.md`

### GREEN (Nice to Have)
10. `mcp-lsp-plugins.ru.md`: expand to EN parity (+22 lines)
11. `advanced/index.ru.md`: expand to EN parity (+69 lines)
12. `ide-plugins-guide.ru.md`: create RU translation
13. Compliance docs: create RU versions as needed

---

## 10. Full File Inventory

| # | File | Lines | Lang | Pair Status |
|---|------|-------|------|-------------|
| 1 | `README.md` | ~350 | EN | NO RU |
| 2 | `CONTRIBUTING.md` | ~120 | EN | NO RU |
| 3 | `AGENTS.md` | ~685 | RU | NO EN |
| 4 | `docs/index.en.md` | 203 | EN | ✅ RU (201) |
| 5 | `docs/index.ru.md` | 201 | RU | ✅ EN (203) |
| 6 | `docs/comparison.en.md` | 114 | EN | ✅ RU (113) |
| 7 | `docs/comparison.ru.md` | 113 | RU | ✅ EN (114) |
| 8 | `docs/comparison.md` | 57 | EN | ⚠️ ORPHAN — different doc |
| 9 | `docs/tags.en.md` | 3 | EN | ✅ RU (3) |
| 10 | `docs/tags.ru.md` | 3 | RU | ✅ EN (3) |
| 11 | `docs/manual-steps.md` | 23 | EN | NO RU |
| 12 | `docs/VERSIONS.md` | 129 | EN | NO RU |
| 13 | `docs/advanced/index.en.md` | 344 | EN | ✅ RU (275) |
| 14 | `docs/advanced/index.ru.md` | 275 | RU | ✅ EN (344) |
| 15 | `docs/architecture/index.en.md` | 248 | EN | ✅ RU (252) |
| 16 | `docs/architecture/index.ru.md` | 252 | RU | ✅ EN (248) |
| 17 | `docs/architecture/agent-system.md` | 200 | EN ⚠️ | NO .en suffix |
| 18 | `docs/architecture/agent-system.ru.md` | 200 | RU | ✅ EN (200) |
| 19 | `docs/architecture/adr/*.md` | ~73 | EN | NO RU |
| 20 | `docs/changelog/index.md` | 2 | EN ⚠️ | NO .en suffix |
| 21 | `docs/changelog/index.ru.md` | 5 | RU | ✅ EN (2) |
| 22 | `docs/changelog/posts/*.md` | ~200 | EN | NO RU |
| 23 | `docs/compliance/iso27001-mapping.md` | 102 | EN | NO RU |
| 24 | `docs/compliance/soc2-checklist.md` | 80 | EN | NO RU |
| 25 | `docs/contributing/index.en.md` | 150 | EN | ✅ RU (153) |
| 26 | `docs/contributing/index.ru.md` | 153 | RU | ✅ EN (150) |
| 27 | `docs/faq/index.en.md` | 306 | EN | ✅ RU (296) |
| 28 | `docs/faq/index.ru.md` | 296 | RU | ✅ EN (306) |
| 29 | `docs/getting-started/index.en.md` | 148 | EN | ✅ RU (139) |
| 30 | `docs/getting-started/index.ru.md` | 139 | RU | ✅ EN (148) |
| 31 | `docs/guides/airgap-offline.en.md` | 101 | EN | ✅ RU (101) |
| 32 | `docs/guides/airgap-offline.ru.md` | 101 | RU | ✅ EN (101) |
| 33 | `docs/guides/deployment-profiles.en.md` | 108 | EN | ✅ RU (108) |
| 34 | `docs/guides/deployment-profiles.ru.md` | 108 | RU | ✅ EN (108) |
| 35 | `docs/guides/team-setup.md` | 249 | EN ⚠️ | NO .en suffix |
| 36 | `docs/guides/team-setup.ru.md` | 249 | RU | ✅ EN (249) |
| 37 | `docs/guides/ai-gateway-proxy.md` | 70 | EN | NO RU |
| 38 | `docs/guides/ide-plugins-guide.md` | 37 | EN | NO RU |
| 39 | `docs/guides/provider-setup.md` | 55 | EN | NO RU |
| 40 | `docs/reference/index.en.md` | 277 | EN | ✅ RU (271) |
| 41 | `docs/reference/index.ru.md` | 271 | RU | ✅ EN (277) |
| 42 | `docs/reference/governance.en.md` | 143 | EN | ✅ RU (143) |
| 43 | `docs/reference/governance.ru.md` | 143 | RU | ✅ EN (143) |
| 44 | `docs/reference/mcp-lsp-plugins.en.md` | 174 | EN | ✅ RU (152) |
| 45 | `docs/reference/mcp-lsp-plugins.ru.md` | 152 | RU | ✅ EN (174) |
| 46 | `docs/reference/security-compliance.en.md` | 120 | EN | ✅ RU (120) |
| 47 | `docs/reference/security-compliance.ru.md` | 120 | RU | ✅ EN (120) |
| 48 | `docs/user-guide/index.en.md` | 391 | EN | ✅ RU (371) |
| 49 | `docs/user-guide/index.ru.md` | 371 | RU | ✅ EN (391) |
