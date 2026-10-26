#!/usr/bin/env bash
# src/lib/68-agent-mesh.sh — Agent networking and service discovery
# Part of Phase 0: Agent Orchestration
# shellcheck disable=SC2034
set -euo pipefail

AGENT_MESH_DIR="${AGENT_MESH_DIR:-$HOME/.local/share/opencode/agent-mesh}"
AGENT_MESH_REGISTRY="${AGENT_MESH_DIR}/registry.json"

# ── Agent Registration ───────────────────────────────────────────────────────

# Register an agent in the mesh
_agent_register() {
  local agent_name="${1:-}"
  local agent_type="${2:-}"
  local agent_endpoint="${3:-}"
  local agent_skills="${4:-}"
  
  if [ -z "$agent_name" ]; then
    err "Agent name required"
  fi
  
  mkdir -p "$AGENT_MESH_DIR"
  
  # Initialize registry if needed
  if [ ! -f "$AGENT_MESH_REGISTRY" ]; then
    echo '{"agents":[]}' > "$AGENT_MESH_REGISTRY"
  fi
  
  # Add agent to registry
  if command -v jq &>/dev/null; then
    local agent_json
    agent_json=$(cat <<EOF
{
  "name": "$agent_name",
  "type": "$agent_type",
  "endpoint": "$agent_endpoint",
  "skills": "$agent_skills",
  "registered_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "active"
}
EOF
    )
    
    jq --argjson agent "$agent_json" \
      '.agents += [$agent]' "$AGENT_MESH_REGISTRY" > "$AGENT_MESH_REGISTRY.tmp"
    mv "$AGENT_MESH_REGISTRY.tmp" "$AGENT_MESH_REGISTRY"
  fi
  
  log "Agent registered: $agent_name ($agent_type)"
}

# Unregister an agent
_agent_unregister() {
  local agent_name="${1:-}"
  
  if [ -z "$agent_name" ]; then
    err "Agent name required"
  fi
  
  if [ ! -f "$AGENT_MESH_REGISTRY" ]; then
    warn "No agent registry"
    return 1
  fi
  
  if command -v jq &>/dev/null; then
    jq --arg name "$agent_name" \
      '.agents = [.agents[] | select(.name != $name)]' \
      "$AGENT_MESH_REGISTRY" > "$AGENT_MESH_REGISTRY.tmp"
    mv "$AGENT_MESH_REGISTRY.tmp" "$AGENT_MESH_REGISTRY"
  fi
  
  log "Agent unregistered: $agent_name"
}

# ── Discovery ────────────────────────────────────────────────────────────────

# List all registered agents
_agent_list() {
  if [ ! -f "$AGENT_MESH_REGISTRY" ]; then
    info "No agents registered"
    return 0
  fi
  
  if command -v jq &>/dev/null; then
    jq -r '.agents[] | "\(.name) (\(.type)) — \(.status)"' \
      "$AGENT_MESH_REGISTRY" 2>/dev/null
  else
    cat "$AGENT_MESH_REGISTRY" 2>/dev/null
  fi
}

# Find agents by type
_agent_find_by_type() {
  local agent_type="${1:-}"
  
  if [ -z "$agent_type" ]; then
    err "Agent type required"
  fi
  
  if [ ! -f "$AGENT_MESH_REGISTRY" ]; then
    return 0
  fi
  
  if command -v jq &>/dev/null; then
    jq -r --arg type "$agent_type" \
      '.agents[] | select(.type == $type) | .name' \
      "$AGENT_MESH_REGISTRY" 2>/dev/null
  fi
}

# Find agents by skill
_agent_find_by_skill() {
  local skill="${1:-}"
  
  if [ -z "$skill" ]; then
    err "Skill required"
  fi
  
  if [ ! -f "$AGENT_MESH_REGISTRY" ]; then
    return 0
  fi
  
  if command -v jq &>/dev/null; then
    jq -r --arg skill "$skill" \
      '.agents[] | select(.skills | contains($skill)) | .name' \
      "$AGENT_MESH_REGISTRY" 2>/dev/null
  fi
}

# Get agent info
_agent_info() {
  local agent_name="${1:-}"
  
  if [ -z "$agent_name" ]; then
    err "Agent name required"
  fi
  
  if [ ! -f "$AGENT_MESH_REGISTRY" ]; then
    err "No agent registry"
  fi
  
  if command -v jq &>/dev/null; then
    jq --arg name "$agent_name" \
      '.agents[] | select(.name == $name)' \
      "$AGENT_MESH_REGISTRY" 2>/dev/null
  fi
}

# ── Health Check ─────────────────────────────────────────────────────────────

# Check agent health
_agent_health() {
  local agent_name="${1:-}"
  
  if [ -z "$agent_name" ]; then
    err "Agent name required"
  fi
  
  local agent_info
  agent_info=$(_agent_info "$agent_name" 2>/dev/null)
  
  if [ -z "$agent_info" ]; then
    echo "unknown"
    return 1
  fi
  
  # Check if agent has endpoint
  local endpoint
  endpoint=$(echo "$agent_info" | jq -r '.endpoint // ""' 2>/dev/null)
  
  if [ -z "$endpoint" ]; then
    echo "no_endpoint"
    return 0
  fi
  
  # Ping endpoint
  if command -v curl &>/dev/null; then
    if curl -sS --max-time 5 "$endpoint/health" &>/dev/null; then
      echo "healthy"
    else
      echo "unhealthy"
    fi
  else
    echo "unknown"
  fi
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_agent_mesh() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    register)   _agent_register "$@" ;;
    unregister) _agent_unregister "$@" ;;
    list)       _agent_list "$@" ;;
    find)       _agent_find_by_type "$@" ;;
    skill)      _agent_find_by_skill "$@" ;;
    info)       _agent_info "$@" ;;
    health)     _agent_health "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode agent-mesh <command> [args]

Commands:
  register <name> <type> [endpoint] [skills]  Register an agent
  unregister <name>                           Unregister an agent
  list                                        List all agents
  find <type>                                 Find agents by type
  skill <skill>                               Find agents by skill
  info <name>                                 Get agent info
  health <name>                               Check agent health
EOF
      ;;
  esac
}
