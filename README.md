# NixOS Configuration

A modular, flake-based NixOS configuration managing three machines with shared modules and per-host feature toggles.

## Host Configurations

| Host | Hardware | GPU | Purpose |
|------|----------|-----|---------|
| `nixos` | NVIDIA GTX 1080 Ti workstation | NVIDIA (proprietary) | Gaming, Sunshine streaming, Docker |
| `nixos-amd` | Ryzen 9 7950X3D + RX 7900 XTX | AMD | Gaming, Sunshine streaming, Docker, fan control |
| `home` | Lenovo Ryzen 5 Pro 2400GE (Vega 11) | AMD (integrated) | Dev machine, Home Assistant, Docker |

## Directory Structure

```
.
├── flake.nix                  # Flake entry point, host definitions, mkHost helper
├── configuration-cleaned.nix  # Shared NixOS config (imports all modules)
├── hardware-configuration.nix # Hardware config for the nixos (NVIDIA) host
├── hosts/
│   ├── amd-workstation/
│   │   └── hardware-configuration.nix
│   └── lenovo-dev/
│       └── hardware-configuration.nix
├── modules/                   # NixOS system modules (see below)
├── home-manager/              # Home Manager user config (see below)
├── devContainer/              # Declarative dev container (systemd-nspawn)
│   ├── container.nix          # NixOS module for the devbox container
│   ├── docker-compose.yml
│   ├── Dockerfile
│   ├── flake.nix / flake.lock
│   ├── setup.sh / shell.nix
│   └── README.md
└── tasks/                     # Task tracking
```

## Usage

Rebuild for a specific host:

```bash
sudo nixos-rebuild switch --flake .#<host>
```

Where `<host>` is `nixos`, `nixos-amd`, or `home`.

Update flake inputs:

```bash
nix flake update
```

### Git User Setup

See [CLAUDE.md](./CLAUDE.md) for first-time git user configuration via environment variables.

## Modules (`modules/`)

| Module | Description |
|--------|-------------|
| `audio-recovery.nix` | Watchdog that auto-recovers stuck HDMI audio after GPU crashes by reloading snd_hda_intel |
| `cli-tools.nix` | Modern CLI tool replacements (eza, bat, etc.) and shell utilities |
| `desktop-apps.nix` | Desktop applications (browsers, media, communication) |
| `docker.nix` | Docker engine and user group configuration |
| `editor-declarative.nix` | Neovim with kickstart.nvim configuration |
| `gaming.nix` | Steam, Wine, Proton, Lutris, Gamescope |
| `gpu.nix` | GPU driver setup for NVIDIA, AMD, or Intel (auto-configured per host) |
| `hardware-monitoring.nix` | lm_sensors, RGB control, and fan control (linear temperature ramp) |
| `home-assistant.nix` | Firewall rules for Home Assistant and HomeKit Bridge |
| `hyprland.nix` | Hyprland Wayland compositor |
| `ollama.nix` | Local LLM server (supports ROCm, CUDA, Vulkan backends) |
| `plasma.nix` | KDE Plasma desktop environment |
| `power-management.nix` | Suspend prevention, Wake-on-LAN, WiFi keep-alive, ethernet preference |
| `streaming-optimization.nix` | Network tuning for Moonlight/Sunshine game streaming |
| `sunshine.nix` | Sunshine game streaming server with gamepad proxy |
| `system-base.nix` | Core system packages available on all hosts |
| `xfce.nix` | XFCE desktop environment |
| `yubikey.nix` | YubiKey hardware key support and optional PAM integration |

## Home Manager (`home-manager/`)

| File | Description |
|------|-------------|
| `dev.nix` | Main entry point, imports all other Home Manager modules |
| `claude.nix` | Claude Code config symlinks to agents and dotfiles repos |
| `environment.nix` | Session environment variables (Wayland, Playwright) |
| `git.nix` | Git configuration with environment-variable-based user identity |
| `hyprland.nix` | Hyprland window manager keybindings, monitors, and theme |
| `mprocs.nix` | mprocs process manager with vim keybindings |
| `neovim.nix` | Neovim with language servers, formatters, and treesitter grammars |
| `packages.nix` | User-level packages and helper scripts (e.g., Playwright browser installer) |
| `plasma.nix` | KDE Plasma Breeze Dark theme activation |
| `repos.nix` | Activation scripts to clone/update external config repos |
| `starship.nix` | Starship prompt with Tokyo Night theme |
| `terminals.nix` | Kitty and Konsole terminal configuration |
| `tmux.nix` | Tmux with plugin management via Nix |
| `zsh.nix` | Zsh shell with autosuggestions, syntax highlighting, and history |

## Maintenance

```bash
# Garbage collect old generations
sudo nix-collect-garbage -d

# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

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
