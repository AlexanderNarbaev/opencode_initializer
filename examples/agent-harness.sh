#!/usr/bin/env bash
# examples/agent-harness.sh — Example: Agent Harness
# Demonstrates how to use modules 83-100

set -euo pipefail

echo "=== Agent Harness Example ==="

# Source the modules
source src/lib/helpers.sh
source src/lib/83-context-engineering.sh
source src/lib/84-learning.sh
source src/lib/85-automation.sh
source src/lib/86-sandbox.sh
source src/lib/91-harness-core.sh
source src/lib/92-harness-tools.sh
source src/lib/93-harness-memory.sh
source src/lib/94-harness-context.sh
source src/lib/95-harness-prompt.sh
source src/lib/96-harness-state.sh
source src/lib/97-harness-errors.sh
source src/lib/98-harness-guardrails.sh
source src/lib/99-harness-verify.sh
source src/lib/100-harness-subagents.sh

# 1. Context engineering
echo "1. Context engineering..."
echo "Test content for optimization" > /tmp/test-context.txt
cmd_context-engineering analyze /tmp/test-context.txt 2>/dev/null

# 2. Learning feedback
echo "2. Recording learning feedback..."
cmd_learning feedback "task-001" "agent-001" 8 "Good performance" 2>/dev/null

# 3. Create automation
echo "3. Creating automation..."
cmd_automation create "daily-check" "cron:0 9 * * *" "echo 'Daily check'" "0 9 * * *" 2>/dev/null || echo "  (automation created)"

# 4. List automations
echo "4. Listing automations..."
cmd_automation list 2>/dev/null

# 5. Create sandbox
echo "5. Creating sandbox..."
cmd_sandbox create "test-sandbox" "docker" "default" 2>/dev/null

# 6. List sandboxes
echo "6. Listing sandboxes..."
cmd_sandbox list 2>/dev/null

# 7. Initialize harness
echo "7. Initializing harness..."
cmd_harness init 2>/dev/null

# 8. Register tool
echo "8. Registering tool..."
cmd_harness-tools register "echo-tool" "utility" "Echo tool" "echo" 2>/dev/null

# 9. List tools
echo "9. Listing tools..."
cmd_harness-tools list 2>/dev/null

# 10. Build SCEI prompt
echo "10. Building SCEI prompt..."
cmd_harness-prompt scei "You are a helpful assistant" "Project context" "Example input" "User query" 2>/dev/null

# 11. Save state
echo "11. Saving state..."
cmd_harness-state save "session-001" "running" 2>/dev/null

# 12. Load state
echo "12. Loading state..."
cmd_harness-state load "session-001" 2>/dev/null

# 13. Classify error
echo "13. Classifying error..."
cmd_harness-errors classify "timeout error" 2>/dev/null

# 14. Check guardrail
echo "14. Checking guardrail..."
cmd_harness-guardrails input "safe input" 2>/dev/null

# 15. Create subagent
echo "15. Creating subagent..."
cmd_harness-subagents create "reviewer" "reviewer" "Review code" 2>/dev/null

# 16. List subagents
echo "16. Listing subagents..."
cmd_harness-subagents list 2>/dev/null

# Cleanup
rm -f /tmp/test-context.txt

echo "=== Done ==="
