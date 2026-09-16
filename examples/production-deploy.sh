#!/usr/bin/env bash
# examples/production-deploy.sh — Example: Production Deployment
# Demonstrates how to use modules 111-116

set -euo pipefail

echo "=== Production Deployment Example ==="

# Source the modules
source src/lib/helpers.sh
source src/lib/111-perf-optimizer.sh
source src/lib/112-cache-manager.sh
source src/lib/113-security-hardening.sh
source src/lib/114-vulnerability-scan.sh
source src/lib/115-scalability.sh
source src/lib/116-load-balancer.sh

# 1. Run performance benchmark
echo "1. Running performance benchmark..."
cmd_perf benchmark . 5 2>/dev/null

# 2. Check cache
echo "2. Checking cache..."
cmd_cache size 2>/dev/null

# 3. List cache
echo "3. Listing cache..."
cmd_cache list 2>/dev/null

# 4. Run security hardening
echo "4. Running security hardening..."
cmd_security-hardening run 2>/dev/null

# 5. Run vulnerability scan
echo "5. Running vulnerability scan..."
cmd_vuln_scan scan . 2>/dev/null

# 6. Check scalability
echo "6. Checking scalability..."
cmd_scalability check 2>/dev/null

# 7. Check load balancer
echo "7. Checking load balancer..."
cmd_lb status 2>/dev/null

# 8. Optimize performance
echo "8. Optimizing performance..."
cmd_perf optimize . 2>/dev/null

echo "=== Done ==="
