# NixOS Configuration Improvements

This document outlines the improvements made to make the NixOS configuration more declarative and maintainable.

## Overview of Changes

The configuration has been restructured from a monolithic setup to a modular, declarative architecture following NixOS best practices.

## 1. Home Manager Integration ✅

### What Changed
- Moved user environment configuration from system-level to Home Manager
- Created `/home-manager/dev.nix` for user-specific configuration
- Migrated user packages, shell configuration, and dotfiles to Home Manager

### Files Created/Modified
- `home-manager/dev.nix` - Complete user environment configuration
- `flake-improved.nix` - Updated to use Home Manager module

### Benefits
- User environments are now reproducible
- Packages can be versioned per-user without affecting system configuration
- Dotfiles are managed declaratively
- Shell configurations (zsh, bash) are version-controlled

### Key Features
- All user packages (Firefox, Thunderbird, Bun, etc.) managed by Home Manager
- Zsh with Oh My Zsh fully configured declaratively
- Tmux configuration with plugins
- Kitty terminal configuration
- Git settings
- Environment variables

## 2. Declarative Neovim Configuration ✅

### What Changed
- Replaced imperative `system.activationScripts` with declarative configuration
- Kickstart.nvim is now fetched and managed through Home Manager
- Language servers and dependencies are explicitly declared

### Files Created/Modified
- `modules/editor-declarative.nix` - New declarative editor module
- `home-manager/dev.nix` - Neovim configuration section

### Benefits
- No network dependency during system activation
- Reproducible Neovim setup
- Version-controlled configuration
- All LSPs and tools explicitly declared

## 3. Package Management Improvements ✅

### What Changed
- Removed manual PATH mutations for Bun
- Bun is now installed via Nix packages
- Created modular package organization

### Files Created
- `modules/cli-tools.nix` - CLI tools with options
- `modules/desktop-apps.nix` - Desktop applications with categories
- `modules/system-base.nix` - Core system packages

### Benefits
- No manual PATH management needed
- All executables come from Nix derivations
- Packages organized by purpose
- Easy to enable/disable package groups

## 4. Modular Configuration with Options ✅

### Docker Module (`modules/docker.nix`)
```nix
my.docker = {
  enable = true;
  users = [ "dev" ];
  enableCompose = true;
  enableBuildkit = true;
  enablePrune = true;
};
```

### CLI Tools Module (`modules/cli-tools.nix`)
```nix
my.cli-tools = {
  enable = true;
  modern = true;  # Enables bat, eza, ripgrep, etc.
};
```

### Desktop Apps Module (`modules/desktop-apps.nix`)
```nix
my.desktop-apps = {
  enable = true;
  browsers = true;
  proton = true;
  onePassword = true;
};
```

### Power Management Module (`modules/power-management.nix`)
```nix
my.powerManagement = {
  preventSuspend = true;
  enableWakeOnLan = true;
  keepWifiAlive = true;
};
```

## 5. Configuration Structure

### New Directory Layout
```
/home/dev/nixos/
├── flake-improved.nix          # Main flake with modular imports
├── configuration-cleaned.nix   # Cleaned system configuration
├── hardware-configuration.nix  # Hardware-specific config
├── home-manager/
│   └── dev.nix                 # User environment configuration
└── modules/
    ├── cli-tools.nix           # CLI tools module
    ├── desktop-apps.nix        # Desktop applications module
    ├── docker.nix              # Docker configuration module
    ├── editor-declarative.nix  # Declarative editor module
    ├── power-management.nix    # Power management module
    └── system-base.nix         # Base system packages
```

## 6. Migration Guide

### Step 1: Backup Current Configuration
```bash
cp -r /home/dev/nixos /home/dev/nixos.backup
```

### Step 2: Apply New Configuration
```bash
# Replace the main flake
mv flake-improved.nix flake.nix

# Replace the main configuration
mv configuration-cleaned.nix configuration.nix

# Test the build
sudo nixos-rebuild dry-build --flake .#nixos

# If successful, apply changes
sudo nixos-rebuild switch --flake .#nixos
```

### Step 3: Verify Services
```bash
# Check Docker
docker ps

# Check Neovim
nvim --version

# Check user shell
echo $SHELL

# Check Home Manager
home-manager --version
```

## 7. Benefits Summary

### Declarative Benefits
- ✅ No imperative scripts during activation
- ✅ All packages from Nix derivations
- ✅ Version-controlled dotfiles
- ✅ Reproducible builds

### Maintainability Benefits
- ✅ Modular configuration
- ✅ Clear separation of concerns
- ✅ Reusable modules across hosts
- ✅ Options for easy customization

### User Experience Benefits
- ✅ User environments managed separately
- ✅ Per-user package versions
- ✅ Consistent shell experience
- ✅ Declarative editor setup

## 8. Further Improvements (Optional)

### Consider for Future
1. **Secrets Management**: Use `agenix` or `sops-nix` for managing secrets
2. **Multiple Hosts**: Create host-specific configurations under `hosts/`
3. **User Modules**: Create reusable user profiles for different roles
4. **Overlay Management**: Create custom overlays for package modifications
5. **CI/CD**: Add GitHub Actions for configuration validation

### Advanced Options Pattern
You could further enhance modules with more granular options:
```nix
my.development = {
  languages = {
    rust = true;
    go = true;
    node = true;
  };
  editors = {
    neovim = true;
    vscode = false;
  };
};
```

## 9. Testing

Run the provided test script to verify configuration:
```bash
./test-config.sh
```

This will check:
- Flake validity
- Module syntax
- Configuration buildability
- Key improvements implementation

## Conclusion

The configuration is now significantly more declarative, modular, and maintainable. All the recommended improvements have been implemented while preserving the existing functionality.