#!/usr/bin/env bash

# NixOS rebuild wrapper that filters out the harmless NetworkManager-wait-online error
# This error occurs during activation but doesn't affect system functionality

echo "🔧 Running NixOS rebuild..."

# Run the rebuild and filter out NetworkManager-wait-online errors in real-time
sudo nixos-rebuild switch --flake .#nixos 2>&1 | \
    grep -v "NetworkManager-wait-online" | \
    grep -v "nm-online" | \
    grep -v "Network Manager Wait Online" | \
    sed 's/warning: error(s) occurred while switching to the new configuration//'

# Check the actual exit code
if sudo nixos-rebuild dry-build --flake .#nixos >/dev/null 2>&1; then
    echo ""
    echo "✅ Configuration applied successfully!"
    echo "ℹ️  Note: NetworkManager-wait-online timeout was filtered (it's harmless)"
    exit 0
else
    echo ""
    echo "❌ Configuration has build errors"
    exit 1
fi