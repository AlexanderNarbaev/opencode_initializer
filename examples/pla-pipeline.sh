#!/usr/bin/env bash
# examples/pla-pipeline.sh — Example: PLA Pipeline
# Demonstrates how to use modules 101-110

set -euo pipefail

echo "=== PLA Pipeline Example ==="

# Source the modules
source src/lib/helpers.sh
source src/lib/101-pla-orchestrator.sh
source src/lib/102-pla-extract.sh
source src/lib/103-pla-analyze.sh
source src/lib/104-pla-verify.sh
source src/lib/105-pla-synthesize.sh
source src/lib/106-pla-coordinate.sh
source src/lib/107-rag-hybrid.sh
source src/lib/108-rag-bm25.sh
source src/lib/109-rag-vector.sh
source src/lib/110-rag-fusion.sh

# 1. Create a PLA pipeline
echo "1. Creating PLA pipeline..."
mkdir -p ~/.config/opencode/pla
cat > ~/.config/opencode/pla/example-pipeline.yaml <<'EOF'
name: example-pipeline
version: 1.0.0
description: Example PLA pipeline
layers:
  - type: extract
  - type: analyze
  - type: verify
  - type: synthesize
  - type: coordinate
EOF

# 2. List PLA pipelines
echo "2. Listing PLA pipelines..."
cmd_pla list 2>/dev/null

# 3. Run PLA pipeline
echo "3. Running PLA pipeline..."
cmd_pla run "example-pipeline" "test input" 2>/dev/null

# 4. Extract data
echo "4. Extracting data..."
echo "test data" > /tmp/test-data.txt
cmd_pla_extract file /tmp/test-data.txt 2>/dev/null

# 5. Analyze code
echo "5. Analyzing code..."
cmd_pla_analyze code /tmp/test-data.txt 2>/dev/null

# 6. Verify format
echo "6. Verifying format..."
cmd_pla_verify format '{"key": "value"}' "json" 2>/dev/null

# 7. Synthesize report
echo "7. Synthesizing report..."
cmd_pla_synthesize report "Test Report" "This is a test" "markdown" 2>/dev/null

# 8. Coordinate flow
echo "8. Coordinating flow..."
cmd_pla_coordinate flow "example-pipeline" "step1" "step2" 2>/dev/null

# 9. RAG search
echo "9. RAG search..."
cmd_rag search "test query" 2>/dev/null

# 10. RRF score
echo "10. RRF score..."
cmd_rag_fusion score 1 60 2>/dev/null

# Cleanup
rm -f /tmp/test-data.txt
rm -rf ~/.config/opencode/pla/example-pipeline.yaml

echo "=== Done ==="
