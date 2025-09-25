{ config, lib, pkgs, ... }:

{
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.blueman.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.fwupd.enable = true;

  powerManagement.enable = true;
  powerManagement.powertop.enable = true;

  services.thermald.enable = true;

  services.upower.enable = true;
}