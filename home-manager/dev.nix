{ config, pkgs, lib, ... }:

{
  # Neovim config is now managed directly in flake.nix
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

    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      save = 10000;
      share = true;
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
      work = "cd /home/dev/work";  # Jump to work folder from anywhere

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

    initContent = ''
      # Add Bun to PATH
      export PATH="/home/dev/.bun/bin:$PATH"

      # Save and restore last working directory
      LAST_DIR_FILE="$HOME/.zsh_last_dir"

      # Restore last directory on shell start (but not in tmux, since tmux handles it)
      if [[ -z "$TMUX" ]] && [[ -f "$LAST_DIR_FILE" ]]; then
        LAST_DIR=$(cat "$LAST_DIR_FILE")
        if [[ -d "$LAST_DIR" ]]; then
          cd "$LAST_DIR"
        fi
      fi

      # Save current directory on every directory change (only outside tmux)
      function save_last_dir() {
        if [[ -z "$TMUX" ]]; then
          pwd > "$LAST_DIR_FILE"
        fi
      }
      add-zsh-hook chpwd save_last_dir
      add-zsh-hook zshexit save_last_dir

      # Enhanced completion settings
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' special-dirs true
      zstyle ':completion:*' squeeze-slashes true
      zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
      zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
      zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
      zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
      zstyle ':completion:*' group-name ""

      # Enhanced history search with up/down arrows
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      # Tab completion navigation
      bindkey '^[[Z' reverse-menu-complete  # Shift+Tab for reverse

      # Additional useful key bindings
      bindkey "^[[1;5C" forward-word    # Ctrl+Right
      bindkey "^[[1;5D" backward-word   # Ctrl+Left
      bindkey "^[[3~" delete-char       # Delete key
      bindkey "^[[H" beginning-of-line  # Home key
      bindkey "^[[F" end-of-line        # End key

      # Sudo plugin: Press ESC twice to add sudo to previous command
      sudo-command-line() {
        [[ -z $BUFFER ]] && LBUFFER="$(fc -ln -1)"
        if [[ $BUFFER == sudo\ * ]]; then
          LBUFFER="''${LBUFFER#sudo }"
        else
          LBUFFER="sudo $LBUFFER"
        fi
      }
      zle -N sudo-command-line
      bindkey "\e\e" sudo-command-line

      # Extract function - universal archive extractor
      extract() {
        if [ -f "$1" ]; then
          case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *.tar.xz)    tar xf "$1"      ;;
            *.tar.zst)   tar xf "$1"      ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }

      # Open a tmux dev workspace for the current directory
      dev() {
        # Use current folder name as session name
        session="$(basename "$PWD")"
        root="$PWD"

        # If session already exists, just attach/switch
        if tmux has-session -t "$session" 2>/dev/null; then
          if [ -n "$TMUX" ]; then
            tmux switch-client -t "$session"
          else
            tmux attach -t "$session"
          fi
          return
        fi

        # Create detached session rooted at the directory
        tmux new-session -d -s "$session" -c "$root"

        # Split horizontally to create right pane
        tmux split-window -h -c "$root"

        # Select left pane and split it vertically
        tmux select-pane -t 0
        tmux split-window -v -c "$root"

        # Now we have:
        # Pane 0: top-left
        # Pane 1: right
        # Pane 2: bottom-left

        # Send commands
        tmux send-keys -t 0 'claude --dangerously-skip-permissions' C-m
        tmux send-keys -t 1 'nvim .' C-m
        tmux send-keys -t 2 'docker compose up -d' C-m

        # Focus right pane with nvim
        tmux select-pane -t 1

        # Attach/switch
        if [ -n "$TMUX" ]; then
          tmux switch-client -t "$session"
        else
          tmux attach -t "$session"
        fi
      }

      # Colored man pages
      export LESS_TERMCAP_mb=$'\e[1;32m'
      export LESS_TERMCAP_md=$'\e[1;32m'
      export LESS_TERMCAP_me=$'\e[0m'
      export LESS_TERMCAP_se=$'\e[0m'
      export LESS_TERMCAP_so=$'\e[01;33m'
      export LESS_TERMCAP_ue=$'\e[0m'
      export LESS_TERMCAP_us=$'\e[1;4;31m'

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

  # Starship prompt - Modern dark minimal theme
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = "[](dark_bg1)$os$username[](bg:dark_bg2 fg:dark_bg1)$directory[](bg:git_bg fg:dark_bg2)$git_branch$git_status$git_state[](fg:git_bg bg:lang_bg)$c$rust$golang$nodejs$php$java$kotlin$haskell$python[](fg:lang_bg bg:dark_bg3)$docker_context$conda[](fg:dark_bg3)$cmd_duration$line_break$character";

      palette = "modern_dark";

      os = {
        disabled = false;
        style = "bg:dark_bg1 fg:dim_text";
        symbols = {
          Windows = "";
          Ubuntu = "󰕈";
          SUSE = "";
          Raspbian = "󰐿";
          Mint = "󰣭";
          Macos = "󰀵";
          Manjaro = "";
          Linux = "󰌽";
          Gentoo = "󰣨";
          Fedora = "󰣛";
          Alpine = "";
          Amazon = "";
          Android = "";
          Arch = "󰣇";
          Artix = "󰣇";
          CentOS = "";
          Debian = "󰣚";
          Redhat = "󱄛";
          RedHatEnterprise = "󱄛";
        };
      };

      username = {
        show_always = true;
        style_user = "bg:dark_bg1 fg:dim_text";
        style_root = "bg:dark_bg1 fg:warning";
        format = "[ $user]($style)";
      };

      directory = {
        style = "bg:dark_bg2 fg:text";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          Documents = "󰈙 ";
          Downloads = " ";
          Music = "󰝚 ";
          Pictures = " ";
          Developer = "󰲋 ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:git_bg fg:git_text";
        format = "[[ $symbol $branch ](bg:git_bg fg:git_text)]($style)";
      };

      git_status = {
        style = "bg:git_bg fg:git_text";
        conflicted = "[!\${count}](bg:git_bg fg:error) ";
        ahead = "[⇡\${count}](bg:git_bg fg:git_text) ";
        behind = "[⇣\${count}](bg:git_bg fg:git_text) ";
        diverged = "[⇕\${ahead_count}⇣\${behind_count}](bg:git_bg fg:git_warn) ";
        up_to_date = "[✓](bg:git_bg fg:success)";
        untracked = "[?\${count}](bg:git_bg fg:dim_text) ";
        stashed = "[$\${count}](bg:git_bg fg:muted) ";
        modified = "[●\${count}](bg:git_bg fg:git_warn) ";
        staged = "[+\${count}](bg:git_bg fg:success) ";
        renamed = "[»\${count}](bg:git_bg fg:muted) ";
        deleted = "[✘\${count}](bg:git_bg fg:error) ";
      };

      git_state = {
        style = "bg:git_bg fg:warning";
        format = "[[ $state($progress_current/$progress_total) ](bg:git_bg fg:warning)]($style)";
        rebase = "rebasing";
        merge = "merging";
        revert = "reverting";
        cherry_pick = "cherry-picking";
        bisect = "bisecting";
        am = "am";
        am_or_rebase = "am/rebase";
      };

      nodejs = {
        symbol = "";
        style = "bg:lang_bg fg:muted";
        format = "[[ $symbol( $version) ](bg:lang_bg fg:muted)]($style)";
      };

      c = {
        symbol = " ";
        style = "bg:lang_bg fg:muted";
        format = "[[ $symbol( $version) ](bg:lang_bg fg:muted)]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:lang_bg fg:muted";
        format = "[[ $symbol( $version) ](bg:lang_bg fg:muted)]($style)";
      };

      golang = {
        symbol = "";
        style = "bg:lang_bg fg:muted";
        format = "[[ $symbol( $version) ](bg:lang_bg fg:muted)]($style)";
      };

      php = {
        symbol = "";
        style = "bg:lang_bg fg:muted";
        format = "[[ $symbol( $version) ](bg:lang_bg fg:muted)]($style)";
      };

      java = {
        symbol = " ";
        style = "bg:lang_bg fg:muted";
        format = "[[ $symbol( $version) ](bg:lang_bg fg:muted)]($style)";
      };

      kotlin = {
        symbol = "";
        style = "bg:lang_bg fg:muted";
        format = "[[ $symbol( $version) ](bg:lang_bg fg:muted)]($style)";
      };

      haskell = {
        symbol = "";
        style = "bg:lang_bg fg:muted";
        format = "[[ $symbol( $version) ](bg:lang_bg fg:muted)]($style)";
      };

      python = {
        symbol = "";
        style = "bg:lang_bg fg:muted";
        format = "[[ $symbol( $version)(($virtualenv)) ](bg:lang_bg fg:muted)]($style)";
      };

      docker_context = {
        symbol = "";
        style = "bg:dark_bg3 fg:muted";
        format = "[[ $symbol( $context) ](bg:dark_bg3 fg:muted)]($style)";
      };

      conda = {
        symbol = " ";
        style = "bg:dark_bg3 fg:muted";
        format = "[[ $symbol$environment ](bg:dark_bg3 fg:muted)]($style)";
        ignore_base = false;
      };

      time = {
        disabled = true;
      };

      line_break = {
        disabled = false;
      };

      character = {
        disabled = false;
        success_symbol = "[❯](bold success)";
        error_symbol = "[❯](bold error)";
        vimcmd_symbol = "[❮](bold success)";
        vimcmd_replace_one_symbol = "[❮](bold warning)";
        vimcmd_replace_symbol = "[❮](bold warning)";
        vimcmd_visual_symbol = "[❮](bold muted)";
      };

      cmd_duration = {
        show_milliseconds = false;
        format = "[ $duration]($style)";
        style = "bg:dark_bg3 fg:dim_text";
        disabled = false;
        min_time = 2000;
        show_notifications = true;
        min_time_to_notify = 45000;
      };

      palettes.modern_dark = {
        # Dark backgrounds
        dark_bg1 = "#1c1c1c";
        dark_bg2 = "#2a2a2a";
        dark_bg3 = "#303030";

        # Git section - dark slate
        git_bg = "#2c3440";

        # Language section
        lang_bg = "#2d2d2d";

        # Text colors - clearer grays
        text = "#e0e0e0";
        dim_text = "#9e9e9e";
        muted = "#8a8a8a";

        # Git colors - more visible
        git_text = "#b0bec5";
        git_warn = "#d4a574";

        # Status colors - more vibrant
        success = "#6b9b6b";
        warning = "#c79c5f";
        error = "#b56b6b";
      };
    };
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

      # Open new windows and panes in current directory
      bind-key c new-window -c "#{pane_current_path}"
      bind-key v split-window -h -c "#{pane_current_path}"
      bind-key s split-window -v -c "#{pane_current_path}"
      bind-key '"' split-window -v -c "#{pane_current_path}"
      bind-key % split-window -h -c "#{pane_current_path}"

      # Pane navigation with vim keybinds (lowercase)
      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R

      # Window navigation with vim keybinds (uppercase)
      bind-key H previous-window
      bind-key L next-window
      bind-key J previous-window
      bind-key K next-window

      # Session navigation with Ctrl + vim keybinds
      bind-key C-h switch-client -p
      bind-key C-l switch-client -n
      bind-key C-j switch-client -p
      bind-key C-k switch-client -n

      # Resize panes with arrow keys
      bind-key -r Left resize-pane -L 5
      bind-key -r Down resize-pane -D 5
      bind-key -r Up resize-pane -U 5
      bind-key -r Right resize-pane -R 5

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
