{ config, lib, pkgs, ... }:

{
  # Basic system packages that should be available on all hosts
  environment.systemPackages = with pkgs; [
    # Core utilities
    vim
    wget
    curl
    git
    htop
    tree
    unzip
    zip

    # Network tools
    nmap
    nettools
    dig
    traceroute

    # System monitoring
    lsof
    iotop
    ncdu
  ];

  # Basic zsh configuration (system-wide)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
  };

  # Enable flatpak support
  services.flatpak.enable = true;

  # XDG Portal configuration for Flatpak deep links and desktop integration
  xdg.portal = {
    enable = true;
    # Critical: Makes xdg-open use portals for URL handling (enables deep links)
    xdgOpenUsePortal = true;
    # GTK portal handles OpenURI for browsers
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    # Portal selection: GTK as fallback, DE-specific configs override in their modules
    config.common.default = [ "gtk" ];
  };

  # GNOME settings daemon for desktop integration
  services.gnome.gnome-settings-daemon.enable = true;

  # Enable dconf for GNOME configuration
  programs.dconf.enable = true;

  # Ensure portal service has correct portal directory
  systemd.user.services.xdg-desktop-portal.environment = {
    NIX_XDG_DESKTOP_PORTAL_DIR = "/run/current-system/sw/share/xdg-desktop-portal/portals";
  };
}