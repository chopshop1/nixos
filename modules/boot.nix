{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.kernelModules = [ "amdgpu" ];
  
  boot.kernelParams = [
    "quiet"
    "splash"
    "vga=current"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
  ];

  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  boot.plymouth = {
    enable = true;
    theme = "breeze";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
}