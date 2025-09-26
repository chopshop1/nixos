# NixOS Configuration Structure

## Overview

This repository contains a modular, declarative NixOS configuration using flakes and Home Manager.

## Directory Structure

```
.
├── flake.nix                   # Main flake configuration
├── configuration.nix           # System-level configuration
├── hardware-configuration.nix  # Hardware-specific settings
├── home-manager/               # User environment configurations
│   └── dev.nix                # Configuration for user 'dev'
└── modules/                    # Reusable NixOS modules
    ├── cli-tools.nix          # CLI utilities and modern replacements
    ├── desktop-apps.nix       # Desktop applications
    ├── docker.nix             # Docker and containerization
    ├── editor-declarative.nix # Neovim configuration
    ├── power-management.nix   # Power and network settings
    └── system-base.nix        # Base system packages
```

## Key Features

### Modular Design
Each module is self-contained with its own options, making it easy to:
- Enable/disable features
- Share modules between different hosts
- Maintain clear separation of concerns

### Home Manager Integration
User environments are managed separately from system configuration:
- User packages and dotfiles in `home-manager/`
- Shell configurations (zsh, bash, tmux)
- Application settings (kitty, neovim, git)

### Declarative Configuration
Everything is managed through Nix:
- No imperative scripts during activation
- All packages from Nix derivations
- Version-controlled configurations
- Reproducible builds

## Module Options

### Docker Module
```nix
my.docker = {
  enable = true;           # Enable Docker
  users = [ "dev" ];       # Users in docker group
  enableCompose = true;    # Install docker-compose
  enableBuildkit = true;   # Use BuildKit by default
  enablePrune = true;      # Auto-prune weekly
};
```

### CLI Tools Module
```nix
my.cli-tools = {
  enable = true;    # Enable CLI tools
  modern = true;    # Use modern replacements (bat, eza, etc.)
};
```

### Desktop Apps Module
```nix
my.desktop-apps = {
  enable = true;       # Enable desktop apps
  browsers = true;     # Web browsers
  proton = true;       # Proton suite
  onePassword = true;  # 1Password
};
```

### Power Management Module
```nix
my.powerManagement = {
  preventSuspend = true;   # Never suspend (for SSH)
  enableWakeOnLan = true;  # Wake-on-LAN support
  keepWifiAlive = true;    # Prevent WiFi sleep
};
```

## Quick Start

### Building the Configuration
```bash
# Test build without applying
sudo nixos-rebuild dry-build --flake .#nixos

# Apply configuration
sudo nixos-rebuild switch --flake .#nixos
```

### Adding a New User
1. Create a new Home Manager configuration:
   ```bash
   cp home-manager/dev.nix home-manager/newuser.nix
   ```

2. Update the flake to include the new user:
   ```nix
   home-manager.users.newuser = import ./home-manager/newuser.nix;
   ```

3. Add the user to the system configuration:
   ```nix
   users.users.newuser = {
     isNormalUser = true;
     extraGroups = [ "wheel" ];
   };
   ```

### Creating a New Module
1. Create a module file in `modules/`:
   ```nix
   { config, lib, pkgs, ... }:
   with lib;
   let
     cfg = config.my.mymodule;
   in {
     options.my.mymodule = {
       enable = mkOption {
         type = types.bool;
         default = false;
         description = "Enable my module";
       };
     };

     config = mkIf cfg.enable {
       # Module configuration here
     };
   }
   ```

2. Import it in `configuration.nix`:
   ```nix
   imports = [
     ./modules/mymodule.nix
   ];
   ```

3. Enable it in the flake:
   ```nix
   my.mymodule.enable = true;
   ```

## Maintenance

### Updating the System
```bash
# Update flake inputs
nix flake update

# Rebuild with updated inputs
sudo nixos-rebuild switch --flake .#nixos
```

### Garbage Collection
```bash
# Remove old generations
sudo nix-collect-garbage -d

# Keep last 3 generations
sudo nix-env --delete-generations +3
```

### Rollback
```bash
# List generations
sudo nix-env --list-generations

# Rollback to previous
sudo nixos-rebuild switch --rollback
```

## Troubleshooting

### Build Errors
```bash
# Verbose build output
sudo nixos-rebuild switch --flake .#nixos --show-trace

# Check flake
nix flake check
```

### Module Conflicts
If modules conflict, use `lib.mkForce`:
```nix
my.option = lib.mkForce value;
```

### Home Manager Issues
```bash
# Rebuild Home Manager separately
home-manager switch --flake .#dev

# Check Home Manager generation
home-manager generations
```

## Documentation

- `IMPROVEMENTS.md` - Detailed list of improvements made
- `test-config.sh` - Script to test configuration validity
- `migrate.sh` - Migration assistant for applying changes

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [NixOS Options Search](https://search.nixos.org/options)