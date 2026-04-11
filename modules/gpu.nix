{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.gpu;
in
{
  options.my.gpu = {
    type = mkOption {
      type = types.enum [ "nvidia" "amd" "intel" "none" ];
      default = "none";
      description = "GPU type for this machine";
    };

    nvidia = {
      package = mkOption {
        type = types.enum [ "stable" "beta" "production" "legacy_470" ];
        default = "stable";
        description = "NVIDIA driver package to use";
      };
      open = mkOption {
        type = types.bool;
        default = false;
        description = "Use open source NVIDIA kernel modules (Turing+ only)";
      };
    };

    primaryMonitor = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "HDMI-0";
      description = "Primary monitor output name";
    };

    defaultResolution = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1920x1080";
      description = "Default resolution";
    };

    defaultRefreshRate = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 120;
      description = "Default refresh rate in Hz";
    };

    overdrive = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable AMD GPU overdrive (overclocking) support. This sets
        amdgpu.ppfeaturemask=0xfffd7fff on the kernel cmdline, which is
        intended for discrete Polaris GPUs. On Raven Ridge / Vega iGPU APUs
        this mask clears PP_GFXOFF_MASK and PP_STUTTER_MODE, which the
        Raven Ridge SMU firmware mishandles and is a well-documented cause
        of silent hard lockups. Only enable on hosts with a discrete AMD
        GPU that you actually want to overclock.
      '';
    };
  };

  config = mkMerge [
    # ==================== Shared (any GPU) ====================
    # LD_LIBRARY_PATH for Vulkan/GL is consolidated in configuration-cleaned.nix

    # ==================== NVIDIA GPU ====================
    (mkIf (cfg.type == "nvidia") {
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          nvidia-vaapi-driver
          libva-vdpau-driver
          libvdpau-va-gl
          vulkan-loader         # libvulkan.so.1 in /run/opengl-driver/lib/
        ];
        extraPackages32 = with pkgs.pkgsi686Linux; [
          nvidia-vaapi-driver
        ];
      };

      hardware.nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.${cfg.nvidia.package};
        modesetting.enable = false;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        open = cfg.nvidia.open;
        nvidiaSettings = true;
      };

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia";
        # Hardware video acceleration (VA-API) in Firefox requires disabling the
        # RDD (Remote Data Decoder) sandbox on Linux.  Removing this breaks
        # GPU-accelerated video decode in Firefox.
        MOZ_DISABLE_RDD_SANDBOX = "1";
        VDPAU_DRIVER = "nvidia";
        __GL_GSYNC_ALLOWED = "1";
        __GL_VRR_ALLOWED = "1";
      };

      environment.systemPackages = with pkgs; [
        nvtopPackages.nvidia
        libva-utils
        vdpauinfo
        vulkan-loader
        vulkan-tools
        mesa-demos
      ];

      # Set display resolution if configured
      services.xserver.displayManager.setupCommands = mkIf (cfg.primaryMonitor != null && cfg.defaultResolution != null) ''
        ${pkgs.xrandr}/bin/xrandr --output ${cfg.primaryMonitor} --mode ${cfg.defaultResolution} ${optionalString (cfg.defaultRefreshRate != null) "--rate ${toString cfg.defaultRefreshRate}"} --primary || true
      '';
    })

    # ==================== AMD GPU ====================
    (mkIf (cfg.type == "amd") {
      services.xserver.videoDrivers = [ "amdgpu" ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        # RADV (Mesa Vulkan) is enabled by default and is the recommended Vulkan driver
        extraPackages = with pkgs; [
          rocmPackages.clr.icd  # OpenCL support
          libva                 # VA-API (video acceleration)
          libvdpau-va-gl        # VDPAU via VA-API
          vulkan-loader         # libvulkan.so.1 in /run/opengl-driver/lib/
        ];
      };

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "radeonsi";
        VDPAU_DRIVER = "radeonsi";
        # RADV is used by default (part of Mesa)
        # Hardware video acceleration (VA-API) in Firefox requires disabling the
        # RDD (Remote Data Decoder) sandbox on Linux.  Removing this breaks
        # GPU-accelerated video decode in Firefox.
        MOZ_DISABLE_RDD_SANDBOX = "1";
        __GL_VRR_ALLOWED = "1";
        # Wayland-specific AMD settings
        WLR_RENDERER = "vulkan";
        WLR_NO_HARDWARE_CURSORS = "0";  # AMD supports hardware cursors
      };

      environment.systemPackages = with pkgs; [
        radeontop
        libva-utils
        vdpauinfo
        vulkan-loader
        vulkan-tools
        mesa-demos
        corectrl
      ];

      programs.corectrl.enable = true;
      # Overdrive must be opt-in: it injects amdgpu.ppfeaturemask=0xfffd7fff
      # which silently hard-locks Raven Ridge iGPUs. See option doc above.
      hardware.amdgpu.overdrive.enable = cfg.overdrive;

      # Set display resolution if configured (for X11/Plasma sessions)
      services.xserver.displayManager.setupCommands = mkIf (cfg.primaryMonitor != null && cfg.defaultResolution != null) ''
        ${pkgs.xrandr}/bin/xrandr --output ${cfg.primaryMonitor} --mode ${cfg.defaultResolution} ${optionalString (cfg.defaultRefreshRate != null) "--rate ${toString cfg.defaultRefreshRate}"} --primary || true
      '';
    })

    # ==================== Intel GPU ====================
    (mkIf (cfg.type == "intel") {
      services.xserver.videoDrivers = [ "modesetting" ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          intel-media-driver
          vaapiIntel
          libvdpau-va-gl
          vulkan-loader         # libvulkan.so.1 in /run/opengl-driver/lib/
        ];
      };

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "iHD";
        VDPAU_DRIVER = "va_gl";
      };

      environment.systemPackages = with pkgs; [
        intel-gpu-tools
        libva-utils
        vdpauinfo
        vulkan-loader
        vulkan-tools
        mesa-demos
      ];
    })
  ];
}
