{ config, pkgs, lib, ... }:

{
  # Repository management activation scripts
  # These clone/update external repos that contain configurations

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
}
