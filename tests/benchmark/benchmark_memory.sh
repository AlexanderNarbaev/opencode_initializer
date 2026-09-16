#!/usr/bin/env bash
# tests/benchmark/benchmark_memory.sh — Performance benchmark for memory operations
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/71-memory-layer.sh" 2>/dev/null || true

section "Performance Benchmark: Memory Operations"

# Benchmark store
start_time=$(date +%s%N)
for i in $(seq 1 100); do
  _memory_store "benchmark" "key-$i" "value-$i" 5 2>/dev/null
done
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo "  Store (100 iterations): ${duration}ms ($(( duration / 100 ))ms per call)"

# Benchmark retrieve
start_time=$(date +%s%N)
for i in $(seq 1 100); do
  _memory_retrieve "benchmark" "key-$i" 2>/dev/null
done
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo "  Retrieve (100 iterations): ${duration}ms ($(( duration / 100 ))ms per call)"

# Benchmark search
start_time=$(date +%s%N)
for i in $(seq 1 10); do
  _memory_search "value" "" 2>/dev/null
done
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo "  Search (10 iterations): ${duration}ms ($(( duration / 10 ))ms per call)"

# Cleanup
rm -rf "$HOME/.local/share/opencode/memory/benchmark"

echo
echo "━━━ Benchmark Complete ━━━"
