#!/usr/bin/env bash
# lib/33-services.sh — Unified Service Configuration Layer
# Manages: port resolution, service modes (local/external/disabled),
#          deployment profiles (personal/corporate/airgapped/hybrid),
#          external service URLs for corporate environments.
set -euo pipefail

_step_skip step_services && return 0

section "Service Configuration"

# ── Resolve all service ports ──────────────────────────────────────────────
info "Deployment profile: ${DEPLOYMENT_PROFILE}"

for svc in "${!SERVICE_PORTS[@]}"; do
  mode=$(_service_mode "$svc")
  default_port="${SERVICE_PORTS[$svc]}"
  port=""

  case "$mode" in
    disabled)
      info "  ${svc}: disabled — skipping"
      continue
      ;;
    external)
      url_var="${svc^^}_EXTERNAL_URL"
      ext_url="${!url_var:-}"
      if [ -f "$SETUP_CONF" ]; then
        # shellcheck disable=SC1090
        . "$SETUP_CONF" 2>/dev/null
        ext_url="${!url_var:-$ext_url}"
      fi
      if [ -n "$ext_url" ]; then
        info "  ${svc}: external → ${ext_url}"
        _set_config "${svc^^}_PORT" "0"
      else
        info "  ${svc}: external mode but no URL set — falling back to local"
        mode="local"
      fi
      ;;
  esac

  if [ "$mode" = "local" ]; then
    port=$(_resolve_service_port "$svc" "$default_port")
    _set_config "${svc^^}_MODE" "local"
    _set_config "${svc^^}_PORT" "$port"
    if [ "$port" != "$default_port" ]; then
      info "  ${svc}: port ${port} (shifted from ${default_port})"
    else
      info "  ${svc}: port ${port}"
    fi
  fi
done

# ── Export resolved values for other modules ───────────────────────────────
if [ -f "$SETUP_CONF" ]; then
  while IFS='=' read -r key value; do
    [[ "$key" =~ ^[A-Z_]+$ ]] || continue
    [[ "$key" == *_API_KEY ]] && continue
    [[ "$key" == *_PASSWORD ]] && continue
    [[ "$key" == GIT_* ]] && continue
    value="${value#\"}"; value="${value%\"}"
    printf -v "${key?}" '%s' "$value"
    export "${key?}"
  done < "$SETUP_CONF"
fi

_step_done step_services
