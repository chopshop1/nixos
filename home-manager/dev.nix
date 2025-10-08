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
      ezp = "git add -A && git commit -m \"update\" && git push";

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

      # Smart tmux attach/switch - works both inside and outside tmux
      ta() {
        if [ -z "$1" ]; then
          echo "Usage: ta <session-name>"
          echo "Available sessions:"
          tmux list-sessions 2>/dev/null || echo "No tmux sessions running"
          return 1
        fi

        if [ -n "$TMUX" ]; then
          # Inside tmux, switch to session
          tmux switch-client -t "$1"
        else
          # Outside tmux, attach to session
          tmux attach -t "$1"
        fi
      }

      # Autocomplete for ta function - list tmux sessions
      _ta_completion() {
        local sessions
        sessions=(''${(f)"$(tmux list-sessions -F '#S' 2>/dev/null)"})
        _describe 'tmux session' sessions
      }
      compdef _ta_completion ta

      # Open a tmux dev workspace for the current directory
      dev() {
        # Use provided path or current directory
        if [ -n "$1" ]; then
          root="$(cd "$1" && pwd)"
        else
          root="$PWD"
        fi

        # Use folder name as session name
        session="$(basename "$root")"

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

  # Starship prompt - Tokyo Night theme (2025 trendy build)
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = "[░▒▓](#a3aed2)[  ](bg:#a3aed2 fg:#090c0c)$os[](bg:#769ff0 fg:#a3aed2)$directory[](fg:#769ff0 bg:#394260)$git_branch$git_status$git_state[](fg:#394260 bg:#212736)$c$rust$golang$nodejs$php$java$kotlin$haskell$python$bun[](fg:#212736 bg:#1d2230)$docker_context$conda$aws[](fg:#1d2230 bg:#16161e)$time[ ](fg:#16161e)$line_break$character";

      palette = "tokyo_night";

      os = {
        disabled = false;
        style = "bg:#a3aed2 fg:#090c0c";
        symbols = {
          Windows = "󰍲";
          Ubuntu = "󰕈";
          SUSE = "";
          Raspbian = "󰐿";
          Mint = "󰣭";
          Macos = "";
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
          NixOS = "";
        };
      };

      directory = {
        style = "fg:#e3e5e5 bg:#769ff0";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          Documents = "󰈙 ";
          Downloads = " ";
          Music = "󰝚 ";
          Pictures = " ";
          Developer = "󰲋 ";
          work = " ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:#394260";
        format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
      };

      git_status = {
        style = "bg:#394260";
        conflicted = "[!\${count}](bg:#394260 fg:#f7768e) ";
        ahead = "[⇡\${count}](bg:#394260 fg:#769ff0) ";
        behind = "[⇣\${count}](bg:#394260 fg:#769ff0) ";
        diverged = "[⇕\${ahead_count}⇣\${behind_count}](bg:#394260 fg:#e0af68) ";
        up_to_date = "[✓](bg:#394260 fg:#9ece6a)";
        untracked = "[?\${count}](bg:#394260 fg:#787c99) ";
        stashed = "[$\${count}](bg:#394260 fg:#bb9af7) ";
        modified = "[●\${count}](bg:#394260 fg:#e0af68) ";
        staged = "[+\${count}](bg:#394260 fg:#9ece6a) ";
        renamed = "[»\${count}](bg:#394260 fg:#7dcfff) ";
        deleted = "[✘\${count}](bg:#394260 fg:#f7768e) ";
        format = "[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)";
      };

      git_state = {
        style = "bg:#394260 fg:#e0af68";
        format = "[[ $state($progress_current/$progress_total) ](bg:#394260 fg:#e0af68)]($style)";
        rebase = "REBASING";
        merge = "MERGING";
        revert = "REVERTING";
        cherry_pick = "CHERRY-PICKING";
        bisect = "BISECTING";
        am = "AM";
        am_or_rebase = "AM/REBASE";
      };

      c = {
        symbol = " ";
        style = "bg:#212736";
        format = "[[ $symbol($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      golang = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      php = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      java = {
        symbol = " ";
        style = "bg:#212736";
        format = "[[ $symbol($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      kotlin = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      haskell = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      python = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol($version)(($virtualenv)) ](fg:#769ff0 bg:#212736)]($style)";
      };

      bun = {
        symbol = "󰛦 ";
        style = "bg:#212736";
        format = "[[ $symbol($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      docker_context = {
        symbol = "";
        style = "bg:#1d2230";
        format = "[[ $symbol($context) ](fg:#769ff0 bg:#1d2230)]($style)";
      };

      conda = {
        symbol = " ";
        style = "bg:#1d2230";
        format = "[[ $symbol$environment ](fg:#769ff0 bg:#1d2230)]($style)";
        ignore_base = false;
      };

      aws = {
        symbol = " ";
        style = "bg:#1d2230";
        format = "[[ $symbol($profile)(\\($region\\)) ](fg:#769ff0 bg:#1d2230)]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:#16161e";
        format = "[[  $time ](fg:#a9b1d6 bg:#16161e)]($style)";
      };

      line_break = {
        disabled = false;
      };

      character = {
        disabled = false;
        success_symbol = "[❯](bold fg:#9ece6a)";
        error_symbol = "[❯](bold fg:#f7768e)";
        vimcmd_symbol = "[❮](bold fg:#9ece6a)";
        vimcmd_replace_one_symbol = "[❮](bold fg:#bb9af7)";
        vimcmd_replace_symbol = "[❮](bold fg:#bb9af7)";
        vimcmd_visual_symbol = "[❮](bold fg:#e0af68)";
      };

      cmd_duration = {
        show_milliseconds = false;
        format = "took [$duration](bold yellow) ";
        disabled = false;
        min_time = 2000;
        show_notifications = true;
        min_time_to_notify = 45000;
      };

      palettes.tokyo_night = {
        # Tokyo Night Storm color palette
        bg = "#24283b";
        bg_dark = "#1f2335";
        bg_highlight = "#292e42";
        terminal_black = "#414868";
        fg = "#c0caf5";
        fg_dark = "#a9b1d6";
        fg_gutter = "#3b4261";
        dark3 = "#545c7e";
        comment = "#565f89";
        dark5 = "#737aa2";
        blue0 = "#3d59a1";
        blue = "#7aa2f7";
        cyan = "#7dcfff";
        blue1 = "#2ac3de";
        blue2 = "#0db9d7";
        blue5 = "#89ddff";
        blue6 = "#b4f9f8";
        blue7 = "#394b70";
        magenta = "#bb9af7";
        magenta2 = "#ff007c";
        purple = "#9d7cd8";
        orange = "#ff9e64";
        yellow = "#e0af68";
        green = "#9ece6a";
        green1 = "#73daca";
        green2 = "#41a6b5";
        teal = "#1abc9c";
        red = "#f7768e";
        red1 = "#db4b4b";
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
      cpu
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

      # Tokyo Night Theme Colors
      set -g @tokyo-night-bg "#1a1b26"
      set -g @tokyo-night-fg "#c0caf5"
      set -g @tokyo-night-blue "#7aa2f7"
      set -g @tokyo-night-cyan "#7dcfff"
      set -g @tokyo-night-green "#9ece6a"
      set -g @tokyo-night-magenta "#bb9af7"
      set -g @tokyo-night-red "#f7768e"
      set -g @tokyo-night-yellow "#e0af68"
      set -g @tokyo-night-gray "#414868"

      # 3D Effect - Pane borders
      set -g pane-border-style "fg=#414868"
      set -g pane-active-border-style "fg=#7aa2f7,bold"

      # Status bar style
      set -g status-style "bg=#1a1b26,fg=#c0caf5"
      set -g status-left-length 50
      set -g status-right-length 100
      set -g status-justify left

      # Left status: Session info
      set -g status-left "#[fg=#1a1b26,bg=#7aa2f7,bold] 󰣇 #S #[fg=#7aa2f7,bg=#414868] #[fg=#c0caf5,bg=#414868] #I:#P #[fg=#414868,bg=#1a1b26]"

      # CPU plugin configuration
      set -g @cpu_low_fg_color "#[fg=#9ece6a]"
      set -g @cpu_medium_fg_color "#[fg=#e0af68]"
      set -g @cpu_high_fg_color "#[fg=#f7768e]"
      set -g @cpu_percentage_format "%3.0f%%"

      set -g @ram_low_fg_color "#[fg=#9ece6a]"
      set -g @ram_medium_fg_color "#[fg=#e0af68]"
      set -g @ram_high_fg_color "#[fg=#f7768e]"
      set -g @ram_percentage_format "%3.0f%%"

      # Right status: CPU, RAM, and time
      set -g status-right "#[fg=#414868,bg=#1a1b26]#[fg=#7aa2f7,bg=#414868] 󰻠 #{cpu_percentage} #[fg=#c0caf5]| #[fg=#7aa2f7]󰍛 #{ram_percentage} #[fg=#7aa2f7,bg=#414868]#[fg=#1a1b26,bg=#7aa2f7,bold] %H:%M %d-%b "

      # Window status
      set -g window-status-format "#[fg=#1a1b26,bg=#414868]#[fg=#c0caf5,bg=#414868] #I:#W #[fg=#414868,bg=#1a1b26]"
      set -g window-status-current-format "#[fg=#1a1b26,bg=#bb9af7]#[fg=#1a1b26,bg=#bb9af7,bold] #I:#W #[fg=#bb9af7,bg=#1a1b26]"
      set -g window-status-separator ""

      # Messages
      set -g message-style "fg=#1a1b26,bg=#7aa2f7,bold"
      set -g message-command-style "fg=#1a1b26,bg=#7aa2f7,bold"

      # Pane number display
      set -g display-panes-active-colour "#7aa2f7"
      set -g display-panes-colour "#414868"

      # Clock
      set -g clock-mode-colour "#7aa2f7"

      # Copy mode
      set -g mode-style "fg=#1a1b26,bg=#7aa2f7"
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

  # Claude Code configuration - symlink to agents repo
  home.file.".config/claude".source = config.lib.file.mkOutOfStoreSymlink "/home/dev/work/agents";

  # Activation script to clone/update agents repo
  home.activation.updateAgentsRepo = lib.hm.dag.entryAfter ["writeBoundary"] ''
    AGENTS_DIR="/home/dev/work/agents"
    AGENTS_REPO="git@github.com:chopshop1/agents.git"

    export PATH="${pkgs.openssh}/bin:${pkgs.git}/bin:$PATH"

    if [ ! -d "$AGENTS_DIR" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone "$AGENTS_REPO" "$AGENTS_DIR"
    else
      cd "$AGENTS_DIR"
      $DRY_RUN_CMD ${pkgs.git}/bin/git pull
    fi
  '';

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
