#!/usr/bin/env bash
# modes/new.sh — Initialize a new project directory only (no system/Docker/tools)
# Use: bash setup.sh --new <dir>
# Sources: helpers.sh + 00-core.sh must be sourced before this file
set -euo pipefail

if [ "$MODE" != "new" ]; then return 0; fi

PROJECT_DIR="${NEW_PROJECT_DIR:-}"
[ -z "$PROJECT_DIR" ] && { warn "--new requires <dir>"; exit 1; }
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd || echo "$PROJECT_DIR")"
[ -d "$PROJECT_DIR" ] || { warn "Dir not found: $PROJECT_DIR"; exit 1; }
export PROJECT_DIR

info "Initializing project: $PROJECT_DIR"
section "Project init: $(basename "$PROJECT_DIR")"

# Pre-source constitution module directly (not via _run_step) so
# exported functions _constitution_generate + _sdd_generate_commands
# survive into 17-project.sh's subshell where they are called.
source "$SCRIPT_DIR/src/lib/41-constitution.sh"

# Set total steps for _progress display
TOTAL_STEPS=5
CURRENT_STEP=0

_run_step step_project "Project structure" "$SCRIPT_DIR/src/lib/17-project.sh"
_run_step step_opencode_json "opencode.json" "$SCRIPT_DIR/src/lib/18-opencode-json.sh"
_run_step step_governance "Model governance" "$SCRIPT_DIR/src/lib/43-governance.sh"
_run_step step_audit "Audit trail" "$SCRIPT_DIR/src/lib/44-audit.sh"
_run_step step_pii_guard "PII sanitizer" "$SCRIPT_DIR/src/lib/45-pii-guard.sh"

log "Project initialized: $PROJECT_DIR"
exit 0
