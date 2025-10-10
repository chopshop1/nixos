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

              # Nvim config is now managed as a git repository (see home-manager/dev.nix activation script)
              # The updateNvimConfig activation script pulls fresh from kickstart.nvim on each rebuild
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