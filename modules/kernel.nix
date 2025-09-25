{ lib, userSettings, ... }:
let
  kernel = userSettings.kernel or { };
  params = kernel.params or [ ];
  consoleLogLevel = kernel.consoleLogLevel or 4; # 4=warning, 7=debug
  initrdVerbose = kernel.initrdVerbose or false;
  forceTextMode = kernel.forceTextMode or false; # adds nomodeset when true
in {
  # Compose kernel params with an optional text-only fallback
  boot.kernelParams = params ++ (lib.optional forceTextMode "nomodeset");

  # Practical defaults for visibility during boot
  boot.consoleLogLevel = consoleLogLevel;
  boot.initrd.verbose = initrdVerbose;
}


