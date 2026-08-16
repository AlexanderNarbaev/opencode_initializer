# Sync Issues

## Status: RESOLVED

SYNC-1 (158 tracked files under `.opencode/` deleted from working tree) is resolved.

- Restored via `git checkout-index --all` (recreates missing worktree files from the index without overwriting existing files).
- Verified: 158 deletions gone, `git status --short` clean of `D` entries.
- Matt Pocock skills restored: 17 SKILL.md files present (`find .opencode/skills/matt-pocock -name SKILL.md | wc -l` → 17).
- `model-policy.json`, `opencode-swarm.json`, `architecture.md` restored.
- HEAD == origin/main (`1e94497`), working tree in sync with remote.
