#!/usr/bin/env bash
# scripts/sign-release.sh — Sign release artifacts with cosign
# Uses keyless signing via Sigstore Fulcio
set -euo pipefail

VERSION="${1:?Usage: sign-release.sh <version>}"

echo "Signing release artifacts for v${VERSION}..."

# Check if cosign is available
if ! command -v cosign &>/dev/null; then
  echo "Error: cosign not installed"
  echo "Install: brew install cosign"
  exit 1
fi

# Sign the release archive
ARCHIVE="opencode_initializer-${VERSION}.tar.gz"
if [ -f "$ARCHIVE" ]; then
  echo "Signing ${ARCHIVE}..."
  cosign sign-blob \
    --yes \
    --output-signature "${ARCHIVE}.sig" \
    --output-certificate "${ARCHIVE}.pem" \
    "$ARCHIVE"
  echo "Signature: ${ARCHIVE}.sig"
  echo "Certificate: ${ARCHIVE}.pem"
else
  echo "Warning: ${ARCHIVE} not found"
fi

# Sign the SBOM
SBOM="sbom-${VERSION}.spdx.json"
if [ -f "$SBOM" ]; then
  echo "Signing ${SBOM}..."
  cosign sign-blob \
    --yes \
    --output-signature "${SBOM}.sig" \
    --output-certificate "${SBOM}.pem" \
    "$SBOM"
  echo "Signature: ${SBOM}.sig"
  echo "Certificate: ${SBOM}.pem"
else
  echo "Warning: ${SBOM} not found"
fi

# Verify signatures
echo ""
echo "Verifying signatures..."
for sig in *.sig; do
  if [ -f "$sig" ]; then
    artifact="${sig%.sig}"
    echo "Verifying ${artifact}..."
    cosign verify-blob \
      --certificate "${artifact}.pem" \
      --signature "$sig" \
      --certificate-identity-regexp ".*" \
      --certificate-oidc-issuer-regexp ".*" \
      "$artifact" && echo "  ✓ Verified" || echo "  ✗ Verification failed"
  fi
done

echo ""
echo "Release signing complete!"
