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
    # Latest dev version of opencode (uses its own nixpkgs for build deps)
    opencode.url = "github:anomalyco/opencode";
  };

  outputs = { self, nixpkgs, home-manager, chopshop-nvim, opencode, ... }@inputs:
  let
    system = "x86_64-linux";

    # Shared modules used by all hosts
    sharedModules = [
      # Make opencode dev package available via overlay
      { nixpkgs.overlays = [
        (final: prev: {
          opencode = opencode.packages.${system}.default;
          lutris = prev.lutris.override {
            lutris-unwrapped = prev.lutris-unwrapped.overrideAttrs (old: rec {
              version = "0.5.20";
              src = prev.fetchFromGitHub {
                owner = "lutris";
                repo = "lutris";
                rev = "v${version}";
                hash = "sha256-ycAlVV5CkLLsk/m17R8k6x40av1wcEVQU2GMbOuc7Bs=";
              };
            });
          };
        })
      ]; }
      ./configuration-cleaned.nix
      ./devContainer/container.nix

      # Import Home Manager module
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.dev = ({ pkgs, ... }: {
          imports = [
            ./home-manager/dev.nix
          ];
        });
        # Use a backup command that handles existing backups gracefully
        home-manager.backupFileExtension = "hm-backup~";
      }

      # Shared module options (per-host features like gaming/streaming are set in extraModules)
      {
        my.cli-tools.enable = true;
        my.desktop-apps.enable = true;
        my.neovim.enable = true;
      }
    ];

    # Helper to create a host configuration
    mkHost = { hostName, hardwareConfig, gpuType, gpuConfig ? {}, extraModules ? [] }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = sharedModules ++ [
          hardwareConfig
          {
            networking.hostName = hostName;
            my.gpu = {
              type = gpuType;
            } // gpuConfig;
          }
        ] ++ extraModules;
        specialArgs = { inherit inputs; };
      };

  in {
    nixosConfigurations = {
      # Current machine: NVIDIA GTX 1080 Ti
      nixos = mkHost {
        hostName = "nixos";
        hardwareConfig = ./hardware-configuration.nix;
        gpuType = "nvidia";
        gpuConfig = {
          nvidia.package = "stable";
          nvidia.open = false;  # Pascal doesn't support open drivers
          primaryMonitor = "HDMI-0";
          defaultResolution = "1920x1080";
          defaultRefreshRate = 120;
        };
        extraModules = [{
          my.gaming.enable = true;
          my.sunshine.enable = true;
          my.docker.enable = true;
          my.yubikey.enable = true;
          my.devContainer.enable = true;
          my.powerManagement = {
            preventSuspend = true;
            enableWakeOnLan = true;
            keepWifiAlive = true;
          };
          my.streaming = {
            enable = true;
            maxBitrate = 100;
          };
          my.hardwareMonitoring = {
            enable = true;
            sensors.enable = true;
            rgb.enable = true;
            rgb.disableOnBoot = true;
          };
        }];
      };

      # AMD Ryzen 9 7950X3D + RX 7900 XTX build
      nixos-amd = mkHost {
        hostName = "nixos-amd";
        hardwareConfig = ./hosts/amd-workstation/hardware-configuration.nix;
        gpuType = "amd";
        gpuConfig = {
          primaryMonitor = "HDMI-A-1";
          defaultResolution = "1920x1080";
          defaultRefreshRate = 120;
        };
        extraModules = [{
          my.gaming.enable = true;
          my.sunshine.enable = true;
          my.docker.enable = true;
          my.yubikey.enable = true;
          my.devContainer.enable = true;
          my.powerManagement = {
            preventSuspend = true;
            enableWakeOnLan = true;
            keepWifiAlive = true;
          };
          my.streaming = {
            enable = true;
            maxBitrate = 100;
          };
          my.hardwareMonitoring = {
            enable = true;
            sensors.enable = true;
            rgb.enable = true;
            rgb.disableOnBoot = true;
          };
        }];
      };

      # Lenovo dev machine: Ryzen 5 Pro 2400GE (Vega 11), 16GB RAM
      home = mkHost {
        hostName = "home";
        hardwareConfig = ./hosts/lenovo-dev/hardware-configuration.nix;
        gpuType = "amd";
        extraModules = [{
          # Fix ath10k WiFi + AMD IOMMU page faults causing system hangs
          boot.kernelParams = [ "iommu=soft" ];

          # Dev-only: no gaming, streaming, sunshine, or hardware monitoring
          my.gaming.enable = false;
          my.sunshine.enable = false;
          my.streaming.enable = false;
          my.hardwareMonitoring.enable = false;
          my.ollama.enable = false;
          my.docker.enable = true;
          my.devContainer.enable = true;
          my.homeAssistant.enable = true;
          # Always-on: never suspend, keep network alive
          my.powerManagement = {
            preventSuspend = true;
            enableWakeOnLan = true;
            keepWifiAlive = true;
            preferEthernet = true;
          };
        }];
      };

      # Legacy alias (points to current machine)
      default = self.nixosConfigurations.nixos;
    };
  };
}