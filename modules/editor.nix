{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Install packages needed for kickstart
    configure = {
      packages.all = with pkgs.vimPlugins; {
        start = [
          # Core dependencies for kickstart
          nvim-treesitter.withAllGrammars
          telescope-nvim
          telescope-fzf-native-nvim
          nvim-lspconfig
          nvim-cmp
          cmp-nvim-lsp
          cmp-buffer
          cmp-path
          cmp-cmdline
          luasnip
          cmp_luasnip
          friendly-snippets
          gitsigns-nvim
          which-key-nvim
          comment-nvim
          indent-blankline-nvim
          lualine-nvim
          nvim-autopairs
          nvim-colorizer-lua
          plenary-nvim
          nvim-web-devicons
        ];
      };
    };
  };

  # Additional packages for development
  environment.systemPackages = with pkgs; [
    # Language servers for kickstart
    lua-language-server
    nil  # Nix LSP
    nodePackages.typescript-language-server
    nodePackages.pyright
    rust-analyzer
    gopls

    # Additional tools
    ripgrep  # Required by telescope
    fd       # Required by telescope
    git      # Required by gitsigns
    gcc      # Required for treesitter compilation

    # Other editors (optional)
    vscode
  ];
}