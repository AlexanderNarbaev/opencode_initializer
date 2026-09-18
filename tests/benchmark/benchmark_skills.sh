#!/usr/bin/env bash
# tests/benchmark/benchmark_skills.sh — Performance benchmark for skill operations
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/62-skill-registry.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/64-skill-security.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/65-skill-eval.sh" 2>/dev/null || true

section "Performance Benchmark: Skill Operations"

# Create test skill
TEST_SKILL_DIR=$(mktemp -d)
cat > "$TEST_SKILL_DIR/SKILL.md" <<'EOF'
# Test Skill
Description: A test skill for benchmarking.
## Usage
1. Run the command
2. Check the output
## Input
- query: string
## Output
- result: string
## Example
```bash
echo "hello"
```
EOF

# Benchmark validation
start_time=$(date +%s%N)
for i in $(seq 1 100); do
  _skill_validate "$TEST_SKILL_DIR" 2>/dev/null
done
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo "  Validation (100 iterations): ${duration}ms ($(( duration / 100 ))ms per call)"

# Benchmark security scan
start_time=$(date +%s%N)
for i in $(seq 1 100); do
  _skill_security_score "$TEST_SKILL_DIR" 2>/dev/null || true
done
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo "  Security scan (100 iterations): ${duration}ms ($(( duration / 100 ))ms per call)"

# Benchmark evaluation
start_time=$(date +%s%N)
for i in $(seq 1 100); do
  _skill_eval_completion "$TEST_SKILL_DIR" 2>/dev/null || true
done
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo "  Evaluation (100 iterations): ${duration}ms ($(( duration / 100 ))ms per call)"

# Cleanup
rm -rf "$TEST_SKILL_DIR"

echo
echo "━━━ Benchmark Complete ━━━"
