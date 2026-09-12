#!/usr/bin/env bash
# scripts/generate-sbom.sh — Generate SBOM (Software Bill of Materials)
# SPDX format for supply chain security
set -euo pipefail

VERSION="${1:-$(grep -m1 'SCRIPT_VERSION' src/lib/00-core.sh | cut -d'"' -f2)}"
OUTPUT="${2:-sbom-$(date +%Y%m%d).spdx.json}"

echo "Generating SBOM for opencode_initializer ${VERSION}..."

# Check if syft is available
if command -v syft &>/dev/null; then
  echo "Using syft for SBOM generation..."
  syft dir:. \
    --name "opencode-initializer" \
    --version "$VERSION" \
    --output spdx-json="$OUTPUT"
else
  echo "syft not found, generating manual SBOM..."

  cat > "$OUTPUT" << EOF
{
  "spdxVersion": "SPDX-2.3",
  "dataLicense": "CC0-1.0",
  "SPDXID": "SPDXRef-DOCUMENT",
  "name": "opencode-initializer-${VERSION}",
  "documentNamespace": "https://github.com/AlexanderNarbaev/opencode_initializer/sbom/${VERSION}",
  "creationInfo": {
    "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "creators": [
      "Tool: opencode-init-sbom-generator",
      "Organization: AlexanderNarbaev"
    ]
  },
  "packages": [
    {
      "SPDXID": "SPDXRef-Package",
      "name": "opencode-initializer",
      "versionInfo": "${VERSION}",
      "downloadLocation": "https://github.com/AlexanderNarbaev/opencode_initializer/archive/refs/tags/v${VERSION}.tar.gz",
      "filesAnalyzed": true,
      "licenseConcluded": "MIT",
      "licenseDeclared": "MIT",
      "copyrightText": "Copyright (c) 2026 Alexander Narbaev",
      "supplier": "Organization: AlexanderNarbaev"
    }
  ],
  "relationships": [
    {
      "spdxElementId": "SPDXRef-DOCUMENT",
      "relationshipType": "DESCRIBES",
      "relatedSpdxElement": "SPDXRef-Package"
    }
  ]
}
EOF
fi

echo "SBOM generated: ${OUTPUT}"
echo "SHA256: $(sha256sum "$OUTPUT" | cut -d' ' -f1)"
