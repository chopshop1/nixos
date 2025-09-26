# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Kernel parameters to prevent suspension
  boot.kernelParams = [
    "consoleblank=0"  # Prevent console blanking
    "noresume"        # Disable resume from hibernation
    "nohibernate"     # Disable hibernation
  ];

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
  services.pulseaudio.enable = false;
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

  # Set zsh as the default shell system-wide
  users.defaultUserShell = pkgs.zsh;

  # Ensure zsh is in the list of valid shells
  environment.shells = with pkgs; [ zsh bash ];

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
  zsh             # Z shell
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  oh-my-zsh
  kitty           # Terminal emulator
  tmux            # Terminal multiplexer
  docker          # Container platform
  ethtool         # Network interface configuration tool for Wake-on-LAN

  # Useful command-line tools for Oh My Zsh plugins
  fzf             # Fuzzy finder
  bat             # Better cat
  eza             # Better ls
  ripgrep         # Better grep
  fd              # Better find
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

# Create .zshenv file for SSH sessions
environment.etc."zshenv".text = ''
  # Ensure zsh is the shell for SSH sessions
  if [ -n "$SSH_CONNECTION" ]; then
    export SHELL=${pkgs.zsh}/bin/zsh
  fi
'';

  # Enable zsh system-wide with Oh My Zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    # Oh My Zsh configuration
    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "docker"
        "npm"
        "node"
        "sudo"
        "history"
        "command-not-found"
        "colored-man-pages"
        "extract"
      ];
      theme = "robbyrussell";
    };

    # Set zsh as a login shell
    loginShellInit = ''
      # Ensure zsh environment for SSH
      export SHELL=${pkgs.zsh}/bin/zsh
    '';

    # Ensure zsh is the default shell for all sessions
    shellInit = ''
      # Force zsh for all terminal sessions
      export SHELL=${pkgs.zsh}/bin/zsh
    '';

    # Interactive shell configuration
    interactiveShellInit = ''
      # History configuration
      export HISTFILE="$HOME/.zsh_history"
      export HISTSIZE=10000
      export SAVEHIST=10000
      setopt HIST_IGNORE_DUPS
      setopt SHARE_HISTORY
      setopt HIST_IGNORE_SPACE

      # Use modern replacements if available
      if command -v eza &> /dev/null; then
        alias ls='eza --icons'
        alias ll='eza -alF --icons'
        alias la='eza -a --icons'
        alias l='eza -F --icons'
        alias tree='eza --tree --icons'
      else
        alias ll='ls -alF'
        alias la='ls -A'
        alias l='ls -CF'
      fi

      if command -v bat &> /dev/null; then
        alias cat='bat'
      fi

      # Directory navigation
      alias ..='cd ..'
      alias ...='cd ../..'
      alias ....='cd ../../..'

      # Git shortcuts
      alias gs='git status'
      alias gp='git pull'
      alias gc='git commit'
      alias ga='git add'
      alias gd='git diff'
      alias gco='git checkout'
      alias gb='git branch'
      alias glog='git log --oneline --graph --decorate'

      # Docker shortcuts
      alias dps='docker ps'
      alias dpsa='docker ps -a'
      alias dimg='docker images'
      alias dexec='docker exec -it'

      # Better history search
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      # Enable fzf if available
      if command -v fzf &> /dev/null; then
        export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
        # Use fd for fzf if available
        if command -v fd &> /dev/null; then
          export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        fi
      fi

      # Source user configuration if exists
      [ -f ~/.zshrc ] && source ~/.zshrc
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
      # Use PAM for proper session setup
      UsePAM = true;
    };
  };

  # Set default shell for SSH sessions
  programs.ssh.extraConfig = ''
    SetEnv SHELL=${pkgs.zsh}/bin/zsh
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
  # Using only the new settings format to avoid duplication
  services.logind.settings = {
    Login = {
      HandleSuspendKey = "ignore";
      HandleHibernateKey = "ignore";
      HandleLidSwitch = "ignore";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      IdleAction = "ignore";
      IdleActionSec = "0";
      UserStopDelaySec = "0";
    };
  };

  # Disable automatic suspend completely
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Mask suspend/sleep services to prevent them from being started
  systemd.services."systemd-suspend" = {
    enable = false;
  };
  systemd.services."systemd-hibernate" = {
    enable = false;
  };
  systemd.services."systemd-hybrid-sleep" = {
    enable = false;
  };

  # Disable suspend on idle for GNOME
  services.gnome.gnome-settings-daemon.enable = true;

  # GNOME power management settings to prevent suspension
  programs.dconf.enable = true;

  # Create a systemd service that prevents suspend when SSH sessions are active
  systemd.services.ssh-nosuspend = {
    description = "Prevent suspend while SSH sessions are active";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "sshd.service" ];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "30";
      ExecStart = "${pkgs.bash}/bin/bash -c 'while true; do if ss -tn state established \"( sport = :22 or dport = :22 )\" | grep -q \":22\"; then systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target; else systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target; fi; sleep 30; done'";
    };
  };

  # Create a permanent systemd inhibitor lock to prevent suspension
  systemd.services.suspend-inhibitor = {
    description = "Inhibit system suspension permanently";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "10";
      ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=sleep:idle:handle-lid-switch --who=nixos --why=\"System configured to never suspend for SSH availability\" --mode=block sleep infinity";
    };
  };

  # Completely disable power management
  powerManagement.enable = false;

  # Keep WiFi connection alive
  networking.networkmanager.wifi.powersave = false;

  # Ensure NetworkManager doesn't put WiFi to sleep using new settings format
  networking.networkmanager.settings = {
    connection = {
      "wifi.powersave" = 2;
    };
    device = {
      "wifi.scan-rand-mac-address" = "no";
    };
  };

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