{ config, pkgs, lib, ... }:
{
  # Drop-in adapter so you can paste a working /etc/nixos configuration.
  # Replace the two imports below with your copies from the test bench:
  # - ./hardware-configuration.nix
  # - ./reference-configuration.nix

  imports = [
    ./hardware-configuration.nix
    ./reference-configuration.nix
  ];

  # Keep a sane stateVersion; adjust if your reference requires older semantics
  system.stateVersion = lib.mkDefault "24.05";
}


