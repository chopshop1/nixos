#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this script as the target user, not root." >&2
  exit 1
fi

PREFIX="$HOME/.npm-global"
ZSHRC="$HOME/.zshrc"
mkdir -p "$PREFIX"

ensure_line() {
  local line="$1"
  if [[ -f "$ZSHRC" ]] && grep -Fqx "$line" "$ZSHRC"; then
    return 0
  fi
  echo "$line" >> "$ZSHRC"
}

ensure_line 'export NPM_CONFIG_PREFIX="$HOME/.npm-global"'
ensure_line 'export PATH="$HOME/.npm-global/bin:$PATH"'

if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found. Ensure Node.js (with npm) is installed via the NixOS configuration." >&2
  exit 1
fi

npm config set prefix "$PREFIX"

install_pkg() {
  local pkg="$1"
  if npm info "$pkg" >/dev/null 2>&1; then
    npm install -g "$pkg"
    return 0
  fi
  return 1
}

warn_and_replace_codex() {
  echo "[WARN] @openai/codex CLI unavailable. Installing official OpenAI CLI (openai) instead." >&2
  npm install -g openai
  echo "[INFO] Use 'openai api' commands for code assistance. Documented in README." >&2
}

warn_and_replace_claude() {
  echo "[WARN] @anthropic-ai/claude-code unavailable. Install 'anthropic' CLI once officially published." >&2
}

if ! install_pkg "@anthropic-ai/claude-code"; then
  warn_and_replace_claude
fi

if ! install_pkg "@openai/codex"; then
  warn_and_replace_codex
fi

echo "Provisioning complete. Ensure ANTHROPIC_API_KEY and OPENAI_API_KEY are exported." >&2
