#!/usr/bin/env bash
# src/lib/63-skill-manager.sh — Skill version management, rollback, updates
# Part of Phase 0: Skill Management System
# shellcheck disable=SC2034
set -euo pipefail

SKILL_MANAGER_HISTORY="${SKILL_INSTALL_DIR}/.history"
SKILL_MANAGER_LOCKFILE="${SKILL_INSTALL_DIR}/.lock"

# ── Version Management ───────────────────────────────────────────────────────

# Get installed version of a skill
_skill_get_version() {
  local skill_name="${1:-}"
  local install_path="$SKILL_INSTALL_DIR/$skill_name"
  
  if [ ! -d "$install_path" ]; then
    echo "not_installed"
    return 1
  fi
  
  cat "$install_path/VERSION" 2>/dev/null || echo "unknown"
}

# Compare versions (returns: -1, 0, 1)
_skill_version_compare() {
  local v1="${1:-0.0.0}" v2="${2:-0.0.0}"
  
  # Normalize versions
  v1="${v1#v}" v2="${v2#v}"
  
  IFS='.' read -r a1 b1 c1 <<< "$v1"
  IFS='.' read -r a2 b2 c2 <<< "$v2"
  
  a1=${a1:-0} b1=${b1:-0} c1=${c1:-0}
  a2=${a2:-0} b2=${b2:-0} c2=${c2:-0}
  
  if [ "$a1" -lt "$a2" ]; then echo -1; return; fi
  if [ "$a1" -gt "$a2" ]; then echo 1; return; fi
  if [ "$b1" -lt "$b2" ]; then echo -1; return; fi
  if [ "$b1" -gt "$b2" ]; then echo 1; return; fi
  if [ "$c1" -lt "$c2" ]; then echo -1; return; fi
  if [ "$c1" -gt "$c2" ]; then echo 1; return; fi
  echo 0
}

# Check for updates
_skill_check_updates() {
  local skill_name="${1:-all}"
  
  if [ "$skill_name" = "all" ]; then
    info "Checking updates for all installed skills..."
    for skill_dir in "$SKILL_INSTALL_DIR"/*/; do
      [ -d "$skill_dir" ] || continue
      local name
      name=$(basename "$skill_dir")
      _skill_check_updates "$name" || true
    done
    return 0
  fi
  
  local installed_version
  installed_version=$(_skill_get_version "$skill_name") || return 0
  
  # Fetch latest version from registry
  local latest_version
  latest_version=$(_skill_registry_info "$skill_name" 2>/dev/null | \
    jq -r '.version // "0.0.0"' 2>/dev/null || echo "0.0.0")
  
  if [ "$latest_version" = "0.0.0" ]; then
    warn "Cannot determine latest version for $skill_name"
    return 1
  fi
  
  local cmp
  cmp=$(_skill_version_compare "$installed_version" "$latest_version")
  
  if [ "$cmp" -lt 0 ]; then
    echo "UPDATE: $skill_name $installed_version → $latest_version"
  elif [ "$cmp" -eq 0 ]; then
    echo "OK: $skill_name@$installed_version (latest)"
  else
    echo "NEWER: $skill_name@$installed_version (registry: $latest_version)"
  fi
}

# Update a skill
_skill_update() {
  local skill_name="${1:-}"
  local target_version="${2:-latest}"
  
  if [ -z "$skill_name" ]; then
    err "Skill name required"
  fi
  
  local installed_version
  installed_version=$(_skill_get_version "$skill_name") || {
    warn "Skill $skill_name not installed"
    return 1
  }
  
  # Backup current version
  _skill_backup "$skill_name" || true
  
  # Install new version
  _skill_install "$skill_name@$target_version" "true"
  
  # Record in history
  _skill_record_history "$skill_name" "$installed_version" "$target_version"
  
  log "Skill $skill_name updated: $installed_version → $target_version"
}

# ── Backup & Rollback ───────────────────────────────────────────────────────

# Backup a skill version
_skill_backup() {
  local skill_name="${1:-}"
  local install_path="$SKILL_INSTALL_DIR/$skill_name"
  
  if [ ! -d "$install_path" ]; then
    return 1
  fi
  
  local version
  version=$(cat "$install_path/VERSION" 2>/dev/null || echo "unknown")
  local backup_dir="$SKILL_INSTALL_DIR/.backups/$skill_name/$version"
  
  mkdir -p "$backup_dir"
  cp -r "$install_path"/* "$backup_dir/" 2>/dev/null || true
  
  info "Backed up $skill_name@$version"
}

# Rollback to previous version
_skill_rollback() {
  local skill_name="${1:-}"
  
  if [ -z "$skill_name" ]; then
    err "Skill name required"
  fi
  
  local backup_dir="$SKILL_INSTALL_DIR/.backups/$skill_name"
  
  if [ ! -d "$backup_dir" ]; then
    err "No backups found for $skill_name"
  fi
  
  # Find latest backup
  local latest_backup
  latest_backup=$(ls -1d "$backup_dir"/*/ 2>/dev/null | sort -V | tail -1)
  
  if [ -z "$latest_backup" ]; then
    err "No backups found for $skill_name"
  fi
  
  local version
  version=$(basename "$latest_backup")
  
  info "Rolling back $skill_name to $version"
  
  # Restore from backup
  local install_path="$SKILL_INSTALL_DIR/$skill_name"
  rm -rf "$install_path"
  cp -r "$latest_backup" "$install_path"
  
  log "Rolled back $skill_name to $version"
}

# List available backups
_skill_list_backups() {
  local skill_name="${1:-}"
  
  if [ -z "$skill_name" ]; then
    err "Skill name required"
  fi
  
  local backup_dir="$SKILL_INSTALL_DIR/.backups/$skill_name"
  
  if [ ! -d "$backup_dir" ]; then
    info "No backups for $skill_name"
    return 0
  fi
  
  for dir in "$backup_dir"/*/; do
    [ -d "$dir" ] || continue
    echo "$skill_name@$(basename "$dir")"
  done
}

# ── History ──────────────────────────────────────────────────────────────────

# Record operation in history
_skill_record_history() {
  local skill_name="${1:-}"
  local from_version="${2:-}"
  local to_version="${3:-}"
  local operation="${4:-update}"
  
  mkdir -p "$(dirname "$SKILL_MANAGER_HISTORY")"
  
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $operation $skill_name $from_version → $to_version" \
    >> "$SKILL_MANAGER_HISTORY"
}

# Show history
_skill_show_history() {
  local skill_name="${1:-}"
  local limit="${2:-20}"
  
  if [ ! -f "$SKILL_MANAGER_HISTORY" ]; then
    info "No history available"
    return 0
  fi
  
  if [ -n "$skill_name" ]; then
    grep "$skill_name" "$SKILL_MANAGER_HISTORY" | tail -n "$limit"
  else
    tail -n "$limit" "$SKILL_MANAGER_HISTORY"
  fi
}

# ── Cleanup ──────────────────────────────────────────────────────────────────

# Clean old backups
_skill_cleanup_backups() {
  local keep="${1:-3}"
  
  info "Cleaning old backups (keeping $keep versions)..."
  
  for skill_dir in "$SKILL_INSTALL_DIR/.backups"/*/; do
    [ -d "$skill_dir" ] || continue
    local skill_name
    skill_name=$(basename "$skill_dir")
    
    local count=0
    for version_dir in $(ls -1d "$skill_dir"/*/ 2>/dev/null | sort -V -r); do
      ((count++))
      if [ "$count" -gt "$keep" ]; then
        info "Removing old backup: $skill_name@$(basename "$version_dir")"
        rm -rf "$version_dir"
      fi
    done
  done
  
  log "Backup cleanup complete"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_skill_manager() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    version)    _skill_get_version "$@" ;;
    updates)    _skill_check_updates "$@" ;;
    update)     _skill_update "$@" ;;
    rollback)   _skill_rollback "$@" ;;
    backups)    _skill_list_backups "$@" ;;
    history)    _skill_show_history "$@" ;;
    cleanup)    _skill_cleanup_backups "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode skill-manager <command> [args]

Commands:
  version <name>          Get installed version
  updates [name]          Check for updates
  update <name> [version] Update skill
  rollback <name>         Rollback to previous version
  backups <name>          List available backups
  history [name] [limit]  Show operation history
  cleanup [keep]          Clean old backups (default: keep 3)
EOF
      ;;
  esac
}
