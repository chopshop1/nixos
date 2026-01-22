{ config, pkgs, lib, ... }:

{
  # Git configuration
  # User name/email are set via environment variables at activation time
  # Set GIT_USER_NAME and GIT_USER_EMAIL in your shell profile or pass to nixos-rebuild
  programs.git = {
    enable = true;
    includes = [
      { path = "~/.config/git/local"; }  # Local config generated from env vars
    ];
    settings = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
  };

  # Generate git local config from environment variables at activation time
  home.activation.gitLocalConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    GIT_LOCAL_CONFIG="$HOME/.config/git/local"
    mkdir -p "$(dirname "$GIT_LOCAL_CONFIG")"

    # Read from environment or existing config
    NAME="''${GIT_USER_NAME:-}"
    EMAIL="''${GIT_USER_EMAIL:-}"

    # If env vars not set, try to preserve existing values
    if [ -z "$NAME" ] && [ -f "$GIT_LOCAL_CONFIG" ]; then
      NAME=$(${pkgs.git}/bin/git config --file "$GIT_LOCAL_CONFIG" user.name 2>/dev/null || true)
    fi
    if [ -z "$EMAIL" ] && [ -f "$GIT_LOCAL_CONFIG" ]; then
      EMAIL=$(${pkgs.git}/bin/git config --file "$GIT_LOCAL_CONFIG" user.email 2>/dev/null || true)
    fi

    # Only write if we have values
    if [ -n "$NAME" ] || [ -n "$EMAIL" ]; then
      echo "[user]" > "$GIT_LOCAL_CONFIG"
      [ -n "$NAME" ] && echo "  name = $NAME" >> "$GIT_LOCAL_CONFIG"
      [ -n "$EMAIL" ] && echo "  email = $EMAIL" >> "$GIT_LOCAL_CONFIG"
      echo "Git local config updated: $GIT_LOCAL_CONFIG"
    elif [ ! -f "$GIT_LOCAL_CONFIG" ]; then
      echo "Warning: GIT_USER_NAME and GIT_USER_EMAIL not set. Run:"
      echo "  GIT_USER_NAME='Your Name' GIT_USER_EMAIL='you@example.com' sudo -E nixos-rebuild switch --flake .#nixos-amd"
    fi
  '';
}
