#!/usr/bin/env bash
# scripts/sync-projects.sh — Sync AI configs across all ~/Projects/*
# Usage: bash scripts/sync-projects.sh [--dry-run]
set -euo pipefail
DRY_RUN=false; [ "${1:-}" = "--dry-run" ] && DRY_RUN=true
SOURCE="$HOME/Projects/opencode_initializer"
TEMPLATE="$SOURCE/opencode.json"
SYNCED=0; SKIPPED=0

echo "=== Cross-Project Sync ==="
for d in "$HOME"/Projects/*/; do
  name=$(basename "$d")
  [ "$name" = "opencode_initializer" ] && continue
  [ ! -d "$d/.git" ] && echo "  SKIP $name (no git)" && SKIPPED=$((SKIPPED+1)) && continue

  # Sync opencode.json model settings
  if [ -f "$d/opencode.json" ] && [ -f "$TEMPLATE" ]; then
    python3 -c "
import json
with open() as f: t = json.load(f)
with open(/opencode.json) as f: c = json.load(f)
changed = False
for k in [model,small_model]:
    if k in t and c.get(k) != t[k]: c[k]=t[k]; changed=True
if compaction not in c: c[compaction]={auto:True,prune:True,tail_turns:2}; changed=True
if changed:
    with open(/opencode.json,w) as f: json.dump(c,f,indent=2); f.write(n)
    print(updated)
" 2>/dev/null && echo "  SYNC $name: opencode.json" && SYNCED=$((SYNCED+1)) || true
  fi

  # Ensure AGENTS.md has AI tools
  if [ -f "$d/AGENTS.md" ] && ! grep -q DevoxxGenie "$d/AGENTS.md" 2>/dev/null; then
    cat >> "$d/AGENTS.md" << EOF

## AI Dev Tools (via opencode_initializer)
- DevoxxGenie (JetBrains, Apache 2.0) — local LLMs, RAG, MCP
- Cline (VS Code+JetBrains, Apache 2.0) — AI agent, Ollama
- Tabby (VS Code+JetBrains, Apache 2.0) — self-hosted completion
- Aider (CLI, Apache 2.0) — git-aware edits
EOF
    echo "  SYNC $name: AGENTS.md"
  fi
done

echo "Synced: $SYNCED, Skipped: $SKIPPED"
