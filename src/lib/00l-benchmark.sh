#!/usr/bin/env bash
# src/lib/00l-benchmark.sh — Performance Benchmark Module (v4.3.0)
# Measures installation time, identifies bottlenecks, generates reports.
set -euo pipefail

# ── Benchmark configuration ──────────────────────────────────────────────────
_BENCHMARK_REPORT="${DL_CACHE}/benchmark-report.json"
_BENCHMARK_RESULTS=()

# ── Start benchmark timer ───────────────────────────────────────────────────
# Usage: _benchmark_start "operation_name"
_benchmark_start() {
  local name="$1"
  local start_time
  start_time=$(date +%s%N)
  echo "$start_time" > "/tmp/bench_${name}.start"
  info "⏱ Benchmark started: $name" >&2
}

# ── Stop benchmark timer ────────────────────────────────────────────────────
# Usage: _benchmark_stop "operation_name"
# Returns duration in milliseconds.
_benchmark_stop() {
  local name="$1"
  local start_time end_time duration_ms
  
  if [ -f "/tmp/bench_${name}.start" ]; then
    start_time=$(cat "/tmp/bench_${name}.start")
    end_time=$(date +%s%N)
    duration_ms=$(( (end_time - start_time) / 1000000 ))
    
    _BENCHMARK_RESULTS+=("$name:$duration_ms")
    log "⏱ $name: ${duration_ms}ms" >&2
    
    rm -f "/tmp/bench_${name}.start"
    echo "$duration_ms"
  else
    warn "No benchmark start found for: $name" >&2
    echo "0"
  fi
}

# ── Benchmark a command ─────────────────────────────────────────────────────
# Usage: _benchmark_cmd "name" command args...
# Runs the command and measures execution time.
_benchmark_cmd() {
  local name="$1"
  shift
  
  _benchmark_start "$name"
  "$@"
  local exit_code=$?
  _benchmark_stop "$name"
  
  return $exit_code
}

# ── Network speed test ──────────────────────────────────────────────────────
# Usage: _benchmark_network
# Tests download speed from various sources.
_benchmark_network() {
  section "Network Speed Test"

  local urls=(
    "https://registry.npmjs.org"
    "https://pypi.org"
    "https://npm-mirror.gitverse.ru"
    "https://pypi-mirror.gitverse.ru"
  )

  for url in "${urls[@]}"; do
    local start_time end_time duration_ms size speed_kbps
    start_time=$(date +%s%N)
    
    size=$(curl -sf --max-time 10 -o /dev/null -w '%{size_download}' "$url" 2>/dev/null || echo "0")
    end_time=$(date +%s%N)
    duration_ms=$(( (end_time - start_time) / 1000000 ))
    
    if [ "$duration_ms" -gt 0 ] && [ "$size" -gt 0 ]; then
      speed_kbps=$(( (size * 1000) / (duration_ms * 1024) ))
      log "  $url: ${speed_kbps} KB/s (${duration_ms}ms)"
    else
      warn "  $url: timeout or error"
    fi
  done
}

# ── Disk I/O benchmark ──────────────────────────────────────────────────────
# Usage: _benchmark_disk
# Tests disk write/read speed.
_benchmark_disk() {
  section "Disk I/O Benchmark"

  local test_file="/tmp/benchmark_test_$$"
  local block_size="1M"
  local count=100

  # Write test
  local start_time end_time duration_ms speed_mbps
  start_time=$(date +%s%N)
  dd if=/dev/zero of="$test_file" bs=$block_size count=$count oflag=direct 2>/dev/null
  end_time=$(date +%s%N)
  duration_ms=$(( (end_time - start_time) / 1000000 ))
  speed_mbps=$(( (count * 1000) / duration_ms ))
  log "  Write: ${speed_mbps} MB/s (${duration_ms}ms for ${count}MB)"

  # Read test
  start_time=$(date +%s%N)
  dd if="$test_file" of=/dev/null bs=$block_size iflag=direct 2>/dev/null
  end_time=$(date +%s%N)
  duration_ms=$(( (end_time - start_time) / 1000000 ))
  speed_mbps=$(( (count * 1000) / duration_ms ))
  log "  Read: ${speed_mbps} MB/s (${duration_ms}ms for ${count}MB)"

  # Cleanup
  rm -f "$test_file"
}

# ── CPU benchmark ───────────────────────────────────────────────────────────
# Usage: _benchmark_cpu
# Tests CPU performance with a simple calculation.
_benchmark_cpu() {
  section "CPU Benchmark"

  local start_time end_time duration_ms
  start_time=$(date +%s%N)
  
  # Calculate prime numbers (simple CPU benchmark)
  python3 -c "
def is_prime(n):
    if n < 2:
        return False
    for i in range(2, int(n**0.5) + 1):
        if n % i == 0:
            return False
    return True

count = 0
for i in range(100000):
    if is_prime(i):
        count += 1
print(f'Found {count} primes')
" 2>/dev/null
  
  end_time=$(date +%s%N)
  duration_ms=$(( (end_time - start_time) / 1000000 ))
  log "  CPU: ${duration_ms}ms (100k prime check)"
}

# ── Memory benchmark ────────────────────────────────────────────────────────
# Usage: _benchmark_memory
# Tests available memory and swap.
_benchmark_memory() {
  section "Memory Benchmark"

  local total_mem free_mem used_mem swap_total swap_free
  total_mem=$(free -m | awk '/^Mem:/ {print $2}')
  free_mem=$(free -m | awk '/^Mem:/ {print $4}')
  used_mem=$(free -m | awk '/^Mem:/ {print $3}')
  swap_total=$(free -m | awk '/^Swap:/ {print $2}')
  swap_free=$(free -m | awk '/^Swap:/ {print $4}')

  log "  Total: ${total_mem}MB"
  log "  Used: ${used_mem}MB"
  log "  Free: ${free_mem}MB"
  log "  Swap: ${swap_total}MB total, ${swap_free}MB free"
}

# ── Full benchmark suite ────────────────────────────────────────────────────
# Usage: _run_benchmark
# Runs all benchmarks and generates report.
_run_benchmark() {
  section "Performance Benchmark Suite"

  _benchmark_network
  _benchmark_disk
  _benchmark_cpu
  _benchmark_memory

  # Generate report
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  cat > "$_BENCHMARK_REPORT" <<EOF
{
  "timestamp": "$now",
  "results": [
$(printf '    {"name": "%s", "duration_ms": %s},\n' "${_BENCHMARK_RESULTS[@]}" | sed '$ s/,$//')
  ],
  "summary": {
    "total_tests": ${#_BENCHMARK_RESULTS[@]},
    "total_time_ms": $(printf '%s\n' "${_BENCHMARK_RESULTS[@]}" | cut -d: -f2 | paste -sd+ | bc)
  }
}
EOF

  log "Benchmark report: $_BENCHMARK_REPORT"
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _benchmark_start _benchmark_stop _benchmark_cmd _benchmark_network \
  _benchmark_disk _benchmark_cpu _benchmark_memory _run_benchmark 2>/dev/null || true
