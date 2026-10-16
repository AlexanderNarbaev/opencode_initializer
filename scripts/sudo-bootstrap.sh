#!/usr/bin/env bash
# One-shot sudo bootstrap for the opencode_initializer maximal build (2026-10-12).
# Run ONCE from a user terminal:  sudo bash scripts/sudo-bootstrap.sh
set -euo pipefail

echo "== 1/6 git 2.56+ via PPA =="
add-apt-repository -y ppa:git-core/ppa
apt-get update -qq
apt-get install -y git
git --version

echo "== 2/6 plugin dependencies (zellij; qdrant via docker) =="
apt-get install -y zellij 2>/dev/null || echo "zellij: no apt package, will use binary install"
command -v zellij && zellij --version || true

echo "== 3/6 services =="
systemctl enable --now docker 2>/dev/null || true
systemctl enable --now postgresql 2>/dev/null || true
systemctl enable --now redis-server 2>/dev/null || true
docker info --format '{{.ServerVersion}}' 2>/dev/null && echo "docker OK" || echo "docker NOT running"
redis-cli ping 2>/dev/null || true
pg_isready 2>/dev/null || true

echo "== 4/6 qdrant container (for opencode-supermemory) =="
docker start qdrant 2>/dev/null || docker run -d --name qdrant --restart unless-stopped -p 6333:6333 -p 6334:6334 qdrant/qdrant:latest
sleep 3
curl -s http://localhost:6333/readyz && echo " qdrant OK" || echo "qdrant NOT ready"

echo "== 5/6 project installer (update mode) =="
cd /home/alexandr-narbaev/Projects/opencode_initializer
SUDO_PASS="" bash setup.sh --update 2>&1 | tail -30 || true

echo "== 6/6 done =="
echo "sudo-bootstrap complete. Report back to the agent session."
