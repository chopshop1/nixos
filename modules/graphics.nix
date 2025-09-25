{ lib, userSettings, config, ... }:
let
  gfx = userSettings.graphics or { };
  enableOpenGL = gfx.enableOpenGL or true;
  driver = gfx.driver or null; # e.g. "amdgpu" | "intel" | "nvidia"
  initrd = gfx.initrd or { };
  preloadAmdgpu = initrd.amdgpu or false;
  plymouthEnable = gfx.plymouthEnable or false; # default off to avoid black screens
  blacklistRadeon = gfx.blacklistRadeon or false;
  oldAmd = gfx.oldAmd or { };
  forceAmdgpu = oldAmd.forceAmdgpu or false; # forces amdgpu on SI/CIK and disables radeon
  amd = gfx.amd or { };
  dcDisable = amd.dcDisable or false; # amdgpu.dc=0 can help some displays
  dpmDisable = amd.dpmDisable or false; # amdgpu.dpm=0 for troubleshooting
  # NVIDIA controls
  isNvidia = (driver == "nvidia");
  nvidia = gfx.nvidia or { };
  nvidiaModeset = nvidia.modeset or true;
  nvidiaOpen = nvidia.open or false; # 1080 Ti uses proprietary, so default false
in {
  # OpenGL/DRI are broadly useful; allow users to opt-out via settings
  hardware.opengl.enable = enableOpenGL;
  hardware.opengl.driSupport32Bit = lib.mkDefault true;

  # Plymouth can cause black screens on some GPUs; keep disabled unless requested
  boot.plymouth.enable = lib.mkForce plymouthEnable;

  # Only constrain video drivers when explicitly specified
  services.xserver.videoDrivers = lib.mkIf (driver != null) [ driver ];

  # Some AMD setups need amdgpu in initrd (e.g., luks on root with early kms)
  boot.initrd.kernelModules = lib.mkIf preloadAmdgpu (lib.mkAfter [ "amdgpu" ]);

  # Consolidate blacklist entries to avoid duplicate assignments
  boot.blacklistedKernelModules = lib.mkAfter (
    (lib.optionals blacklistRadeon [ "radeon" ])
    ++ (lib.optionals isNvidia [ "nouveau" ])
  );

  # Collect optional GPU-related kernel params into a single assignment to avoid conflicts
  boot.kernelParams = lib.mkAfter (
    (lib.optionals forceAmdgpu [
      "amdgpu.si_support=1"
      "amdgpu.cik_support=1"
      "radeon.si_support=0"
      "radeon.cik_support=0"
    ])
    ++ (lib.optionals dcDisable [ "amdgpu.dc=0" ])
    ++ (lib.optionals dpmDisable [ "amdgpu.dpm=0" ])
    ++ (lib.optionals isNvidia [ "nvidia_drm.modeset=1" ])
  );

  # Enable NVIDIA proprietary driver integration when selected
  hardware.nvidia = lib.mkIf isNvidia {
    modesetting.enable = nvidiaModeset;
    open = nvidiaOpen;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}


