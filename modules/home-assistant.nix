{ config, lib, pkgs, ... }:

let
  cfg = config.my.homeAssistant;
in {
  options.my.homeAssistant = {
    enable = lib.mkEnableOption "Home Assistant firewall rules";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = [
        8123   # Home Assistant web UI
        21064  # HomeKit Bridge
      ];
      allowedUDPPorts = [
        5353   # mDNS (HomeKit discovery)
      ];
    };
  };
}
