#!/usr/bin/env bash
# lib/02-docker.sh — Docker (STEP 2)
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_DOCKER"; then
  section "Docker"
  if ! command -v docker &>/dev/null; then
    DOCKER_SCRIPT=$(mktemp /tmp/docker-install.XXXXXX.sh)
    if _curl "https://get.docker.com" "$DOCKER_SCRIPT" &>/dev/null && sudo sh "$DOCKER_SCRIPT" 2>/dev/null; then
      sudo usermod -aG docker "$USER" 2>/dev/null || true
      log "Docker installed (relogin needed for group)"
    elif _retry 3 "Docker apt install" sudo apt-get install -y docker.io docker-compose-v2 2>/dev/null; then
      [ -f "$DOCKER_SCRIPT" ] && rm -f "$DOCKER_SCRIPT"
      if command -v docker &>/dev/null; then
        log "Docker installed from apt (relogin needed for group)"
      else
        warn "Docker install failed — install manually: https://docs.docker.com/engine/install/ubuntu/"
      fi
    else
      warn "Docker entirely unavailable — install manually"
    fi
  fi
  if command -v docker &>/dev/null && [ ! -f /etc/docker/daemon.json ]; then
    sudo mkdir -p /etc/docker
    echo '{
  "registry-mirrors": [
    "https://mirror.gcr.io",
    "https://docker.mirrors.ustc.edu.cn",
    "https://docker.m.daocloud.io"
  ],
  "dns": ["77.88.8.8", "77.88.8.1", "1.1.1.1", "8.8.8.8"]
}' | sudo tee /etc/docker/daemon.json >/dev/null && \
      sudo systemctl restart docker 2>/dev/null && \
      log "Docker mirror configured" || true
  fi
  _step_done step_docker
fi
