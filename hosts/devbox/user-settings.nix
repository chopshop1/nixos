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
    # Optionally set systemd-boot console mode: "keep", "0", "1", ...
    # Helps when firmware sets an unsupported graphics mode
    # systemdConsoleMode = "keep";
  };

  virtualization = {
    enableKVM = false; # Set true to load KVM when virtualization is enabled.
    # Optionally pin vendor for correct KVM module: "amd" or "intel".
    kvmVendor = "amd";
  };

  # Optional kernel tuning and visibility during boot
  kernel = {
    params = [ ]; # e.g. "amd_pstate=active" "pci=nomsi"
    consoleLogLevel = 7; # start verbose while diagnosing black screen
    initrdVerbose = true;
    forceTextMode = false; # set true only as last resort
    showStatus = true;
    console = "tty0"; # also try "ttyS0,115200n8" for serial logs
    # useLatest = true; # enable for newest kernel when GPU support is needed
    # Debugging toggles if netlink/systemd stalls persist
    systemdDebug = true;
    systemdRescue = false; # set true to boot into rescue target
    earlySerial = null; # e.g. "ttyS0,115200n8" to capture early logs
    iommu = {
      mode = null; # try "soft" or "pt" if hangs relate to IOMMU
      vendor = "amd";
    };
    disableEfifb = false;
    disableVesafb = true; # often avoids early fb conflicts
    pcieAspmOff = true;   # some boards hang without this
    pciNoAER = true;      # silence AER storms that can look like stalls
  };

  # Graphics configuration; keep conservative defaults to avoid black screens
  graphics = {
    enableOpenGL = true;
    driver = "amdgpu"; # pin driver for AMD
    plymouthEnable = false; # enable if you want a splash screen
    initrd = {
      amdgpu = true; # enable early KMS for AMD (helps avoid blank screen)
    };
    # Additional AMD safety toggles
    # blacklistRadeon = true; # uncomment to ensure radeon is not loaded
    # oldAmd.forceAmdgpu = true; # uncomment for SI/CIK-era GPUs
    amd = {
      dcDisable = false;  # set true if blank screen remains
      dpmDisable = false; # set true if power mgmt causes stalls
    };
  };
}
