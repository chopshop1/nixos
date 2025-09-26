#!/usr/bin/env bash

echo "Applying zsh configuration to NixOS..."

# Copy the configuration to the system location
echo "Step 1: Copying fixed configuration to /etc/nixos/"
echo "  - Removed missing editor.nix import"
sudo cp /home/dev/nixos/configuration.nix /etc/nixos/configuration.nix

# Test build first
echo ""
echo "Step 2: Testing configuration build..."
if sudo nixos-rebuild dry-build; then
    echo "✓ Configuration build test successful"
else
    echo "✗ Build test failed. Please check the error messages above."
    exit 1
fi

# Rebuild the system
echo ""
echo "Step 3: Rebuilding NixOS..."
if sudo nixos-rebuild switch; then
    echo "✓ NixOS rebuild successful"
else
    echo "✗ Rebuild failed. Please check the error messages above."
    exit 1
fi

# Verify zsh is available
echo ""
echo "Step 4: Verifying zsh installation..."
if which zsh > /dev/null 2>&1; then
    echo "✓ Zsh is successfully installed at: $(which zsh)"
    echo ""
    echo "To use zsh immediately, run: zsh"
    echo "New SSH sessions will automatically use zsh."

    # Show current shell vs available zsh
    echo ""
    echo "Current shell: $SHELL"
    echo "Zsh location: $(which zsh)"
else
    echo "⚠ Zsh not found. There may have been an issue with the rebuild."
fi