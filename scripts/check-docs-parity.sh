#!/usr/bin/env bash
#
# check-docs-parity.sh — i18n completeness gate for the MkDocs suffix structure.
#
# The docs site uses `mkdocs-static-i18n` with `docs_structure: suffix`, so every
# translated page is a `name.en.md` + `name.ru.md` pair. This gate enforces that:
#   1. every `.en.md` has a `.ru.md` sibling (and vice versa);
#   2. bare `.md` files (no locale suffix) appear only where explicitly allowlisted
#      (single-locale working documents: dated plans, research notes, ADRs).
#
# Exit 0 on success ("doc-parity: OK (N locale pairs)"), exit 1 on any violation
# (including bare-vs-suffixed conflicts counted in $bare_conflicts)
# ("PARITY GAP: ..." lines). bash 3.2 compatible (no associative arrays).

set -euo pipefail

# ---------------------------------------------------------------------------
# Allowlist: bare (non-suffixed) .md files that are intentionally single-locale.
# Paths are relative to docs/ and use forward slashes.
# ---------------------------------------------------------------------------
ALLOWLIST_FILES="
docs/VERSIONS.md
docs/manual-steps.md
docs/operations/orchestrator-patch.md
docs/audit/2026-08-22-full-audit.md
"

# Directory prefixes (relative to docs/) whose entire subtree may hold bare .md
# working documents (dated plans, research notes, ADRs, superpowers specs).
ALLOWLIST_DIRS="
architecture/adr/
plans/
research/
superpowers/
"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../docs" && pwd)"

# ---------------------------------------------------------------------------
# is_allowlisted <relpath>  -> 0 if the bare file is allowlisted, 1 otherwise
# ---------------------------------------------------------------------------
is_allowlisted() {
  local path="$1"
  local f
  local d
  for f in $ALLOWLIST_FILES; do
    [ -n "$f" ] && [ "docs/$path" = "$f" ] && return 0
  done
  for d in $ALLOWLIST_DIRS; do
    case "$path" in
      "$d"*) return 0 ;;
    esac
  done
  return 1
}

# ---------------------------------------------------------------------------
# has_pages_ancestor <dir>  -> 0 if any ancestor directory contains a .pages file
# ---------------------------------------------------------------------------
has_pages_ancestor() {
  local dir="$1"
  while [ "$dir" != "$DOCS_DIR" ] && [ "$dir" != "/" ]; do
    [ -f "$dir/.pages" ] && return 0
    dir="$(dirname "$dir")"
  done
  return 1
}

# Conflict rule (applies everywhere, incl. .pages-managed dirs): a bare page
# that also has a locale-suffixed sibling breaks mkdocs-static-i18n suffix mode.
bare_conflicts=0
while IFS= read -r f; do
  case "$f" in *.en.md|*.ru.md) continue ;; esac
  base="${f%.md}"
  # Only a FULL suffixed pair alongside the bare page is fatal (i18n suffix
  # mode). Legacy bare(EN) + .ru.md-only dirs are an accepted pattern.
  if [ -f "$base.en.md" ] && [ -f "$base.ru.md" ]; then
    echo "PARITY GAP: $f conflicts with locale-suffixed sibling"
    bare_conflicts=$((bare_conflicts + 1))
  fi
done < <(find "$DOCS_DIR" -name '*.md' ! -path '*/.archive/*' ! -path '*/site/*')

pairs=0
gaps=0

while IFS= read -r -d '' file; do
  # Exclude archive and built-site trees (absolute-path match is the most robust).
  case "$file" in
    *"/.archive/"* | *"/site/"*) continue ;;
  esac

  rel="${file#"$DOCS_DIR"/}"

  # Skip any subtree governed by a `.pages` file (the changelog blog structure).
  if has_pages_ancestor "$(dirname "$file")"; then
    continue
  fi

  case "$rel" in
    *.en.md)
      ru="${file%.en.md}.ru.md"
      if [ ! -f "$ru" ]; then
        echo "PARITY GAP: $rel missing ${rel%.en.md}.ru.md"
        gaps=$((gaps + 1))
      else
        pairs=$((pairs + 1))
      fi
      ;;
    *.ru.md)
      en="${file%.ru.md}.en.md"
      if [ ! -f "$en" ]; then
        echo "PARITY GAP: $rel missing ${rel%.ru.md}.en.md"
        gaps=$((gaps + 1))
      fi
      ;;
    *.md)
      # Bare file: must be allowlisted.
      if ! is_allowlisted "$rel"; then
        echo "PARITY GAP: $rel missing locale suffix (.en.md / .ru.md pair)"
        gaps=$((gaps + 1))
      fi
      ;;
  esac
done < <(find "$DOCS_DIR" -type f -name '*.md' -print0 | sort -z)

gaps=$((gaps + bare_conflicts))

if [ "$gaps" -gt 0 ]; then
  echo "doc-parity: FAILED ($gaps gap(s))"
  exit 1
fi

echo "doc-parity: OK ($pairs locale pairs)"
[ "$gaps" -eq 0 ] && [ "${bare_conflicts:-0}" -eq 0 ] && exit 0 || exit 1
