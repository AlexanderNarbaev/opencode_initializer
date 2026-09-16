#!/usr/bin/env bash
# src/lib/80-templates.sh — Agent template management
# Part of Phase 2: Ecosystem Expansion
# shellcheck disable=SC2034
set -euo pipefail

TEMPLATES_DIR="${TEMPLATES_DIR:-$HOME/.config/opencode/templates}"

# ── Template Operations ──────────────────────────────────────────────────────

# Create a template
_template_create() {
  local template_name="${1:-}"
  local description="${2:-}"
  
  if [ -z "$template_name" ]; then
    err "Template name required"
  fi
  
  local template_dir="$TEMPLATES_DIR/$template_name"
  mkdir -p "$template_dir"
  
  cat > "$template_dir/template.yaml" <<EOF
name: $template_name
version: 1.0.0
description: $description
agents: []
skills: []
config: {}
EOF
  
  log "Template created: $template_name"
}

# List templates
_template_list() {
  if [ ! -d "$TEMPLATES_DIR" ]; then
    info "No templates"
    return 0
  fi
  
  find "$TEMPLATES_DIR" -maxdepth 1 -type d 2>/dev/null | while read -r d; do
    local name
    name=$(basename "$d")
    if [ "$name" != "$(basename "$TEMPLATES_DIR")" ]; then
      echo "$name"
    fi
  done | sort
}

# Use a template
_template_use() {
  local template_name="${1:-}"
  local target_dir="${2:-.}"
  
  if [ -z "$template_name" ]; then
    err "Template name required"
  fi
  
  local template_dir="$TEMPLATES_DIR/$template_name"
  
  if [ ! -d "$template_dir" ]; then
    err "Template not found: $template_name"
  fi
  
  info "Using template: $template_name"
  
  # Copy template files
  if [ -f "$template_dir/template.yaml" ]; then
    cp "$template_dir/template.yaml" "$target_dir/"
  fi
  
  log "Template applied: $template_name"
}

# Delete a template
_template_delete() {
  local template_name="${1:-}"
  
  if [ -z "$template_name" ]; then
    err "Template name required"
  fi
  
  local template_dir="$TEMPLATES_DIR/$template_name"
  
  if [ ! -d "$template_dir" ]; then
    err "Template not found: $template_name"
  fi
  
  rm -rf "$template_dir"
  log "Template deleted: $template_name"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_template() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    create)  _template_create "$@" ;;
    list)    _template_list ;;
    use)     _template_use "$@" ;;
    delete)  _template_delete "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode template <command> [args]

Commands:
  create <name> [description]  Create a template
  list                         List templates
  use <name> [target_dir]      Use a template
  delete <name>                Delete a template
EOF
      ;;
  esac
}
