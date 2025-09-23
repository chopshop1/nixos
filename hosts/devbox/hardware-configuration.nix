{ lib, ... }: {
  # Placeholder hardware configuration. Replace with the generated version from
  # `nixos-generate-config --hardware-config-file hosts/devbox/hardware-configuration.nix`
  # on the target machine. Values below are safe defaults that allow evaluation
  # but will not boot real hardware without adjustment.
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS";
    fsType = "ext4";
  };

  swapDevices = [ ];

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault false;
}
