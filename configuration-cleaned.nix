{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/editor-declarative.nix
    ./modules/docker.nix
    ./modules/cli-tools.nix
    ./modules/desktop-apps.nix
    ./modules/system-base.nix
    ./modules/power-management.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Kernel parameters to prevent suspension
  boot.kernelParams = [
    "consoleblank=0"
    "noresume"
    "nohibernate"
  ];

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Time zone and locale
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

  # Enable the X11 windowing system
  services.xserver.enable = true;

  # Enable GDM Display Manager with auto-login
  services.xserver.displayManager.gdm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "dev";

  # Enable GNOME desktop
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Enable sound with pipewire
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable polkit for authentication
  security.polkit.enable = true;

  # Enable passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Enable dbus for desktop integration
  services.dbus.enable = true;

  # Set zsh as the default shell system-wide
  users.defaultUserShell = pkgs.zsh;
  environment.shells = with pkgs; [ zsh bash ];

  # Define a user account (minimal, as Home Manager manages the environment)
  users.users.dev = {
    isNormalUser = true;
    description = "dev";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
    hashedPassword = ""; # No password for automatic login
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable flakes and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # XDG Desktop Portal configuration
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitUserEnvironment = true;
      AcceptEnv = "SHELL LANG LC_*";
      UsePAM = true;
    };
  };

  # Set default shell for SSH sessions
  programs.ssh.extraConfig = ''
    SetEnv SHELL=${pkgs.zsh}/bin/zsh
  '';

  # Enable Tailscale
  services.tailscale.enable = true;

  # System state version
  system.stateVersion = "25.05";

  # Enable nix-ld for running unpackaged binaries
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      glibc
      gcc
      zlib
    ];
  };
}