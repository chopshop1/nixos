{ config, pkgs, lib, userSettings, nvchadSrc, ... }:
let username = userSettings.username or "devuser";
in {
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/users.nix
    ../../modules/networking.nix
    ../../modules/security.nix
    ../../modules/ssh.nix
    ../../modules/docker.nix
    ../../modules/editor.nix
    ../../modules/boot.nix
  ];

  # Ensure Home Manager uses the same package set for consistency.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  # Host-wide defaults not covered by modules.
  services.openssh.openFirewall = true;

  users.users.${username}.packages = with pkgs; [ ];

  system.stateVersion = "24.05";
}
