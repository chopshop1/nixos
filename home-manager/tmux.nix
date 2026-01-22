{ config, pkgs, lib, ... }:

{
  # Tmux configuration
  # Main config is in dotfiles/tmux/ for cross-platform compatibility
  # Home-manager manages plugins on NixOS, TPM is used on macOS
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
    terminal = "screen-256color";
    shell = "${pkgs.zsh}/bin/zsh";

    # Plugins managed by home-manager on NixOS
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      prefix-highlight
      cpu
    ];

    # Source the cross-platform config from dotfiles
    # This config handles OS detection and sources platform-specific files
    extraConfig = ''
      # Source cross-platform config from dotfiles
      source-file ~/.config/tmux/dotfiles.conf
    '';
  };

  # Symlink tmux config files from dotfiles
  # Main config with cross-platform settings and theme
  home.file.".config/tmux/dotfiles.conf".source =
    config.lib.file.mkOutOfStoreSymlink "/home/dev/work/dotfiles/tmux/tmux.conf";

  # Platform-specific configs (sourced by dotfiles.conf based on OS)
  home.file.".config/tmux/platform-nixos.conf".source =
    config.lib.file.mkOutOfStoreSymlink "/home/dev/work/dotfiles/tmux/platform-nixos.conf";
  home.file.".config/tmux/platform-macos.conf".source =
    config.lib.file.mkOutOfStoreSymlink "/home/dev/work/dotfiles/tmux/platform-macos.conf";

  # Session picker script from dotfiles
  # Note: executable bit is set on the source file in dotfiles repo
  home.file.".local/bin/tmux-session-picker".source =
    config.lib.file.mkOutOfStoreSymlink "/home/dev/work/dotfiles/tmux/tmux-session-picker";
}
