{ config, pkgs, lib, ... }:

{
  # Tmux configuration
  # Main config is in dotfiles/tmux/ for cross-platform sharing
  # Home-manager handles plugin installation via Nix
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";

    # Plugins managed by Nix (faster than TPM, declarative)
    # Plugin extraConfig is placed BEFORE run-shell, so options are
    # available when the plugin initializes (critical for restore on boot)
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      prefix-highlight
      cpu
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];

    # Source the shared dotfiles config
    # This overrides home-manager defaults with our cross-platform settings
    extraConfig = ''
      # Source main config from dotfiles (shared with macOS)
      source-file ~/.config/tmux/dotfiles/tmux.conf
    '';
  };

  # Auto-start tmux server on boot so continuum can restore sessions
  systemd.user.services.tmux-server = {
    Unit = {
      Description = "tmux server";
      After = [ "default.target" ];
    };
    Service = {
      Type = "forking";
      ExecStart = "${pkgs.tmux}/bin/tmux new-session -d";
      ExecStop = "${pkgs.tmux}/bin/tmux kill-server";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
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

  # Symlink tmux scripts from dotfiles
  home.file.".local/bin/tmux-session-picker".source =
    config.lib.file.mkOutOfStoreSymlink "/home/dev/work/dotfiles/tmux/tmux-session-picker";
  home.file.".local/bin/tmux-continuum-save".source =
    config.lib.file.mkOutOfStoreSymlink "/home/dev/work/dotfiles/tmux/tmux-continuum-save";
}
