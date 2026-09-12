#!/usr/bin/env bash
# scripts/post-release.sh — Post-release hook for semantic-release
set -euo pipefail

VERSION="${1:?Usage: post-release.sh <version>}"

echo "=== Post-release: v${VERSION} ==="

# Sign release artifacts if cosign is available
if command -v cosign &>/dev/null; then
  echo "Signing release artifacts..."
  bash scripts/sign-release.sh "$VERSION"
else
  echo "cosign not installed, skipping signing"
fi

# Update mirrors if configured
if [ "${MIRROR_UPDATE:-false}" = "true" ]; then
  echo "Updating mirrors..."
  # Add mirror sync commands here
fi

echo "Post-release complete!"
