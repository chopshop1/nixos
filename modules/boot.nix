# Boot loader configuration driven by user settings.
{ lib, userSettings, ... }:
let
  bootLoader = userSettings.bootLoader or { };
  loaderType = bootLoader.type or "grub";
  grubDevice = bootLoader.device or "/dev/sda";
  grubUseEFI = bootLoader.efiSupport or false;
  grubUseOSProber = bootLoader.useOSProber or false;
  grubEnableCryptodisk = bootLoader.enableCryptodisk or false;
  grubSplashImage = bootLoader.splashImage or null;
  base = {
    boot.loader.systemd-boot.enable = lib.mkDefault false;
    boot.loader.efi.canTouchEfiVariables = lib.mkDefault false;
    boot.loader.grub.enable = lib.mkDefault false;
  };
  systemdBootCfg = lib.mkIf (loaderType == "systemd-boot") {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables =
      bootLoader.efiCanTouchEfiVariables or true;
    boot.loader.grub.enable = lib.mkForce false;
  };
  grubCfg = lib.mkIf (loaderType == "grub") {
    boot.loader.grub = {
      enable = true;
      device = grubDevice;
      efiSupport = grubUseEFI;
      useOSProber = grubUseOSProber;
      enableCryptodisk = grubEnableCryptodisk;
    } // lib.optionalAttrs (grubSplashImage != null) {
      splashImage = grubSplashImage;
    };

    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = lib.mkForce grubUseEFI;
  };
  noneCfg = lib.mkIf (loaderType == "none") {
    boot.loader.grub.enable = lib.mkForce false;
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  };
in lib.mkMerge [ base systemdBootCfg grubCfg noneCfg ]
