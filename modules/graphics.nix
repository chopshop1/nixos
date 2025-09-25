{ lib, userSettings, ... }:
let
  gfx = userSettings.graphics or { };
  enableOpenGL = gfx.enableOpenGL or true;
  driver = gfx.driver or null; # e.g. "amdgpu" | "intel" | "nvidia"
  initrd = gfx.initrd or { };
  preloadAmdgpu = initrd.amdgpu or false;
  plymouthEnable = gfx.plymouthEnable or false; # default off to avoid black screens
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
}


