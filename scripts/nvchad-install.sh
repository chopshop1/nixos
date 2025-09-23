#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/NvChad/NvChad.git"
BRANCH="main"
TARGET="${HOME}/.config/nvim"

if [[ -d "$TARGET" && ! -d "$TARGET/.git" ]]; then
  echo "Target $TARGET exists but is not a git repository. Refusing to overwrite." >&2
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  echo "Cloning NvChad into $TARGET..."
  git clone --depth=1 --branch "$BRANCH" "$REPO" "$TARGET"
else
  echo "Updating existing NvChad repository in $TARGET..."
  git -C "$TARGET" fetch origin "$BRANCH"
  git -C "$TARGET" reset --hard "origin/$BRANCH"
fi

echo "NvChad installed. Launch nvim to trigger plugin sync if needed."
