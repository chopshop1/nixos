{ lib, ... }: {
  # Placeholder hardware configuration for the legacy path. Replace this file
  # with the generated hardware config from `nixos-generate-config` on the
  # target machine before building.
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS";
    fsType = "ext4";
  };

  swapDevices = [ ];

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault false;
}
