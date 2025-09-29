{
  description = "NixOS Configuration Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
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
            home-manager.users.dev = import ./home-manager/dev.nix;
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