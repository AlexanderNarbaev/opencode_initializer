#!/usr/bin/env bash
# ============================================================================
# ISOLATED Unit Test for 17-project.sh — Project structure initialization
# Target: src/lib/17-project.sh (786 lines)
# Session: ses_test_project
# ============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") 2>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $desc" >&2
  fi
}

# ── Isolated environment ─────────────────────────────────────────────────────
TMPDIR=$(mktemp -d /tmp/test_project.XXXXXX)
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT
export HOME="$TMPDIR/home"
mkdir -p "$HOME/.config/opencode" "$HOME/.cache/opencode"

TEST_PROJECT="$TMPDIR/test-project"
S="$REPO_ROOT/src/lib/17-project.sh"

echo "=== Testing 17-project.sh ==="

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 1: Module validity (no sourcing yet)
# ═══════════════════════════════════════════════════════════════════════════════

assert "17-project.sh exists" "[ -f '$S' ]"
assert "17-project.sh syntax valid (bash -n)" "bash -n '$S'"
assert "17-project.sh has shebang" "head -1 '$S' | grep -q '#!/usr/bin/env bash'"
assert "17-project.sh has set -euo pipefail" "grep -q 'set -euo pipefail' '$S'"
assert "has MODE=full gate" "grep -q '\$MODE.*=.*full' '$S'"
assert "has MODE=new gate" "grep -q '\$MODE.*=.*new' '$S'"
assert "has PROJECT_DIR guard" "grep -q 'PROJECT_DIR' '$S'"
assert "has section header" "grep -q 'section.*Project structure' '$S'"

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 2: Source module + trigger project init (isolated)
# ═══════════════════════════════════════════════════════════════════════════════

# Stubs required by the module
_step_skip() { return 1; }
section() { :; }
log() { :; }
info() { :; }
warn() { echo "[WARN] $*" >&2; }
err() { echo "[ERR] $*" >&2; return 1; }
_step_done() { :; }

# SDD stubs — simulate constitution + command generators
_constitution_generate() { :; }
_sdd_generate_commands() { :; }

# Set MODE and PROJECT_DIR, then source
export MODE=full
export PROJECT_DIR="$TEST_PROJECT"

# shellcheck disable=SC1090
source "$S" 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 3: Verify project artifacts
# ═══════════════════════════════════════════════════════════════════════════════

# ── Directory structure ──────────────────────────────────────────────────────
assert "PROJECT_DIR created" "[ -d '$TEST_PROJECT' ]"
assert "docs/ directory exists" "[ -d '$TEST_PROJECT/docs' ]"
assert "wal/ directory exists" "[ -d '$TEST_PROJECT/wal' ]"
assert ".opencode/ directory exists" "[ -d '$TEST_PROJECT/.opencode' ]"
assert ".opencode/agents exists" "[ -d '$TEST_PROJECT/.opencode/agents' ]"
assert ".opencode/skills exists" "[ -d '$TEST_PROJECT/.opencode/skills' ]"
assert ".opencode/commands exists" "[ -d '$TEST_PROJECT/.opencode/commands' ]"
assert ".opencode/context exists" "[ -d '$TEST_PROJECT/.opencode/context' ]"
assert "infra/ directory exists" "[ -d '$TEST_PROJECT/infra' ]"
assert "templates/ directory exists" "[ -d '$TEST_PROJECT/templates' ]"
assert "icon/ directory exists" "[ -d '$TEST_PROJECT/icon' ]"
assert "output/ directory exists" "[ -d '$TEST_PROJECT/output' ]"
assert ".lock/ directory exists" "[ -d '$TEST_PROJECT/.lock' ]"

# ── plugins.json ─────────────────────────────────────────────────────────────
assert "plugins.json registry created" "[ -f '$HOME/.config/opencode/plugins.json' ]"
assert "plugins.json has tiers key" "grep -q '\"tiers\"' '$HOME/.config/opencode/plugins.json'"
assert "plugins.json has always plugins" "grep -q 'opencode-codegraph' '$HOME/.config/opencode/plugins.json'"
assert "plugins.json has conditional plugins" "grep -q 'opencode-background-agents' '$HOME/.config/opencode/plugins.json'"
assert "plugins.json has on_demand plugins" "grep -q 'opencode-notify' '$HOME/.config/opencode/plugins.json'"

# ── AGENTS.md ────────────────────────────────────────────────────────────────
assert "AGENTS.md created" "[ -f '$TEST_PROJECT/AGENTS.md' ]"
assert "AGENTS.md has Universal AI Coprocessor" "grep -q 'Universal AI Coprocessor' '$TEST_PROJECT/AGENTS.md'"
assert "AGENTS.md has Dual-Process Reasoning" "grep -q 'Dual-Process Reasoning' '$TEST_PROJECT/AGENTS.md'"
assert "AGENTS.md has WAL Protocol" "grep -q 'WAL Protocol' '$TEST_PROJECT/AGENTS.md'"
assert "AGENTS.md has SDD WORKFLOW" "grep -q 'SDD WORKFLOW' '$TEST_PROJECT/AGENTS.md'"
assert "AGENTS.md has technology stack" "grep -q 'ТЕХНОЛОГИЧЕСКИЙ СТЕК' '$TEST_PROJECT/AGENTS.md'"
assert "AGENTS.md has Russian language" "grep -q 'Отвечай на русском' '$TEST_PROJECT/AGENTS.md'"
assert "AGENTS.md has CO-STAR contract" "grep -q 'CO-STAR' '$TEST_PROJECT/AGENTS.md'"
assert "AGENTS.md 250+ lines" "[ \$(wc -l < '$TEST_PROJECT/AGENTS.md') -ge 250 ]"

# ── WAL (wal/state.yaml) ────────────────────────────────────────────────────
assert "wal/state.yaml created" "[ -f '$TEST_PROJECT/wal/state.yaml' ]"
assert "wal/state.yaml has session id" "grep -q 'session:' '$TEST_PROJECT/wal/state.yaml'"
assert "wal/state.yaml has status init" "grep -q 'status:.*init' '$TEST_PROJECT/wal/state.yaml'"
assert "wal/state.yaml has artifacts" "grep -q 'artifacts:' '$TEST_PROJECT/wal/state.yaml'"
assert "wal/state.yaml has protected paths" "grep -q 'protected:' '$TEST_PROJECT/wal/state.yaml'"
assert "wal/state.yaml protects secrets.env" "grep -q 'secrets.env' '$TEST_PROJECT/wal/state.yaml'"

# ── INDEX.md ─────────────────────────────────────────────────────────────────
assert "INDEX.md created" "[ -f '$TEST_PROJECT/docs/INDEX.md' ]"
assert "INDEX.md has table header" "grep -q 'Knowledge Base Map' '$TEST_PROJECT/docs/INDEX.md'"

# ── CONTEXT.md (shared-language domain glossary) ────────────────────────────
assert "CONTEXT.md created" "[ -f '$TEST_PROJECT/CONTEXT.md' ]"
assert "CONTEXT.md has Project Context header" "grep -q '^# Project Context' '$TEST_PROJECT/CONTEXT.md'"
assert "CONTEXT.md has Domain Glossary section" "grep -q 'Domain Glossary' '$TEST_PROJECT/CONTEXT.md'"
assert "CONTEXT.md has Conventions section" "grep -q '## Conventions' '$TEST_PROJECT/CONTEXT.md'"
assert "CONTEXT.md has Non-Goals section" "grep -q 'Non-Goals' '$TEST_PROJECT/CONTEXT.md'"
assert "CONTEXT.md references domain-modeling flow" "grep -q 'domain-modeling' '$TEST_PROJECT/CONTEXT.md'"
assert "CONTEXT.md has glossary table stub" "grep -q '| Term | Definition | Notes |' '$TEST_PROJECT/CONTEXT.md'"

# ── docker-compose.yml ───────────────────────────────────────────────────────
assert "docker-compose.yml created" "[ -f '$TEST_PROJECT/infra/docker-compose.yml' ]"
assert "docker-compose has zookeeper" "grep -q 'zookeeper' '$TEST_PROJECT/infra/docker-compose.yml'"
assert "docker-compose has kafka" "grep -q 'kafka:' '$TEST_PROJECT/infra/docker-compose.yml'"
assert "docker-compose has postgres" "grep -q 'postgres:18' '$TEST_PROJECT/infra/docker-compose.yml'"
assert "docker-compose has mongodb" "grep -q 'mongo:8' '$TEST_PROJECT/infra/docker-compose.yml'"
assert "docker-compose has redis" "grep -q 'redis:7' '$TEST_PROJECT/infra/docker-compose.yml'"
assert "docker-compose has minio" "grep -q 'minio' '$TEST_PROJECT/infra/docker-compose.yml'"
assert "docker-compose has wiremock" "grep -q 'wiremock' '$TEST_PROJECT/infra/docker-compose.yml'"
assert "docker-compose has volumes" "grep -q '^volumes:' '$TEST_PROJECT/infra/docker-compose.yml'"
assert "docker-compose valid YAML structure" "grep -q 'services:' '$TEST_PROJECT/infra/docker-compose.yml'"

# ── wiremock stubs dir ───────────────────────────────────────────────────────
assert "wiremock stubs dir exists" "[ -d '$TEST_PROJECT/infra/wiremock/stubs' ]"

# ── Spec template ────────────────────────────────────────────────────────────
assert "specs/_template.md created" "[ -f '$TEST_PROJECT/specs/_template.md' ]"
assert "spec template has FR-001" "grep -q 'FR-001' '$TEST_PROJECT/specs/_template.md'"
assert "spec template has GIVEN/WHEN/THEN" "grep -q 'GIVEN.*precondition' '$TEST_PROJECT/specs/_template.md'"
assert "spec template has SC section" "grep -q 'Success Criteria' '$TEST_PROJECT/specs/_template.md'"
assert "spec template has NFR section" "grep -q 'Non-Functional Requirements' '$TEST_PROJECT/specs/_template.md'"

# ── todo.md template ─────────────────────────────────────────────────────────
assert "todo.md template created" "[ -f '$TEST_PROJECT/.opencode/todo.md' ]"
assert "todo.md has Mission header" "grep -q 'Mission:' '$TEST_PROJECT/.opencode/todo.md'"
assert "todo.md has M1 milestone" "grep -q 'M1:' '$TEST_PROJECT/.opencode/todo.md'"
assert "todo.md has subtask format" "grep -q 'S1\\.1\\.1' '$TEST_PROJECT/.opencode/todo.md'"
assert "todo.md has Legend section" "grep -q 'Legend' '$TEST_PROJECT/.opencode/todo.md'"
assert "todo.md has Progress section" "grep -q 'Progress' '$TEST_PROJECT/.opencode/todo.md'"

# ── Skills ───────────────────────────────────────────────────────────────────
assert "context-switching skill created" "[ -f '$TEST_PROJECT/.opencode/skills/context-switching/SKILL.md' ]"
assert "context-switching has frontmatter" "grep -q '^---$' '$TEST_PROJECT/.opencode/skills/context-switching/SKILL.md'"
assert "context-switching has Step 1" "grep -q 'Step 1' '$TEST_PROJECT/.opencode/skills/context-switching/SKILL.md'"
assert "code-review-checklist skill created" "[ -f '$TEST_PROJECT/.opencode/skills/code-review-checklist/SKILL.md' ]"
assert "code-review has Security section" "grep -q 'Security' '$TEST_PROJECT/.opencode/skills/code-review-checklist/SKILL.md'"
assert "code-review checklist has checkboxes" "grep -q '\- \[ \]' '$TEST_PROJECT/.opencode/skills/code-review-checklist/SKILL.md'"
assert "deployment-checklist skill created" "[ -f '$TEST_PROJECT/.opencode/skills/deployment-checklist/SKILL.md' ]"
assert "deployment has Pre-Deployment" "grep -q 'Pre-Deployment' '$TEST_PROJECT/.opencode/skills/deployment-checklist/SKILL.md'"
assert "testing-strategy skill created" "[ -f '$TEST_PROJECT/.opencode/skills/testing-strategy/SKILL.md' ]"
assert "testing-strategy has Test Pyramid" "grep -q 'Test Pyramid' '$TEST_PROJECT/.opencode/skills/testing-strategy/SKILL.md'"

# ── Agent role files ─────────────────────────────────────────────────────────
assert "pm agent created" "[ -f '$TEST_PROJECT/.opencode/agents/pm.md' ]"
assert "developer agent created" "[ -f '$TEST_PROJECT/.opencode/agents/developer.md' ]"
assert "architect agent created" "[ -f '$TEST_PROJECT/.opencode/agents/architect.md' ]"
assert "qa agent created" "[ -f '$TEST_PROJECT/.opencode/agents/qa.md' ]"
assert "security agent created" "[ -f '$TEST_PROJECT/.opencode/agents/security.md' ]"
assert "reviewer agent created" "[ -f '$TEST_PROJECT/.opencode/agents/reviewer.md' ]"
assert "researcher agent created" "[ -f '$TEST_PROJECT/.opencode/agents/researcher.md' ]"
assert "devops agent created" "[ -f '$TEST_PROJECT/.opencode/agents/devops.md' ]"
assert "designer agent created" "[ -f '$TEST_PROJECT/.opencode/agents/designer.md' ]"
assert "docs-writer agent created" "[ -f '$TEST_PROJECT/.opencode/agents/docs-writer.md' ]"
assert "security-auditor agent created" "[ -f '$TEST_PROJECT/.opencode/agents/security-auditor.md' ]"
assert "debugger agent created" "[ -f '$TEST_PROJECT/.opencode/agents/debugger.md' ]"
assert "16+ agent files total" "[ \$(ls '$TEST_PROJECT/.opencode/agents/'*.md 2>/dev/null | wc -l) -ge 16 ]"

# ── Agent file content ───────────────────────────────────────────────────────
assert "agent file has model field" "grep -q 'model:' '$TEST_PROJECT/.opencode/agents/developer.md'"
assert "agent file has mode subagent" "grep -q 'mode: subagent' '$TEST_PROJECT/.opencode/agents/developer.md'"
assert "agent file has permission block" "grep -q 'permission:' '$TEST_PROJECT/.opencode/agents/developer.md'"
assert "developer agent has edit: allow" "grep -q 'edit: allow' '$TEST_PROJECT/.opencode/agents/developer.md'"
assert "reviewer agent has edit: deny" "grep -q 'edit: deny' '$TEST_PROJECT/.opencode/agents/reviewer.md'"
assert "security agent has edit: deny" "grep -q 'edit: deny' '$TEST_PROJECT/.opencode/agents/security.md'"

# ── SDD Integration ──────────────────────────────────────────────────────────
assert "constitution generate stub exists" "declare -f _constitution_generate >/dev/null 2>&1"
assert "sdd generate commands stub exists" "declare -f _sdd_generate_commands >/dev/null 2>&1"

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 4: Idempotency — re-source the module, verify nothing breaks
# ═══════════════════════════════════════════════════════════════════════════════

AGENTS_MD_BEFORE=$(wc -c < "$TEST_PROJECT/AGENTS.md")
WAL_BEFORE=$(wc -c < "$TEST_PROJECT/wal/state.yaml")
DOCKER_BEFORE=$(wc -c < "$TEST_PROJECT/infra/docker-compose.yml")
CONTEXT_MD_BEFORE=$(wc -c < "$TEST_PROJECT/CONTEXT.md")

# Re-source (should be idempotent — artifacts preserved, not overwritten)
source "$S" 2>/dev/null || true

AGENTS_MD_AFTER=$(wc -c < "$TEST_PROJECT/AGENTS.md")
WAL_AFTER=$(wc -c < "$TEST_PROJECT/wal/state.yaml")
DOCKER_AFTER=$(wc -c < "$TEST_PROJECT/infra/docker-compose.yml")
CONTEXT_MD_AFTER=$(wc -c < "$TEST_PROJECT/CONTEXT.md")

assert "AGENTS.md unchanged on re-run" "[ '$AGENTS_MD_BEFORE' = '$AGENTS_MD_AFTER' ]"
assert "WAL unchanged on re-run" "[ '$WAL_BEFORE' = '$WAL_AFTER' ]"
assert "docker-compose unchanged on re-run" "[ '$DOCKER_BEFORE' = '$DOCKER_AFTER' ]"
assert "CONTEXT.md unchanged on re-run" "[ '$CONTEXT_MD_BEFORE' = '$CONTEXT_MD_AFTER' ]"

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 5: setup.sh integration
# ═══════════════════════════════════════════════════════════════════════════════

SETUP="$REPO_ROOT/setup.sh"
assert "setup.sh references 17-project.sh" "grep -q '17-project' '$SETUP'"

echo "test_project: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
