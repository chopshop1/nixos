{ lib, userSettings, pkgs, ... }:
let
  kernel = userSettings.kernel or { };
  params = kernel.params or [ ];
  consoleLogLevel = kernel.consoleLogLevel or 4; # 4=warning, 7=debug
  initrdVerbose = kernel.initrdVerbose or false;
  forceTextMode = kernel.forceTextMode or false; # adds nomodeset when true
  showStatus = kernel.showStatus or true; # systemd show_status
  console = kernel.console or null; # e.g. "tty0", "ttyS0,115200n8"
  useLatestKernel = kernel.useLatest or false;
in {
  # Compose kernel params with an optional text-only fallback
  boot.kernelParams = params
    ++ (lib.optional forceTextMode "nomodeset")
    ++ (lib.optional (console != null) ("console=" + console));

  # Practical defaults for visibility during boot
  boot.consoleLogLevel = consoleLogLevel;
  boot.initrd.verbose = initrdVerbose;

  # Show systemd status messages; helpful when debugging black screens
  boot.initrd.systemd.extraConfig = lib.mkIf showStatus ''
    [Manager]
    ShowStatus=yes
  '';

  # Optionally track the latest kernel for improved GPU support
  boot.kernelPackages = lib.mkIf useLatestKernel pkgs.linuxPackages_latest;
}


