{ config, lib, modulesPath, ... }: {
  imports = [
    ../../modules/hardware-basics.nix
    ../../modules/hardware-cpu.nix
    # Keep vendor-specific helpers optional; prefer generic modules above
    # ../../modules/hardware-amd.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
