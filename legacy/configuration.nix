{ config, pkgs, lib, ... }:
let
  userSettings = import ../hosts/devbox/user-settings.nix;

  homeManagerTarball = builtins.fetchTarball {
    url =
      "https://github.com/nix-community/home-manager/archive/refs/tags/release-24.05.tar.gz";
    sha256 = "sha256-Vl+WVTJwutXkimwGprnEtXc/s/s8sMuXzqXaspIGlwM=";
  };

  homeManagerModule = import "${homeManagerTarball}/nixos";

  nvchadSrc = builtins.fetchTarball {
    url =
      "https://github.com/NvChad/NvChad/archive/f107fabe11ac8013dc3435ecd5382bee872b1584.tar.gz";
    sha256 = "sha256-wtJ46PEwLTZ4mpUfRZ/+D1S1soflKbbYU3y2cIPjXXk=";
  };
in {
  imports = [
    ./hardware-configuration.nix
    ../modules/base.nix
    ../modules/users.nix
    ../modules/networking.nix
    ../modules/security.nix
    ../modules/ssh.nix
    ../modules/docker.nix
    ../modules/editor.nix
    homeManagerModule
  ];

  _module.args = { inherit userSettings nvchadSrc; };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  system.stateVersion = "24.05";
}
