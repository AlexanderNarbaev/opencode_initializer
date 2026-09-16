#!/usr/bin/env bash
# examples/agent-orchestration.sh — Example: Agent Orchestration
# Demonstrates how to use modules 66-71

set -euo pipefail

echo "=== Agent Orchestration Example ==="

# Source the modules
source src/lib/helpers.sh
source src/lib/66-agent-orchestrator.sh
source src/lib/67-agent-pipeline.sh
source src/lib/68-agent-mesh.sh
source src/lib/69-agent-protocol.sh
source src/lib/70-context-engine.sh
source src/lib/71-memory-layer.sh

# 1. Create a workflow
echo "1. Creating workflow..."
mkdir -p ~/.config/opencode/workflows
cat > ~/.config/opencode/workflows/example.yaml <<'EOF'
name: example-workflow
version: 1.0.0
description: Example workflow
steps:
  - name: step1
    type: extract
  - name: step2
    type: analyze
  - name: step3
    type: synthesize
EOF

# 2. List workflows
echo "2. Listing workflows..."
cmd_orchestrator list 2>/dev/null

# 3. Register an agent
echo "3. Registering agent..."
cmd_agent_mesh register "example-agent" "implementation" "http://localhost:8080" "code-review,testing" 2>/dev/null || echo "  (registration requires mesh)"

# 4. List agents
echo "4. Listing agents..."
cmd_agent_mesh list 2>/dev/null

# 5. Store context
echo "5. Storing context..."
cmd_context store "project" "architecture" "Microservices with REST API" 2>/dev/null

# 6. Retrieve context
echo "6. Retrieving context..."
cmd_context retrieve "project" "architecture" 2>/dev/null

# 7. Store memory
echo "7. Storing memory..."
cmd_memory store "decisions" "api-design" "REST API with OpenAPI spec" 7 2>/dev/null

# 8. Retrieve memory
echo "8. Retrieving memory..."
cmd_memory retrieve "decisions" "api-design" 2>/dev/null

# Cleanup
rm -rf ~/.config/opencode/workflows/example.yaml

echo "=== Done ==="
