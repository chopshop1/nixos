{ config, lib, modulesPath, userSettings, ... }:
let
  get = path: default: lib.attrByPath path default userSettings;
  rootDevice = get [ "root" "device" ] "/dev/disk/by-label/nixos";
  rootFsType = get [ "root" "fsType" ] "ext4";
  rootOptions = get [ "root" "options" ] [ ];
  bootDevice = get [ "boot" "device" ] null;
  bootFsType = get [ "boot" "fsType" ] "vfat";
  bootOptions = get [ "boot" "options" ] [ "fmask=0077" "dmask=0077" ];
  swapConfig = get [ "swap" ] [ ];
  rootFs = {
    device = rootDevice;
    fsType = rootFsType;
  } // lib.optionalAttrs (rootOptions != [ ]) { options = rootOptions; };
  bootFs = lib.optionalAttrs (bootDevice != null) {
    "/boot" = {
      device = bootDevice;
      fsType = bootFsType;
    } // lib.optionalAttrs (bootOptions != [ ]) { options = bootOptions; };
  };
in {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  fileSystems = { "/" = rootFs; } // bootFs;

  swapDevices = swapConfig;

  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";

  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
