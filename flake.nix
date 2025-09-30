{
  description = "NixOS Configuration Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Add chopshop nvim config as a flake input
    chopshop-nvim = {
      url = "github:chopshop1/.nvim";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, chopshop-nvim, ... }@inputs: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration-cleaned.nix
          ./hardware-configuration.nix

          # Import Home Manager module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.dev = ({ pkgs, ... }: {
              imports = [
                # Import the main dev.nix but we'll override the neovim config
                ./home-manager/dev.nix
              ];

              # Override the neovim config files with our patched version
              xdg.configFile = let
                # Create a patched version that removes the hardtime requirement
                chopshop-nvim-patched = pkgs.stdenv.mkDerivation {
                  name = "chopshop-nvim-config-patched";
                  src = chopshop-nvim;

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
              in {
                # Main init.lua file (patched)
                "nvim/init.lua".source = "${chopshop-nvim-patched}/init.lua";

                # Copy the entire lua directory structure
                "nvim/lua".source = "${chopshop-nvim-patched}/lua";

                # Copy doc directory if it exists
                "nvim/doc".source = "${chopshop-nvim-patched}/doc";

                # Copy any other config files
                "nvim/.stylua.toml".source = "${chopshop-nvim-patched}/.stylua.toml";

                # Add a file to track the source
                "nvim/.config-info".text = ''
                  Neovim config fetched from: https://github.com/chopshop1/.nvim
                  Managed by NixOS flake input

                  To update to the latest version:
                  Run: nix flake update chopshop-nvim
                  Then: sudo nixos-rebuild switch --flake .#nixos
                '';
              };
            });
            # Backup existing files that conflict with Home Manager
            home-manager.backupFileExtension = "hm-backup";
          }

          # Enable module options
          {
            # Enable all our custom modules with their defaults
            my.cli-tools.enable = true;
            my.desktop-apps.enable = true;
            my.docker.enable = true;
            my.neovim.enable = true;
            my.powerManagement = {
              preventSuspend = true;
              enableWakeOnLan = true;
              keepWifiAlive = true;
            };
          }
        ];
        specialArgs = { inherit inputs; };
      };
    };
  };
}