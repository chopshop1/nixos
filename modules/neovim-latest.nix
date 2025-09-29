{ pkgs, lib, ... }:

let
  # Fetch the latest chopshop1 nvim configuration from GitHub
  # Using the specific latest commit
  chopshop-nvim-src = pkgs.fetchFromGitHub {
    owner = "chopshop1";
    repo = ".nvim";
    # Latest commit as of now
    rev = "00bbc9b";
    # Update this hash when the repo changes
    sha256 = "sha256-EX1PhtNqoOENmKjUb2vKugwZOwYqaqmfHQtmJaadBy0=";
  };

  # Create a patched version that removes the hardtime requirement
  chopshop-nvim = pkgs.stdenv.mkDerivation {
    name = "chopshop-nvim-config-latest";
    src = chopshop-nvim-src;

    buildPhase = ''
      # Remove or comment out the hardtime requirement
      if grep -q 'require("hardtime")' init.lua; then
        sed -i 's/require("hardtime").setup()/-- require("hardtime").setup() -- Commented out by NixOS config/' init.lua
      fi
      if grep -q "require('hardtime')" init.lua; then
        sed -i "s/require('hardtime').setup()/-- require('hardtime').setup() -- Commented out by NixOS config/" init.lua
      fi
    '';

    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };
in
{
  # Complete Neovim configuration from chopshop1/.nvim fetched from GitHub
  # To update to latest: run 'nix flake update' or change the rev above

  xdg.configFile = {
    # Main init.lua file (patched)
    "nvim/init.lua".source = "${chopshop-nvim}/init.lua";

    # Copy the entire lua directory structure
    "nvim/lua".source = "${chopshop-nvim}/lua";

    # Copy doc directory if it exists
    "nvim/doc".source = "${chopshop-nvim}/doc";

    # Copy any other config files
    "nvim/.stylua.toml".source = "${chopshop-nvim}/.stylua.toml";

    # Add a file to track the source
    "nvim/.config-info".text = ''
      Neovim config fetched from: https://github.com/chopshop1/.nvim
      Branch/Rev: main

      To update to the latest version:
      1. Run: nix-prefetch-github chopshop1 .nvim
      2. Update the sha256 hash in /home/dev/nixos/modules/neovim-latest.nix
      3. Run: sudo nixos-rebuild switch --flake .#nixos
    '';
  };
}