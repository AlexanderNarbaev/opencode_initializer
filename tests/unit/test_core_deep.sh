#!/usr/bin/env bash
# tests/unit/test_core_deep.sh — Deep tests for 00-core.sh
# Actually sources and tests module functionality
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source dependencies
source "$SCRIPT_DIR/src/lib/helpers.sh" 2>/dev/null || true
export SKIP_MIRROR_RESOLVE=true  # Skip network calls
source "$SCRIPT_DIR/src/lib/00-core.sh" 2>/dev/null || true

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo -e "  \033[32m✓\033[0m $1"; }
fail() { FAIL=$((FAIL + 1)); echo -e "  \033[31m✗\033[0m $1"; }

echo "=== Deep Tests for 00-core.sh ==="

# Test: SCRIPT_VERSION is set
if [ -n "${SCRIPT_VERSION:-}" ]; then
  pass "SCRIPT_VERSION is set: $SCRIPT_VERSION"
else
  fail "SCRIPT_VERSION is not set"
fi

# Test: Architecture detection works
if [ -n "${ARCH:-}" ]; then
  pass "ARCH detected: $ARCH"
else
  fail "ARCH not detected"
fi

# Test: Package manager detection works
if [ -n "${PKG_MANAGER:-}" ]; then
  pass "PKG_MANAGER detected: $PKG_MANAGER"
else
  fail "PKG_MANAGER not detected"
fi

# Test: DL_CACHE is set
if [ -n "${DL_CACHE:-}" ]; then
  pass "DL_CACHE is set: $DL_CACHE"
else
  fail "DL_CACHE is not set"
fi

# Test: PROGRESS file path is set
if [ -n "${PROGRESS:-}" ]; then
  pass "PROGRESS is set: $PROGRESS"
else
  fail "PROGRESS is not set"
fi

# Test: _step_skip function exists
if type _step_skip &>/dev/null; then
  pass "_step_skip function exists"
else
  fail "_step_skip function missing"
fi

# Test: _wal_checkpoint function exists
if type _wal_checkpoint &>/dev/null; then
  pass "_wal_checkpoint function exists"
else
  fail "_wal_checkpoint function missing"
fi

# Test: Mirror variables are set (with SKIP_MIRROR_RESOLVE)
if [ -n "${GITHUB_MIRROR:-}" ]; then
  pass "GITHUB_MIRROR is set: $GITHUB_MIRROR"
else
  fail "GITHUB_MIRROR is not set"
fi

if [ -n "${NPM_REGISTRY:-}" ]; then
  pass "NPM_REGISTRY is set: $NPM_REGISTRY"
else
  fail "NPM_REGISTRY is not set"
fi

if [ -n "${PYPI_MIRROR:-}" ]; then
  pass "PYPI_MIRROR is set: $PYPI_MIRROR"
else
  fail "PYPI_MIRROR is not set"
fi

if [ -n "${DOCKER_MIRROR:-}" ]; then
  pass "DOCKER_MIRROR is set: $DOCKER_MIRROR"
else
  fail "DOCKER_MIRROR is not set"
fi

# Test: Environment exports
if [ -n "${NPM_CONFIG_REGISTRY:-}" ]; then
  pass "NPM_CONFIG_REGISTRY exported: $NPM_CONFIG_REGISTRY"
else
  fail "NPM_CONFIG_REGISTRY not exported"
fi

if [ -n "${PIP_INDEX_URL:-}" ]; then
  pass "PIP_INDEX_URL exported: $PIP_INDEX_URL"
else
  fail "PIP_INDEX_URL not exported"
fi

# Test: _step_done function exists
if type _step_done &>/dev/null; then
  pass "_step_done function exists"
else
  fail "_step_done function missing"
fi

echo ""
echo "━━━ Results: $PASS passed, $FAIL failed ━━━"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
