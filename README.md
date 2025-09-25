# NixOS Configuration

A modular NixOS configuration using flakes for reproducible system management.

## Structure

```
.
├── flake.nix           # Main flake configuration
├── flake.lock          # Locked flake dependencies
├── hosts/              # Host-specific configurations
│   └── devbox/         # Configuration for 'devbox' host
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       └── user-settings.nix
├── modules/            # Reusable NixOS modules
│   ├── base.nix        # Base system configuration
│   ├── boot.nix        # Boot loader settings
│   ├── docker.nix      # Docker configuration
│   ├── editor.nix      # Text editor configurations
│   ├── hardware-amd.nix    # AMD-specific hardware
│   ├── hardware-basics.nix # Common hardware settings
│   ├── networking.nix  # Network configuration
│   ├── security.nix    # Security settings
│   ├── ssh.nix         # SSH server configuration
│   └── users.nix       # User management
├── legacy/             # Traditional NixOS configuration (non-flake)
│   ├── configuration.nix
│   └── hardware-configuration.nix
└── scripts/            # Utility scripts
    ├── nvchad-install.sh      # Install NvChad for Neovim
    ├── provision-ai-cli.sh    # Install AI CLI tools
    ├── update.sh              # System update script
    └── verify.sh              # Configuration verification
```

## Quick Start

### Using Flakes (Recommended)

1. **Build the system configuration:**
   ```bash
   sudo nixos-rebuild switch --flake .#devbox
   ```

2. **Update flake inputs:**
   ```bash
   nix flake update
   ```

3. **Check configuration:**
   ```bash
   nix flake check
   ```

### Using Traditional Configuration

1. **Copy to system location:**
   ```bash
   sudo cp -r legacy/* /etc/nixos/
   ```

2. **Build and switch:**
   ```bash
   sudo nixos-rebuild switch
   ```

## Scripts

Make scripts executable first:
```bash
chmod +x scripts/*.sh
```

### Update System
```bash
sudo ./scripts/update.sh
```

### Verify Configuration
```bash
./scripts/verify.sh
```

### Install NvChad
```bash
./scripts/nvchad-install.sh
```

### Install AI CLI Tools
```bash
./scripts/provision-ai-cli.sh
```

## Customization

### Adding a New Host

1. Create a new directory under `hosts/`:
   ```bash
   mkdir -p hosts/newhostname
   ```

2. Copy and modify the configuration files:
   ```bash
   cp hosts/devbox/*.nix hosts/newhostname/
   ```

3. Update `flake.nix` to add the new host:
   ```nix
   nixosConfigurations = {
     newhostname = nixpkgs.lib.nixosSystem {
       system = "x86_64-linux";
       modules = [
         ./hosts/newhostname/configuration.nix
         ./hosts/newhostname/hardware-configuration.nix
       ];
     };
   };
   ```

### Creating New Modules

1. Create a new module file in `modules/`:
   ```bash
   touch modules/mymodule.nix
   ```

2. Add the module structure:
   ```nix
   { config, lib, pkgs, ... }:
   {
     # Your configuration here
   }
   ```

3. Import it in your host configuration:
   ```nix
   imports = [
     ../../modules/mymodule.nix
   ];
   ```

## Features

- **Modular Configuration**: Organized into reusable modules
- **Flake Support**: Reproducible builds with pinned dependencies
- **AMD Hardware Support**: Optimized for AMD CPUs and GPUs
- **Development Tools**: Docker, editors, and programming languages
- **Security Hardening**: AppArmor, Fail2ban, ClamAV
- **Modern Desktop**: GNOME with Wayland support

## Maintenance

### Garbage Collection
Remove old generations:
```bash
sudo nix-collect-garbage -d
```

### List Generations
```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

### Rollback
```bash
sudo nixos-rebuild switch --rollback
```

## License

This configuration is provided as-is for personal use.