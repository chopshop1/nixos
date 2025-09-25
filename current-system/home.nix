{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "dev";
  home.homeDirectory = "/home/dev";

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    # Add user-specific packages here
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Configure zsh with home-manager for better integration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "docker"
        "npm"
        "node"
        "nodejs"
        "nix"
      ];
      theme = "robbyrussell";
    };

    # Custom aliases
    shellAliases = {
      ll = "ls -la";
      la = "ls -la";
      rebuild = "sudo nixos-rebuild switch --flake /home/dev/nixos#current-system";
      update-flake = "cd /home/dev/nixos && nix flake update";
    };

    # Custom zsh configuration
    initExtra = ''
      # Custom prompt modifications
      export EDITOR="nvim"
      export PATH="$HOME/.bun/bin:$PATH"

      # History settings
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_IGNORE_SPACE
      setopt HIST_SAVE_NO_DUPS
      setopt SHARE_HISTORY

      # Enable history search with arrow keys
      autoload -U history-search-end
      zle -N history-beginning-search-backward-end history-search-end
      zle -N history-beginning-search-forward-end history-search-end
      bindkey "^[[A" history-beginning-search-backward-end
      bindkey "^[[B" history-beginning-search-forward-end
    '';
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  home.stateVersion = "24.11";
}