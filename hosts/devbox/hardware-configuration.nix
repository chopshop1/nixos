{ config, lib, modulesPath, ... }: {
  imports =
    [ ../../modules/hardware-basics.nix ../../modules/hardware-amd.nix ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
