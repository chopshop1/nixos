{ lib, userSettings, ... }:
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

  # Optionally blacklist legacy radeon driver to avoid conflicts
  boot.blacklistedKernelModules = lib.mkIf blacklistRadeon (lib.mkAfter [ "radeon" ]);

  # Toggle to force amdgpu on older Southern/Sea Islands generations
  boot.kernelParams = lib.mkIf forceAmdgpu (
    lib.mkAfter [
      "amdgpu.si_support=1"
      "amdgpu.cik_support=1"
      "radeon.si_support=0"
      "radeon.cik_support=0"
    ]
  );
}


