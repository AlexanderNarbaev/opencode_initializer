#!/usr/bin/env bash
# scripts/pre-release.sh — Pre-release hook for semantic-release
set -euo pipefail

VERSION="${1:?Usage: pre-release.sh <version>}"

echo "=== Pre-release: v${VERSION} ==="

# Update version in source files
echo "Updating version in source files..."
sed -i "s/SCRIPT_VERSION=\"\${SCRIPT_VERSION:-v[^\"]*}\"/SCRIPT_VERSION=\"\${SCRIPT_VERSION:-v${VERSION}}\"/" src/lib/00-core.sh

# Update package.json
if [ -f package.json ]; then
  sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"${VERSION}\"/" package.json
fi

# Generate SBOM
echo "Generating SBOM..."
bash scripts/generate-sbom.sh "$VERSION"

# Run tests
echo "Running tests..."
bash tests/unit/test_core.sh

echo "Pre-release checks passed!"
