{ config, pkgs, lib, ... }:

let
  # Import secrets directly (must exist and be staged with: git add -f secrets.nix)
  # If build fails, create secrets.nix from secrets.nix.example
  secrets = import ../secrets.nix;
in
{
  imports = [
    ./hyprland.nix  # Hyprland window manager configuration
  ];

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
    cargo
    rustc
    rust-analyzer

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
    obsidian

    # 1Password
    _1password-cli
    _1password-gui

    # Proton applications
    protonmail-desktop
    protonmail-bridge
    protonmail-bridge-gui
    proton-pass
    protonvpn-gui
    libsecret
    gnome-keyring

    # Development
    vscode

    # Playwright (browsers are pre-patched for NixOS)
    playwright-driver
    playwright-driver.browsers
  ];

  # Environment variables
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    SHELL = "${pkgs.zsh}/bin/zsh";
    # Playwright configuration for NixOS
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };

  # Zsh configuration
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    historySubstringSearch.enable = true;

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

      # Kickstart nvim (backup config)
      nvk = "NVIM_APPNAME=nvim-kickstart nvim";
    };

    initContent = ''
      # Add Bun to PATH
      export PATH="/home/dev/.bun/bin:$PATH"

      # Initialize gnome-keyring if not already running
      if [ -z "$GNOME_KEYRING_CONTROL" ] && command -v gnome-keyring-daemon &> /dev/null; then
        eval $(gnome-keyring-daemon --start --components=secrets 2>/dev/null)
        export GNOME_KEYRING_CONTROL
      fi

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
      # Multiple bindings to cover different terminal modes (normal, application, tmux)
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      bindkey '^[OA' history-substring-search-up    # Application mode (tmux)
      bindkey '^[OB' history-substring-search-down  # Application mode (tmux)
      bindkey "$terminfo[kcuu1]" history-substring-search-up    # Terminfo up
      bindkey "$terminfo[kcud1]" history-substring-search-down  # Terminfo down

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
        tmux send-keys -t 2 'claude --dangerously-skip-permissions' C-m

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

        # Auto-attach to tmux on SSH (attach to latest session)
        if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
          tmux attach 2>/dev/null
        fi
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
      # Status bar at top
      set -g status-position top

      # Enable mouse support
      set -g mouse on

      # OSC 52 clipboard support - allows tmux to copy to local clipboard over SSH
      # This works with most modern terminals (iTerm2, Kitty, Alacritty, Windows Terminal)
      set -g set-clipboard on
      set -ga terminal-features ',*:clipboard'

      # Configure tmux-yank to use OSC 52 for SSH sessions
      set -g @yank_action 'copy-pipe-no-clear'
      set -g @yank_with_mouse on
      set -g @yank_selection_mouse 'clipboard'

      # Copy mode bindings that use OSC 52
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel

      # Open new windows and panes in current directory
      bind-key c new-window -c "#{pane_current_path}"
      bind-key v split-window -h -c "#{pane_current_path}"
      bind-key x split-window -v -c "#{pane_current_path}"

      # Session switcher (prefix + s)
      bind-key s choose-tree -s
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

      # Custom Theme - Code Editor Principles
      # Purple (#8031f7): Keywords, functions → session, time
      # Pink (#d23d91): Strings, special → git branch
      # Cyan (#76e3ea): Types, constants, success → staged, clean, active window
      # Coral (#fc704f): Numbers, operators → modified
      # Red (#ff4445): Errors, deletions → high usage
      # Light Purple (#b780ff): Comments → untracked

      # 3D Effect - Pane borders
      set -g pane-border-style "fg=#3a3a5c"
      set -g pane-active-border-style "fg=#76e3ea,bold"

      # Status bar style
      set -g status-style "bg=#1a1a2e,fg=#e6ccff"
      set -g status-left-length 100
      set -g status-right-length 200
      set -g status-justify left

      # Left status: Session info and git status
      set -g status-left "#[fg=#1a1a2e,bg=#8031f7,bold] #S #[fg=#8031f7,bg=#3a3a5c]#[fg=#d23d91,bg=#3a3a5c]#(cd #{pane_current_path} && git branch --show-current 2>/dev/null | xargs -I{} echo ' {}')#[fg=#76e3ea]#(cd #{pane_current_path} && git diff --cached --numstat 2>/dev/null | wc -l | awk '$1>0{print \" +\"$1}')#[fg=#fc704f]#(cd #{pane_current_path} && git diff --numstat 2>/dev/null | wc -l | awk '$1>0{print \" ~\"$1}')#[fg=#b780ff]#(cd #{pane_current_path} && git ls-files --others --exclude-standard 2>/dev/null | wc -l | awk '$1>0{print \" ?\"$1}')#[fg=#76e3ea]#(cd #{pane_current_path} && git status --porcelain 2>/dev/null | wc -l | awk '$1==0{print \" ✓\"}') #[fg=#3a3a5c,bg=#1a1a2e]"

      # CPU plugin configuration
      set -g @cpu_low_fg_color "#[fg=#76e3ea]"
      set -g @cpu_medium_fg_color "#[fg=#fc704f]"
      set -g @cpu_high_fg_color "#[fg=#ff4445]"
      set -g @cpu_percentage_format "%3.0f%%"

      set -g @ram_low_fg_color "#[fg=#76e3ea]"
      set -g @ram_medium_fg_color "#[fg=#fc704f]"
      set -g @ram_high_fg_color "#[fg=#ff4445]"
      set -g @ram_percentage_format "%3.0f%%"

      # Status interval for updating status bar
      set -g status-interval 2

      # Right status: CPU, RAM, and time
      set -g status-right "#[fg=#3a3a5c,bg=#1a1a2e]#[fg=#76e3ea,bg=#3a3a5c] 󰻠 #(top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100-$1\"%\"}') #[fg=#e6ccff]| #[fg=#76e3ea]󰍛 #(free | awk '/Mem:/ {printf \"%.0f%%\", $3/$2*100}') #[fg=#8031f7,bg=#3a3a5c]#[fg=#1a1a2e,bg=#8031f7,bold] %H:%M %d-%b "

      # Window status - Cyan for active (like highlighted type/class)
      set -g window-status-format "#[fg=#1a1a2e,bg=#3a3a5c]#[fg=#b780ff,bg=#3a3a5c] #I:#W #[fg=#3a3a5c,bg=#1a1a2e]"
      set -g window-status-current-format "#[fg=#1a1a2e,bg=#76e3ea]#[fg=#1a1a2e,bg=#76e3ea,bold] #I:#W #[fg=#76e3ea,bg=#1a1a2e]"
      set -g window-status-separator ""

      # Messages
      set -g message-style "fg=#1a1a2e,bg=#76e3ea,bold"
      set -g message-command-style "fg=#1a1a2e,bg=#8031f7,bold"

      # Pane number display
      set -g display-panes-active-colour "#76e3ea"
      set -g display-panes-colour "#3a3a5c"

      # Clock
      set -g clock-mode-colour "#8031f7"

      # Copy mode - Cyan selection like editor selection
      set -g mode-style "fg=#1a1a2e,bg=#76e3ea"
    '';
  };

  # Kitty terminal configuration with Tokyo Night theme
  programs.kitty = {
    enable = true;
    settings = {
      shell = "${pkgs.zsh}/bin/zsh";
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      window_padding_width = 10;

      # Tokyo Night Storm colorscheme
      background = "#1a1b26";
      foreground = "#c0caf5";
      selection_background = "#283457";
      selection_foreground = "#c0caf5";
      url_color = "#73daca";
      cursor = "#c0caf5";
      cursor_text_color = "#1a1b26";

      # Tabs
      active_tab_background = "#7aa2f7";
      active_tab_foreground = "#1f2335";
      inactive_tab_background = "#292e42";
      inactive_tab_foreground = "#545c7e";

      # Normal colors
      color0 = "#15161e";
      color1 = "#f7768e";
      color2 = "#9ece6a";
      color3 = "#e0af68";
      color4 = "#7aa2f7";
      color5 = "#bb9af7";
      color6 = "#7dcfff";
      color7 = "#a9b1d6";

      # Bright colors
      color8 = "#414868";
      color9 = "#f7768e";
      color10 = "#9ece6a";
      color11 = "#e0af68";
      color12 = "#7aa2f7";
      color13 = "#bb9af7";
      color14 = "#7dcfff";
      color15 = "#c0caf5";
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
  };

  # GTK/Qt theme configuration is in hyprland.nix

  # Konsole (KDE Terminal) Tokyo Night theme
  home.file.".local/share/konsole/TokyoNight.colorscheme".text = ''
    [Background]
    Color=26,27,38

    [BackgroundFaint]
    Color=26,27,38

    [BackgroundIntense]
    Color=36,40,59

    [Color0]
    Color=21,22,30

    [Color0Faint]
    Color=21,22,30

    [Color0Intense]
    Color=65,72,104

    [Color1]
    Color=247,118,142

    [Color1Faint]
    Color=247,118,142

    [Color1Intense]
    Color=247,118,142

    [Color2]
    Color=158,206,106

    [Color2Faint]
    Color=158,206,106

    [Color2Intense]
    Color=158,206,106

    [Color3]
    Color=224,175,104

    [Color3Faint]
    Color=224,175,104

    [Color3Intense]
    Color=224,175,104

    [Color4]
    Color=122,162,247

    [Color4Faint]
    Color=122,162,247

    [Color4Intense]
    Color=122,162,247

    [Color5]
    Color=187,154,247

    [Color5Faint]
    Color=187,154,247

    [Color5Intense]
    Color=187,154,247

    [Color6]
    Color=125,207,255

    [Color6Faint]
    Color=125,207,255

    [Color6Intense]
    Color=125,207,255

    [Color7]
    Color=169,177,214

    [Color7Faint]
    Color=169,177,214

    [Color7Intense]
    Color=192,202,245

    [Foreground]
    Color=192,202,245

    [ForegroundFaint]
    Color=169,177,214

    [ForegroundIntense]
    Color=192,202,245

    [General]
    Anchor=0.5,0.5
    Blur=false
    ColorRandomization=false
    Description=Tokyo Night
    FillStyle=Tile
    Opacity=1
    Wallpaper=
    WallpaperFlipType=NoFlip
    WallpaperOpacity=1
  '';

  home.file.".local/share/konsole/TokyoNight.profile".text = ''
    [Appearance]
    ColorScheme=TokyoNight
    Font=JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1

    [Cursor Options]
    CursorShape=1

    [General]
    Command=/run/current-system/sw/bin/zsh
    Name=Tokyo Night
    Parent=FALLBACK/

    [Scrolling]
    HistoryMode=2
    ScrollBarPosition=2

    [Terminal Features]
    BlinkingCursorEnabled=true
  '';

  # Set Konsole to use Tokyo Night profile by default
  home.file.".config/konsolerc".text = ''
    [Desktop Entry]
    DefaultProfile=TokyoNight.profile

    [General]
    ConfigVersion=1

    [MainWindow]
    MenuBar=Disabled
    ToolBarsMovable=Disabled

    [TabBar]
    TabBarVisibility=ShowTabBarWhenNeeded
  '';

  # Git configuration (uses secrets.nix for user info)
  programs.git = {
    enable = true;
    settings = {
      user.name = secrets.git.userName;
      user.email = secrets.git.userEmail;
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

  # Activation script to clone/update agents repo (graceful failure if unavailable)
  home.activation.updateAgentsRepo = lib.hm.dag.entryAfter ["writeBoundary"] ''
    AGENTS_DIR="/home/dev/work/agents"
    AGENTS_REPO="git@github.com:chopshop1/agents.git"

    export PATH="${pkgs.openssh}/bin:${pkgs.git}/bin:$PATH"

    if [ ! -d "$AGENTS_DIR" ]; then
      echo "Cloning agents repo..."
      if $DRY_RUN_CMD ${pkgs.git}/bin/git clone "$AGENTS_REPO" "$AGENTS_DIR" 2>/dev/null; then
        echo "Successfully cloned agents repo"
      else
        echo "Warning: Could not clone agents repo (network unavailable or SSH key issue)"
        echo "Creating minimal agents structure for build to continue..."
        $DRY_RUN_CMD mkdir -p "$AGENTS_DIR"
      fi
    else
      cd "$AGENTS_DIR"
      if ${pkgs.git}/bin/git diff --quiet 2>/dev/null && ${pkgs.git}/bin/git diff --cached --quiet 2>/dev/null; then
        if $DRY_RUN_CMD ${pkgs.git}/bin/git pull 2>/dev/null; then
          echo "Successfully updated agents repo"
        else
          echo "Warning: Could not update agents repo (network unavailable)"
        fi
      else
        echo "Skipping agents repo update: local changes detected in $AGENTS_DIR"
      fi
    fi
  '';

  # Neovim config - symlink to .nvim repo (uses lazy.nvim)
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "/home/dev/work/.nvim";

  # Activation script to clone/update .nvim repo (graceful failure if unavailable)
  home.activation.updateNvimRepo = lib.hm.dag.entryAfter ["writeBoundary"] ''
    NVIM_DIR="/home/dev/work/.nvim"
    NVIM_REPO="git@github.com:chopshop1/.nvim.git"

    export PATH="${pkgs.openssh}/bin:${pkgs.git}/bin:$PATH"

    if [ ! -d "$NVIM_DIR" ]; then
      echo "Cloning nvim repo..."
      if $DRY_RUN_CMD ${pkgs.git}/bin/git clone "$NVIM_REPO" "$NVIM_DIR" 2>/dev/null; then
        echo "Successfully cloned nvim repo"
      else
        echo "Warning: Could not clone nvim repo (network unavailable or SSH key issue)"
        echo "Creating minimal nvim structure for build to continue..."
        $DRY_RUN_CMD mkdir -p "$NVIM_DIR"
      fi
    else
      cd "$NVIM_DIR"
      # Only pull if working tree is clean, otherwise skip to avoid losing local changes
      if ${pkgs.git}/bin/git diff --quiet 2>/dev/null && ${pkgs.git}/bin/git diff --cached --quiet 2>/dev/null; then
        if $DRY_RUN_CMD ${pkgs.git}/bin/git pull 2>/dev/null; then
          echo "Successfully updated nvim repo"
        else
          echo "Warning: Could not update nvim repo (network unavailable)"
        fi
      else
        echo "Skipping nvim repo update: local changes detected in $NVIM_DIR"
      fi
    fi
  '';

  # Dotfiles repo - symlink individual claude config files (not the whole directory)
  # This preserves session data (history, projects, credentials) while syncing settings
  home.file.".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "/home/dev/work/dotfiles/claude/settings.json";
  home.file.".claude/hooks".source = config.lib.file.mkOutOfStoreSymlink "/home/dev/work/dotfiles/claude/hooks";

  # Activation script to clone/update dotfiles repo (graceful failure if unavailable)
  home.activation.updateDotfilesRepo = lib.hm.dag.entryAfter ["writeBoundary"] ''
    DOTFILES_DIR="/home/dev/work/dotfiles"
    DOTFILES_REPO="git@github.com:chopshop1/dotfiles.git"

    export PATH="${pkgs.openssh}/bin:${pkgs.git}/bin:$PATH"

    clone_or_update_dotfiles() {
      if [ ! -d "$DOTFILES_DIR" ]; then
        echo "Cloning dotfiles repo..."
        if $DRY_RUN_CMD ${pkgs.git}/bin/git clone "$DOTFILES_REPO" "$DOTFILES_DIR" 2>/dev/null; then
          echo "Successfully cloned dotfiles repo"
        else
          echo "Warning: Could not clone dotfiles repo (network unavailable or SSH key issue)"
          echo "Creating minimal dotfiles structure for build to continue..."
          $DRY_RUN_CMD mkdir -p "$DOTFILES_DIR/claude/hooks"
          $DRY_RUN_CMD touch "$DOTFILES_DIR/claude/settings.json"
          echo '{}' > "$DOTFILES_DIR/claude/settings.json" 2>/dev/null || true
        fi
      else
        cd "$DOTFILES_DIR"
        # Only pull if working tree is clean
        if ${pkgs.git}/bin/git diff --quiet 2>/dev/null && ${pkgs.git}/bin/git diff --cached --quiet 2>/dev/null; then
          if $DRY_RUN_CMD ${pkgs.git}/bin/git pull 2>/dev/null; then
            echo "Successfully updated dotfiles repo"
          else
            echo "Warning: Could not update dotfiles repo (network unavailable)"
          fi
        else
          echo "Skipping dotfiles repo update: local changes detected in $DOTFILES_DIR"
        fi
      fi
    }

    clone_or_update_dotfiles
  '';

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
