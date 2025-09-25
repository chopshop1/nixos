{ config, lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 8080 3000 5000 ];
    allowedUDPPorts = [ ];
  };

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
    extraConfig = ''
      DNSOverTLS=yes
    '';
  };

  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  services.avahi = {
    enable = true;
    nssmdns = true;
    openFirewall = true;
  };

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}