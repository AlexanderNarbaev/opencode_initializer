#!/usr/bin/env bash
# examples/skill-management.sh — Example: Skill Management
# Demonstrates how to use modules 62-65

set -euo pipefail

echo "=== Skill Management Example ==="

# Source the modules
source src/lib/helpers.sh
source src/lib/62-skill-registry.sh
source src/lib/63-skill-manager.sh
source src/lib/64-skill-security.sh
source src/lib/65-skill-eval.sh

# 1. Search for skills
echo "1. Searching for skills..."
cmd_skill search "code-review" 2>/dev/null || echo "  (search requires registry)"

# 2. List available skills
echo "2. Listing available skills..."
cmd_skill available 2>/dev/null || echo "  (list requires registry)"

# 3. Validate a skill
echo "3. Validating a skill..."
mkdir -p /tmp/test-skill
cat > /tmp/test-skill/SKILL.md <<'EOF'
# Test Skill
Description: A test skill for validation.
EOF
cmd_skill validate /tmp/test-skill 2>/dev/null && echo "  ✓ Valid" || echo "  ✗ Invalid"

# 4. Security scan
echo "4. Running security scan..."
cmd_skill-security score /tmp/test-skill 2>/dev/null || echo "  (scan requires skill)"

# 5. Evaluation
echo "5. Running evaluation..."
cmd_skill-eval run "test-skill" 2>/dev/null || echo "  (eval requires installed skill)"

# Cleanup
rm -rf /tmp/test-skill

echo "=== Done ==="
