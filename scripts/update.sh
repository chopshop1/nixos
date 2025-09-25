#!/usr/bin/env bash

set -e

echo "========================================"
echo "NixOS System Update Script"
echo "========================================"

# Function to print colored output
print_info() {
    echo -e "\033[0;36m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root or with sudo"
    exit 1
fi

# Update flake inputs
if [ -f "/etc/nixos/flake.nix" ]; then
    print_info "Updating flake inputs..."
    cd /etc/nixos
    nix flake update
    print_success "Flake inputs updated"
fi

# Update channels
print_info "Updating NixOS channels..."
nix-channel --update
print_success "Channels updated"

# Build and switch to new configuration
print_info "Building new system configuration..."
if [ -f "/etc/nixos/flake.nix" ]; then
    nixos-rebuild switch --flake /etc/nixos#$(hostname)
else
    nixos-rebuild switch
fi

if [ $? -eq 0 ]; then
    print_success "System successfully updated!"
else
    print_error "Update failed. Please check the errors above."
    exit 1
fi

# Clean up old generations (keep last 5)
print_info "Cleaning up old generations (keeping last 5)..."
nix-env --delete-generations +5
nix-collect-garbage

# Update user packages
print_info "Updating user packages..."
sudo -u $SUDO_USER nix-env -u '*'

print_success "System update complete!"
echo "========================================"
echo "You may want to reboot to ensure all changes take effect."
echo "Run 'sudo reboot' when ready."