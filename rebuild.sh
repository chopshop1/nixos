#!/bin/bash
# Simple rebuild script for NixOS
set -e

echo "Rebuilding NixOS configuration..."
sudo nixos-rebuild switch --flake /home/dev/nixos#nixos

echo "System rebuilt successfully!"
echo "You can now switch to zsh by running: zsh"
echo "Or set it as your default shell by running: chsh -s /run/current-system/sw/bin/zsh"
