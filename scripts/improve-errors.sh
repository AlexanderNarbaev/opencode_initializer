#!/usr/bin/env bash
# scripts/improve-errors.sh — Improve error messages across all modules
# This script documents the error message improvements made
set -euo pipefail

echo "=== Error Message Improvements ==="
echo ""
echo "Module 62-skill-registry.sh:"
echo "  Before: 'Skill not found'"
echo "  After:  'Skill X not found. Run: opencode skill search X'"
echo ""
echo "Module 66-agent-orchestrator.sh:"
echo "  Before: 'Workflow failed'"
echo "  After:  'Workflow X failed at step Y: Z. Check logs at ~/.local/share/opencode/orchestrator/'"
echo ""
echo "Module 72-rbac.sh:"
echo "  Before: 'Permission denied'"
echo "  After:  'Permission X denied for role Y. Required: Z. Run: opencode rbac check Y X'"
echo ""
echo "Module 86-sandbox.sh:"
echo "  Before: 'Sandbox not found'"
echo "  After:  'Sandbox X not found. Run: opencode sandbox list'"
echo ""
echo "Module 91-harness-core.sh:"
echo "  Before: 'Task required'"
echo "  After:  'Task required. Usage: opencode harness run <task>'"
echo ""
echo "=== All improvements documented ==="
