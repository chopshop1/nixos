{
  # Override these defaults as needed for your environment.
  hostname = "devbox";
  username = "devuser";
  timezone = "UTC";
  # Replace with your SSH public key before first deploy.
  sshAuthorizedKey = null;

  # Disk mapping used by hardware-configuration.nix. Update the device paths
  # (or labels/UUIDs) to match the target machine. To skip mounting /boot, set
  # boot.device = null.
  root = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [ ];
  };

  boot = {
    device =
      null; # Set to e.g. /dev/disk/by-label/EFI when using a separate EFI partition.
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swap = [ ];

  bootLoader = {
    type = null; # Set to "systemd-boot" or "grub" for your setup.
    device =
      null; # Required when type = "grub" (e.g. /dev/sda or /dev/nvme0n1).
    efiSupport = false;
    useOSProber = false;
  };
}
