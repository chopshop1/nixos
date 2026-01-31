{ config, pkgs, lib, ... }:

{
  # Tmux configuration
  # Main config is in dotfiles/tmux/ for cross-platform sharing
  # Home-manager handles plugin installation via Nix
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";

    # Plugins managed by Nix (faster than TPM, declarative)
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      prefix-highlight
      cpu
    ];

    # Source the shared dotfiles config
    # This overrides home-manager defaults with our cross-platform settings
    extraConfig = ''
      # Source main config from dotfiles (shared with macOS)
      source-file ~/.config/tmux/dotfiles/tmux.conf
    '';
  };

  # Force-overwrite tmux.conf to avoid conflicts with stale non-HM-managed files
  xdg.configFile."tmux/tmux.conf".force = true;

  # Symlink dotfiles tmux configs
  home.file.".config/tmux/dotfiles/tmux.conf".source =
    config.lib.file.mkOutOfStoreSymlink "/home/dev/work/dotfiles/tmux/tmux.conf";
  home.file.".config/tmux/platform-nixos.conf".source =
    config.lib.file.mkOutOfStoreSymlink "/home/dev/work/dotfiles/tmux/platform-nixos.conf";
  home.file.".config/tmux/platform-macos.conf".source =
    config.lib.file.mkOutOfStoreSymlink "/home/dev/work/dotfiles/tmux/platform-macos.conf";

  # Symlink tmux session picker script from dotfiles
  home.file.".local/bin/tmux-session-picker".source =
    config.lib.file.mkOutOfStoreSymlink "/home/dev/work/dotfiles/tmux/tmux-session-picker";
}
