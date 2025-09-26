{ config, pkgs, ... }:

{
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
    # Additional zsh plugins and tools
    zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];

  # Zsh configuration
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    enableCompletion = true;

    # Additional zsh configuration
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
        "tmux"
        "history-substring-search"
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
      ];
      theme = "robbyrussell";
    };

    # Additional shell initialization
    initExtra = ''
      # Ensure zsh is the shell for all contexts
      export SHELL="$(which zsh)"

      # Enhanced history search with up/down arrows
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

      # Useful aliases
      alias ll='ls -alF'
      alias la='ls -A'
      alias l='ls -CF'
      alias ..='cd ..'
      alias ...='cd ../..'

      # Tmux aliases that ensure zsh
      alias tm='tmux'
      alias tma='tmux attach'
      alias tms='tmux list-sessions'
      alias tmn='tmux new-session'
      alias tmz='tmux new-session -s main -c $HOME'

      # Function to ensure zsh in all new shells
      ensure_zsh() {
        if [[ "$SHELL" != *"zsh" ]]; then
          exec zsh
        fi
      }

      # Force zsh when someone SSHs into this machine
      if [ -n "$SSH_CONNECTION" ]; then
        export SHELL=${pkgs.zsh}/bin/zsh
      fi

      # SSH wrapper to ensure zsh on remote sessions
      ssh() {
        command ssh -t "$@" "zsh || bash || sh"
      }
    '';
  };

  # Kitty terminal configuration to ensure zsh
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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}