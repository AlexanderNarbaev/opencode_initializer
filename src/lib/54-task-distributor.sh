#!/usr/bin/env bash
# src/lib/54-task-distributor.sh — Task Distribution Intelligence
# Routes tasks to the right agent (Commander/Planner/Worker/Reviewer) based on
# task type + complexity, splits complex tasks into subtasks, and emits parallel
# dispatch commands for independent units. Complements 36-model-router.sh
# (model selection) and 52-context-selector.sh (MCP/LSP selection).
set -euo pipefail

_step_skip step_task_distributor && return 0

# Opt-out flag (matches SKIP_DOTFILES / SKIP_DEVBOX / SKIP_GUI convention)
[ "${SKIP_TASK_DISTRIBUTOR:-false}" = "true" ] && { info "Task Distribution skipped (SKIP_TASK_DISTRIBUTOR=true)"; return 0; }

section "Task Distribution Intelligence"

DISTRIBUTOR_DIR="$HOME/.config/opencode/task-distributor"
mkdir -p "$DISTRIBUTOR_DIR"

# ── Agent capability registry + distribution rules ──────────────────────────
# Single source of truth for the 4-agent architecture (Commander → Planner →
# Worker → Reviewer). Consumed by distribute.sh and by the wrapper functions.

cat >"$DISTRIBUTOR_DIR/config.json" <<'CONFIG'
{
  "version": "1.0.0",
  "architecture": "Commander → Planner → Worker → Reviewer",

  "agents": {
    "Commander": {
      "capabilities": ["orchestration", "delegation", "verification", "mission_control"],
      "delegates_to": ["Planner", "Worker", "Reviewer"],
      "best_for": ["complex", "multi_agent", "end_to_end"],
      "skill": null
    },
    "Planner": {
      "capabilities": ["research", "analysis", "planning", "decomposition"],
      "delegates_to": ["Worker"],
      "best_for": ["medium", "research", "design", "planning"],
      "skill": "plan"
    },
    "Worker": {
      "capabilities": ["implementation", "testing", "documentation", "fixes"],
      "delegates_to": [],
      "best_for": ["simple", "coding", "testing", "debug", "refactor", "docs"],
      "skill": "implement"
    },
    "Reviewer": {
      "capabilities": ["verification", "validation", "quality_checks"],
      "delegates_to": [],
      "best_for": ["review", "verification", "qa"],
      "skill": "code-review"
    }
  },

  "complexity": {
    "simple":  { "max_minutes": 5,   "agent": "Worker",    "flow": "direct",         "description": "Single file, mechanical edit, quick fix" },
    "medium":  { "max_minutes": 30,  "agent": "Planner",   "flow": "plan_then_work", "description": "Multi-file, needs research or a plan first" },
    "complex": { "max_minutes": 999, "agent": "Commander", "flow": "orchestrate",    "description": "Large scope, multi-agent, end-to-end" }
  },

  "distribution_rules": {
    "coding":         { "agent": "Worker",    "skill": "implement" },
    "testing":        { "agent": "Worker",    "skill": "tdd" },
    "research":       { "agent": "Planner",   "skill": "deep-research" },
    "planning":       { "agent": "Planner",   "skill": "plan" },
    "review":         { "agent": "Reviewer",  "skill": "code-review" },
    "debug":          { "agent": "Worker",    "skill": "diagnosing-bugs" },
    "refactor":       { "agent": "Worker",    "skill": "improve-codebase-architecture" },
    "docs":           { "agent": "Worker",    "skill": null },
    "orchestration":  { "agent": "Commander", "skill": null }
  },

  "keyword_map": {
    "coding":    ["implement", "add", "create", "write", "build", "feature", "code", "function", "module"],
    "testing":   ["test", "assert", "coverage", "verify", "unit", "integration", "e2e"],
    "research":  ["research", "investigate", "explore", "analyze", "survey", "audit", "discover"],
    "planning":  ["plan", "design", "architecture", "spec", "roadmap", "strategy", "break down"],
    "review":    ["review", "inspect", "critique", "audit code", "code review"],
    "debug":     ["debug", "fix", "bug", "error", "crash", "broken", "failing", "diagnose"],
    "refactor":  ["refactor", "cleanup", "simplify", "optimize", "restructure", "migrate"],
    "docs":      ["document", "readme", "guide", "comment", "translate"],
    "orchestration": ["orchestrate", "delegate", "coordinate", "distribute", "multi-agent", "parallelize", "mission"]
  },

  "complexity_signals": {
    "simple":  ["typo", "rename", "single file", "one file", "trivial", "quick", "small", "format"],
    "medium":  ["multiple files", "multi-file", "several", "update", "refactor", "add tests", "docs"],
    "complex": ["system", "architecture", "end-to-end", "migrate", "rewrite", "pipeline", "orchestrate", "all projects", "framework"]
  }
}
CONFIG

log "Task distribution config written to $DISTRIBUTOR_DIR/config.json"

# ── distribute.sh helper (canonical implementation, single Python worker) ────
# All classification logic lives in ONE embedded Python worker so the sourceable
# wrapper functions below and the CLI never drift. Priority-ordered matching
# resolves keyword ambiguities (e.g. "review code changes" → review, not coding).

cat >"$DISTRIBUTOR_DIR/distribute.sh" <<'DISTRIBUTE'
#!/usr/bin/env bash
# distribute.sh — CLI for task distribution
# Usage:
#   distribute.sh analyze  "implement login feature" [--json]
#   distribute.sh agent    "implement login feature"
#   distribute.sh split    "build end-to-end auth system"
#   distribute.sh parallel "task A" "task B" "task C"
set -euo pipefail
DISTRIBUTOR_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$DISTRIBUTOR_DIR/config.json"
[ -f "$CONFIG" ] || { echo "Error: config.json not found at $CONFIG" >&2; exit 1; }

exec python3 - "$CONFIG" "$@" <<'PY'
import json, sys

cfg = json.load(open(sys.argv[1]))
args = sys.argv[2:]

# Priority order: specific, high-signal types first; generic "coding" is the
# catch-all fallback (lowest priority). Ties resolve to the earlier entry.
TYPE_PRIORITY = ["orchestration", "review", "debug", "research", "planning",
                 "testing", "refactor", "docs", "coding"]
CPLX_PRIORITY = ["complex", "medium", "simple"]


def _score(keywords, text):
    return sum(1 for kw in keywords if kw in text)


def task_type(text):
    best, best_score = "coding", 0
    for k in TYPE_PRIORITY:
        s = _score(cfg["keyword_map"].get(k, []), text)
        if s > best_score:
            best, best_score = k, s
    return best


def complexity(text):
    best, best_score = "simple", 0
    for k in CPLX_PRIORITY:
        s = _score(cfg["complexity_signals"].get(k, []), text)
        if s > best_score:
            best, best_score = k, s
    return best


def get_analysis(desc):
    text = (desc or "").lower()
    t = task_type(text)
    c = complexity(text)
    # Refinement: planning/research/orchestration hints upgrade simple → medium,
    # and any orchestration intent upgrades medium → complex.
    if t in ("research", "planning", "orchestration") and c == "simple":
        c = "medium"
    if t == "orchestration" and c == "medium":
        c = "complex"
    return t, c


def agent_for(t, c):
    if c == "complex":
        return "Commander"
    if t in ("research", "planning"):
        return "Planner"
    if t == "review":
        return "Reviewer"
    return cfg["distribution_rules"].get(t, {}).get("agent", "Worker")


def pipeline_for(t, c):
    skill = cfg["distribution_rules"].get(t, {}).get("skill")
    if c == "simple":
        return [{"step": "implement", "agent": "Worker", "skill": skill, "depends": []}]
    if c == "medium":
        return [
            {"step": "research",  "agent": "Planner", "skill": "research", "depends": []},
            {"step": "implement", "agent": "Worker",   "skill": skill,     "depends": ["research"]},
        ]
    return [
        {"step": "research",  "agent": "Planner",  "skill": "deep-research", "depends": []},
        {"step": "plan",      "agent": "Planner",  "skill": "plan",          "depends": ["research"]},
        {"step": "implement", "agent": "Worker",   "skill": skill,           "depends": ["plan"]},
        {"step": "verify",    "agent": "Reviewer", "skill": "code-review",   "depends": ["implement"]},
    ]


def main():
    if not args:
        _usage(); sys.exit(1)
    cmd = args[0]
    rest = [a for a in args[1:] if a != "--json"]
    want_json = "--json" in args[1:]
    desc = rest[0] if rest else ""

    if cmd == "analyze":
        t, c = get_analysis(desc)
        print(json.dumps({"task_type": t, "complexity": c}) if want_json else f"{t} / {c}")
    elif cmd == "agent":
        t, c = get_analysis(desc)
        print(agent_for(t, c))
    elif cmd == "split":
        t, c = get_analysis(desc)
        print(json.dumps({"task": desc, "complexity": c, "task_type": t,
                          "pipeline": pipeline_for(t, c)}, indent=2))
    elif cmd == "parallel":
        print("# ── Parallel dispatch (background=true) ──")
        for i, task in enumerate(rest, 1):
            t, c = get_analysis(task)
            a = agent_for(t, c)
            print(f'delegate_task(agent="{a}", prompt="{task}", background=true)  # lane {i}')
    else:
        _usage(); sys.exit(1)


def _usage():
    print("Usage: distribute.sh {analyze|agent|split|parallel} <args...> [--json]",
          file=sys.stderr)


main()
PY
DISTRIBUTE

chmod +x "$DISTRIBUTOR_DIR/distribute.sh"
log "Task distributor CLI: $DISTRIBUTOR_DIR/distribute.sh"

# ── Wrapper functions (sourceable) ───────────────────────────────────────────
# Thin delegates to the canonical distribute.sh — no duplicated logic, so the
# functions below and the CLI can never disagree. Default path is fallback-safe
# for shells that don't carry DISTRIBUTOR_DIR.

_td_bin() { echo "${DISTRIBUTOR_DIR:-$HOME/.config/opencode/task-distributor}/distribute.sh"; }

# _analyze_task <description> [--json] — task type + complexity
_analyze_task() { "$(_td_bin)" analyze "$@"; }

# _select_agent <description> — best agent for the task
_select_agent() { "$(_td_bin)" agent "$@"; }

# _distribute_tasks <description> — ordered subtask pipeline (JSON)
_distribute_tasks() { "$(_td_bin)" split "$@"; }

# _parallel_execute <subtask...> — parallel dispatch commands (read-only)
_parallel_execute() { "$(_td_bin)" parallel "$@"; }

log "Task distribution functions defined: _analyze_task _select_agent _distribute_tasks _parallel_execute"

# ── Integrate with existing agent system ────────────────────────────────────
# Reference this directory from opencode.json so plugins/agents can discover it
# (mirrors 36-model-router.sh's experimental.model_router_dir).
OC_CONFIG="$HOME/.config/opencode/opencode.json"
if [ -f "$OC_CONFIG" ]; then
  python3 -c "
import json
with open('$OC_CONFIG') as f:
    cfg = json.load(f)
if 'experimental' not in cfg:
    cfg['experimental'] = {}
cfg['experimental']['task_distributor_dir'] = '$DISTRIBUTOR_DIR'
with open('$OC_CONFIG', 'w') as f:
    json.dump(cfg, f, indent=2)
print('opencode.json: task_distributor_dir added')
" 2>/dev/null && log "opencode.json updated with task_distributor_dir" || warn "Failed to update opencode.json"
fi

info "Task distribution configured. Use: $DISTRIBUTOR_DIR/distribute.sh {analyze|agent|split|parallel} <args...>"
info "Example: $DISTRIBUTOR_DIR/distribute.sh agent 'implement login feature'"

_step_done step_task_distributor
