{ lib, pkgs, userSettings, nvchadSrc, ... }:
{
  imports = [
    ../../modules/base.nix
    ../../modules/users.nix
    ../../modules/networking.nix
    ../../modules/security.nix
    ../../modules/ssh.nix
    ../../modules/docker.nix
    ../../modules/editor.nix
    ../../modules/boot.nix
  ];

  boot.isContainer = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;

  fileSystems."/" = {
    device = "rootfs";
    fsType = "rootfs";
  };

  swapDevices = [ ];

  virtualisation.docker.enable = lib.mkForce false;
  virtualisation.docker.rootless.enable = lib.mkForce false;

  networking.hostName = userSettings.hostname or "devbox";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  system.stateVersion = "24.05";
}
