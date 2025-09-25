#!/usr/bin/env bash

set -e

echo "Installing NvChad for Neovim..."

# Backup existing nvim config if it exists
if [ -d "$HOME/.config/nvim" ]; then
    echo "Backing up existing nvim config..."
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
fi

if [ -d "$HOME/.local/share/nvim" ]; then
    echo "Backing up existing nvim data..."
    mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.backup.$(date +%Y%m%d_%H%M%S)"
fi

if [ -d "$HOME/.cache/nvim" ]; then
    echo "Cleaning nvim cache..."
    rm -rf "$HOME/.cache/nvim"
fi

# Clone NvChad
echo "Cloning NvChad repository..."
git clone https://github.com/NvChad/NvChad "$HOME/.config/nvim" --depth 1

echo "NvChad installation complete!"
echo "Run 'nvim' to start Neovim with NvChad."
echo "On first run, NvChad will install necessary plugins automatically."