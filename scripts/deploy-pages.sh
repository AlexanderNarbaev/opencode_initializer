#!/usr/bin/env bash
# deploy-pages.sh — Deploy documentation to GitHub Pages and GitVerse Pages
# Usage: bash scripts/deploy-pages.sh [--github-only|--gitverse-only]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

log()  { echo -e "${CYAN}[deploy]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC} $*"; exit 1; }

DO_GITHUB=true
DO_GITVERSE=true

case "${1:-}" in
  --github-only)  DO_GITVERSE=false ;;
  --gitverse-only) DO_GITHUB=false ;;
esac

# ── Check prerequisites ──────────────────────────────────────────
log "Checking prerequisites..."
command -v python3 &>/dev/null || err "python3 not found"

# Activate venv if exists
if [ -f "$PROJECT_DIR/.venv-docs/bin/activate" ]; then
  source "$PROJECT_DIR/.venv-docs/bin/activate"
elif ! python3 -c "import mkdocs" 2>/dev/null; then
  err "MkDocs not installed. Run: python3 -m venv .venv-docs && pip install -r requirements.txt"
fi

# ── Build documentation ──────────────────────────────────────────
log "Building documentation..."
cd "$PROJECT_DIR"
mkdocs build --clean 2>&1 | tail -3
ok "Documentation built in site/"

# ── GitVerse Pages (static branch) ───────────────────────────────
if [ "$DO_GITVERSE" = true ]; then
  log "Deploying to GitVerse Pages (pages branch)..."
  
  TMPDIR=$(mktemp -d)
  cp -r site/* "$TMPDIR/"
  
  cd "$TMPDIR"
  git init
  git checkout -b pages
  git add -A
  git commit -m "docs: built site $(date +%Y-%m-%d)" --quiet
  
  git remote add gitverse git@gitverse.ru:AlexandrNarbaev/opencode_initializer.git 2>/dev/null || true
  git push gitverse pages --force --quiet 2>&1
  
  rm -rf "$TMPDIR"
  ok "GitVerse Pages deployed to 'pages' branch"
  log "  Site: https://alexandrnarbaev.gitverse.site/opencode_initializer"
fi

# ── GitHub Pages (via Actions trigger) ───────────────────────────
if [ "$DO_GITHUB" = true ]; then
  log "GitHub Pages deploys automatically via GitHub Actions on push to main."
  log "  Site: https://alexandernarbaev.github.io/opencode_initializer/"
  log "  If not deployed, push to main or check Actions tab."
fi

echo ""
echo -e "${GREEN}✓ Deploy complete${NC}"
