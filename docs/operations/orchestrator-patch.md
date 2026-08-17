# Orchestrator Patch Note

The `opencode-orchestrator` npm package (`@npm-global/lib/node_modules/opencode-orchestrator/`)
unconditionally demotes the built-in `build` and `plan` primary agents to `subagent`/`hidden`
in its config hook (`dist/index.js` around lines 15603–15616), and sets
`default_agent = "Commander"`.

## Patch

File: `/home/alexandr-narbaev/.npm-global/lib/node_modules/opencode-orchestrator/dist/index.js`

Original block (the demotion):
```javascript
const processedExistingAgents = { ...existingAgents };
if (processedExistingAgents.build) {
  processedExistingAgents.build = {
    ...processedExistingAgents.build,
    mode: "subagent",
    hidden: true
  };
}
if (processedExistingAgents.plan) {
  processedExistingAgents.plan = {
    ...processedExistingAgents.plan,
    mode: "subagent"
  };
}
```

Patched to:
```javascript
const processedExistingAgents = { ...existingAgents };
// PATCHED: preserve built-in build/plan primary mode (do not demote to subagent)
// if (processedExistingAgents.build) { ...demoted... }
// if (processedExistingAgents.plan) { ...demoted... }
```

The orchestrator's own agents (`architect` as primary, `coder`/`researcher`/`reviewer` as
subagents — renamed from Commander/Planner/Worker/Reviewer) are still registered.

## Result

After patching + re-enabling `opencode-orchestrator` in `~/.config/opencode/opencode.jsonc`:

| Agent | Mode | Source |
|---|---|---|
| `build` | **primary** ✅ | built-in (preserved) |
| `plan` | **primary** ✅ | built-in (preserved) |
| `architect` | primary | orchestrator (renamed Commander) |
| `coder` | subagent | orchestrator (renamed Worker) |
| `researcher` | subagent | orchestrator (renamed Planner) |
| `reviewer` | subagent | orchestrator (renamed Reviewer) |
| `goal` | primary | opencode-goal-plugin |
| `general`, `explore`, `code-reviewer` | subagent | built-in |
| 26 × `goal-*` | subagent | opencode-goal-plugin |
| critics / curators / sme / test_engineer / ... | subagent | various |

Total: 57 agents (7 primary + 50 subagents).

## To re-apply after npm update

When `opencode-orchestrator` is updated via `npm install -g`, the patch in
`dist/index.js` is overwritten. Re-apply with:

```bash
cp /home/alexandr-narbaev/.npm-global/lib/node_modules/opencode-orchestrator/dist/index.js \
   /home/alexandr-narbaev/.npm-global/lib/node_modules/opencode-orchestrator/dist/index.js.bak
```

Then comment out the `if (processedExistingAgents.build)` and
`if (processedExistingAgents.plan)` blocks, OR replace with a guarded version that
skips the demotion when `build`/`plan` exist.
