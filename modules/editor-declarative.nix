{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.neovim;

  # Note: kickstart.nvim is managed through Home Manager's xdg.configFile
  # This module just ensures the necessary packages are installed
in
{
  options.my.neovim = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Neovim with kickstart.nvim configuration";
    };

    useKickstart = mkOption {
      type = types.bool;
      default = true;
      description = "Use kickstart.nvim configuration";
    };

    additionalLSPs = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional language servers to install";
    };
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    environment.systemPackages = with pkgs; [
      # Core Neovim dependencies
      neovim

      # Language servers
      lua-language-server
      nil                                    # Nix LSP
      nodePackages.typescript-language-server
      pyright
      rust-analyzer
      gopls

      # Tools required by kickstart.nvim
      # ripgrep, fd, git, nodejs available via cli-tools.nix / system-base.nix
      gcc      # Required for treesitter compilation
      gnumake  # For building some plugins

      # Additional formatters and linters
      nixpkgs-fmt
      black
      nodePackages.prettier
      rustfmt
      gofumpt
    ] ++ cfg.additionalLSPs;

    # Instead of using activation scripts, we'll manage the config through Home Manager
    # This is more declarative and reproducible
  };
}