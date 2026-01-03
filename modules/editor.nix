{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Neovim config is managed via Home Manager (symlinked from ~/work/.nvim)
  # Uses lazy.nvim as plugin manager

  # Additional packages for development
  environment.systemPackages = with pkgs; [
    # Language servers for neovim
    lua-language-server
    nil  # Nix LSP
    nodePackages.typescript-language-server
    pyright
    rust-analyzer
    gopls

    # Additional tools
    ripgrep  # Required by telescope
    fd       # Required by telescope
    git      # Required by lazy.nvim and gitsigns
    gcc      # Required for treesitter compilation

    # Proton applications
    protonmail-desktop      # ProtonMail desktop app
    protonmail-bridge       # ProtonMail bridge for email clients
    protonmail-bridge-gui   # ProtonMail bridge GUI
    proton-pass            # Proton Pass password manager
    protonvpn-gui          # ProtonVPN GUI

    # Other editors (optional)
    vscode
  ];
}