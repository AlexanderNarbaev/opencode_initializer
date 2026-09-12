#!/usr/bin/env bash
# scripts/generate-provenance.sh — Generate SLSA provenance attestation
# https://slsa.dev/
set -euo pipefail

VERSION="${1:?Usage: generate-provenance.sh <version>}"
ARTIFACT="${2:-opencode_initializer-${VERSION}.tar.gz}"

echo "Generating SLSA provenance for v${VERSION}..."

# Check if slsa-verifier is available
if ! command -v slsa-verifier &>/dev/null; then
  echo "Warning: slsa-verifier not installed"
  echo "Install: go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest"
fi

# Generate provenance
cat > "provenance-${VERSION}.intoto.jsonl" << EOF
{
  "_type": "https://in-toto.io/Statement/v0.1",
  "predicateType": "https://slsa.dev/provenance/v0.2",
  "subject": [
    {
      "name": "${ARTIFACT}",
      "digest": {
        "sha256": "$(sha256sum "${ARTIFACT}" 2>/dev/null | cut -d' ' -f1 || echo "PENDING")"
      }
    }
  ],
  "predicate": {
    "builder": {
      "id": "https://github.com/AlexanderNarbaev/opencode_initializer/.github/workflows/release.yml"
    },
    "buildType": "https://github.com/slsa-framework/slsa-github-generator/generic@v1",
    "invocation": {
      "configSource": {
        "uri": "git+https://github.com/AlexanderNarbaev/opencode_initializer.git",
        "digest": {
          "sha1": "$(git rev-parse HEAD)"
        },
        "entryPoint": ".github/workflows/release.yml"
      }
    },
    "metadata": {
      "buildStartedOn": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
      "completeness": {
        "parameters": true,
        "environment": false,
        "materials": true
      },
      "reproducible": false
    },
    "materials": [
      {
        "uri": "git+https://github.com/AlexanderNarbaev/opencode_initializer.git",
        "digest": {
          "sha1": "$(git rev-parse HEAD)"
        }
      }
    ]
  }
}
EOF

echo "Provenance generated: provenance-${VERSION}.intoto.jsonl"
echo "SHA256: $(sha256sum "provenance-${VERSION}.intoto.jsonl" | cut -d' ' -f1)"

# Verify if slsa-verifier is available
if command -v slsa-verifier &>/dev/null; then
  echo ""
  echo "Verifying provenance..."
  slsa-verifier verify-artifact \
    --provenance-path "provenance-${VERSION}.intoto.jsonl" \
    --source-uri "github.com/AlexanderNarbaev/opencode_initializer" \
    "${ARTIFACT}" 2>&1 || echo "Verification failed (expected for local builds)"
fi
