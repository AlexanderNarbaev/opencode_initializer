

---

## AI-Native Modules (from opencode_initializer)

Three context-aware modules are installed under `src/lib/` (create the directory if absent). They cut token/context overhead and route work to the right agent.

| Module | Purpose | Local config snapshot |
|--------|---------|-----------------------|
| `src/lib/52-context-selector.sh` | Selects only the MCP/LSP servers relevant to a task | `.opencode/context-selector/config.json` |
| `src/lib/53-auto-skills.sh` | Detects task type + file type, suggests skills to load | `.opencode/auto-skills/config.json` |
| `src/lib/54-task-distributor.sh` | Routes tasks to Commander / Planner / Worker / Reviewer | `.opencode/task-distributor/config.json` |

### Quick reference
- **Context:** `_select_mcp_for_task coding` · `_select_lsp_for_file foo.ts` · `_optimize_context coding foo.ts`
- **Skills:** `_detect_task_type "fix the bug"` · `_skill_suggest "review this"` · `_auto_load_skills "..."`
- **Distribution:** `_analyze_task "..."` · `_select_agent "..."` · `_distribute_tasks "..."` · `_parallel_execute "a" "b"`

Canonical source: the `opencode_initializer` repo. Keep these config snapshots in sync with upstream.
