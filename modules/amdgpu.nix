{ config, lib, pkgs, ... }:

{
  # Enable AMD GPU drivers (open source, built into kernel)
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Hardware graphics configuration
  # RADV (Mesa Vulkan) is enabled by default and is the recommended Vulkan driver for AMD
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd      # OpenCL support
      libva                     # VA-API
      libvdpau-va-gl            # VDPAU via VA-API
    ];
  };

  # Environment variables for AMD hardware encoding
  environment.sessionVariables = {
    # VA-API driver (radeonsi is the Mesa VA-API driver for AMD)
    LIBVA_DRIVER_NAME = "radeonsi";
    # VDPAU via VA-API
    VDPAU_DRIVER = "radeonsi";
    # RADV (Mesa Vulkan) is used by default - best Vulkan driver for AMD
    # Firefox hardware acceleration
    MOZ_DISABLE_RDD_SANDBOX = "1";
    # VRR/FreeSync support
    __GL_VRR_ALLOWED = "1";
  };

  # AMD-specific packages
  environment.systemPackages = with pkgs; [
    radeontop          # GPU monitoring (like nvtop for AMD)
    libva-utils        # vainfo command to verify VA-API
    vdpauinfo          # VDPAU info tool
    vulkan-tools       # vulkaninfo
    mesa-demos         # OpenGL info (glxinfo, etc.)
    corectrl           # AMD GPU overclocking/fan control GUI
  ];

  # Enable corectrl without root (for GPU tuning)
  programs.corectrl.enable = true;
  hardware.amdgpu.overdrive.enable = true;  # Allow GPU overclocking

  # AMD GPUs work great with Wayland - can optionally enable
  # services.displayManager.sddm.wayland.enable = true;
}
