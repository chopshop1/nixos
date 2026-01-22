{ config, pkgs, lib, ... }:

{
  # User-specific packages
  home.packages = with pkgs; [
    # Browsers
    google-chrome  # Required for Claude Code browser integration

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
    mprocs

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
  ];
}
