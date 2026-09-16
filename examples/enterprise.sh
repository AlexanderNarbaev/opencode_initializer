#!/usr/bin/env bash
# examples/enterprise.sh — Example: Enterprise Features
# Demonstrates how to use modules 72-77

set -euo pipefail

echo "=== Enterprise Features Example ==="

# Source the modules
source src/lib/helpers.sh
source src/lib/72-rbac.sh
source src/lib/73-governance.sh
source src/lib/74-compliance.sh
source src/lib/75-security-posture.sh
source src/lib/76-analytics.sh
source src/lib/77-observability.sh

# 1. Initialize RBAC
echo "1. Initializing RBAC..."
cmd_rbac init 2>/dev/null

# 2. List roles
echo "2. Listing roles..."
cmd_rbac list 2>/dev/null

# 3. Check permission
echo "3. Checking permission..."
cmd_rbac check "developer" "write" 2>/dev/null

# 4. Initialize governance
echo "4. Initializing governance..."
cmd_governance init 2>/dev/null

# 5. List governance rules
echo "5. Listing governance rules..."
cmd_governance rules 2>/dev/null

# 6. Run compliance check
echo "6. Running compliance check..."
cmd_compliance score "soc2" 2>/dev/null

# 7. Run security assessment
echo "7. Running security assessment..."
cmd_security-posture assess 2>/dev/null

# 8. Track analytics event
echo "8. Tracking analytics event..."
cmd_analytics track "example" "test_event" "key=value" 2>/dev/null

# 9. Initialize observability
echo "9. Initializing observability..."
cmd_observability init 2>/dev/null

# 10. Set metric
echo "10. Setting metric..."
cmd_observability metric-set "example_metric" 42 2>/dev/null

# 11. Get metric
echo "11. Getting metric..."
cmd_observability metric-get "example_metric" 2>/dev/null

echo "=== Done ==="
