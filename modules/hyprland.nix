{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.hyprland;
in
{
  options.my.hyprland = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Hyprland window manager";
    };
  };

  config = mkIf cfg.enable {
    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;  # For X11 app compatibility
    };

    # XDG Portal for Hyprland (extends base config in system-base.nix)
    xdg.portal = {
      wlr.enable = true;  # wlroots portal for screen capture
      extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    };

    # Wayland session environment variables
    environment.sessionVariables = {
      # Wayland
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";

      # AMD GPU Wayland optimization
      WLR_NO_HARDWARE_CURSORS = "0";  # AMD supports HW cursors
      WLR_RENDERER = "vulkan";

      # Electron/Chromium Wayland
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      NIXOS_OZONE_WL = "1";

      # Qt Wayland
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";

      # GTK Wayland
      GDK_BACKEND = "wayland,x11";

      # Theme
      GTK_THEME = "Adwaita:dark";
    };

    # Essential Hyprland packages
    environment.systemPackages = with pkgs; [
      # Hyprland ecosystem
      hyprpaper          # Wallpaper
      hyprlock           # Screen locker
      hypridle           # Idle daemon
      hyprpicker         # Color picker

      # Wayland utilities
      wl-clipboard       # Clipboard support
      wlr-randr          # Display configuration
      wlsunset           # Night light
      cliphist           # Clipboard history

      # Application launcher
      wofi               # App launcher

      # Status bar
      waybar             # Status bar

      # Notification daemon
      mako               # Notifications
      libnotify          # notify-send command

      # Screenshot tools
      grim               # Screenshot utility
      slurp              # Region selection
      swappy             # Screenshot editor

      # Screen recording
      wf-recorder

      # File manager
      nautilus           # GNOME Files (works well with Wayland)

      # Authentication agent
      kdePackages.polkit-kde-agent-1   # Polkit auth dialog
    ];

    # Fonts
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts._0xproto
      font-awesome
    ];

    # Use greetd display manager (better Wayland support)
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          # Show session menu with both Hyprland and XFCE options
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --sessions /etc/greetd/sessions";
          user = "greeter";
        };
        # Auto-login to XFCE (X11 - best for Sunshine streaming)
        initial_session = {
          command = "startx /run/current-system/sw/bin/startxfce4 -- -keeptty";
          user = "dev";
        };
      };
    };

    # Create session files for greetd
    environment.etc."greetd/sessions/hyprland.desktop".text = ''
      [Desktop Entry]
      Name=Hyprland
      Exec=Hyprland
      Type=Application
    '';

    environment.etc."greetd/sessions/xfce.desktop".text = ''
      [Desktop Entry]
      Name=XFCE
      Exec=startx /run/current-system/sw/bin/startxfce4
      Type=Application
    '';

    # Security - needed for Hyprland
    security.pam.services.hyprlock = {};

    # Enable dconf for GTK settings
    programs.dconf.enable = true;
  };
}
