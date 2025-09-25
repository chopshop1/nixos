{ config, lib, pkgs, ... }:

{
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = true;

  security.polkit.enable = true;

  security.apparmor.enable = true;

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.1"
      "192.168.0.0/16"
      "10.0.0.0/8"
    ];
  };

  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
  };

  security.pam.services = {
    login.enableGnomeKeyring = true;
    gdm.enableGnomeKeyring = true;
  };

  programs.firejail.enable = true;

  boot.kernel.sysctl = {
    "kernel.unprivileged_userns_clone" = 1;
    "net.ipv4.ip_forward" = 1;
  };
}