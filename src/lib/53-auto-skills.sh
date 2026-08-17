#!/usr/bin/env bash
# src/lib/53-auto-skills.sh — Auto-Triggering Skill System (STEP 53)
# Context-aware skill activation: detects the task type from free-text context
# and file extensions, then suggests the minimal set of skills under
# .opencode/skills/ to load — without user intervention.
#
# Single source of truth: the trigger tables below (bash functions) + the
# generated ~/.config/opencode/auto-skills/config.json (human-readable mirror,
# regenerated on each run). Keep the two in sync when editing either.
#
# macOS bash 3.2 compatible: no associative arrays (indexed/word-list only).
set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# Utility functions — defined unconditionally so they stay available to the
# agent at runtime (even after the install step is marked done).
# ══════════════════════════════════════════════════════════════════════════════

# _dedupe <word ...> — remove duplicate words, preserving first-seen order.
_dedupe() {
  local out="" w
  for w in $*; do
    case " $out " in
      *" $w "*) : ;;
      *) out="$out $w" ;;
    esac
  done
  echo "${out# }"
}

# _keyword_match <text> <space-separated keywords> — 0 if any keyword matches
# the text as a whole word (case-insensitive, ASCII word boundaries).
_keyword_match() {
  local text="${1:-}" kw
  for kw in ${2:-}; do
    if grep -qiE "(^|[^[:alnum:]])${kw}([^[:alnum:]]|$)" <<<"$text"; then
      return 0
    fi
  done
  return 1
}

# _skills_for_type <task-type> — map a task category to its skill slugs.
# Slugs are relative to .opencode/skills/ (project) or the global config dir.
# Mirrors config.json "task_triggers".
_skills_for_type() {
  case "${1:-}" in
    specify)  echo "specify" ;;
    plan)     echo "plan brainstorm clarify" ;;
    test)     echo "running-tests matt-pocock/tdd writing-tests" ;;
    debug)    echo "matt-pocock/diagnosing-bugs" ;;
    review)   echo "matt-pocock/code-review codebase-review-swarm" ;;
    refactor) echo "matt-pocock/improve-codebase-architecture matt-pocock/codebase-design" ;;
    research) echo "deep-research matt-pocock/research" ;;
    coding)   echo "matt-pocock/implement coprocessor" ;;
    *)        echo "coprocessor" ;;
  esac
}

# _skill_path <slug> — resolve a skill slug to its SKILL.md path.
# Checks the project's .opencode/skills/ first, then the global config dir.
_skill_path() {
  local slug="${1:-}" base
  [ -n "$slug" ] || return 1
  for base in "${PROJECT_DIR:-}" "${HOME}/.config/opencode"; do
    [ -n "$base" ] || continue
    if [ -f "$base/.opencode/skills/$slug/SKILL.md" ]; then
      echo "$base/.opencode/skills/$slug/SKILL.md"
      return 0
    fi
  done
  return 1
}

# _detect_task_type [text ...] — detect the task category from free text.
# Sources, in order: positional args → $AUTO_SKILLS_CTX → git working-tree
# status. Falls back to "coding". Priority order below biases toward the more
# specific categories (test is matched last: "test"/"verify" are common
# substrings of unrelated words, so more distinctive types win first).
_detect_task_type() {
  local text="${*:-}"
  [ -z "$text" ] && text="${AUTO_SKILLS_CTX:-}"
  [ -z "$text" ] && text="$(git status --short 2>/dev/null | tr '\n' ' ' || true)"
  [ -z "$text" ] && { echo "coding"; return 0; }

  _keyword_match "$text" "specify specification requirements define"  && { echo "specify";   return 0; }
  _keyword_match "$text" "plan planning design architect"            && { echo "plan";      return 0; }
  _keyword_match "$text" "debug fix bug error exception"             && { echo "debug";     return 0; }
  _keyword_match "$text" "review"                                    && { echo "review";    return 0; }
  _keyword_match "$text" "refactor improve"                          && { echo "refactor";  return 0; }
  _keyword_match "$text" "research investigate"                      && { echo "research";  return 0; }
  _keyword_match "$text" "test tests testing verify validate"        && { echo "test";      return 0; }

  echo "coding"
  return 0
}

# _detect_file_skills [files ...] — map file extensions to skills.
# Sources, in order: positional args → $AUTO_SKILLS_FILES → git-changed files.
# Mirrors config.json "file_triggers".
_detect_file_skills() {
  local files="${*:-}"
  [ -z "$files" ] && files="${AUTO_SKILLS_FILES:-}"
  [ -z "$files" ] && files="$(git diff --name-only --diff-filter=ACMRT 2>/dev/null | tr '\n' ' ' || true)"

  local out="" f ext
  for f in $files; do
    ext="${f##*.}"
    case "$ext" in
      ts|tsx|js|jsx|mjs|cjs)
        out="$out matt-pocock/implement matt-pocock/tdd matt-pocock/codebase-design" ;;
      py|pyi)
        out="$out matt-pocock/implement running-tests" ;;
      sh|bash|zsh)
        out="$out running-tests" ;;
    esac
  done
  echo "$(_dedupe $out)"
}

# _auto_load_skills [text ...] — resolve the minimal set of SKILL.md paths for
# the given context (task type + file skills, deduplicated, only installed).
_auto_load_skills() {
  local task skills slug path out=""
  task="$(_detect_task_type "$@")"
  skills="$(_dedupe "$(_skills_for_type "$task") $(_detect_file_skills)")"

  for slug in $skills; do
    if path="$(_skill_path "$slug")"; then
      out="$out $path"
    fi
  done
  echo "${out# }"
}

# _skill_suggest [text ...] — human-readable skill recommendation.
_skill_suggest() {
  local task slug path file_skills all
  task="$(_detect_task_type "$@")"
  file_skills="$(_detect_file_skills)"
  all="$(_dedupe "$(_skills_for_type "$task") $file_skills")"

  echo "Task type: $task"
  echo "Skills: $(_skills_for_type "$task")"
  [ -n "$file_skills" ] && echo "File skills: $file_skills"
  echo "Load via:"
  for slug in $all; do
    if path="$(_skill_path "$slug")"; then
      echo "  → $slug  ($path)"
    else
      echo "  → $slug  (not installed)"
    fi
  done
  echo "Usage: read the SKILL.md content above into the agent context, or invoke the 'skill' tool."
}

# ══════════════════════════════════════════════════════════════════════════════
# Install — gated by step tracking, idempotent on re-run.
# ══════════════════════════════════════════════════════════════════════════════

_step_skip step_auto_skills && return 0

# Opt-out flag (matches SKIP_DOTFILES / SKIP_DEVBOX / SKIP_GUI convention)
[ "${SKIP_AUTO_SKILLS:-false}" = "true" ] && { info "Auto-skills skipped (SKIP_AUTO_SKILLS=true)"; return 0; }

section "Auto-Triggering Skills"

AUTO_SKILLS_DIR="${AUTO_SKILLS_DIR:-$HOME/.config/opencode/auto-skills}"
mkdir -p "$AUTO_SKILLS_DIR"

# ── Trigger table (human-readable mirror of the bash functions above) ────────
cat >"$AUTO_SKILLS_DIR/config.json" <<'CONFIG'
{
  "$schema": "https://opencode.ai/auto-skills.json",
  "version": "1.0.0",
  "description": "Auto-Triggering Skill System — maps task types and file types to skills under .opencode/skills/. Regenerated by 53-auto-skills.sh; keep in sync with the bash trigger tables in that module.",

  "task_triggers": {
    "specify":  { "keywords": ["specify", "specification", "requirements", "define"], "skills": ["specify"] },
    "plan":     { "keywords": ["plan", "planning", "design", "architect"], "skills": ["plan", "brainstorm", "clarify"] },
    "test":     { "keywords": ["test", "tests", "testing", "verify", "validate"], "skills": ["running-tests", "matt-pocock/tdd", "writing-tests"] },
    "debug":    { "keywords": ["debug", "fix", "bug", "error", "exception"], "skills": ["matt-pocock/diagnosing-bugs"] },
    "review":   { "keywords": ["review"], "skills": ["matt-pocock/code-review", "codebase-review-swarm"] },
    "refactor": { "keywords": ["refactor", "improve"], "skills": ["matt-pocock/improve-codebase-architecture", "matt-pocock/codebase-design"] },
    "research": { "keywords": ["research", "investigate"], "skills": ["deep-research", "matt-pocock/research"] },
    "coding":   { "keywords": ["implement", "build", "create"], "skills": ["matt-pocock/implement", "coprocessor"] }
  },

  "file_triggers": {
    "typescript": { "patterns": [".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs"], "skills": ["matt-pocock/implement", "matt-pocock/tdd", "matt-pocock/codebase-design"] },
    "python":     { "patterns": [".py", ".pyi"], "skills": ["matt-pocock/implement", "running-tests"] },
    "shell":      { "patterns": [".sh", ".bash", ".zsh"], "skills": ["running-tests"] }
  },

  "default_skills": ["coprocessor"],
  "priority": ["specify", "plan", "debug", "review", "refactor", "research", "test", "coding"],
  "_comment": "skills are slugs relative to .opencode/skills/ (project) or ~/.config/opencode/skills/ (global, flat)"
}
CONFIG

log "Auto-skills config written to $AUTO_SKILLS_DIR/config.json"

# ── Readiness summary ────────────────────────────────────────────────────────
info "Auto-Triggering Skills ready. Detection/suggestion helpers:"
info "  _detect_task_type '<task text>'"
info "  _skill_suggest    '<task text>'"
info "  _auto_load_skills '<task text>'"

_step_done step_auto_skills
log "Auto-Triggering Skills configured"
