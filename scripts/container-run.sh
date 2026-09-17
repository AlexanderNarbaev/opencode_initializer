#!/usr/bin/env bash
# Container run script for opencode_initializer
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
PROFILE=""
DETACH=true
PORTS="4096:4096"
VOLUMES=""
ENV_VARS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --profile) PROFILE="$2"; shift 2 ;;
    --detach) DETACH="$2"; shift 2 ;;
    --port) PORTS="$PORTS -p $2"; shift 2 ;;
    --volume) VOLUMES="$VOLUMES -v $2"; shift 2 ;;
    --env) ENV_VARS="$ENV_VARS -e $2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Build profile args
PROFILE_ARGS=""
if [ -n "$PROFILE" ]; then
  PROFILE_ARGS="--profile $PROFILE"
fi

echo "Starting opencode_initializer containers..."

# Run with docker-compose
docker compose \
  --project-directory "$PROJECT_DIR" \
  $PROFILE_ARGS \
  up -d

echo "Containers started!"
echo "Web UI: http://localhost:4096"
echo ""
echo "Useful commands:"
echo "  docker compose logs -f opencode    # View logs"
echo "  docker compose down                # Stop containers"
echo "  docker compose restart opencode    # Restart service"
