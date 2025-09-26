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

  # GNOME settings daemon for desktop integration
  services.gnome.gnome-settings-daemon.enable = true;

  # Enable dconf for GNOME configuration
  programs.dconf.enable = true;
}