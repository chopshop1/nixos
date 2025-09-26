#!/usr/bin/env bash

echo "Applying NixOS configuration with ZSH and no-suspend settings..."
echo "================================================"

# Copy the configuration to the system location
echo "Step 1: Copying configuration to /etc/nixos/"
echo "  - Removed missing editor.nix import"
echo "  - Added comprehensive power management prevention"
echo "  - Configured ZSH as default shell"
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
echo "Step 4: Verifying installations..."
echo "-----------------------------------"

# Check ZSH
if which zsh > /dev/null 2>&1; then
    echo "✓ Zsh is installed at: $(which zsh)"
else
    echo "⚠ Zsh not found"
fi

# Check power management status
echo ""
echo "Power Management Status:"
echo "------------------------"

# Check if sleep targets are masked
if systemctl status sleep.target 2>&1 | grep -q "masked"; then
    echo "✓ Sleep target is masked"
else
    echo "⚠ Sleep target is not masked yet (will be after reboot)"
fi

# Check logind settings
if grep -q "HandleSuspendKey=ignore" /etc/systemd/logind.conf 2>/dev/null; then
    echo "✓ Suspend key handling disabled"
fi

# Show current inhibitors
echo ""
echo "Current suspension inhibitors:"
systemd-inhibit --list 2>/dev/null | head -5 || echo "  (Will be active after reboot)"

echo ""
echo "================================================"
echo "Configuration applied successfully!"
echo ""
echo "The system is now configured to:"
echo "  • Use ZSH as the default shell"
echo "  • NEVER suspend (even with SSH sessions)"
echo "  • Ignore lid close events"
echo "  • Disable all sleep/hibernation modes"
echo "  • Keep WiFi always active"
echo ""
echo "Note: A reboot may be required for all changes to take full effect."
echo "To test zsh immediately, run: zsh"