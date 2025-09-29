{ config, pkgs, lib, ... }:

{
  imports = [
    ../modules/neovim-latest.nix
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "dev";
  home.homeDirectory = "/home/dev";

  # This value determines the Home Manager release which your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.11";

  # User-specific packages
  home.packages = with pkgs; [
    # Development tools
    bun
    nodejs

    # CLI tools
    fzf
    bat
    eza
    ripgrep
    fd

    # Desktop applications
    firefox
    thunderbird
    kitty

    # 1Password
    _1password-cli
    _1password-gui

    # Proton applications
    protonmail-desktop
    protonmail-bridge
    protonmail-bridge-gui
    proton-pass
    protonvpn-gui
    protonvpn-cli

    # Development
    vscode
  ];

  # Environment variables
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    SHELL = "${pkgs.zsh}/bin/zsh";
  };

  # Zsh configuration
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    dotDir = ".config/zsh";

    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      save = 10000;
      share = true;
    };

    # Oh My Zsh configuration
    oh-my-zsh = {
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
        "tmux"
        "history-substring-search"
      ];
      theme = "robbyrussell";
    };

    shellAliases = {
      # Modern replacements
      ls = "eza --icons";
      ll = "eza -alF --icons";
      la = "eza -a --icons";
      l = "eza -F --icons";
      tree = "eza --tree --icons";
      cat = "bat";

      # Directory navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Git shortcuts
      gs = "git status";
      gp = "git pull";
      gc = "git commit";
      ga = "git add";
      gd = "git diff";
      gco = "git checkout";
      gb = "git branch";
      glog = "git log --oneline --graph --decorate";

      # Docker shortcuts
      dps = "docker ps";
      dpsa = "docker ps -a";
      dimg = "docker images";
      dexec = "docker exec -it";

      # Tmux aliases
      tm = "tmux";
      tma = "tmux attach";
      tms = "tmux list-sessions";
      tmn = "tmux new-session";
      tmz = "tmux new-session -s main -c $HOME";
    };

    initExtra = ''
      # Add Bun to PATH
      export PATH="/home/dev/.bun/bin:$PATH"

      # Enhanced history search with up/down arrows
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      # Additional useful key bindings
      bindkey "^[[1;5C" forward-word    # Ctrl+Right
      bindkey "^[[1;5D" backward-word   # Ctrl+Left
      bindkey "^[[3~" delete-char       # Delete key
      bindkey "^[[H" beginning-of-line  # Home key
      bindkey "^[[F" end-of-line        # End key

      # Enable fzf if available
      if command -v fzf &> /dev/null; then
        export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
        # Use fd for fzf if available
        if command -v fd &> /dev/null; then
          export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        fi
      fi

      # Force zsh when someone SSHs into this machine
      if [ -n "$SSH_CONNECTION" ]; then
        export SHELL=${pkgs.zsh}/bin/zsh
      fi
    '';

    profileExtra = ''
      # Ensure zsh is the shell for all contexts
      export SHELL=${pkgs.zsh}/bin/zsh
    '';

    loginExtra = ''
      # Ensure zsh environment for SSH
      export SHELL=${pkgs.zsh}/bin/zsh
    '';
  };

  # Tmux configuration
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
    terminal = "screen-256color";
    shell = "${pkgs.zsh}/bin/zsh";

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      prefix-highlight
    ];

    extraConfig = ''
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

  # Kitty terminal configuration
  programs.kitty = {
    enable = true;
    settings = {
      shell = "${pkgs.zsh}/bin/zsh";
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      window_padding_width = 10;
    };
    font = {
      name = "monospace";
      size = 11;
    };
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "dev";
    userEmail = "dev@localhost";

    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
  };

  # Neovim configuration (declarative)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Use the latest Neovim package available
    package = pkgs.neovim-unwrapped;

    # Install required packages
    extraPackages = with pkgs; [
      # Language servers
      lua-language-server
      nil
      nodePackages.typescript-language-server
      pyright
      rust-analyzer
      gopls

      # Additional tools
      ripgrep
      fd
      gcc
      git  # Required for lazy.nvim to clone plugins
    ];

    # We'll migrate kickstart.nvim configuration here later
    # For now, we'll use xdg.configFile to manage the config
  };


  # Bash configuration (for compatibility)
  programs.bash = {
    enable = true;
    initExtra = ''
      # If not running interactively, don't do anything
      [[ $- != *i* ]] && return

      # Switch to zsh if available
      if command -v zsh >/dev/null 2>&1; then
        exec zsh
      fi
    '';
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}