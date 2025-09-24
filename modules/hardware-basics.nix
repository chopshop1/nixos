# Generic storage configuration driven by user settings.
{ lib, userSettings, config, ... }:
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
  fileSystems = { "/" = rootFs; } // bootFs;
  swapDevices = swapConfig;
}
