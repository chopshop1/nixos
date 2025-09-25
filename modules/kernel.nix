{ lib, userSettings, pkgs, ... }:
let
  kernel = userSettings.kernel or { };
  params = kernel.params or [ ];
  consoleLogLevel = kernel.consoleLogLevel or 4; # 4=warning, 7=debug
  initrdVerbose = kernel.initrdVerbose or false;
  forceTextMode = kernel.forceTextMode or false; # adds nomodeset when true
  showStatus = kernel.showStatus or true; # systemd show_status
  console = kernel.console or null; # e.g. "tty0", "ttyS0,115200n8"
  useLatestKernel = kernel.useLatest or false;
  systemdRescue = kernel.systemdRescue or false;
  systemdDebug = kernel.systemdDebug or false;
  earlySerial = kernel.earlySerial or null; # e.g. "ttyS0,115200n8"
  iommu = kernel.iommu or { };
  iommuMode = iommu.mode or null; # "off" | "soft" | "on" | "pt"
  iommuVendor = iommu.vendor or null; # "amd" | "intel"
  disableEfifb = kernel.disableEfifb or false;
  disableVesafb = kernel.disableVesafb or false;
  pcieAspmOff = kernel.pcieAspmOff or false;
  pciNoAER = kernel.pciNoAER or false;
in {
  # Compose kernel params with an optional text-only fallback
  boot.kernelParams = params
    ++ (lib.optional forceTextMode "nomodeset")
    ++ (lib.optional (console != null) ("console=" + console))
    ++ (lib.optional (earlySerial != null) ("earlyprintk=" + earlySerial))
    ++ (lib.optional systemdRescue "systemd.unit=rescue.target")
    ++ (lib.optional systemdDebug "systemd.log_level=debug")
    ++ (lib.optional systemdDebug "loglevel=7")
    ++ (lib.optional disableEfifb "video=efifb:off")
    ++ (lib.optional disableVesafb "video=vesafb:off")
    ++ (lib.optional pcieAspmOff "pcie_aspm=off")
    ++ (lib.optional pciNoAER "pci=noaer")
    ++ (lib.optionals (iommuMode == "off") (
      [ "iommu=off" ]
      ++ (lib.optional (iommuVendor == "amd") "amd_iommu=off")
      ++ (lib.optional (iommuVendor == "intel") "intel_iommu=off")
    ))
    ++ (lib.optionals (iommuMode == "soft") [ "iommu=soft" ])
    ++ (lib.optionals (iommuMode == "on") (
      [ "iommu=on" ]
      ++ (lib.optional (iommuVendor == "amd") "amd_iommu=on")
      ++ (lib.optional (iommuVendor == "intel") "intel_iommu=on")
    ))
    ++ (lib.optionals (iommuMode == "pt") (
      [ "iommu=pt" ]
      ++ (lib.optional (iommuVendor == "amd") "amd_iommu=on")
      ++ (lib.optional (iommuVendor == "intel") "intel_iommu=on")
    ));

  # Practical defaults for visibility during boot
  boot.consoleLogLevel = consoleLogLevel;
  boot.initrd.verbose = initrdVerbose;

  # Show systemd status messages; helpful when debugging black screens
  boot.initrd.systemd.extraConfig = lib.mkIf showStatus ''
    [Manager]
    ShowStatus=yes
  '';

  # Optionally track the latest kernel for improved GPU support
  boot.kernelPackages = lib.mkIf useLatestKernel pkgs.linuxPackages_latest;
}


