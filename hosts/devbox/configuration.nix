{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./user-settings.nix
    ../../modules/base.nix
    ../../modules/boot.nix
    ../../modules/networking.nix
    ../../modules/security.nix
    ../../modules/ssh.nix
    ../../modules/users.nix
    ../../modules/docker.nix
    ../../modules/editor.nix
    ../../modules/hardware-basics.nix
    ../../modules/hardware-amd.nix
  ];

  networking.hostName = "devbox";

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    firefox
    gnome.gnome-tweaks
    gnome.gnome-terminal
  ];

  system.stateVersion = "25.05";
}