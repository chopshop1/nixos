{ config, lib, modulesPath, userSettings, ... }:
let
  virt = userSettings.virtualization or { };
  enableKvm = virt.enableKVM or false;
  kvmVendor = virt.kvmVendor or null; # "amd" | "intel" | null
in {
  # Keep generic kernel hints from the installer for broad hardware support
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Prefer redistributable firmware so GPUs/Wi-Fi work out of the box
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # Enable microcode for both vendors; the non-applicable one is a no-op
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Append the right KVM module based on vendor when explicitly requested
  boot.kernelModules = lib.mkMerge [
    (lib.mkIf (enableKvm && kvmVendor == "amd") (lib.mkAfter [ "kvm-amd" ]))
    (lib.mkIf (enableKvm && kvmVendor == "intel") (lib.mkAfter [ "kvm-intel" ]))
  ];
}


