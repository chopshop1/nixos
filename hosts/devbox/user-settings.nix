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

  virtualization = {
    enableKVM = false; # Set true to load KVM when virtualization is enabled.
    # Optionally pin vendor for correct KVM module: "amd" or "intel".
    kvmVendor = "amd";
  };

  # Optional kernel tuning and visibility during boot
  kernel = {
    params = [ ]; # e.g. "amd_pstate=active" "pci=nomsi"
    consoleLogLevel = 4; # 4=warning, 7=debug
    initrdVerbose = false;
    forceTextMode = false; # adds nomodeset
  };

  # Graphics configuration; keep conservative defaults to avoid black screens
  graphics = {
    enableOpenGL = true;
    driver = null; # set to "amdgpu" for AMD, or leave null for auto
    plymouthEnable = false; # enable if you want a splash screen
    initrd = {
      amdgpu = false; # set true if using early KMS or encrypted root
    };
  };
}
