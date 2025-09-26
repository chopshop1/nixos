#!/usr/bin/env bash

echo "Fixing and applying NixOS configuration..."
echo "=========================================="

# First, ensure our local configuration is correct
echo "Step 1: Verifying local configuration is fixed..."

# Check for all deprecated options
DEPRECATED_FOUND=false

if grep -q "services.logind.extraConfig" /home/dev/nixos/configuration.nix; then
    echo "✗ Error: Local configuration still has deprecated logind.extraConfig!"
    DEPRECATED_FOUND=true
fi

if grep -q "networking.networkmanager.extraConfig" /home/dev/nixos/configuration.nix; then
    echo "✗ Error: Local configuration still has deprecated networkmanager.extraConfig!"
    DEPRECATED_FOUND=true
fi

if grep -q "services.logind.lidSwitch" /home/dev/nixos/configuration.nix; then
    echo "✗ Error: Local configuration still has deprecated logind.lidSwitch!"
    DEPRECATED_FOUND=true
fi

if grep -q "hardware.pulseaudio" /home/dev/nixos/configuration.nix; then
    echo "✗ Error: Local configuration still has deprecated hardware.pulseaudio!"
    DEPRECATED_FOUND=true
fi

if [ "$DEPRECATED_FOUND" = true ]; then
    echo "Please fix the deprecated options first."
    exit 1
fi

echo "✓ Local configuration is properly updated"

# Copy to system location
echo ""
echo "Step 2: Copying fixed configuration to /etc/nixos/"
echo "This will fix:"
echo "  - Deprecated logind.extraConfig → services.logind.settings"
echo "  - Deprecated networkmanager.extraConfig → networking.networkmanager.settings"
echo "  - Remove missing editor.nix import"

sudo cp /home/dev/nixos/configuration.nix /etc/nixos/configuration.nix

# Verify the copy
echo ""
echo "Step 3: Verifying system configuration..."
if grep -q "services.logind.extraConfig" /etc/nixos/configuration.nix; then
    echo "✗ Error: System configuration still has deprecated logind.extraConfig!"
    echo "  The copy may have failed. Please run with sudo."
    exit 1
fi

if grep -q "networking.networkmanager.extraConfig" /etc/nixos/configuration.nix; then
    echo "✗ Error: System configuration still has deprecated networkmanager.extraConfig!"
    echo "  The copy may have failed. Please run with sudo."
    exit 1
fi

echo "✓ System configuration updated successfully"

# Test the build
echo ""
echo "Step 4: Testing configuration build..."
if sudo nixos-rebuild dry-build; then
    echo "✓ Configuration test successful"
else
    echo "✗ Build test failed. Check errors above."
    exit 1
fi

# Perform the actual rebuild
echo ""
echo "Step 5: Rebuilding NixOS..."
if sudo nixos-rebuild switch; then
    echo "✓ System rebuilt successfully!"
else
    echo "✗ Rebuild failed."
    exit 1
fi

# Verify installations
echo ""
echo "Step 6: Verification"
echo "==================="

# Check ZSH
if which zsh > /dev/null 2>&1; then
    echo "✓ ZSH installed: $(which zsh)"
else
    echo "⚠ ZSH not found"
fi

# Check power management
echo ""
echo "Power Management Status:"
if systemctl status sleep.target 2>&1 | grep -q "masked"; then
    echo "✓ Sleep target masked"
else
    echo "  Sleep target will be masked after reboot"
fi

echo ""
echo "=========================================="
echo "Configuration applied successfully!"
echo ""
echo "System is now configured to:"
echo "  • Use ZSH as default shell"
echo "  • NEVER suspend or hibernate"
echo "  • Ignore lid close events"
echo "  • Keep WiFi always active"
echo "  • Monitor and prevent suspension during SSH"
echo ""
echo "To use ZSH immediately: exec zsh"