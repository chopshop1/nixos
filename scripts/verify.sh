#!/usr/bin/env bash

set -e

echo "========================================"
echo "NixOS Configuration Verification"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0

# Function to check if file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 exists"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is missing"
        ((ERRORS++))
        return 1
    fi
}

# Function to check if directory exists
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 directory exists"
        return 0
    else
        echo -e "${RED}✗${NC} $1 directory is missing"
        ((ERRORS++))
        return 1
    fi
}

# Check essential files
echo "Checking essential files..."
if [ -f "flake.nix" ]; then
    check_file "flake.nix"
    check_file "flake.lock"
else
    check_file "configuration.nix"
    check_file "hardware-configuration.nix"
fi

# Check directory structure
echo -e "\nChecking directory structure..."
if [ -f "flake.nix" ]; then
    check_dir "hosts"
    check_dir "modules"
    check_dir "scripts"
fi

# Check module files if modules directory exists
if [ -d "modules" ]; then
    echo -e "\nChecking module files..."
    for module in base boot networking security ssh users docker editor hardware-basics hardware-amd; do
        check_file "modules/${module}.nix"
    done
fi

# Check host configurations
if [ -d "hosts" ]; then
    echo -e "\nChecking host configurations..."
    for host in hosts/*/; do
        if [ -d "$host" ]; then
            hostname=$(basename "$host")
            echo "Checking host: $hostname"
            check_file "${host}configuration.nix"
            check_file "${host}hardware-configuration.nix"
        fi
    done
fi

# Validate Nix syntax
echo -e "\nValidating Nix syntax..."
if [ -f "flake.nix" ]; then
    if nix flake check . 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Flake configuration is valid"
    else
        echo -e "${YELLOW}⚠${NC} Flake check failed (this might be normal if not all inputs are available)"
        ((WARNINGS++))
    fi
else
    if nixos-rebuild dry-build 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Configuration syntax is valid"
    else
        echo -e "${RED}✗${NC} Configuration has syntax errors"
        ((ERRORS++))
    fi
fi

# Check script permissions
if [ -d "scripts" ]; then
    echo -e "\nChecking script permissions..."
    for script in scripts/*.sh; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                echo -e "${GREEN}✓${NC} $(basename $script) is executable"
            else
                echo -e "${YELLOW}⚠${NC} $(basename $script) is not executable"
                echo "  Run: chmod +x $script"
                ((WARNINGS++))
            fi
        fi
    done
fi

# Summary
echo -e "\n========================================"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
else
    if [ $ERRORS -gt 0 ]; then
        echo -e "${RED}Found $ERRORS error(s)${NC}"
    fi
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Found $WARNINGS warning(s)${NC}"
    fi
    exit 1
fi