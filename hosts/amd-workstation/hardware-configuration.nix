# Hardware configuration for AMD Ryzen 9 7950X3D + RX 7900 XTX
#
# IMPORTANT: This is a template! Generate the actual config by running:
#   sudo nixos-generate-config --show-hardware-config > hosts/amd-workstation/hardware-configuration.nix
#
# Or copy the auto-generated /etc/nixos/hardware-configuration.nix after installing NixOS

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

  # Filesystem configuration - UPDATE THESE UUIDs after installation!
  # Run `blkid` to get your actual UUIDs
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-ROOT-UUID";
    fsType = "ext4";  # or "btrfs" if you prefer
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-BOOT-UUID";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [
    # Uncomment and set if you have a swap partition:
    # { device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-SWAP-UUID"; }
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
