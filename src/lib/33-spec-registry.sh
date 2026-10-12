#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# OpenCode Initializer v15.0.0 - Module 33: Spec Registry
# =============================================================================
# Description: VibeVM-inspired spec:// URI system for cognitive artifacts
# Version: 1.0.0
# Status: Active
# Dependencies: 00-core.sh, 05-logging.sh, 10-config.sh
# Gap Addressed: S3 (spec:// URI scheme), SK3 (spec tree with artifacts)
# =============================================================================

# NOTE: sourced by setup.sh — set -euo pipefail is idempotent there (setup.sh already strict).

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
SPEC_REGISTRY_VERSION="1.0.0"
SPEC_REGISTRY_DIR="${OPENCODE_SPEC_DIR:-${OPENCODE_ROOT:-.}/specs}"
SPEC_CATALOG_FILE="${SPEC_REGISTRY_DIR}/catalog.json"
SPEC_INDEX_FILE="${SPEC_REGISTRY_DIR}/index.jsonl"

# Package kinds (VibeVM-compatible)
declare -a VALID_PACKAGE_KINDS=(
    "flow"      # Workflow definitions
    "feat"      # Feature specifications
    "stack"     # Technology stack configs
    "tool"      # Tool configurations
    "mcp"       # MCP server specs
    "lang"      # Language-specific guidelines
    "doc"       # Documentation specs
    "app"       # Application blueprints
)

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
spec_log_info() {
    log_info "[SPEC] $*"
}

spec_log_warn() {
    log_warn "[SPEC] $*"
}

spec_log_error() {
    log_error "[SPEC] $*"
}

spec_log_debug() {
    log_debug "[SPEC] $*"
}

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------
init_spec_registry() {
    spec_log_info "Initializing Spec Registry v${SPEC_REGISTRY_VERSION}"
    
    # Create directory structure
    mkdir -p "${SPEC_REGISTRY_DIR}"
    mkdir -p "${SPEC_REGISTRY_DIR}/flows"
    mkdir -p "${SPEC_REGISTRY_DIR}/feats"
    mkdir -p "${SPEC_REGISTRY_DIR}/stacks"
    mkdir -p "${SPEC_REGISTRY_DIR}/tools"
    mkdir -p "${SPEC_REGISTRY_DIR}/mcps"
    mkdir -p "${SPEC_REGISTRY_DIR}/langs"
    mkdir -p "${SPEC_REGISTRY_DIR}/docs"
    mkdir -p "${SPEC_REGISTRY_DIR}/apps"
    
    # Initialize catalog if not exists
    if [[ ! -f "${SPEC_CATALOG_FILE}" ]]; then
        spec_log_info "Creating initial spec catalog"
        cat > "${SPEC_CATALOG_FILE}" << 'EOF'
{
    "version": "1.0.0",
    "created": "$(date -Iseconds)",
    "total_specs": 0,
    "kinds": {
        "flow": 0,
        "feat": 0,
        "stack": 0,
        "tool": 0,
        "mcp": 0,
        "lang": 0,
        "doc": 0,
        "app": 0
    },
    "specs": []
}
EOF
    fi
    
    # Initialize index if not exists
    if [[ ! -f "${SPEC_INDEX_FILE}" ]]; then
        touch "${SPEC_INDEX_FILE}"
    fi
    
    spec_log_info "Spec Registry initialized at ${SPEC_REGISTRY_DIR}"
}

# -----------------------------------------------------------------------------
# URI Parser
# -----------------------------------------------------------------------------
# Parse spec:// URI
# Format: spec://<kind>/<name>[@version][/path]
# Example: spec://feat/auth-flow@1.0.0/requirements
parse_spec_uri() {
    local uri="$1"
    local result_var="${2:-}"
    
    # Validate URI format
    if [[ ! "$uri" =~ ^spec:// ]]; then
        spec_log_error "Invalid URI format: $uri (must start with spec://)"
        return 1
    fi
    
    # Remove spec:// prefix
    local path="${uri#spec://}"
    
    # Parse components
    local kind name version subpath
    
    # Extract kind (before first /)
    kind="${path%%/*}"
    path="${path#*/}"
    
    # Validate kind
    local valid_kind=false
    for k in "${VALID_PACKAGE_KINDS[@]}"; do
        if [[ "$k" == "$kind" ]]; then
            valid_kind=true
            break
        fi
    done
    
    if [[ "$valid_kind" != "true" ]]; then
        spec_log_error "Invalid package kind: $kind (valid: ${VALID_PACKAGE_KINDS[*]})"
        return 1
    fi
    
    # Extract name (before @ or /)
    if [[ "$path" == *"@"* ]]; then
        name="${path%%@*}"
        local remainder="${path#*@}"
        if [[ "$remainder" == *"/"* ]]; then
            version="${remainder%%/*}"
            subpath="${remainder#*/}"
        else
            version="$remainder"
            subpath=""
        fi
    elif [[ "$path" == *"/"* ]]; then
        name="${path%%/*}"
        subpath="${path#*/}"
        version="latest"
    else
        name="$path"
        version="latest"
        subpath=""
    fi
    
    # Remove trailing slash from subpath
    subpath="${subpath%/}"
    
    # Build result
    local result
    result=$(cat << EOF
{
    "uri": "$uri",
    "kind": "$kind",
    "name": "$name",
    "version": "$version",
    "subpath": "$subpath",
    "file_path": "${SPEC_REGISTRY_DIR}/${kind}s/${name}",
    "resolved": false
}
EOF
)
    
    if [[ -n "$result_var" ]]; then
        echo "$result" | jq -r ".$result_var"
    else
        echo "$result"
    fi
}

# Resolve spec URI to file path
resolve_spec_uri() {
    local uri="$1"
    local parsed
    parsed=$(parse_spec_uri "$uri")
    
    local kind name version subpath file_path
    kind=$(echo "$parsed" | jq -r '.kind')
    name=$(echo "$parsed" | jq -r '.name')
    version=$(echo "$parsed" | jq -r '.version')
    subpath=$(echo "$parsed" | jq -r '.subpath')
    file_path=$(echo "$parsed" | jq -r '.file_path')
    
    # Check if spec exists
    local spec_file="${file_path}.spec.json"
    if [[ ! -f "$spec_file" ]]; then
        spec_log_error "Spec not found: $uri"
        return 1
    fi
    
    # Handle version resolution
    if [[ "$version" == "latest" ]]; then
        # Get latest version from spec file
        version=$(jq -r '.version' "$spec_file")
    fi
    
    # Build full path
    local full_path
    if [[ -n "$subpath" ]]; then
        full_path="${file_path}/${subpath}"
    else
        full_path="$spec_file"
    fi
    
    echo "$full_path"
}

# -----------------------------------------------------------------------------
# CRUD Operations
# -----------------------------------------------------------------------------
# Register a new spec
register_spec() {
    local kind="$1"
    local name="$2"
    local title="$3"
    local description="$4"
    local version="${5:-1.0.0}"
    local status="${6:-draft}"
    
    # Validate kind
    local valid_kind=false
    for k in "${VALID_PACKAGE_KINDS[@]}"; do
        if [[ "$k" == "$kind" ]]; then
            valid_kind=true
            break
        fi
    done
    
    if [[ "$valid_kind" != "true" ]]; then
        spec_log_error "Invalid package kind: $kind"
        return 1
    fi
    
    local spec_dir="${SPEC_REGISTRY_DIR}/${kind}s/${name}"
    local spec_file="${spec_dir}.spec.json"
    
    # Create directory
    mkdir -p "$(dirname "$spec_file")"
    
    # Create spec file
    cat > "$spec_file" << EOF
{
    "\$schema": "https://opencode.initializer/schemas/spec-v1.json",
    "uri": "spec://${kind}/${name}@${version}",
    "kind": "$kind",
    "name": "$name",
    "title": "$title",
    "description": "$description",
    "version": "$version",
    "status": "$status",
    "created": "$(date -Iseconds)",
    "updated": "$(date -Iseconds)",
    "authors": [],
    "reviewers": [],
    "dependencies": [],
    "tags": [],
    "content": {
        "requirements": [],
        "acceptance_criteria": [],
        "implementation_notes": [],
        "test_strategy": []
    },
    "metadata": {
        "complexity": "medium",
        "priority": "medium",
        "estimated_tokens": 0,
        "actual_tokens": 0
    }
}
EOF
    
    # Update index
    echo "{\"event\":\"register\",\"uri\":\"spec://${kind}/${name}@${version}\",\"timestamp\":\"$(date -Iseconds)\"}" >> "${SPEC_INDEX_FILE}"
    
    # Update catalog
    update_spec_catalog
    
    spec_log_info "Registered spec: spec://${kind}/${name}@${version}"
    echo "$spec_file"
}

# Update existing spec
update_spec() {
    local kind="$1"
    local name="$2"
    local field="$3"
    local value="$4"
    
    local spec_file="${SPEC_REGISTRY_DIR}/${kind}s/${name}.spec.json"
    
    if [[ ! -f "$spec_file" ]]; then
        spec_log_error "Spec not found: spec://${kind}/${name}"
        return 1
    fi
    
    # Update field using jq
    local tmp_file
    tmp_file=$(mktemp)
    jq ".$field = $value" "$spec_file" > "$tmp_file" && mv "$tmp_file" "$spec_file"
    
    # Update timestamp
    tmp_file=$(mktemp)
    jq ".updated = \"$(date -Iseconds)\"" "$spec_file" > "$tmp_file" && mv "$tmp_file" "$spec_file"
    
    # Update index
    echo "{\"event\":\"update\",\"uri\":\"spec://${kind}/${name}\",\"field\":\"$field\",\"timestamp\":\"$(date -Iseconds)\"}" >> "${SPEC_INDEX_FILE}"
    
    spec_log_info "Updated spec: spec://${kind}/${name} ($field)"
}

# Delete spec
delete_spec() {
    local kind="$1"
    local name="$2"
    
    local spec_file="${SPEC_REGISTRY_DIR}/${kind}s/${name}.spec.json"
    
    if [[ ! -f "$spec_file" ]]; then
        spec_log_error "Spec not found: spec://${kind}/${name}"
        return 1
    fi
    
    rm -f "$spec_file"
    
    # Update index
    echo "{\"event\":\"delete\",\"uri\":\"spec://${kind}/${name}\",\"timestamp\":\"$(date -Iseconds)\"}" >> "${SPEC_INDEX_FILE}"
    
    # Update catalog
    update_spec_catalog
    
    spec_log_info "Deleted spec: spec://${kind}/${name}"
}

# Get spec content
get_spec() {
    local uri="$1"
    local resolved_path
    resolved_path=$(resolve_spec_uri "$uri")
    
    if [[ -f "$resolved_path" ]]; then
        cat "$resolved_path"
    else
        spec_log_error "Spec not found: $uri"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Catalog Management
# -----------------------------------------------------------------------------
update_spec_catalog() {
    local specs=()
    local spec_kinds=()
    
    # Find all specs
    while IFS= read -r -d '' spec_file; do
        local kind name version title status
        kind=$(jq -r '.kind' "$spec_file")
        name=$(jq -r '.name' "$spec_file")
        version=$(jq -r '.version' "$spec_file")
        title=$(jq -r '.title' "$spec_file")
        status=$(jq -r '.status' "$spec_file")
        
        # Record kind for per-kind counts (bash 3.2-safe — no declare -A)
        spec_kinds+=("$kind")
        
        # Add to specs array
        specs+=("$(jq -c '{uri: .uri, kind: .kind, name: .name, title: .title, version: .version, status: .status}' "$spec_file")")
    done < <(find "${SPEC_REGISTRY_DIR}" -name "*.spec.json" -print0)
    
    # Build catalog
    local total=${#specs[@]}
    local catalog_tmp
    catalog_tmp=$(mktemp)
    
    cat > "$catalog_tmp" << EOF
{
    "version": "1.0.0",
    "updated": "$(date -Iseconds)",
    "total_specs": $total,
    "kinds": {
EOF
    
    # Add counts
    local first=true
    for k in "${VALID_PACKAGE_KINDS[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo "," >> "$catalog_tmp"
        fi
        local kcount=0
        local sk
        for sk in ${spec_kinds[@]+"${spec_kinds[@]}"}; do
            if [ "$sk" = "$k" ]; then
                kcount=$((kcount + 1))
            fi
        done
        printf '        "%s": %d' "$k" "$kcount" >> "$catalog_tmp"
    done
    
    cat >> "$catalog_tmp" << EOF

    },
    "specs": [
EOF
    
    # Add specs
    first=true
    for spec in "${specs[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo "," >> "$catalog_tmp"
        fi
        printf '        %s' "$spec" >> "$catalog_tmp"
    done
    
    cat >> "$catalog_tmp" << EOF

    ]
}
EOF
    
    mv "$catalog_tmp" "${SPEC_CATALOG_FILE}"
    spec_log_info "Updated catalog: $total specs"
}

list_specs() {
    local kind_filter="${1:-}"
    
    if [[ ! -f "${SPEC_CATALOG_FILE}" ]]; then
        spec_log_warn "Catalog not found. Run 'init_spec_registry' first."
        return 1
    fi
    
    if [[ -n "$kind_filter" ]]; then
        jq -r ".specs[] | select(.kind == \"$kind_filter\") | \"\\(.uri) - \\(.title) [\\(.status)]\"" "${SPEC_CATALOG_FILE}"
    else
        jq -r '.specs[] | "\(.uri) - \(.title) [\(.status)]"' "${SPEC_CATALOG_FILE}"
    fi
}

# -----------------------------------------------------------------------------
# Citation Checker
# -----------------------------------------------------------------------------
check_citations() {
    local target_dir="${1:-.}"
    local errors=0
    local warnings=0
    local checked=0
    
    spec_log_info "Checking citations in $target_dir"
    
    # Find all spec:// references in code
    while IFS= read -r line; do
        ((checked++)) || true
        
        # Extract URI
        local uri
        uri=$(echo "$line" | grep -oE 'spec://[a-zA-Z0-9/_@.-]+' || true)
        
        if [[ -z "$uri" ]]; then
            continue
        fi
        
        # Check if spec exists
        if ! resolve_spec_uri "$uri" &>/dev/null; then
            spec_log_error "Broken citation: $uri in $line"
            ((errors++)) || true
        fi
    done < <(grep -r "spec://" "$target_dir" --include="*.sh" --include="*.py" --include="*.js" --include="*.ts" --include="*.md" 2>/dev/null || true)
    
    spec_log_info "Citation check complete: $checked references, $errors errors, $warnings warnings"
    
    if [[ $errors -gt 0 ]]; then
        return 1
    fi
    return 0
}

# -----------------------------------------------------------------------------
# CLI Interface
# -----------------------------------------------------------------------------
spec_cli() {
    local cmd="${1:-help}"
    shift || true
    
    case "$cmd" in
        init)
            init_spec_registry
            ;;
        register)
            if [[ $# -lt 4 ]]; then
                echo "Usage: spec register <kind> <name> <title> <description> [version] [status]"
                exit 1
            fi
            register_spec "$@"
            ;;
        get)
            if [[ $# -lt 1 ]]; then
                echo "Usage: spec get <uri>"
                exit 1
            fi
            get_spec "$1"
            ;;
        update)
            if [[ $# -lt 4 ]]; then
                echo "Usage: spec update <kind> <name> <field> <value>"
                exit 1
            fi
            update_spec "$@"
            ;;
        delete)
            if [[ $# -lt 2 ]]; then
                echo "Usage: spec delete <kind> <name>"
                exit 1
            fi
            delete_spec "$@"
            ;;
        list)
            list_specs "${1:-}"
            ;;
        resolve)
            if [[ $# -lt 1 ]]; then
                echo "Usage: spec resolve <uri>"
                exit 1
            fi
            resolve_spec_uri "$1"
            ;;
        parse)
            if [[ $# -lt 1 ]]; then
                echo "Usage: spec parse <uri>"
                exit 1
            fi
            parse_spec_uri "$1"
            ;;
        check)
            check_citations "${1:-.}"
            ;;
        help|*)
            cat << EOF
OpenCode Spec Registry CLI v${SPEC_REGISTRY_VERSION}

Usage: spec <command> [options]

Commands:
  init                          Initialize spec registry
  register <kind> <name> <title> <description> [version] [status]
                                Register a new spec
  get <uri>                     Get spec content
  update <kind> <name> <field> <value>
                                Update spec field
  delete <kind> <name>          Delete spec
  list [kind]                   List specs (optionally filter by kind)
  resolve <uri>                 Resolve URI to file path
  parse <uri>                   Parse URI components
  check [directory]             Check citations in codebase

Package Kinds:
  flow, feat, stack, tool, mcp, lang, doc, app

Examples:
  spec init
  spec register feat auth-flow "Authentication Flow" "User authentication specification" 1.0.0 approved
  spec get spec://feat/auth-flow@1.0.0
  spec list feat
  spec check ./src

EOF
            ;;
    esac
}

# Export functions

# Auto-initialize if sourced and OPENCODE_AUTO_INIT is set
if [[ "${OPENCODE_AUTO_INIT:-false}" == "true" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_spec_registry
fi

# Direct execution only (never runs when sourced by setup.sh)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        init|register|update|delete|get|list|check-citations|catalog) spec_cli "$@" ;;
        *) spec_cli "help"; exit 2 ;;
    esac
fi
