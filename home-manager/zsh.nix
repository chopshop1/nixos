{ config, pkgs, lib, ... }:

{
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
      # Add local bin and Bun to PATH
      export PATH="$HOME/.local/bin:/home/dev/.bun/bin:$PATH"

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

      # Ralph - Claude Code automation scripts
      # Human-in-the-loop: run once, watch what it does, run again
      ralph-once() {
        if [ ! -f "progress.txt" ]; then
          echo "Creating progress.txt..."
          touch progress.txt
        fi
        claude --dangerously-skip-permissions "@.planning/PROJECT.md @progress.txt \
1. Read the PRD phases and progress file. \
2. Find the next incomplete task and implement it. \
3. Commit your changes. \
4. Update progress.txt with what you did. \
ONLY DO ONE TASK AT A TIME."
      }

      # AFK Ralph: run Claude in a loop for autonomous work
      afk-ralph() {
        if [ -z "$1" ]; then
          echo "Usage: afk-ralph <iterations>"
          echo "Example: afk-ralph 20"
          return 1
        fi
        if [ ! -f "progress.txt" ]; then
          echo "Creating progress.txt..."
          touch progress.txt
        fi

        local iterations=$1
        for ((i=1; i<=iterations; i++)); do
          echo "=== Iteration $i of $iterations ==="
          local result
          result=$(claude -p "@.planning/PROJECT.md @progress.txt \
1. Find the next phase's task and implement it. \
2. Run your tests and type checks. \
3. Update the PRD and phases with what was done. \
4. Append your progress to progress.txt. \
5. Commit your changes. \
ONLY WORK ON A SINGLE TASK. \
If the PRD is complete, output <promise>COMPLETE</promise>.")

          echo "$result"

          if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
            echo "PRD complete after $i iterations."
            return 0
          fi
        done
        echo "Completed $iterations iterations."
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
}
