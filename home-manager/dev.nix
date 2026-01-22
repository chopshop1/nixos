{ config, pkgs, lib, ... }:

{
  imports = [
    ./packages.nix      # User packages
    ./environment.nix   # Environment variables
    ./zsh.nix           # Zsh and bash configuration
    ./starship.nix      # Starship prompt theme
    ./tmux.nix          # Tmux configuration
    ./terminals.nix     # Kitty and Konsole terminals
    ./git.nix           # Git configuration
    ./neovim.nix        # Neovim editor
    ./mprocs.nix        # mprocs process manager
    ./repos.nix         # Repository management
    ./claude.nix        # Claude Code configuration
    ./hyprland.nix      # Hyprland window manager
  ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "dev";
  home.homeDirectory = "/home/dev";

  # This value determines the Home Manager release which your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
