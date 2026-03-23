{ config, lib, pkgs, ... }:

{
  # Disable NetworkManager-wait-online service completely
  # This service causes harmless but annoying timeout errors during nixos-rebuild switch

  # Method 1: Disable the service
  systemd.services."NetworkManager-wait-online".enable = lib.mkForce false;

  # Method 2: Remove it from all targets
  systemd.services."NetworkManager-wait-online".wantedBy = lib.mkForce [ ];

  # Method 3: Override the entire service definition
  systemd.services."NetworkManager-wait-online" = lib.mkForce {
    enable = false;
  };
}