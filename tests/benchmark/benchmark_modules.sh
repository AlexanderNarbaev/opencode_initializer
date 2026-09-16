#!/usr/bin/env bash
# tests/benchmark/benchmark_modules.sh — Performance benchmark for modules
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

section "Performance Benchmark: Module Loading"

# Benchmark module loading time
benchmark_module() {
  local module="$1"
  local start_time
  start_time=$(date +%s%N)
  
  source "$PROJECT_ROOT/src/lib/$module" 2>/dev/null || true
  
  local end_time
  end_time=$(date +%s%N)
  local duration=$(( (end_time - start_time) / 1000000 ))
  
  echo "  $module: ${duration}ms"
}

# Benchmark all new modules
for module in 62-skill-registry.sh 63-skill-manager.sh 64-skill-security.sh 65-skill-eval.sh \
              66-agent-orchestrator.sh 67-agent-pipeline.sh 68-agent-mesh.sh 69-agent-protocol.sh \
              70-context-engine.sh 71-memory-layer.sh 72-rbac.sh 73-governance.sh \
              74-compliance.sh 75-security-posture.sh 76-analytics.sh 77-observability.sh \
              78-marketplace.sh 79-plugin-manager.sh 80-templates.sh 81-integrations.sh \
              82-connectors.sh 83-context-engineering.sh 84-learning.sh 85-automation.sh \
              86-sandbox.sh 87-cicd-integration.sh 88-workflow-engine.sh 89-security-policies.sh \
              90-secrets-manager.sh 91-harness-core.sh 92-harness-tools.sh 93-harness-memory.sh \
              94-harness-context.sh 95-harness-prompt.sh 96-harness-state.sh 97-harness-errors.sh \
              98-harness-guardrails.sh 99-harness-verify.sh 100-harness-subagents.sh \
              101-pla-orchestrator.sh 102-pla-extract.sh 103-pla-analyze.sh 104-pla-verify.sh \
              105-pla-synthesize.sh 106-pla-coordinate.sh 107-rag-hybrid.sh 108-rag-bm25.sh \
              109-rag-vector.sh 110-rag-fusion.sh 111-perf-optimizer.sh 112-cache-manager.sh \
              113-security-hardening.sh 114-vulnerability-scan.sh 115-scalability.sh \
              116-load-balancer.sh; do
  benchmark_module "$module"
done

echo
echo "━━━ Benchmark Complete ━━━"
