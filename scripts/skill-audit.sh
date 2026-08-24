#!/usr/bin/env bash
# scripts/skill-audit.sh — audit installed skills against auto-skills registration.
#
# Single purpose: surface drift between three views of the skill estate:
#   1. INSTALLED — SKILL.md files under the global skills directory
#      (${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills, or $OPENCODE_SKILLS_DIR).
#   2. REGISTERED — skill slugs referenced by the auto-skills config.json
#      (default_skills, priority, and every task_triggers[*]/file_triggers[*].skills).
#   3. USED — skill names mentioned in recent OpenCode logs (best-effort, optional).
#
# Advisory tool: exits 0 on any finding; exit 1 only with --strict when a skill
# is registered but not installed (broken) or the config is missing/unparseable.
#
# macOS bash 3.2 compatible: no associative arrays — sorted temp files + comm.
# All file paths are quoted. python3 is used only for the --json assembly.
set -euo pipefail

# Byte-order collation for sort/uniq/comm consistency (skill names are ASCII slugs).
export LC_ALL=C

SKILLS_ROOT="${OPENCODE_SKILLS_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills}"
CONFIG="${AUTO_SKILLS_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/auto-skills/config.json}"
LOG_DIR="${OPENCODE_LOG_DIR:-$HOME/.local/share/opencode/log}"
SINCE=30
OVERSIZE_LINES=400
MAX_LOGS=50
JSON=0
STRICT=0

usage() {
  cat <<'EOF'
Usage: skill-audit.sh [--json] [--strict] [--since N] [--help]

Audit installed skills against the auto-skills registration (config.json)
and report drift between what is installed, what is registered, and what
has recent usage evidence.

Checks (each reported as OK / WARN / INFO with counts):
  broken       registered in config.json but no SKILL.md on disk
  unregistered SKILL.md present but name absent from config.json
               (candidates to register, or to prune if unused)
  stale-config config.json missing or unparseable
  oversize     SKILL.md longer than 400 lines (split/trim hint)
  duplicates   same skill name present in more than one location
  used_recently unregistered skills with recent log mentions (KEEP candidates)

Flags:
  --json     machine-readable summary (counts + lists) via python3
  --strict   exit 1 when broken > 0 or stale-config
  --since N  look back N days for usage evidence (default 30)
  --help     this message

Environment overrides: OPENCODE_SKILLS_DIR, AUTO_SKILLS_CONFIG, OPENCODE_LOG_DIR.
Exit codes: 0 advisory success; 1 only with --strict when drift detected.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --json) JSON=1 ;;
    --strict) STRICT=1 ;;
    --since) shift; SINCE="${1:-30}" ;;
    --help | -h) usage; exit 0 ;;
    *) echo "Unknown flag: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT

# ── 1. Installed skills: one "name<TAB>path" line per SKILL.md found ──────
# Flat layout (root/<name>/SKILL.md) and scoped bundles (root/<...>/skills/<name>/SKILL.md)
# are both covered by a bounded find; .git trees are skipped.
: > "$TMPD/skills"
if [ -d "$SKILLS_ROOT" ]; then
  find "$SKILLS_ROOT" -maxdepth 6 -name SKILL.md -not -path '*/.git/*' 2>/dev/null \
    | while IFS= read -r f; do
        [ -n "$f" ] || continue
        printf '%s\t%s\n' "$(basename "$(dirname "$f")")" "$f"
      done > "$TMPD/skills" || true
fi

cut -f1 "$TMPD/skills" | sort > "$TMPD/names_sorted"
uniq "$TMPD/names_sorted" > "$TMPD/names"            # distinct skill names
cut -f1 "$TMPD/skills" | sort | uniq -d > "$TMPD/dups"  # names with >1 location

# ── 2. Registered skills from auto-skills config.json ─────────────────────
: > "$TMPD/registered"
if [ ! -f "$CONFIG" ]; then
  STALE=1
elif ! jq empty "$CONFIG" >/dev/null 2>&1; then
  STALE=1
else
  STALE=0
  jq -r '
    [ (.default_skills // []), (.priority // []) ]
    + [ (.task_triggers // {}) | to_entries[]? | .value.skills // [] ]
    + [ (.file_triggers  // {}) | to_entries[]? | .value.skills // [] ]
    | flatten
    | map(select(type == "string" and length > 0))
    | .[]
  ' "$CONFIG" 2>/dev/null | sort -u > "$TMPD/registered" || STALE=1
fi

# ── 3/4. broken (registered-not-installed) vs unregistered (installed-not-registered)
comm -23 "$TMPD/registered" "$TMPD/names" > "$TMPD/broken" || true
comm -13 "$TMPD/registered" "$TMPD/names" > "$TMPD/unregistered" || true

# ── 5. Oversize SKILL.md files ────────────────────────────────────────────
: > "$TMPD/oversize"
while IFS=$'\t' read -r name path; do
  [ -n "$name" ] || continue
  [ -f "$path" ] || continue
  lines="$(wc -l < "$path" 2>/dev/null || echo 0)"
  lines="${lines// /}"
  [ -n "$lines" ] || lines=0
  if [ "$lines" -gt "$OVERSIZE_LINES" ] 2>/dev/null; then
    echo "$name" >> "$TMPD/oversize"
  fi
done < "$TMPD/skills"
sort -u "$TMPD/oversize" -o "$TMPD/oversize"

# ── 6. Usage evidence (optional): unregistered skills mentioned in logs ───
: > "$TMPD/used"
if [ -d "$LOG_DIR" ]; then
  recent_logs="$(find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' -mtime "-${SINCE}" 2>/dev/null | head -"$MAX_LOGS")"
  if [ -n "$recent_logs" ]; then
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      if grep -l -m1 -F -- "$name" $recent_logs >/dev/null 2>&1; then
        echo "$name" >> "$TMPD/used"
      fi
    done < "$TMPD/unregistered"
  fi
fi

# ── Counts ────────────────────────────────────────────────────────────────
count() { wc -l < "$1" | tr -d ' '; }
INSTALLED="$(count "$TMPD/names")"
REGISTERED="$(count "$TMPD/registered")"
BROKEN="$(count "$TMPD/broken")"
UNREGISTERED="$(count "$TMPD/unregistered")"
OVERSIZE="$(count "$TMPD/oversize")"
DUPES="$(count "$TMPD/dups")"
USED="$(count "$TMPD/used")"

join_list() { tr '\n' ' ' < "$1" | sed 's/ *$//'; }

if [ "$JSON" -eq 1 ]; then
  python3 - "$TMPD" "$STALE" <<'PY'
import json, os, sys
tmpd = sys.argv[1]
stale = bool(int(sys.argv[2]))

def lines(name):
    p = os.path.join(tmpd, name)
    try:
        with open(p, encoding="utf-8") as fh:
            return [l.rstrip("\n") for l in fh if l.strip()]
    except OSError:
        return []

def count(name):
    return len(lines(name))

out = {
    "installed": count("names"),
    "registered": count("registered"),
    "broken": count("broken"),
    "unregistered": count("unregistered"),
    "oversize": count("oversize"),
    "duplicates": count("dups"),
    "used_recently": count("used"),
    "stale_config": stale,
    "broken_list": lines("broken"),
    "unregistered_list": lines("unregistered"),
    "oversize_list": lines("oversize"),
    "duplicates_list": lines("dups"),
    "used_recently_list": lines("used"),
}
print(json.dumps(out, indent=2, ensure_ascii=False))
PY
  exit 0
fi

# ── Human-readable report ─────────────────────────────────────────────────
echo "Skills audit"
echo "  Skills root:   $SKILLS_ROOT"
echo "  Config:        $CONFIG"
echo "  Log dir:       $LOG_DIR (since ${SINCE}d)"
echo

if [ "$STALE" -eq 1 ]; then
  echo "WARN stale-config: config.json missing or unparseable at $CONFIG"
else
  echo "OK   config: $REGISTERED skills registered"
fi

if [ "$BROKEN" -gt 0 ]; then
  echo "WARN broken ($BROKEN): $(join_list "$TMPD/broken")"
else
  echo "OK   broken: none (every registered skill has a SKILL.md)"
fi

if [ "$UNREGISTERED" -gt 0 ]; then
  echo "INFO unregistered ($UNREGISTERED): $(join_list "$TMPD/unregistered")"
else
  echo "OK   unregistered: none"
fi

if [ "$OVERSIZE" -gt 0 ]; then
  echo "INFO oversize ($OVERSIZE): $(join_list "$TMPD/oversize")"
else
  echo "OK   oversize: none (all SKILL.md <= $OVERSIZE_LINES lines)"
fi

if [ "$DUPES" -gt 0 ]; then
  echo "WARN duplicates ($DUPES): $(join_list "$TMPD/dups")"
else
  echo "OK   duplicates: none"
fi

if [ "$USED" -gt 0 ]; then
  echo "INFO used_recently ($USED): $(join_list "$TMPD/used")  ← KEEP candidates"
else
  echo "OK   used_recently: none"
fi

echo
echo "SKILLS AUDIT SUMMARY: installed=$INSTALLED registered=$REGISTERED broken=$BROKEN unregistered=$UNREGISTERED oversize=$OVERSIZE duplicates=$DUPES used_recently=$USED"

if [ "$STRICT" -eq 1 ] && { [ "$BROKEN" -gt 0 ] || [ "$STALE" -eq 1 ]; }; then
  exit 1
fi
exit 0
