{
  description = "Terminal-first NixOS devbox with reproducible tooling";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvchad = {
      url = "github:NvChad/NvChad";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, nvchad, ... }:
    let
      lib = nixpkgs.lib;
      defaultUserSettings = {
        hostname = "devbox";
        username = "devuser";
        timezone = "UTC";
        sshAuthorizedKey = null;
      };

      makeSystem =
        { system, hostPath, userSettings ? { }, userSettingsPath ? null }:
        let
          fromFile = if userSettingsPath != null
          && builtins.pathExists userSettingsPath then
            import userSettingsPath
          else
            { };
          mergedSettings = lib.recursiveUpdate defaultUserSettings
            (lib.recursiveUpdate fromFile userSettings);
        in lib.nixosSystem {
          inherit system;
          specialArgs = {
            userSettings = mergedSettings;
            nvchadSrc = nvchad;
          };
          modules = [ hostPath home-manager.nixosModules.default ];
        };
    in {
      nixosConfigurations = {
        devbox = makeSystem {
          system = "x86_64-linux";
          hostPath = ./hosts/devbox/configuration.nix;
          userSettingsPath = ./hosts/devbox/user-settings.nix;
        };

        devbox-aarch64 = makeSystem {
          system = "aarch64-linux";
          hostPath = ./hosts/devbox/configuration.nix;
          userSettingsPath = ./hosts/devbox/user-settings.nix;
        };
      };

      formatter = {
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
        aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt;
      };
    };
}
