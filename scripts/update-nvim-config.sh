#!/usr/bin/env bash

# Script to update Neovim config from latest GitHub commit

echo "Fetching latest nvim config from https://github.com/chopshop1/.nvim..."

# Get the latest hash
NEW_HASH=$(nix-prefetch-github chopshop1 .nvim 2>/dev/null | grep sha256 | cut -d'"' -f4)

if [ -z "$NEW_HASH" ]; then
    echo "Error: Could not fetch new hash"
    exit 1
fi

echo "New hash: $NEW_HASH"

# Update the module file
MODULE_FILE="/home/dev/nixos/modules/neovim-latest.nix"

# Create a backup
cp "$MODULE_FILE" "$MODULE_FILE.bak"

# Update the sha256 hash
sed -i "s/sha256 = \"sha256-[^\"]*\"/sha256 = \"$NEW_HASH\"/" "$MODULE_FILE"

echo "Updated $MODULE_FILE with new hash"
echo ""
echo "Now run: sudo nixos-rebuild switch --flake .#nixos"
echo ""
echo "To revert if needed: cp $MODULE_FILE.bak $MODULE_FILE"