{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.kernelParams = [
    "quiet"
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
}