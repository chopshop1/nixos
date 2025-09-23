#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-${HOSTNAME:-devbox}}"
if [[ -z "$HOST" ]]; then
  echo "Usage: $0 <hostname>" >&2
  exit 1
fi

echo "Updating flake inputs..."
nix flake update

echo "Rebuilding NixOS configuration for host $HOST..."
sudo nixos-rebuild switch --flake ".#$HOST"

echo "Done. Consider running 'sudo nixos-rebuild test --rollback' if you need to validate before switching."
