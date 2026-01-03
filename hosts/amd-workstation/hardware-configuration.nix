# Hardware configuration for AMD Ryzen 9 7950X3D + RX 7900 XTX
# Using same nvme0n1 drive layout as current machine

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Kernel modules - adjust based on actual hardware
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];  # AMD virtualization support
  boot.extraModulePackages = [ ];

  # Filesystem configuration
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/c6fdfd15-a5ad-4c81-ace1-932b2b6edc79";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/EEDA-8B03";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/bbddf905-46bf-4cda-a379-f065b9f382dd"; }
  ];

  # Network interface - will be auto-detected, but typically:
  # networking.interfaces.enp6s0.useDHCP = lib.mkDefault true;  # Ethernet
  # networking.interfaces.wlp5s0.useDHCP = lib.mkDefault true;  # WiFi (if present)

  # Platform and firmware
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # AMD CPU microcode updates (important for Zen 4!)
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Enable all redistributable firmware (AMD GPU firmware, etc.)
  hardware.enableRedistributableFirmware = true;
}
