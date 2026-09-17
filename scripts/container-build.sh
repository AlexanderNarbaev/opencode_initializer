#!/usr/bin/env bash
# Container build script for opencode_initializer
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
IMAGE_NAME="opencode-initializer"
IMAGE_TAG="latest"
BUILD_ARGS=""
PUSH=false
REGISTRY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --tag) IMAGE_TAG="$2"; shift 2 ;;
    --push) PUSH=true; shift ;;
    --registry) REGISTRY="$2"; shift 2 ;;
    --build-arg) BUILD_ARGS="$BUILD_ARGS --build-arg $2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Full image name
if [ -n "$REGISTRY" ]; then
  FULL_IMAGE="$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
else
  FULL_IMAGE="$IMAGE_NAME:$IMAGE_TAG"
fi

echo "Building container image: $FULL_IMAGE"

# Build image
docker build \
  --tag "$FULL_IMAGE" \
  --file "$PROJECT_DIR/Dockerfile" \
  $BUILD_ARGS \
  "$PROJECT_DIR"

echo "Build complete: $FULL_IMAGE"

# Push if requested
if [ "$PUSH" = true ]; then
  echo "Pushing image: $FULL_IMAGE"
  docker push "$FULL_IMAGE"
  echo "Push complete"
fi

echo "Done!"
