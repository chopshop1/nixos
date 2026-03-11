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

---

# Sunshine + Moonlight Controller Proxy

This section documents the gamepad proxy setup for Sunshine streaming to ensure reliable controller input.

## Problem Statement

When using Sunshine with Moonlight clients, several issues arise:

1. **Multiple gamepads**: Sunshine creates a new virtual gamepad per client connection
2. **Stale devices**: Devices persist after disconnection, confusing Steam and games
3. **Reconnect failures**: Controller stops working after Moonlight reconnects
4. **Spamming inputs**: Complex proxy logic with multiple device merging causes duplicate inputs
5. **xpad interference**: Linux kernel xpad driver creates spurious Xbox controllers

## Solution

The configuration uses three key fixes:

### 1. Force Single Client (`channels = "1"`)

In `modules/sunshine.nix`:

```nix
settings = {
  # Force single client to prevent multiple gamepads
  channels = "1";
  # ... other settings
};
```

This prevents Sunshine from accepting multiple simultaneous connections, eliminating the need to merge multiple gamepads.

### 2. Block xpad Kernel Module

```nix
# Block xpad from loading - prevents spurious Xbox controllers
boot.blacklistedKernelModules = [ "xpad" ];
boot.kernelModules = [ "uinput" ];
```

The xpad driver creates fake Xbox controller devices that interfere with the proxy.

### 3. Simple Pass-Through Proxy

The proxy script (`/etc/sunshine-gamepad-proxy.py`) uses simple, reliable logic:

- Finds the first Sunshine virtual gamepad
- Creates ONE persistent Xbox 360 Controller output device
- Passes events directly without buffering or merging
- Re-creates the output device on disconnect/reconnect

Key implementation points:
- Single device handling (not multi-device merging)
- Direct event pass-through (no buffering)
- Proper grab/release on device changes
- No watchdog (prevents crashes)

## Diagnostics

### Check Service Status
```bash
systemctl status sunshine-gamepad-proxy
journalctl -u sunshine-gamepad-proxy --no-pager -n 20
```

### List Gamepad Devices
```bash
cat /proc/bus/input/devices | grep -E "Name=|Vendor=" | grep -B1 -E "Xbox|Sunshine"
```

### Check Sunshine Settings
```bash
cat ~/.config/sunshine/sunshine.conf | grep -E "channels|gamepad|controller"
```

### Manually Unload xpad (if needed)
```bash
sudo rmmod xpad
```

## Common Issues

### "3 Xbox controllers in Steam"
- **Cause**: Multiple Sunshine gamepads + xpad devices
- **Fix**: Ensure `channels = "1"` and xpad is blocked

### "Controller stops working after reconnect"
- **Cause**: Proxy lost grip on device
- **Fix**: Simple proxy handles reconnection automatically

### "Spamming/duplicate inputs"
- **Cause**: Complex multi-device merging logic
- **Fix**: Use simple pass-through proxy (channels=1 means no merging needed)

### "Steam crashes on open"
- **Cause**: Conflicting gamepad devices
- **Fix**: Kill Steam, ensure only 1 Xbox 360 Controller exists

## Architecture

```
Moonlight Client
       |
       v
Sunshine (creates virtual gamepad: "Sunshine X-Box One (virtual) pad")
       |
       v
sunshine-gamepad-proxy (grabs Sunshine device)
       |
       v
Xbox 360 Controller (0x045e:0x028e) <-- Persistent, single device
       |
       v
Steam / Games
```