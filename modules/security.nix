# Minimal security hardening and sudo policy.
{ lib, userSettings, ... }:
let
  sshKey = userSettings.sshAuthorizedKey or null;
  hasKey = sshKey != null && sshKey != "";
in {
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  users.mutableUsers = lib.mkDefault (!hasKey);

  services.openssh.settings.MaxAuthTries = 3;
}
