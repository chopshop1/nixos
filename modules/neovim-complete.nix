{ pkgs, lib, ... }:

{
  # Complete Neovim configuration from chopshop1/.nvim in a single module

  xdg.configFile = {
    # Main init.lua file
    "nvim/init.lua".text = builtins.readFile ./chopshop-init.lua;

    # Custom plugins
    "nvim/lua/custom/plugins/init.lua".text = builtins.readFile ./nvim-lua/custom/plugins/init.lua;

    # Kickstart plugins
    "nvim/lua/kickstart/plugins/debug.lua".text = builtins.readFile ./nvim-lua/kickstart/plugins/debug.lua;
    "nvim/lua/kickstart/plugins/indent_line.lua".text = builtins.readFile ./nvim-lua/kickstart/plugins/indent_line.lua;
    "nvim/lua/kickstart/plugins/lint.lua".text = builtins.readFile ./nvim-lua/kickstart/plugins/lint.lua;
    "nvim/lua/kickstart/plugins/autopairs.lua".text = builtins.readFile ./nvim-lua/kickstart/plugins/autopairs.lua;
    "nvim/lua/kickstart/plugins/neo-tree.lua".text = builtins.readFile ./nvim-lua/kickstart/plugins/neo-tree.lua;
    "nvim/lua/kickstart/plugins/gitsigns.lua".text = builtins.readFile ./nvim-lua/kickstart/plugins/gitsigns.lua;

    # Health check
    "nvim/lua/kickstart/health.lua".text = builtins.readFile ./nvim-lua/kickstart/health.lua;
  };
}