{ config, lib, pkgs, ... }:

{
  # Enable NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  # Hardware graphics configuration (replaces hardware.opengl in NixOS 24.11+)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # Extra packages for Vulkan and video encoding
    extraPackages = with pkgs; [
      nvidia-vaapi-driver  # VAAPI driver for NVIDIA (hardware video decode)
      libva-vdpau-driver   # VDPAU backend for VAAPI
      libvdpau-va-gl       # VAAPI backend for VDPAU
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      nvidia-vaapi-driver
    ];
  };

  # With 4K dummy plug, let it auto-detect the native 4K resolution
  # boot.kernelParams = [ "video=HDMI-A-1:3840x2160@60" ];

  # NVIDIA driver configuration
  hardware.nvidia = {
    # Use the stable driver (recommended for GTX 1080 Ti)
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Modesetting disabled for X11 (only needed for Wayland)
    modesetting.enable = false;

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

  # Environment variables for NVIDIA hardware encoding (used by Sunshine)
  environment.sessionVariables = {
    # Force VAAPI to use NVIDIA
    LIBVA_DRIVER_NAME = "nvidia";
    # Required for Firefox hardware acceleration
    MOZ_DISABLE_RDD_SANDBOX = "1";
    # NVIDIA VDPAU
    VDPAU_DRIVER = "nvidia";
    # Help with Proton/Wine game capture
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
  };

  # Add NVIDIA-related packages
  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia  # GPU monitoring tool
    libva-utils           # vainfo command to verify VAAPI
    vdpauinfo             # VDPAU info tool
    vulkan-tools          # vulkaninfo
    mesa-demos            # OpenGL info (glxinfo, etc.)
  ];

  # Set default display resolution to 1080p 120Hz on login
  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-0 --mode 1920x1080 --rate 120 --primary || true
  '';
}
