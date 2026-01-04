{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.xfce;
in
{
  options.my.xfce = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable XFCE desktop environment";
    };
  };

  config = mkIf cfg.enable {
    # Enable X11
    services.xserver.enable = true;

    # Enable XFCE
    services.xserver.desktopManager.xfce.enable = true;

    # Note: Auto-login handled by greetd in hyprland.nix

    # XDG Portal for compatibility
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
      config.common.default = "*";
    };

    # Note: Session-specific env vars are set by the desktop session itself
    # GDK_BACKEND and XDG_SESSION_TYPE are handled automatically

    # XFCE packages
    environment.systemPackages = with pkgs; [
      # X11 session management
      xorg.xinit
      xorg.xauth

      # XFCE extras
      xfce.xfce4-whiskermenu-plugin
      xfce.xfce4-pulseaudio-plugin
      xfce.xfce4-clipman-plugin
      xfce.xfce4-screenshooter
      xfce.xfce4-taskmanager
      xfce.xfce4-terminal

      # File manager
      xfce.thunar
      xfce.thunar-volman
      xfce.thunar-archive-plugin

      # Utilities
      xfce.xfconf
      xfce.xfce4-settings

      # Notifications
      xfce.xfce4-notifyd
      libnotify
    ];

    # Enable dconf for GTK settings
    programs.dconf.enable = true;

    # Thunar services
    programs.thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    # Enable gvfs for Thunar
    services.gvfs.enable = true;
  };
}
