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

  # Enable SDDM Display Manager
  services.displayManager.sddm.enable = true;

  # Enable GNOME as fallback desktop
  services.xserver.desktopManager.gnome.enable = true;

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

  # Enable dbus for desktop integration
  services.dbus.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.dev = {
    isNormalUser = true;
    description = "dev";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
    #  thunderbird
    firefox
    ];
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
  _1password
  _1password-gui

  # Terminal and shell tools
  kitty           # Terminal emulator
  zsh             # Shell
  oh-my-zsh       # Zsh framework
  tmux            # Terminal multiplexer
  docker          # Container platform
  ];

# Add Bun's binary path to environment variables (adjust path if necessary)
environment.variables.PATH = [
  "/home/dev/.bun/bin"
];

# Environment variables
environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";
};

# Enable zsh system-wide
programs.zsh = {
  enable = true;
  ohMyZsh = {
    enable = true;
    plugins = [
      "git"
      "docker"
      "npm"
      "node"
      "tmux"
      "history-substring-search"
    ];
    theme = "robbyrussell";
  };
  autosuggestions.enable = true;
  syntaxHighlighting.enable = true;
  enableCompletion = true;

  # Enhanced history configuration
  histSize = 10000;
  histFile = "$HOME/.zsh_history";

  # Shell initialization with better history search
  interactiveShellInit = ''
    # History configuration
    setopt HIST_IGNORE_DUPS
    setopt HIST_IGNORE_ALL_DUPS
    setopt HIST_IGNORE_SPACE
    setopt HIST_SAVE_NO_DUPS
    setopt SHARE_HISTORY
    setopt APPEND_HISTORY
    setopt INC_APPEND_HISTORY
    setopt HIST_REDUCE_BLANKS
    setopt HIST_VERIFY

    # Better history search with up/down arrows
    autoload -U up-line-or-beginning-search
    autoload -U down-line-or-beginning-search
    zle -N up-line-or-beginning-search
    zle -N down-line-or-beginning-search
    bindkey "^[[A" up-line-or-beginning-search
    bindkey "^[[B" down-line-or-beginning-search

    # Additional useful key bindings
    bindkey "^[[1;5C" forward-word    # Ctrl+Right
    bindkey "^[[1;5D" backward-word   # Ctrl+Left
    bindkey "^[[3~" delete-char       # Delete key
    bindkey "^[[H" beginning-of-line  # Home key
    bindkey "^[[F" end-of-line        # End key

    # Tmux aliases and functions
    alias tm='tmux'
    alias tma='tmux attach'
    alias tms='tmux list-sessions'
    alias tmn='tmux new-session'
    alias tmz='tmux new-session -s main -c $HOME'  # New session with zsh
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
    # Use zsh as default shell (both settings for compatibility)
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
  services.openssh.enable = true;

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