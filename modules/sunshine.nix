{ config, lib, pkgs, ... }:

{
  # Enable Sunshine game streaming server
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;  # Required for KMS capture
    openFirewall = true;  # Opens ports 47984-47990 TCP and 47998-48000 UDP
  };

  # Enable Avahi for network discovery (helps Moonlight find the host)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # Additional packages for Sunshine functionality
  environment.systemPackages = with pkgs; [
    sunshine  # CLI access if needed
  ];

  # Ensure the dev user is in the input group for capture
  users.users.dev.extraGroups = [ "input" ];
}
