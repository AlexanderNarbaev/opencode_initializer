#!/usr/bin/env bash
# src/lib/00s-cloud-sync.sh — Cloud Sync (v6.0.0)
# Synchronize configuration and state across multiple machines.
set -euo pipefail

# ── Cloud sync configuration ─────────────────────────────────────────────────
_CLOUD_SYNC_DIR="${HOME}/.config/opencode-sync"
_CLOUD_SYNC_CONFIG="${_CLOUD_SYNC_DIR}/config.json"
_CLOUD_SYNC_STATE="${_CLOUD_SYNC_DIR}/state.json"
_CLOUD_SYNC_HISTORY="${_CLOUD_SYNC_DIR}/history.jsonl"

# ── Supported sync backends ──────────────────────────────────────────────────
# Using function-based lookup for bash 3.2 compatibility
_SYNC_BACKEND_NAMES=("github" "gitlab" "s3" "gcs" "azure" "dropbox" "gdrive" "rsync" "syncthing")

_sync_backend_description() {
  case "$1" in
    github) echo "GitHub Gist (private)" ;;
    gitlab) echo "GitLab Snippet" ;;
    s3) echo "AWS S3 / MinIO" ;;
    gcs) echo "Google Cloud Storage" ;;
    azure) echo "Azure Blob Storage" ;;
    dropbox) echo "Dropbox" ;;
    gdrive) echo "Google Drive" ;;
    rsync) echo "rsync over SSH" ;;
    syncthing) echo "Syncthing P2P" ;;
    *) echo "" ;;
  esac
}

# ── Initialize cloud sync ───────────────────────────────────────────────────
_cloud_sync_init() {
  mkdir -p "$_CLOUD_SYNC_DIR"
  
  if [ ! -f "$_CLOUD_SYNC_CONFIG" ]; then
    cat > "$_CLOUD_SYNC_CONFIG" <<EOF
{
  "version": "1.0.0",
  "backend": "github",
  "enabled": false,
  "auto_sync": true,
  "sync_interval": 3600,
  "encrypt": true,
  "compression": true,
  "conflict_resolution": "newest",
  "exclude": [
    "*.log",
    "node_modules",
    ".git",
    "*.tmp"
  ],
  "include": [
    "~/.config/opencode/**",
    "~/.config/opencode-setup/**",
    "~/.cache/opencode-setup/wal.md",
    "~/.cache/opencode-setup/progress"
  ]
}
EOF
  fi

  if [ ! -f "$_CLOUD_SYNC_STATE" ]; then
    cat > "$_CLOUD_SYNC_STATE" <<EOF
{
  "version": "1.0.0",
  "last_sync": null,
  "last_upload": null,
  "last_download": null,
  "sync_count": 0,
  "conflicts": [],
  "pending": []
}
EOF
  fi
}

# ── Configure sync backend ──────────────────────────────────────────────────
# Usage: _cloud_sync_configure "github" --token "xxx"
_cloud_sync_configure() {
  local backend="$1"
  shift

  _cloud_sync_init

  section "Configuring Cloud Sync: $backend"

  case "$backend" in
    github)
      local token="${1:-}"
      if [ -z "$token" ]; then
        warn "GitHub token required"
        return 1
      fi
      
      python3 -c "
import json
with open('$_CLOUD_SYNC_CONFIG', 'r') as f:
    config = json.load(f)
config['backend'] = 'github'
config['github_token'] = '$token'
config['enabled'] = True
with open('$_CLOUD_SYNC_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null || true
      
      log "GitHub backend configured"
      ;;
    
    gitlab)
      local token="${1:-}"
      if [ -z "$token" ]; then
        warn "GitLab token required"
        return 1
      fi
      
      python3 -c "
import json
with open('$_CLOUD_SYNC_CONFIG', 'r') as f:
    config = json.load(f)
config['backend'] = 'gitlab'
config['gitlab_token'] = '$token'
config['enabled'] = True
with open('$_CLOUD_SYNC_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null || true
      
      log "GitLab backend configured"
      ;;
    
    s3)
      local bucket="${1:-}" region="${2:-us-east-1}"
      if [ -z "$bucket" ]; then
        warn "S3 bucket required"
        return 1
      fi
      
      python3 -c "
import json
with open('$_CLOUD_SYNC_CONFIG', 'r') as f:
    config = json.load(f)
config['backend'] = 's3'
config['s3_bucket'] = '$bucket'
config['s3_region'] = '$region'
config['enabled'] = True
with open('$_CLOUD_SYNC_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null || true
      
      log "S3 backend configured"
      ;;
    
    rsync)
      local host="${1:-}" path="${2:-}"
      if [ -z "$host" ] || [ -z "$path" ]; then
        warn "SSH host and path required"
        return 1
      fi
      
      python3 -c "
import json
with open('$_CLOUD_SYNC_CONFIG', 'r') as f:
    config = json.load(f)
config['backend'] = 'rsync'
config['rsync_host'] = '$host'
config['rsync_path'] = '$path'
config['enabled'] = True
with open('$_CLOUD_SYNC_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null || true
      
      log "rsync backend configured"
      ;;
    
    *)
      warn "Unknown backend: $backend"
      info "Available: github, gitlab, s3, gcs, azure, dropbox, gdrive, rsync, syncthing"
      return 1
      ;;
  esac
}

# ── Upload config to cloud ──────────────────────────────────────────────────
# Usage: _cloud_sync_upload
_cloud_sync_upload() {
  _cloud_sync_init

  section "Uploading Configuration"

  local backend
  backend=$(python3 -c "import json; print(json.load(open('$_CLOUD_SYNC_CONFIG')).get('backend','github'))" 2>/dev/null || echo "github")

  # Create sync bundle
  local bundle="/tmp/opencode-sync-$(date +%Y%m%d-%H%M%S).tar.gz"
  local include_args=""
  
  # Read include patterns from config
  local includes
  includes=$(python3 -c "
import json
config = json.load(open('$_CLOUD_SYNC_CONFIG'))
for p in config.get('include', []):
    print(p)
" 2>/dev/null || true)

  # Create tar bundle
  tar -czf "$bundle" -C "$HOME" \
    .config/opencode \
    .config/opencode-setup \
    .cache/opencode-setup/wal.md \
    .cache/opencode-setup/progress \
    2>/dev/null || true

  case "$backend" in
    github)
      local token
      token=$(python3 -c "import json; print(json.load(open('$_CLOUD_SYNC_CONFIG')).get('github_token',''))" 2>/dev/null || echo "")
      
      if [ -z "$token" ]; then
        warn "GitHub token not configured"
        return 1
      fi
      
      # Upload as GitHub Gist
      local gist_id
      gist_id=$(curl -s -X POST \
        -H "Authorization: token $token" \
        -H "Content-Type: application/json" \
        -d '{
          "description": "opencode_initializer sync",
          "public": false,
          "files": {
            "opencode-sync.tar.gz": {
              "content": "'$(base64 -w0 "$bundle")'"
            }
          }
        }' \
        "https://api.github.com/gists" 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || echo "")
      
      if [ -n "$gist_id" ]; then
        log "Uploaded to GitHub Gist: $gist_id"
        
        # Save gist ID
        python3 -c "
import json
with open('$_CLOUD_SYNC_CONFIG', 'r') as f:
    config = json.load(f)
config['github_gist_id'] = '$gist_id'
with open('$_CLOUD_SYNC_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null || true
      else
        warn "Upload failed"
        return 1
      fi
      ;;
    
    rsync)
      local host path
      host=$(python3 -c "import json; print(json.load(open('$_CLOUD_SYNC_CONFIG')).get('rsync_host',''))" 2>/dev/null || echo "")
      path=$(python3 -c "import json; print(json.load(open('$_CLOUD_SYNC_CONFIG')).get('rsync_path',''))" 2>/dev/null || echo "")
      
      if [ -z "$host" ] || [ -z "$path" ]; then
        warn "rsync not configured"
        return 1
      fi
      
      if rsync -avz "$bundle" "${host}:${path}/opencode-sync.tar.gz" 2>/dev/null; then
        log "Uploaded via rsync"
      else
        warn "rsync upload failed"
        return 1
      fi
      ;;
    
    *)
      warn "Upload not implemented for backend: $backend"
      return 1
      ;;
  esac

  # Update state
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  python3 -c "
import json
with open('$_CLOUD_SYNC_STATE', 'r') as f:
    state = json.load(f)
state['last_upload'] = '$now'
state['last_sync'] = '$now'
state['sync_count'] = state.get('sync_count', 0) + 1
with open('$_CLOUD_SYNC_STATE', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null || true

  # Cleanup
  rm -f "$bundle"

  log "Upload complete"
}

# ── Download config from cloud ──────────────────────────────────────────────
# Usage: _cloud_sync_download
_cloud_sync_download() {
  _cloud_sync_init

  section "Downloading Configuration"

  local backend
  backend=$(python3 -c "import json; print(json.load(open('$_CLOUD_SYNC_CONFIG')).get('backend','github'))" 2>/dev/null || echo "github")

  case "$backend" in
    github)
      local token gist_id
      token=$(python3 -c "import json; print(json.load(open('$_CLOUD_SYNC_CONFIG')).get('github_token',''))" 2>/dev/null || echo "")
      gist_id=$(python3 -c "import json; print(json.load(open('$_CLOUD_SYNC_CONFIG')).get('github_gist_id',''))" 2>/dev/null || echo "")
      
      if [ -z "$token" ] || [ -z "$gist_id" ]; then
        warn "GitHub not configured"
        return 1
      fi
      
      # Download from GitHub Gist
      local bundle="/tmp/opencode-sync-download.tar.gz"
      local content
      content=$(curl -s \
        -H "Authorization: token $token" \
        "https://api.github.com/gists/$gist_id" 2>/dev/null | \
        python3 -c "import json,sys; g=json.load(sys.stdin); print(list(g.get('files',{}).values())[0].get('content',''))" 2>/dev/null || echo "")
      
      if [ -n "$content" ]; then
        echo "$content" | base64 -d > "$bundle"
        
        # Extract
        tar -xzf "$bundle" -C "$HOME" 2>/dev/null || true
        
        rm -f "$bundle"
        log "Downloaded from GitHub Gist"
      else
        warn "Download failed"
        return 1
      fi
      ;;
    
    rsync)
      local host path
      host=$(python3 -c "import json; print(json.load(open('$_CLOUD_SYNC_CONFIG')).get('rsync_host',''))" 2>/dev/null || echo "")
      path=$(python3 -c "import json; print(json.load(open('$_CLOUD_SYNC_CONFIG')).get('rsync_path',''))" 2>/dev/null || echo "")
      
      if [ -z "$host" ] || [ -z "$path" ]; then
        warn "rsync not configured"
        return 1
      fi
      
      local bundle="/tmp/opencode-sync-download.tar.gz"
      if rsync -avz "${host}:${path}/opencode-sync.tar.gz" "$bundle" 2>/dev/null; then
        tar -xzf "$bundle" -C "$HOME" 2>/dev/null || true
        rm -f "$bundle"
        log "Downloaded via rsync"
      else
        warn "rsync download failed"
        return 1
      fi
      ;;
    
    *)
      warn "Download not implemented for backend: $backend"
      return 1
      ;;
  esac

  # Update state
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  python3 -c "
import json
with open('$_CLOUD_SYNC_STATE', 'r') as f:
    state = json.load(f)
state['last_download'] = '$now'
state['last_sync'] = '$now'
state['sync_count'] = state.get('sync_count', 0) + 1
with open('$_CLOUD_SYNC_STATE', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null || true

  log "Download complete"
}

# ── Show sync status ────────────────────────────────────────────────────────
# Usage: _cloud_sync_status
_cloud_sync_status() {
  _cloud_sync_init

  section "Cloud Sync Status"

  python3 -c "
import json
with open('$_CLOUD_SYNC_CONFIG', 'r') as f:
    config = json.load(f)
with open('$_CLOUD_SYNC_STATE', 'r') as f:
    state = json.load(f)

print(f\"Backend:     {config.get('backend', 'not configured')}\")
print(f\"Enabled:     {config.get('enabled', False)}\")
print(f\"Auto-sync:   {config.get('auto_sync', False)}\")
print(f\"Encrypt:     {config.get('encrypt', False)}\")
print(f\"Last sync:   {state.get('last_sync', 'never')}\")
print(f\"Sync count:  {state.get('sync_count', 0)}\")
print(f\"Conflicts:   {len(state.get('conflicts', []))}\")
" 2>/dev/null || true
}

# ── List available backends ──────────────────────────────────────────────────
# Usage: _cloud_sync_backends
_cloud_sync_backends() {
  section "Available Sync Backends"

  for backend in "${_SYNC_BACKEND_NAMES[@]}"; do
    local desc
    desc=$(_sync_backend_description "$backend")
    printf "  %-15s %s\n" "$backend" "$desc"
  done
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _cloud_sync_init _cloud_sync_configure _cloud_sync_upload \
  _cloud_sync_download _cloud_sync_status _cloud_sync_backends 2>/dev/null || true
