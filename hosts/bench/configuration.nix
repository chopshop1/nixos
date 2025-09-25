{ config, pkgs, lib, ... }:
{
  # Paste your working /etc/nixos/configuration.nix into
  #   ./reference-configuration.nix
  # Keep its imports as-is (including ./hardware-configuration.nix).
  # This avoids duplicate imports and keeps behavior identical to the host.

  imports = [ ./reference-configuration.nix ];

  # Keep a sane stateVersion; reference config may override if it sets one.
  system.stateVersion = lib.mkDefault "24.05";
}


