#!/usr/bin/env bash

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     NixOS Configuration Migration Assistant         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"

# Function to prompt user
prompt_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

echo -e "\n${YELLOW}This script will help you migrate to the improved NixOS configuration.${NC}"
echo -e "${YELLOW}It will:${NC}"
echo "  1. Create a backup of your current configuration"
echo "  2. Test the new configuration"
echo "  3. Optionally apply the changes"

if ! prompt_yes_no "Do you want to continue?"; then
    echo -e "${RED}Migration cancelled.${NC}"
    exit 0
fi

# Step 1: Create backup
echo -e "\n${BLUE}Step 1: Creating backup...${NC}"
BACKUP_DIR="/home/dev/nixos-backup-$(date +%Y%m%d-%H%M%S)"
cp -r /home/dev/nixos "$BACKUP_DIR"
echo -e "${GREEN}✓ Backup created at: $BACKUP_DIR${NC}"

# Step 2: Check all required files exist
echo -e "\n${BLUE}Step 2: Checking required files...${NC}"
REQUIRED_FILES=(
    "flake-improved.nix"
    "configuration-cleaned.nix"
    "home-manager/dev.nix"
    "modules/cli-tools.nix"
    "modules/desktop-apps.nix"
    "modules/docker.nix"
    "modules/editor-declarative.nix"
    "modules/power-management.nix"
    "modules/system-base.nix"
)

all_files_exist=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ $file${NC}"
    else
        echo -e "${RED}✗ $file missing${NC}"
        all_files_exist=false
    fi
done

if [ "$all_files_exist" = false ]; then
    echo -e "${RED}Some required files are missing. Please ensure all files are created.${NC}"
    exit 1
fi

# Step 3: Test build
echo -e "\n${BLUE}Step 3: Testing new configuration...${NC}"
echo "Running dry-build (this won't make any changes)..."

# First, let's copy the improved files temporarily for testing
cp configuration.nix configuration.bak 2>/dev/null || true
cp flake.nix flake.bak 2>/dev/null || true
cp flake.lock flake.lock.bak 2>/dev/null || true
cp flake-improved.nix flake.nix
cp configuration-cleaned.nix configuration.nix

# Update the flake lock for the improved configuration
echo "Updating flake lock for compatibility..."
nix --extra-experimental-features 'nix-command flakes' flake update 2>/dev/null || true

echo "Testing build..."
if sudo nixos-rebuild dry-build --flake .#nixos 2>/dev/null; then
    echo -e "${GREEN}✓ Configuration builds successfully${NC}"
    # Restore original files after successful test
    mv flake.bak flake.nix 2>/dev/null || true
    mv configuration.bak configuration.nix 2>/dev/null || true
    mv flake.lock.bak flake.lock 2>/dev/null || true
else
    echo -e "${RED}✗ Build test failed${NC}"
    # Restore original files after failed test
    mv flake.bak flake.nix 2>/dev/null || true
    mv configuration.bak configuration.nix 2>/dev/null || true
    mv flake.lock.bak flake.lock 2>/dev/null || true

    echo -e "${YELLOW}Would you like to see the detailed error?${NC}"
    if prompt_yes_no "Show detailed error?"; then
        cp flake-improved.nix flake.nix
        cp configuration-cleaned.nix configuration.nix
        nix --extra-experimental-features 'nix-command flakes' flake update 2>/dev/null || true
        sudo nixos-rebuild dry-build --flake .#nixos --show-trace 2>&1 | head -50
        mv flake.bak flake.nix 2>/dev/null || true
        mv configuration.bak configuration.nix 2>/dev/null || true
        mv flake.lock.bak flake.lock 2>/dev/null || true
    fi
    echo -e "${YELLOW}Note: The test build failed, but you can still proceed if you want to debug.${NC}"
fi

# Step 4: Show changes summary
echo -e "\n${BLUE}Step 4: Summary of changes${NC}"
echo -e "${YELLOW}The following changes will be made:${NC}"
echo "  • User packages moved to Home Manager"
echo "  • Neovim configuration made declarative"
echo "  • Bun installed via Nix packages (no PATH manipulation)"
echo "  • Modular configuration with options"
echo "  • Docker settings consolidated"
echo "  • Power management in separate module"

# Step 5: Apply changes
echo -e "\n${BLUE}Step 5: Apply configuration${NC}"
echo -e "${YELLOW}Warning: This will rebuild your system configuration.${NC}"
echo -e "${YELLOW}You can restore from backup at: $BACKUP_DIR${NC}"

if prompt_yes_no "Do you want to apply the new configuration?"; then
    echo -e "\n${BLUE}Applying configuration...${NC}"

    # Rename files
    echo "Updating flake.nix..."
    mv flake.nix flake.old.nix 2>/dev/null || true
    cp flake-improved.nix flake.nix

    echo "Updating configuration.nix..."
    mv configuration.nix configuration.old.nix 2>/dev/null || true
    cp configuration-cleaned.nix configuration.nix

    # Update flake lock to use compatible versions
    echo "Updating flake lock..."
    nix --extra-experimental-features 'nix-command flakes' flake update

    # Rebuild
    echo -e "\n${BLUE}Running nixos-rebuild switch...${NC}"
    if sudo nixos-rebuild switch --flake .#nixos; then
        echo -e "\n${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║           Migration completed successfully!          ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"

        echo -e "\n${GREEN}Your old configuration files have been renamed:${NC}"
        echo "  • flake.old.nix"
        echo "  • configuration.old.nix"
        echo "  • home.nix (preserved, but now replaced by home-manager/dev.nix)"

        echo -e "\n${GREEN}Backup location: $BACKUP_DIR${NC}"

        echo -e "\n${YELLOW}Recommended next steps:${NC}"
        echo "1. Restart your shell to apply Home Manager changes"
        echo "2. Test that all your applications work correctly"
        echo "3. Review IMPROVEMENTS.md for detailed documentation"
        echo "4. Remove old configuration files once everything is verified"

    else
        echo -e "\n${RED}Rebuild failed!${NC}"
        echo -e "${YELLOW}Restoring original configuration...${NC}"
        mv flake.old.nix flake.nix 2>/dev/null || true
        mv configuration.old.nix configuration.nix 2>/dev/null || true
        echo -e "${RED}Configuration has been restored.${NC}"
        echo -e "${YELLOW}Your backup is at: $BACKUP_DIR${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Migration cancelled. No changes were made.${NC}"
    echo -e "${YELLOW}Your backup is at: $BACKUP_DIR${NC}"
    echo -e "${YELLOW}You can manually apply changes later by:${NC}"
    echo "  1. cp flake-improved.nix flake.nix"
    echo "  2. cp configuration-cleaned.nix configuration.nix"
    echo "  3. sudo nixos-rebuild switch --flake .#nixos"
fi

echo -e "\n${BLUE}To verify everything is working:${NC}"
echo "  • Check Docker: docker ps"
echo "  • Check Neovim: nvim --version"
echo "  • Check shell: echo \$SHELL"
echo "  • Check Home Manager: home-manager --version"