#!/usr/bin/env bash
set -euo pipefail

if ! command -v nix >/dev/null 2>&1; then
  echo "nix command not found; install Nix to build the image." >&2
  exit 1
fi

IMAGE_NAME=${IMAGE_NAME:-devbox}
IMAGE_TAG=${IMAGE_TAG:-latest}
FLAKE_REF=${FLAKE_REF:-".#devbox-container"}
RESULT_DIR=$(mktemp -d)
trap 'rm -rf "$RESULT_DIR"' EXIT

nix run github:nix-community/nixos-generators -- \
  --flake "$FLAKE_REF" docker \
  --image-name "${IMAGE_NAME}:${IMAGE_TAG}" \
  --result "$RESULT_DIR/image.tar"

docker load < "$RESULT_DIR/image.tar"

echo "Docker image loaded as ${IMAGE_NAME}:${IMAGE_TAG}." >&2
echo "Run with: docker run --rm -it --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro ${IMAGE_NAME}:${IMAGE_TAG}" >&2
