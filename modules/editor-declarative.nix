{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.neovim;

  # Create a custom kickstart.nvim package
  kickstartNvim = pkgs.stdenv.mkDerivation rec {
    pname = "kickstart-nvim-config";
    version = "2024-01-01";

    src = pkgs.fetchFromGitHub {
      owner = "nvim-lua";
      repo = "kickstart.nvim";
      rev = "master";
      sha256 = "sha256-0000000000000000000000000000000000000000000="; # Update with actual hash
    };

    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };
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
      ripgrep  # Required by telescope
      fd       # Required by telescope
      git      # Required by gitsigns
      gcc      # Required for treesitter compilation
      gnumake  # For building some plugins
      nodejs   # For some LSPs and plugins

      # Additional formatters and linters
      nixpkgs-fmt
      black
      prettier
      rustfmt
      gofumpt
    ] ++ cfg.additionalLSPs;

    # Instead of using activation scripts, we'll manage the config through Home Manager
    # This is more declarative and reproducible
  };
}