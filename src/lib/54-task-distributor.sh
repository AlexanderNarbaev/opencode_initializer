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
    "simple":  { "max_minutes": 5,   "agent": "Worker",    "flow": "direct",            "description": "Single file, mechanical edit, quick fix" },
    "medium":  { "max_minutes": 30,  "agent": "Planner",   "flow": "plan_then_work",    "description": "Multi-file, needs research or a plan first" },
    "complex": { "max_minutes": 999, "agent": "Commander", "flow": "orchestrate",       "description": "Large scope, multi-agent, end-to-end" }
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
    "review":    ["review", "inspect", "check", "critique", "audit code", "code review"],
    "debug":     ["debug", "fix", "bug", "error", "crash", "broken", "failing", "diagnose"],
    "refactor":  ["refactor", "cleanup", "simplify", "optimize", "restructure", "migrate"],
    "docs":      ["document", "doc", "readme", "guide", "comment", "translate"],
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

# ── Wrapper functions (sourceable) ──────────────────────────────────────────
# Each reads config.json, so they stay in sync with team edits (like
# 36-model-router.sh's task-profiles.json). They emit machine-readable JSON
# when --json is passed, human text otherwise.

_task_dist_load_config() {
  # Guard: functions must not execute during a bare `source` of the module.
  # The module body only defines them; distribute.sh invokes them explicitly.
  local cfg="$DISTRIBUTOR_DIR/config.json"
  [ -f "$cfg" ] || { echo "{}" >&2; return 1; }
  echo "$cfg"
}

# _analyze_task <description> [--json]
# Determines task type (coding/testing/...) and complexity (simple/medium/complex)
# by keyword-matching against config.json. Emits "type|complexity" (or JSON).
_analyze_task() {
  local desc="${1:-}" cfg out=""
  cfg="$(_task_dist_load_config)" || return 1
  out="$(python3 - "$cfg" "$desc" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))
desc = sys.argv[2].lower()

def classify(kw_map, desc):
    scores = {}
    for label, kws in kw_map.items():
        scores[label] = sum(1 for kw in kws if kw in desc)
    best = max(scores, key=scores.get)
    return best if scores[best] > 0 else "coding"

ttype = classify(cfg["keyword_map"], desc)
cplx  = classify(cfg["complexity_signals"], desc)

# Complexity refinement: planning/research/orchestration hints upgrade medium.
if ttype in ("research", "planning", "orchestration") and cplx == "simple":
    cplx = "medium"
if ttype == "orchestration" and cplx == "medium":
    cplx = "complex"

print(json.dumps({"task_type": ttype, "complexity": cplx}))
PY
)"
  if [ "${2:-}" = "--json" ]; then
    echo "$out"
  else
    python3 -c "import json; d=json.loads('$out'); print(f\"{d['task_type']} / {d['complexity']}\")"
  fi
}

# _select_agent <description> [--json]
# Picks the best agent (Commander/Planner/Worker/Reviewer) for a task using
# type → distribution rule, then complexity override.
_select_agent() {
  local desc="${1:-}" analysis="" ttype="" cplx="" agent="" cfg=""
  cfg="$(_task_dist_load_config)" || return 1
  analysis="$(_analyze_task "$desc" --json)"
  ttype="$(echo "$analysis" | python3 -c "import json,sys; print(json.load(sys.stdin)['task_type'])")"
  cplx="$(echo "$analysis" | python3 -c "import json,sys; print(json.load(sys.stdin)['complexity'])")"
  agent="$(python3 - "$cfg" "$ttype" "$cplx" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1])); ttype = sys.argv[2]; cplx = sys.argv[3]
# Complexity overrides the type rule: complex → Commander, medium+planning → Planner.
if cplx == "complex":
    agent = "Commander"
elif ttype in ("research", "planning"):
    agent = "Planner"
elif ttype == "review":
    agent = "Reviewer"
else:
    agent = cfg["distribution_rules"].get(ttype, {}).get("agent", "Worker")
print(agent)
PY
)"
  if [ "${2:-}" = "--json" ]; then
    echo "{\"task_type\": \"$ttype\", \"complexity\": \"$cplx\", \"agent\": \"$agent\"}"
  else
    echo "$agent"
  fi
}

# _distribute_tasks <description> [--json]
# Splits a task into an ordered subtask pipeline (research → plan → implement →
# verify) proportional to its complexity. Simple → 1 Worker subtask; medium →
# Planner+Worker; complex → full Commander-orchestrated pipeline.
_distribute_tasks() {
  local desc="${1:-}" analysis="" cplx="" ttype="" cfg=""
  cfg="$(_task_dist_load_config)" || return 1
  analysis="$(_analyze_task "$desc" --json)"
  cplx="$(echo "$analysis" | python3 -c "import json,sys; print(json.load(sys.stdin)['complexity'])")"
  ttype="$(echo "$analysis" | python3 -c "import json,sys; print(json.load(sys.stdin)['task_type'])")"
  python3 - "$cfg" "$cplx" "$ttype" "$desc" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1])); cplx = sys.argv[2]; ttype = sys.argv[3]; desc = sys.argv[4]
rule = cfg["distribution_rules"].get(ttype, {"agent": "Worker", "skill": None})
skill = rule.get("skill")

pipeline = []
if cplx == "simple":
    pipeline = [{"step": "implement", "agent": "Worker", "skill": skill, "depends": []}]
elif cplx == "medium":
    pipeline = [
        {"step": "research",  "agent": "Planner", "skill": "research", "depends": []},
        {"step": "implement", "agent": "Worker",   "skill": skill,     "depends": ["research"]},
    ]
else:
    pipeline = [
        {"step": "research",  "agent": "Planner",  "skill": "deep-research", "depends": []},
        {"step": "plan",      "agent": "Planner",  "skill": "plan",          "depends": ["research"]},
        {"step": "implement", "agent": "Worker",   "skill": skill,           "depends": ["plan"]},
        {"step": "verify",    "agent": "Reviewer", "skill": "code-review",   "depends": ["implement"]},
    ]
print(json.dumps({"task": desc, "complexity": cplx, "task_type": ttype, "pipeline": pipeline}, indent=2))
PY
}

# _parallel_execute <subtask...>
# Given independent subtask descriptions, emits the parallel dispatch commands
# (one `delegate_task` per subtask). Read-only: prints commands, never executes.
_parallel_execute() {
  local n=0
  if [ "$#" -eq 0 ]; then
    echo "# No subtasks supplied. Usage: _parallel_execute \"task A\" \"task B\" ..."
    return 0
  fi
  echo "# ── Parallel dispatch (background=true) ──"
  for task in "$@"; do
    n=$((n + 1))
    local agent
    agent="$(_select_agent "$task")"
    echo "delegate_task(agent=\"$agent\", prompt=\"$task\", background=true)  # lane $n"
  done
}

log "Task distribution functions defined: _analyze_task _select_agent _distribute_tasks _parallel_execute"

# ── distribute.sh helper (CLI entry, mirrors 36-model-router.sh/recommend.sh) ─

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

if [ ! -f "$CONFIG" ]; then
  echo "Error: config.json not found at $CONFIG" >&2
  exit 1
fi

cmd="${1:-help}"
shift || true

json_flag=""
for a in "$@"; do [ "$a" = "--json" ] && json_flag="--json"; done

analyze() {
  python3 - "$CONFIG" "${1:-}" "$json_flag" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1])); desc = (sys.argv[2] or "").lower(); js = sys.argv[3] == "--json"
def classify(m, d):
    s = {k: sum(1 for kw in kws if kw in d) for k, kws in m.items()}
    b = max(s, key=s.get); return b if s[b] > 0 else ("coding" if m is cfg["keyword_map"] else "simple")
t = classify(cfg["keyword_map"], desc); c = classify(cfg["complexity_signals"], desc)
if t in ("research","planning","orchestration") and c == "simple": c = "medium"
if t == "orchestration" and c == "medium": c = "complex"
if js: print(json.dumps({"task_type": t, "complexity": c}))
else:  print(f"{t} / {c}")
PY
}

agent() {
  local a; a="$(analyze "${1:-}" --json)"
  local t c
  t="$(echo "$a" | python3 -c 'import json,sys;print(json.load(sys.stdin)["task_type"])')"
  c="$(echo "$a" | python3 -c 'import json,sys;print(json.load(sys.stdin)["complexity"])')"
  python3 - "$CONFIG" "$t" "$c" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1])); t = sys.argv[2]; c = sys.argv[3]
if c == "complex": a = "Commander"
elif t in ("research","planning"): a = "Planner"
elif t == "review": a = "Reviewer"
else: a = cfg["distribution_rules"].get(t, {}).get("agent", "Worker")
print(a)
PY
}

split() {
  local a t c
  a="$(analyze "${1:-}" --json)"
  t="$(echo "$a" | python3 -c 'import json,sys;print(json.load(sys.stdin)["task_type"])')"
  c="$(echo "$a" | python3 -c 'import json,sys;print(json.load(sys.stdin)["complexity"])')"
  python3 - "$CONFIG" "$t" "$c" "${1:-}" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1])); t = sys.argv[2]; c = sys.argv[3]; desc = sys.argv[4]
skill = cfg["distribution_rules"].get(t, {}).get("skill")
if c == "simple":
    p = [{"step":"implement","agent":"Worker","skill":skill,"depends":[]}]
elif c == "medium":
    p = [{"step":"research","agent":"Planner","skill":"research","depends":[]},
         {"step":"implement","agent":"Worker","skill":skill,"depends":["research"]}]
else:
    p = [{"step":"research","agent":"Planner","skill":"deep-research","depends":[]},
         {"step":"plan","agent":"Planner","skill":"plan","depends":["research"]},
         {"step":"implement","agent":"Worker","skill":skill,"depends":["plan"]},
         {"step":"verify","agent":"Reviewer","skill":"code-review","depends":["implement"]}]
print(json.dumps({"task": desc, "complexity": c, "task_type": t, "pipeline": p}, indent=2))
PY
}

parallel() {
  [ "$#" -eq 0 ] && { echo "# no subtasks"; exit 0; }
  echo "# ── Parallel dispatch (background=true) ──"
  local i=0
  for task in "$@"; do
    i=$((i+1))
    echo "delegate_task(agent=\"$(agent "$task")\", prompt=\"$task\", background=true)  # lane $i"
  done
}

case "$cmd" in
  analyze)  analyze "$@" ;;
  agent)    agent "$@" ;;
  split)    split "$@" ;;
  parallel) parallel "$@" ;;
  *)
    echo "Usage: distribute.sh {analyze|agent|split|parallel} <args...> [--json]"
    exit 1
    ;;
esac
DISTRIBUTE

chmod +x "$DISTRIBUTOR_DIR/distribute.sh"
log "Task distributor CLI: $DISTRIBUTOR_DIR/distribute.sh"

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
