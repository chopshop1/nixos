#!/usr/bin/env bash

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    Enabling Flakes for NixOS Configuration Migration   ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}This script will enable flakes support which is required for the migration.${NC}"
echo -e "${YELLOW}Flakes have already been added to your configuration.nix${NC}"

echo -e "\n${BLUE}Rebuilding system to enable flakes...${NC}"
sudo nixos-rebuild switch

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✓ Flakes successfully enabled!${NC}"
    echo -e "${GREEN}You can now run ./migrate.sh to complete the migration.${NC}"
else
    echo -e "\n${YELLOW}There was an issue enabling flakes.${NC}"
    echo -e "${YELLOW}Please check the error messages above.${NC}"
fi