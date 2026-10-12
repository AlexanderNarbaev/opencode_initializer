#!/usr/bin/env bash
set -euo pipefail
# OpenCode Initializer v15.0.0 - Module 35: Debt & Intent Registry
# Track technical debt and architectural decisions (VibeVM-inspired)

# NOTE: sourced by setup.sh — set -euo pipefail is idempotent there (setup.sh already strict).

REGISTRY_VERSION="1.0.0"
DISCIPLINE_DIR="${OPENCODE_DISCIPLINE_DIR:-${OPENCODE_ROOT:-.}/discipline/registry}"
DEBT_FILE="${DISCIPLINE_DIR}/debt.jsonl"
INTENT_FILE="${DISCIPLINE_DIR}/intent.jsonl"

registry_log_info() { log_info "[REGISTRY] $*"; }
registry_log_warn() { log_warn "[REGISTRY] $*"; }
registry_log_error() { log_error "[REGISTRY] $*"; }

init_registry() {
    registry_log_info "Initializing Debt & Intent Registry v${REGISTRY_VERSION}"
    mkdir -p "${DISCIPLINE_DIR}"
    [[ ! -f "${DEBT_FILE}" ]] && touch "${DEBT_FILE}"
    [[ ! -f "${INTENT_FILE}" ]] && touch "${INTENT_FILE}"
    registry_log_info "Registry initialized at ${DISCIPLINE_DIR}"
}

debt_add() {
    local id="$1" type="$2" severity="$3" title="$4" description="$5"
    echo "{\"id\":\"$id\",\"type\":\"$type\",\"severity\":\"$severity\",\"title\":\"$title\",\"description\":\"$description\",\"created\":\"$(date -Iseconds)\",\"status\":\"open\",\"wave\":null,\"resolution\":null}" >> "${DEBT_FILE}"
    registry_log_info "Added debt: $id - $title"
}

debt_list() {
    local status_filter="${1:-all}" severity_filter="${2:-all}"
    [[ ! -f "${DEBT_FILE}" ]] && { registry_log_warn "Debt file not found"; return 1; }
    echo "=== Technical Debt Registry ==="
    while IFS= read -r line; do
        local s=$(echo "$line" | jq -r '.status') sev=$(echo "$line" | jq -r '.severity')
        local i=$(echo "$line" | jq -r '.id') t=$(echo "$line" | jq -r '.title')
        [[ "$status_filter" != "all" && "$s" != "$status_filter" ]] && continue
        [[ "$severity_filter" != "all" && "$sev" != "$severity_filter" ]] && continue
        printf "%-12s [%-8s] %-40s\n" "$i" "$sev" "$t"
    done < "${DEBT_FILE}"
    echo "==============================="
}

debt_resolve() {
    local debt_id="$1" resolution="$2"
    [[ ! -f "${DEBT_FILE}" ]] && { registry_log_error "Debt file not found"; return 1; }
    local tmp_file=$(mktemp)
    while IFS= read -r line; do
        local id=$(echo "$line" | jq -r '.id')
        [[ "$id" == "$debt_id" ]] && line=$(echo "$line" | jq ".status = \"resolved\" | .resolution = \"$resolution\"")
        echo "$line" >> "$tmp_file"
    done < "${DEBT_FILE}"
    mv "$tmp_file" "${DEBT_FILE}"
    registry_log_info "Resolved debt: $debt_id"
}

intent_record() {
    local id="$1" decision="$2" rationale="$3" alternatives="$4" revisit="$5"
    echo "{\"id\":\"$id\",\"decision\":\"$decision\",\"rationale\":\"$rationale\",\"alternatives\":$alternatives,\"revisit_condition\":\"$revisit\",\"created\":\"$(date -Iseconds)\",\"status\":\"active\"}" >> "${INTENT_FILE}"
    registry_log_info "Recorded intent: $id"
}

intent_list() {
    [[ ! -f "${INTENT_FILE}" ]] && { registry_log_warn "Intent file not found"; return 1; }
    echo "=== Intent Ledger ==="
    while IFS= read -r line; do
        local i=$(echo "$line" | jq -r '.id') d=$(echo "$line" | jq -r '.decision') s=$(echo "$line" | jq -r '.status')
        printf "%-12s [%-8s] %s\n" "$i" "$s" "$d"
    done < "${INTENT_FILE}"
    echo "====================="
}

intent_render() {
    local intent_id="$1"
    [[ ! -f "${INTENT_FILE}" ]] && { registry_log_error "Intent file not found"; return 1; }
    local entry=$(grep "\"id\":\"$intent_id\"" "${INTENT_FILE}" || true)
    [[ -z "$entry" ]] && { registry_log_error "Intent not found: $intent_id"; return 1; }
    echo "## Intent: $intent_id"
    echo "**Decision:** $(echo "$entry" | jq -r '.decision')"
    echo "**Rationale:** $(echo "$entry" | jq -r '.rationale')"
    echo "**Alternatives:** $(echo "$entry" | jq -c '.alternatives')"
    echo "**Revisit:** $(echo "$entry" | jq -r '.revisit_condition')"
}

registry_stats() {
    echo "=== Registry Statistics ==="
    if [[ -f "${DEBT_FILE}" ]]; then
        echo "Debt: $(wc -l < "${DEBT_FILE}") total, $(grep -c '"status":"open"' "${DEBT_FILE}" || echo 0) open"
    fi
    if [[ -f "${INTENT_FILE}" ]]; then
        echo "Intent: $(wc -l < "${INTENT_FILE}") total, $(grep -c '"status":"active"' "${INTENT_FILE}" || echo 0) active"
    fi
    echo "==========================="
}

registry_cli() {
    local cmd="${1:-help}"; shift || true
    case "$cmd" in
        init) init_registry ;;
        debt-add) [[ $# -lt 5 ]] && { echo "Usage: registry debt-add <id> <type> <severity> <title> <description>"; exit 1; }; debt_add "$@" ;;
        debt-list) debt_list "${1:-all}" "${2:-all}" ;;
        debt-resolve) [[ $# -lt 2 ]] && { echo "Usage: registry debt-resolve <id> <resolution>"; exit 1; }; debt_resolve "$@" ;;
        intent-record) [[ $# -lt 5 ]] && { echo "Usage: registry intent-record <id> <decision> <rationale> <alternatives> <revisit>"; exit 1; }; intent_record "$@" ;;
        intent-list) intent_list ;;
        intent-render) [[ $# -lt 1 ]] && { echo "Usage: registry intent-render <id>"; exit 1; }; intent_render "$1" ;;
        stats) registry_stats ;;
        *) echo "Usage: registry <init|debt-add|debt-list|debt-resolve|intent-record|intent-list|intent-render|stats>" ;;
    esac
}

[[ "${OPENCODE_AUTO_INIT:-false}" == "true" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]] && init_registry

# Direct execution only (never runs when sourced by setup.sh)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        init|debt-add|debt-list|debt-resolve|intent-record|intent-list|intent-render|stats) registry_cli "$@" ;;
        *) registry_cli "help"; exit 2 ;;
    esac
fi
