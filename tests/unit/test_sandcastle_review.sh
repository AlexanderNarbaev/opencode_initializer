#!/usr/bin/env bash
# ============================================================================
# ISOLATED Unit Test for `dev sandcastle review` + .github/workflows/sandcastle-review.yml
# Target: dev.sh (cmd_sandcastle) + .github/workflows/sandcastle-review.yml
# Session: ses_sandcastle_review_test
#
# Tests:
#   (a) dev.sh syntax + sandcastle command wiring
#   (b) Defensive guards (node / sandcastle pkg / docker-podman absent → exit 0)
#   (c) Review flow primitives (createSandbox, hooks, timeouts, implement→review)
#   (d) CI workflow presence + structure (workflow_dispatch, jobs, checkout)
#
# Isolation: grep-based structural assertions (no live sandcastle/network run)
# ============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
DEV="$PROJECT_DIR/dev.sh"
WF="$PROJECT_DIR/.github/workflows/sandcastle-review.yml"

assert() {
  local d="$1" c="$2"
  if (eval "$c") &>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $d" >&2
  fi
}

echo "=== Testing dev sandcastle review + CI workflow ==="

# ── (a) dev.sh syntax + command wiring ─────────────────────────────────────
assert "dev.sh exists" "[ -f '$DEV' ]"
assert "dev.sh syntax clean" "bash -n '$DEV'"
assert "has cmd_sandcastle function" "grep -q 'cmd_sandcastle()' '$DEV'"
assert "has _sandcastle_review function" "grep -q '_sandcastle_review()' '$DEV'"
assert "has _sandcastle_status function" "grep -q '_sandcastle_status()' '$DEV'"
assert "has sandcastle case branch" "grep -q 'sandcastle) cmd_sandcastle' '$DEV'"
assert "usage mentions sandcastle review" "grep -q 'sandcastle review' '$DEV'"

# ── (b) Defensive guards (never hard-fail) ─────────────────────────────────
assert "guards missing node" "grep -q 'Node.js not found' '$DEV'"
assert "guards missing git" "grep -q 'git not found' '$DEV'"
assert "guards missing sandcastle pkg" "grep -q '@ai-hero/sandcastle not installed' '$DEV'"
assert "guards no docker/podman" "grep -q 'Docker nor Podman' '$DEV'"
assert "provider detect has no-sandbox fallback" "grep -q 'no-sandbox' '$DEV'"

# ── (c) Review flow primitives ─────────────────────────────────────────────
assert "writes review-main.ts" "grep -q 'review-main.ts' '$DEV'"
assert "writes review.prompt.md" "grep -q 'review.prompt.md' '$DEV'"
assert "uses createSandbox" "grep -q 'createSandbox' '$DEV'"
assert "implements then reviews" "grep -q 'Step 2: review' '$DEV'"
assert "sets lifecycle hooks" "grep -q 'onSandboxReady' '$DEV'"
assert "sets timeouts" "grep -q 'gitSetupMs' '$DEV'"
assert "runs via npx tsx" "grep -q 'npx --yes tsx' '$DEV'"

# ── (d) CI workflow ────────────────────────────────────────────────────────
assert "workflow file exists" "[ -f '$WF' ]"
assert "workflow has name" "grep -q '^name:' '$WF'"
assert "workflow has workflow_dispatch" "grep -q 'workflow_dispatch' '$WF'"
assert "workflow has pull_request" "grep -q 'pull_request' '$WF'"
assert "workflow has jobs" "grep -q '^jobs:' '$WF'"
assert "workflow has steps" "grep -q 'steps:' '$WF'"
assert "workflow calls dev sandcastle review" "grep -q 'sandcastle review' '$WF'"
assert "workflow uses actions/checkout" "grep -q 'actions/checkout@v4' '$WF'"
assert "workflow sets node 24" "grep -q \"node-version: '24'\" '$WF'"

echo "test_sandcastle_review: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
