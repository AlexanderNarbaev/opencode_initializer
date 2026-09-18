#!/usr/bin/env bash
set -euo pipefail
# Offline Bundle Module - Creates offline installation bundles
# Supports air-gapped environments

_BUNDLE_DIR="${HOME}/.cache/opencode/bundles"

# Create offline bundle
offline_bundle_create() {
  local name="${1:-latest}"
  local bundle_path="${_BUNDLE_DIR}/${name}.tar.gz"
  
  mkdir -p "$_BUNDLE_DIR"
  
  echo "Creating offline bundle: $name"
  
  # Collect key files
  tar -czf "$bundle_path" \
    -C "$HOME/.config/opencode" \
    opencode.json \
    secrets.env \
    2>/dev/null || true
  
  echo "Bundle created: $bundle_path"
}

# List available bundles
offline_bundle_list() {
  if [ -d "$_BUNDLE_DIR" ]; then
    ls -la "$_BUNDLE_DIR"/*.tar.gz 2>/dev/null || echo "No bundles found"
  else
    echo "No bundles directory"
  fi
}

# Restore from offline bundle
offline_bundle_restore() {
  local name="${1:-latest}"
  local bundle_path="${_BUNDLE_DIR}/${name}.tar.gz"
  
  if [ ! -f "$bundle_path" ]; then
    echo "Bundle not found: $bundle_path"
    return 1
  fi
  
  echo "Restoring from bundle: $name"
  tar -xzf "$bundle_path" -C "$HOME/.config/opencode"
  echo "Restore complete"
}

export -f offline_bundle_create offline_bundle_list offline_bundle_restore