{ config, pkgs, lib, ... }:

{
  # Neovim configuration (declarative)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Use the latest Neovim package available
    package = pkgs.neovim-unwrapped;

    # Install required packages
    extraPackages = with pkgs; [
      # Language servers
      lua-language-server
      nil
      nodePackages.typescript-language-server
      pyright
      rust-analyzer
      gopls

      # Additional tools
      ripgrep
      fd
      gcc
      git  # Required for lazy.nvim to clone plugins
    ];

    # We'll migrate kickstart.nvim configuration here later
    # For now, we'll use xdg.configFile to manage the config
  };

  # Neovim config - symlink to .nvim repo (uses lazy.nvim)
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "/home/dev/work/.nvim";
}
