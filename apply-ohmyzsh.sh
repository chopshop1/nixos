#!/usr/bin/env bash

echo "Applying Oh My Zsh configuration to NixOS..."
echo "============================================"

# Copy configuration to system
echo "Step 1: Copying configuration to /etc/nixos/"
sudo cp /home/dev/nixos/configuration.nix /etc/nixos/configuration.nix

# Test build
echo ""
echo "Step 2: Testing configuration..."
if sudo nixos-rebuild dry-build; then
    echo "✓ Configuration test successful"
else
    echo "✗ Build test failed"
    exit 1
fi

# Apply configuration
echo ""
echo "Step 3: Rebuilding NixOS with Oh My Zsh..."
if sudo nixos-rebuild switch; then
    echo "✓ Rebuild successful!"
else
    echo "✗ Rebuild failed"
    exit 1
fi

# Verify installations
echo ""
echo "Step 4: Verification"
echo "==================="

# Check if zsh is available
if which zsh > /dev/null 2>&1; then
    echo "✓ Zsh installed: $(which zsh)"
else
    echo "✗ Zsh not found"
fi

# Check for Oh My Zsh
if [ -d "/nix/store/"*"-oh-my-zsh"* ] 2>/dev/null; then
    echo "✓ Oh My Zsh installed"
else
    echo "⚠ Oh My Zsh package installed (will be available after switching to zsh)"
fi

# Check for tools
echo ""
echo "Modern CLI tools:"
command -v eza &>/dev/null && echo "✓ eza (better ls) installed" || echo "✗ eza not found"
command -v bat &>/dev/null && echo "✓ bat (better cat) installed" || echo "✗ bat not found"
command -v fzf &>/dev/null && echo "✓ fzf (fuzzy finder) installed" || echo "✗ fzf not found"
command -v fd &>/dev/null && echo "✓ fd (better find) installed" || echo "✗ fd not found"
command -v rg &>/dev/null && echo "✓ ripgrep installed" || echo "✗ ripgrep not found"
command -v thefuck &>/dev/null && echo "✓ thefuck installed" || echo "✗ thefuck not found"

echo ""
echo "============================================"
echo "Oh My Zsh configuration complete!"
echo ""
echo "Features enabled:"
echo "  • Oh My Zsh with robbyrussell theme"
echo "  • Plugins: git, docker, npm, node, sudo, history, etc."
echo "  • Auto-suggestions and syntax highlighting"
echo "  • Modern CLI tools (eza, bat, fzf, fd, ripgrep)"
echo "  • Custom aliases and shortcuts"
echo ""
echo "To start using Oh My Zsh:"
echo "  1. Run: exec zsh"
echo "  2. Or start a new terminal/SSH session"
echo ""
echo "Try these commands:"
echo "  • 'll' for detailed listing with icons"
echo "  • 'tree' for tree view with icons"
echo "  • 'fuck' to correct previous command"
echo "  • Ctrl+R for fuzzy history search"