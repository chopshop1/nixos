{ config, lib, pkgs, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PubkeyAuthentication = true;
      X11Forwarding = false;
      PrintMotd = false;
      UsePAM = true;
    };
    ports = [ 22 ];
    openFirewall = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
  };

  # Disabled because GnuPG agent is handling SSH support
  # programs.ssh.startAgent = true;

  environment.systemPackages = with pkgs; [
    openssh
    mosh
  ];
}