{ config, lib, modulesPath, ... }:
{
  # Replace this file with the hardware-configuration.nix from the working machine
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}


