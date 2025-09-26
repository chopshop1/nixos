{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Clone kickstart.nvim to user's config directory
  system.activationScripts.kickstart-nvim = {
    text = ''
      if [ ! -d /home/dev/.config/nvim ]; then
        mkdir -p /home/dev/.config
        ${pkgs.git}/bin/git clone https://github.com/nvim-lua/kickstart.nvim.git /home/dev/.config/nvim
        chown -R dev:users /home/dev/.config/nvim
      fi
    '';
    deps = [];
  };

  # Additional packages for development
  environment.systemPackages = with pkgs; [
    # Language servers for kickstart
    lua-language-server
    nil  # Nix LSP
    nodePackages.typescript-language-server
    pyright
    rust-analyzer
    gopls

    # Additional tools
    ripgrep  # Required by telescope
    fd       # Required by telescope
    git      # Required by gitsigns
    gcc      # Required for treesitter compilation

    # Proton applications
    protonmail-desktop      # ProtonMail desktop app
    protonmail-bridge       # ProtonMail bridge for email clients
    protonmail-bridge-gui   # ProtonMail bridge GUI
    proton-pass            # Proton Pass password manager
    protonvpn-gui          # ProtonVPN GUI
    protonvpn-cli          # ProtonVPN CLI

    # Other editors (optional)
    vscode
  ];
}