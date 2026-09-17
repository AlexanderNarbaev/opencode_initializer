#!/usr/bin/env bash
# Container test script for opencode_initializer
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Testing container builds..."

# Test Dockerfile syntax
echo "1. Checking Dockerfile syntax..."
if docker build --check "$PROJECT_DIR" 2>/dev/null; then
  echo "   ✓ Dockerfile syntax OK"
else
  echo "   ✗ Dockerfile syntax error"
  exit 1
fi

# Test docker-compose syntax
echo "2. Checking docker-compose.yml syntax..."
if docker compose config --quiet 2>/dev/null; then
  echo "   ✓ docker-compose.yml syntax OK"
else
  echo "   ✗ docker-compose.yml syntax error"
  exit 1
fi

# Test build (dry-run)
echo "3. Testing build (dry-run)..."
if docker build --dry-run "$PROJECT_DIR" 2>/dev/null; then
  echo "   ✓ Build dry-run OK"
else
  echo "   ✗ Build dry-run failed"
  exit 1
fi

echo ""
echo "All container tests passed!"
