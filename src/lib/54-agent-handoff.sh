#!/usr/bin/env bash
set -euo pipefail
# Module 54: Agent Handoff - Context transfer between design stages
# NOTE: sourced by setup.sh — set -euo pipefail is idempotent there (setup.sh already strict).
# ── Idempotent module constants (safe under repeated sourcing) ──
MODULE_54_VERSION="${MODULE_54_VERSION:-"1.0.0"}"
MODULE_54_DIR="${MODULE_54_DIR:-"${OPENCODE_ROOT:-$PWD}/.opencode/agent-handoffs"}"

# Guard: only source core/logging when running standalone (avoid double-source under setup.sh)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  source "${OPENCODE_ROOT:-$PWD}/src/lib/helpers.sh" || { echo "ERROR: Cannot load helpers"; exit 1; }
  source "${OPENCODE_ROOT:-$PWD}/src/lib/00-core.sh" || { echo "ERROR: Cannot load core"; exit 1; }
  source "${OPENCODE_ROOT:-$PWD}/src/lib/00y-logging.sh" || { echo "ERROR: Cannot load logging"; exit 1; }
fi

create_handoff() {
    local from_stage="${1:-}"; local to_stage="${2:-}"; local feature="${3:-}"
    [[ -z "$from_stage" || -z "$to_stage" || -z "$feature" ]] && { log_error "Usage: opencode agent-handoff create <from-stage> <to-stage> <feature>"; return 1; }
    
    local slug=$(echo "$feature" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
    local ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    mkdir -p "$MODULE_54_DIR"
    
    cat > "${MODULE_54_DIR}/${slug}-${from_stage}-to-${to_stage}.json" << ENDJSON
{
  "handoff_id": "handoff-${slug}-${ts}",
  "feature": "$feature",
  "from_stage": "$from_stage",
  "to_stage": "$to_stage",
  "timestamp": "$ts",
  "status": "pending",
  "context": {
    "artifacts": [],
    "decisions": [],
    "open_questions": [],
    "constraints": []
  },
  "acknowledged_by_agent": false,
  "acknowledged_at": null
}
ENDJSON
    log_success "Handoff created: ${slug}-${from_stage}-to-${to_stage}.json"
}

list_handoffs() {
    find "$MODULE_54_DIR" -name "*.json" 2>/dev/null | while read f; do
        basename "$f" .json
    done
}

main_agent_handoff() {
    case "${1:-help}" in
        create) create_handoff "$2" "$3" "$4" ;;
        list) list_handoffs ;;
        *) echo "Usage: opencode agent-handoff {create|list}" ;;
    esac
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_agent_handoff "$@"
fi

