# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./modules/editor.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable GDM Display Manager with auto-login (better for GNOME)
  services.displayManager.gdm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "dev";

  # Enable GNOME as fallback desktop
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable polkit for authentication
  security.polkit.enable = true;

  # Enable passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Enable dbus for desktop integration
  services.dbus.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account with no password for automatic login
  users.users.dev = {
    isNormalUser = true;
    description = "dev";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
    # No password required for automatic login
    hashedPassword = "";
    packages = with pkgs; [
    #  thunderbird
    firefox
    ];
    # Ensure shell environment for SSH
    openssh.authorizedKeys.keyFiles = [];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  neovim
  git
  nodejs
  bun
  flatpak
  _1password-cli
  _1password-gui

  # Terminal and shell tools
  kitty           # Terminal emulator
  tmux            # Terminal multiplexer
  docker          # Container platform
  ethtool         # Network interface configuration tool for Wake-on-LAN
  ];

# Add Bun's binary path to environment variables (adjust path if necessary)
environment.variables.PATH = [
  "/home/dev/.bun/bin"
];

# Environment variables
environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";
  # Ensure zsh is used in all contexts
  SHELL = "${pkgs.zsh}/bin/zsh";
};

# Enable zsh system-wide (minimal configuration)
programs.zsh = {
  enable = true;
  enableCompletion = true;

  # Ensure zsh is the default shell for all sessions
  shellInit = ''
    # Force zsh for all terminal sessions
    export SHELL=${pkgs.zsh}/bin/zsh
  '';
};

# Configure tmux to use zsh
programs.tmux = {
  enable = true;
  baseIndex = 1;
  escapeTime = 0;
  keyMode = "vi";
  terminal = "screen-256color";

  extraConfig = ''
    # Use zsh as default shell (multiple methods for maximum compatibility)
    set-option -g default-shell ${pkgs.zsh}/bin/zsh
    set-option -g default-command ${pkgs.zsh}/bin/zsh

    # Alternative paths for compatibility
    set-option -g default-shell /run/current-system/sw/bin/zsh
    set-option -g default-command /run/current-system/sw/bin/zsh

    # Enable mouse support
    set -g mouse on

    # Better key bindings
    bind-key v split-window -h
    bind-key s split-window -v
    bind-key h select-pane -L
    bind-key j select-pane -D
    bind-key k select-pane -U
    bind-key l select-pane -R

    # Resize panes
    bind-key H resize-pane -L 5
    bind-key J resize-pane -D 5
    bind-key K resize-pane -U 5
    bind-key L resize-pane -R 5

    # Status bar
    set -g status-bg black
    set -g status-fg white
    set -g status-left-length 40
    set -g status-left "#[fg=green]Session: #S #[fg=yellow]#I #[fg=cyan]#P"
    set -g status-right "#[fg=cyan]%d %b %R"
    set -g status-justify centre

    # Highlight active window
    setw -g window-status-current-style fg=white,bg=red,bright
  '';
};

programs._1password-gui.enable = true;

# XDG Desktop Portal configuration
xdg.portal = {
  enable = true;
  extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
  ];
};

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      # Allow users to use their configured shell
      PermitUserEnvironment = true;
      AcceptEnv = "SHELL LANG LC_*";
    };
    extraConfig = ''
      # Force zsh for all interactive SSH sessions
      ForceCommand ${pkgs.bash}/bin/bash -c 'if [ -t 0 ]; then exec ${pkgs.zsh}/bin/zsh -l; else exec "$SHELL" -c "$SSH_ORIGINAL_COMMAND"; fi'
    '';
  };

  # Set default shell for SSH sessions
  programs.ssh.extraConfig = ''
    SetEnv SHELL=${pkgs.zsh}/bin/zsh
  '';

  # Ensure SSH sessions use zsh by default
  environment.shellInit = ''
    # Force zsh for SSH sessions
    if [ -n "$SSH_CONNECTION" ] && [ "$SHELL" != "${pkgs.zsh}/bin/zsh" ]; then
      export SHELL=${pkgs.zsh}/bin/zsh
      [ -x ${pkgs.zsh}/bin/zsh ] && exec ${pkgs.zsh}/bin/zsh -l
    fi
  '';

  # Power management configuration for SSH availability
  # Wake-on-LAN for ethernet + prevent sleep for WiFi availability

  # Enable Wake-on-LAN for ethernet interfaces (when plugged in)
  systemd.services.wake-on-lan = {
    description = "Enable Wake-on-LAN for ethernet interfaces";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''
        ${pkgs.bash}/bin/bash -c '
          for iface in $(ls /sys/class/net | grep -E "^(en|eth)"); do
            ${pkgs.ethtool}/bin/ethtool -s $iface wol g 2>/dev/null || true
          done
        '
      '';
    };
  };

  # Re-enable Wake-on-LAN after suspend/resume
  powerManagement.powerUpCommands = ''
    for iface in $(ls /sys/class/net | grep -E "^(en|eth)"); do
      ${pkgs.ethtool}/bin/ethtool -s $iface wol g 2>/dev/null || true
    done
  '';

  # Prevent system from sleeping to maintain SSH availability
  services.logind.extraConfig = ''
    HandleSuspendKey=ignore
    HandleHibernateKey=ignore
    HandleLidSwitch=ignore
    HandleLidSwitchDocked=ignore
    IdleAction=ignore
  '';

  # Disable automatic suspend
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Keep WiFi connection alive
  networking.networkmanager.wifi.powersave = false;

  # Ensure NetworkManager doesn't put WiFi to sleep
  networking.networkmanager.extraConfig = ''
    [connection]
    wifi.powersave = 2

    [device]
    wifi.scan-rand-mac-address = no
  '';

  # Enable Docker service
  virtualisation.docker.enable = true;

  # Enable Tailscale
  services.tailscale.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?






 programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries for unpackaged programs
    # here, NOT in environment.systemPackages
    glibc
    gcc
    zlib
  ];
}