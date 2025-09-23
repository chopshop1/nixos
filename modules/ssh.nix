# OpenSSH server configuration with hardened defaults.
{ lib, userSettings, ... }:
let
  sshKey = userSettings.sshAuthorizedKey or null;
  hasKey = sshKey != null && sshKey != "";
in {
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = !hasKey;
      KbdInteractiveAuthentication = !hasKey;
      ChallengeResponseAuthentication = false;
      X11Forwarding = false;
      AllowTcpForwarding = true;
    };
  };

  networking.firewall.allowedTCPPorts = lib.mkDefault [ 22 ];
}
