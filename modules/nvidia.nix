{ config, lib, pkgs, ... }:

{
  # Enable NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  # Hardware graphics configuration (replaces hardware.opengl in NixOS 24.11+)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA driver configuration
  hardware.nvidia = {
    # Use the stable driver (recommended for GTX 1080 Ti)
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Modesetting is required for most Wayland compositors and GNOME
    modesetting.enable = true;

    # Enable power management (experimental, may cause issues on some systems)
    powerManagement.enable = false;

    # Fine-grained power management (for Turing+ GPUs only, not Pascal)
    powerManagement.finegrained = false;

    # Use the open source kernel module (not recommended for GTX 1080 Ti)
    # The open source drivers are for Turing and newer (RTX 20xx+)
    open = false;

    # Enable the nvidia-settings GUI
    nvidiaSettings = true;
  };

  # Add NVIDIA-related packages
  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia  # GPU monitoring tool
  ];
}
