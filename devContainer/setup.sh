#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="/build/config"
HOME="${HOME:-/home/dev}"

# --- Create home directories ---
mkdir -p "$HOME/.config/git" \
         "$HOME/.config/starship" \
         "$HOME/.config/mprocs" \
         "$HOME/.local/bin" \
         "$HOME/.zsh" \
         "$HOME/.cache"

# --- Symlink config files ---
ln -sf "$CONFIG_DIR/zshrc"         "$HOME/.zshrc"
ln -sf "$CONFIG_DIR/starship.toml" "$HOME/.config/starship.toml"
ln -sf "$CONFIG_DIR/tmux.conf"     "$HOME/.tmux.conf"
ln -sf "$CONFIG_DIR/gitconfig"     "$HOME/.config/git/config"
ln -sf "$CONFIG_DIR/mprocs.yaml"   "$HOME/.config/mprocs/mprocs.yaml"

# --- Set git user from env vars ---
if [ -n "${GIT_USER_NAME:-}" ]; then
  git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
  git config --global user.email "$GIT_USER_EMAIL"
fi

# --- Install TPM for tmux (if not present) ---
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" 2>/dev/null || true
fi

# --- Welcome banner ---
cat <<'BANNER'

  ╔══════════════════════════════════════════════╗
  ║          Nix Dev Container                   ║
  ╠══════════════════════════════════════════════╣
  ║  Shell:     zsh + starship + fzf             ║
  ║  Editor:    neovim                           ║
  ║  Mux:       tmux + mprocs                    ║
  ║  Languages: node, bun, python, rust, go      ║
  ║  Tools:     git, gh, docker, ripgrep, fd     ║
  ║                                              ║
  ║  Run 'nix develop' to enter the full shell   ║
  ║  Run 'dev' to open a tmux workspace          ║
  ╚══════════════════════════════════════════════╝

BANNER

# --- Enter nix shell or run command ---
if [ $# -gt 0 ]; then
  exec nix develop /build --command "$@"
else
  exec nix develop /build --command zsh
fi
