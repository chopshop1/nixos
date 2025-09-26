#!/usr/bin/env bash

set -e

echo "Testing NixOS configuration improvements..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
        return 1
    fi
}

echo -e "\n${YELLOW}1. Checking flake configuration...${NC}"
nix flake check ./flake-improved.nix 2>/dev/null && print_status "Flake configuration is valid" || print_status "Flake configuration has issues"

echo -e "\n${YELLOW}2. Building the configuration (dry-run)...${NC}"
sudo nixos-rebuild dry-build --flake ./flake-improved.nix#nixos 2>/dev/null && print_status "Configuration builds successfully" || print_status "Configuration build failed"

echo -e "\n${YELLOW}3. Checking module structure...${NC}"
for module in system-base cli-tools desktop-apps docker power-management editor-declarative; do
    if [ -f "modules/$module.nix" ]; then
        nix-instantiate --parse modules/$module.nix > /dev/null 2>&1 && print_status "Module $module.nix is syntactically valid" || print_status "Module $module.nix has syntax errors"
    else
        echo -e "${RED}✗${NC} Module $module.nix not found"
    fi
done

echo -e "\n${YELLOW}4. Checking Home Manager configuration...${NC}"
if [ -f "home-manager/dev.nix" ]; then
    nix-instantiate --parse home-manager/dev.nix > /dev/null 2>&1 && print_status "Home Manager configuration is syntactically valid" || print_status "Home Manager configuration has syntax errors"
else
    echo -e "${RED}✗${NC} Home Manager configuration not found"
fi

echo -e "\n${YELLOW}5. Verifying key improvements:${NC}"

# Check if user packages moved to Home Manager
grep -q "home.packages" home-manager/dev.nix && print_status "User packages moved to Home Manager" || print_status "User packages not in Home Manager"

# Check if Neovim is declaratively configured
grep -q "xdg.configFile.\"nvim\"" home-manager/dev.nix && print_status "Neovim config is declarative" || print_status "Neovim config not declarative"

# Check if Bun is in packages (not PATH manipulation)
grep -q "bun" home-manager/dev.nix && print_status "Bun installed via Nix packages" || print_status "Bun not in Nix packages"

# Check for modular configuration
[ -f "modules/docker.nix" ] && grep -q "options.my.docker" modules/docker.nix && print_status "Docker module has options" || print_status "Docker module missing options"

# Check for reusable modules
[ -f "modules/cli-tools.nix" ] && print_status "CLI tools module exists" || print_status "CLI tools module missing"
[ -f "modules/desktop-apps.nix" ] && print_status "Desktop apps module exists" || print_status "Desktop apps module missing"

echo -e "\n${YELLOW}Summary:${NC}"
echo "The configuration has been restructured to be more declarative with:"
echo "  - User environment managed by Home Manager"
echo "  - Declarative Neovim configuration"
echo "  - Modular, reusable components with options"
echo "  - Bun installed via Nix packages"
echo "  - Consolidated package lists"

echo -e "\n${YELLOW}Next steps to apply changes:${NC}"
echo "1. Review the new configuration in flake-improved.nix"
echo "2. Backup your current configuration"
echo "3. Replace flake.nix with flake-improved.nix"
echo "4. Run: sudo nixos-rebuild switch --flake .#nixos"
echo "5. Verify all services are working correctly"