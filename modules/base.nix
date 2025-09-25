{ config, lib, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    curl
    file
    git
    htop
    lsof
    ncdu
    tree
    unzip
    wget
    zip
    tmux
    neovim
    ripgrep
    fd
    bat
    eza
    zoxide
    fzf
    flatpak
    bun
  ];

  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
    };
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Enable nix-ld for running dynamically linked executables
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glibc
    gcc
    zlib
  ];

  # Enable 1Password GUI
  programs._1password-gui.enable = true;

  # Add Bun's binary path to environment variables
  environment.variables.PATH = [
    "/root/.bun/bin"
  ];
}