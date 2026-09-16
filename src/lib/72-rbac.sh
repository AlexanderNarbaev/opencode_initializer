#!/usr/bin/env bash
# src/lib/72-rbac.sh — Role-based access control
# Part of Phase 1: Enterprise Features
# shellcheck disable=SC2034
set -euo pipefail

RBAC_DIR="${RBAC_DIR:-$HOME/.config/opencode/rbac}"
RBAC_ROLES_FILE="${RBAC_DIR}/roles.json"
RBAC_POLICIES_FILE="${RBAC_DIR}/policies.json"

# ── Role Management ──────────────────────────────────────────────────────────

# Initialize RBAC
_rbac_init() {
  mkdir -p "$RBAC_DIR"
  
  if [ ! -f "$RBAC_ROLES_FILE" ]; then
    cat > "$RBAC_ROLES_FILE" <<'EOF'
{
  "roles": [
    {
      "name": "admin",
      "description": "Full system access",
      "permissions": ["*"],
      "autonomy_level": 3
    },
    {
      "name": "developer",
      "description": "Development access",
      "permissions": ["read", "write", "execute", "test"],
      "autonomy_level": 2
    },
    {
      "name": "reviewer",
      "description": "Code review access",
      "permissions": ["read", "review", "approve"],
      "autonomy_level": 2
    },
    {
      "name": "viewer",
      "description": "Read-only access",
      "permissions": ["read"],
      "autonomy_level": 1
    },
    {
      "name": "agent",
      "description": "AI agent access",
      "permissions": ["read", "write", "execute"],
      "autonomy_level": 3
    }
  ]
}
EOF
    log "RBAC initialized with default roles"
  fi
}

# Create a role
_rbac_create_role() {
  local role_name="${1:-}"
  local description="${2:-}"
  local permissions="${3:-read}"
  local autonomy_level="${4:-1}"
  
  if [ -z "$role_name" ]; then
    err "Role name required"
  fi
  
  _rbac_init
  
  if command -v jq &>/dev/null; then
    # Check if role exists
    local exists
    exists=$(jq -r --arg name "$role_name" '.roles[] | select(.name == $name) | .name' "$RBAC_ROLES_FILE" 2>/dev/null)
    
    if [ -n "$exists" ]; then
      warn "Role already exists: $role_name"
      return 1
    fi
    
    # Add role
    jq --arg name "$role_name" --arg desc "$description" \
       --arg perms "$permissions" --argjson level "$autonomy_level" \
      '.roles += [{"name": $name, "description": $desc, "permissions": ($perms | split(",")), "autonomy_level": $level}]' \
      "$RBAC_ROLES_FILE" > "$RBAC_ROLES_FILE.tmp"
    mv "$RBAC_ROLES_FILE.tmp" "$RBAC_ROLES_FILE"
  fi
  
  log "Role created: $role_name"
}

# List roles
_rbac_list_roles() {
  _rbac_init
  
  if command -v jq &>/dev/null; then
    jq -r '.roles[] | "\(.name) — \(.description) (autonomy: \(.autonomy_level))"' \
      "$RBAC_ROLES_FILE" 2>/dev/null
  fi
}

# Get role info
_rbac_get_role() {
  local role_name="${1:-}"
  
  if [ -z "$role_name" ]; then
    err "Role name required"
  fi
  
  _rbac_init
  
  if command -v jq &>/dev/null; then
    jq --arg name "$role_name" '.roles[] | select(.name == $name)' \
      "$RBAC_ROLES_FILE" 2>/dev/null
  fi
}

# Delete a role
_rbac_delete_role() {
  local role_name="${1:-}"
  
  if [ -z "$role_name" ]; then
    err "Role name required"
  fi
  
  if [ "$role_name" = "admin" ]; then
    err "Cannot delete admin role"
  fi
  
  _rbac_init
  
  if command -v jq &>/dev/null; then
    jq --arg name "$role_name" \
      '.roles = [.roles[] | select(.name != $name)]' \
      "$RBAC_ROLES_FILE" > "$RBAC_ROLES_FILE.tmp"
    mv "$RBAC_ROLES_FILE.tmp" "$RBAC_ROLES_FILE"
  fi
  
  log "Role deleted: $role_name"
}

# ── Permission Checks ────────────────────────────────────────────────────────

# Check permission
_rbac_check_permission() {
  local role_name="${1:-}"
  local permission="${2:-}"
  
  if [ -z "$role_name" ] || [ -z "$permission" ]; then
    err "Role and permission required"
  fi
  
  _rbac_init
  
  if command -v jq &>/dev/null; then
    local has_perm
    has_perm=$(jq -r --arg role "$role_name" --arg perm "$permission" \
      '.roles[] | select(.name == $role) | .permissions | if any(. == "*") then "true" elif any(. == $perm) then "true" else "false" end' \
      "$RBAC_ROLES_FILE" 2>/dev/null)
    
    echo "$has_perm"
  fi
}

# Get autonomy level
_rbac_get_autonomy() {
  local role_name="${1:-}"
  
  if [ -z "$role_name" ]; then
    err "Role name required"
  fi
  
  _rbac_init
  
  if command -v jq &>/dev/null; then
    jq -r --arg name "$role_name" \
      '.roles[] | select(.name == $name) | .autonomy_level' \
      "$RBAC_ROLES_FILE" 2>/dev/null
  fi
}

# ── Policy Management ────────────────────────────────────────────────────────

# Create a policy
_rbac_create_policy() {
  local policy_name="${1:-}"
  local description="${2:-}"
  local rules="${3:-}"
  
  if [ -z "$policy_name" ]; then
    err "Policy name required"
  fi
  
  mkdir -p "$RBAC_DIR"
  
  if [ ! -f "$RBAC_POLICIES_FILE" ]; then
    echo '{"policies":[]}' > "$RBAC_POLICIES_FILE"
  fi
  
  if command -v jq &>/dev/null; then
    jq --arg name "$policy_name" --arg desc "$description" --arg rules "$rules" \
      '.policies += [{"name": $name, "description": $desc, "rules": ($rules | split(",")), "created_at": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}]' \
      "$RBAC_POLICIES_FILE" > "$RBAC_POLICIES_FILE.tmp"
    mv "$RBAC_POLICIES_FILE.tmp" "$RBAC_POLICIES_FILE"
  fi
  
  log "Policy created: $policy_name"
}

# List policies
_rbac_list_policies() {
  if [ ! -f "$RBAC_POLICIES_FILE" ]; then
    info "No policies"
    return 0
  fi
  
  if command -v jq &>/dev/null; then
    jq -r '.policies[] | "\(.name) — \(.description)"' \
      "$RBAC_POLICIES_FILE" 2>/dev/null
  fi
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_rbac() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    init)       _rbac_init ;;
    create)     _rbac_create_role "$@" ;;
    list)       _rbac_list_roles ;;
    get)        _rbac_get_role "$@" ;;
    delete)     _rbac_delete_role "$@" ;;
    check)      _rbac_check_permission "$@" ;;
    autonomy)   _rbac_get_autonomy "$@" ;;
    policy-create) _rbac_create_policy "$@" ;;
    policy-list)   _rbac_list_policies ;;
    help|*)
      cat <<'EOF'
Usage: opencode rbac <command> [args]

Commands:
  init                                    Initialize RBAC
  create <name> [desc] [perms] [level]    Create a role
  list                                    List roles
  get <name>                              Get role info
  delete <name>                           Delete a role
  check <role> <permission>               Check permission
  autonomy <name>                         Get autonomy level
  policy-create <name> [desc] [rules]     Create a policy
  policy-list                             List policies
EOF
      ;;
  esac
}
