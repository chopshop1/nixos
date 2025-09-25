{ config, lib, pkgs, ... }:

{
  hardware.cpu.amd.updateMicrocode = true;
  
  boot.kernelModules = [ "kvm-amd" ];
  
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      amdvlk
      rocm-opencl-icd
      rocm-opencl-runtime
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };

  environment.variables.AMD_VULKAN_ICD = "RADV";

  services.xserver.videoDrivers = [ "amdgpu" ];
}