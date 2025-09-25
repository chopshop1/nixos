# Boot loader configuration driven by user settings.
{ lib, config, userSettings, ... }:
let
  bootLoader = userSettings.bootLoader or { };
  hasBootFs = config.fileSystems ? "/boot";
  defaultType = if hasBootFs then "systemd-boot" else null;
  loaderType = bootLoader.type or defaultType;
  grubDevice = bootLoader.device or null;
  grubDevices = bootLoader.devices or null; # list of disks for GRUB install
  grubMirroredBoots = bootLoader.mirroredBoots or [ ];
  grubUseEFI = bootLoader.efiSupport or false;
  grubUseOSProber = bootLoader.useOSProber or false;
  grubEnableCryptodisk = bootLoader.enableCryptodisk or false;
  grubSplashImage = bootLoader.splashImage or null;
  sysdConsoleMode = bootLoader.systemdConsoleMode or null; # e.g. "keep", "0", "1"
  systemdBootCfg = lib.mkIf (loaderType == "systemd-boot") {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables =
      bootLoader.efiCanTouchEfiVariables or true;
    boot.loader.grub.enable = lib.mkForce false;
    # Configure consoleMode when provided, useful for blank/overscanned screens
    boot.loader.systemd-boot.consoleMode = lib.mkIf (sysdConsoleMode != null) sysdConsoleMode;
  };
  grubCfg = lib.mkIf (loaderType == "grub") {
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = lib.mkForce grubUseEFI;
    boot.loader.grub = {
      enable = true;
      # device is used for single-disk installs; "nodev" for UEFI-only
      # devices is the newer multi-disk interface; mirroredBoots for complex setups
      device = lib.mkIf (grubDevice != null) grubDevice;
      devices = lib.mkIf (grubDevices != null) grubDevices;
      mirroredBoots = lib.mkIf (grubMirroredBoots != [ ]) grubMirroredBoots;
      efiSupport = grubUseEFI;
      useOSProber = grubUseOSProber;
      enableCryptodisk = grubEnableCryptodisk;
    } // lib.optionalAttrs (grubSplashImage != null) {
      splashImage = grubSplashImage;
    };
  };
  noneCfg = lib.mkIf (loaderType == "none" || loaderType == null) {
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
    boot.loader.grub.enable = lib.mkForce false;
  };
  assertionCfg = lib.mkIf (loaderType == "grub" && grubDevice == null && grubDevices == null && grubMirroredBoots == [ ]) {
    assertions = [{
      assertion = false;
      message =
        ''Set one of `bootLoader.device` (e.g. "/dev/nvme0n1" or "nodev" for UEFI-only), `bootLoader.devices` (list of disks), or `bootLoader.mirroredBoots` when bootLoader.type = "grub".'';
    }];
  };
in lib.mkMerge [ assertionCfg noneCfg systemdBootCfg grubCfg ]
