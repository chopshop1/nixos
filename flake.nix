{
  description = "NixOS Configuration Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Latest dev version of opencode (uses its own nixpkgs for build deps)
    opencode.url = "github:anomalyco/opencode";
  };

  outputs = { self, nixpkgs, home-manager, opencode, ... }@inputs:
  let
    system = "x86_64-linux";

    # Shared modules used by all hosts
    sharedModules = [
      # Make opencode dev package available via overlay
      { nixpkgs.overlays = [
        (final: prev: let
          ollamaVersion = "0.20.2";
          ollamaSrc = prev.fetchFromGitHub {
            owner = "ollama";
            repo = "ollama";
            tag = "v${ollamaVersion}";
            hash = "sha256-Ic3eLOohLR7MQGkLvDJBNOCiBBKxh6l8X9MgK0b4w+Y=";
          };
          ollamaOverride = {
            version = ollamaVersion;
            src = ollamaSrc;
            vendorHash = "sha256-Lc1Ktdqtv2VhJQssk8K1UOimeEjVNvDWePE9WkamCos=";
          };
        in {
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
          ollama = prev.ollama.overrideAttrs ollamaOverride;
          ollama-rocm = prev.ollama-rocm.overrideAttrs ollamaOverride;
          ollama-cuda = prev.ollama-cuda.overrideAttrs ollamaOverride;
          ollama-vulkan = prev.ollama-vulkan.overrideAttrs ollamaOverride;
          ollama-cpu = prev.ollama-cpu.overrideAttrs ollamaOverride;
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
          my.sunshine = {
            enable = true;
            # Set to a PulseAudio/PipeWire sink name to capture audio directly,
            # or null to let Sunshine create a virtual sink.
            # Find sinks with: pactl list short sinks
            audioSink = null;
          };
          my.docker.enable = true;
          my.yubikey.enable = true;
          my.devContainer.enable = true;
          my.powerManagement = {
            preventSuspend = true;
            enableWakeOnLan = true;
            keepWifiAlive = true;
            preferEthernet = true;
          };
          my.streaming = {
            enable = true;
            interface = "enp4s0";
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
          my.ollama.package = "rocm";
          # Only use discrete GPU (gfx1100) for Ollama — the Ryzen iGPU (gfx1036)
          # lacks rocBLAS Tensile kernels and crashes inference
          services.ollama.environmentVariables.HIP_VISIBLE_DEVICES = "0";
          my.gaming.enable = true;
          my.sunshine = {
            enable = true;
            audioSink = null;
          };
          my.docker.enable = true;
          my.yubikey.enable = true;
          my.devContainer.enable = true;
          my.powerManagement = {
            preventSuspend = true;
            enableWakeOnLan = true;
            keepWifiAlive = true;
            preferEthernet = true;
          };
          my.streaming = {
            enable = true;
            interface = "enp6s0";
            maxBitrate = 100;
          };
          my.hardwareMonitoring = {
            enable = true;
            sensors.enable = true;
            rgb.enable = true;
            rgb.disableOnBoot = true;
            fanControl.enable = true;
            # Linear ramp: minPwm at 45°C, full speed at 75°C
            fanControl.minTemp = 45;
            fanControl.maxTemp = 75;
            fanControl.minPwm = 80;
          };
        }];
      };

      # Lenovo dev machine: Ryzen 5 Pro 2400GE (Vega 11), 16GB RAM
      home = mkHost {
        hostName = "home";
        hardwareConfig = ./hosts/lenovo-dev/hardware-configuration.nix;
        gpuType = "amd";
        extraModules = [
          ./modules/crash-monitor.nix
          {
          # Fix ath10k WiFi + AMD IOMMU page faults causing system hangs
          # Disable PCIe ASPM and deep CPU C-states to prevent silent hard lockups
          boot.kernelParams = [ "iommu=soft" "pcie_aspm=off" "processor.max_cstate=1" ];

          # Blacklist WiFi driver entirely -- ethernet-only machine, prevents
          # ath10k DMA/IOMMU issues even with iommu=soft
          boot.blacklistedKernelModules = [ "ath10k_pci" "ath10k_core" ];

          # Compressed in-memory swap -- prevents OOM deadlocks on 16GB system
          zramSwap = {
            enable = true;
            memoryPercent = 50;
            algorithm = "zstd";
          };

          # Crash recovery: convert lockups into panics so pstore captures them,
          # then auto-reboot. Check /sys/fs/pstore/ after reboot for crash dumps.
          boot.kernel.sysctl = {
            "kernel.panic" = 10;
            "kernel.panic_on_oops" = 1;
            "kernel.softlockup_panic" = 1;
            "kernel.hardlockup_panic" = 1;
            "kernel.hung_task_panic" = 1;
          };

          # Hardware watchdog: auto-reboot on hard lockup (SP5100 TCO timer)
          # Without this, silent freezes require physical reboot
          systemd.settings.Manager.RuntimeWatchdogSec = "30s";
          systemd.settings.Manager.RebootWatchdogSec = "10min";

          # Userspace OOM killer -- acts before kernel OOM can deadlock
          systemd.oomd = {
            enable = true;
            enableRootSlice = true;
            enableUserSlices = true;
            enableSystemSlice = true;
          };

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
            keepWifiAlive = false;  # WiFi driver blacklisted, no interface to manage
            preferEthernet = true;
          };
        }];
      };

      # Legacy alias (points to current machine)
      default = self.nixosConfigurations.nixos;
    };
  };
}