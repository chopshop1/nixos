{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.opensnitch;
in
{
  options.my.opensnitch = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable OpenSnitch application firewall";
    };
  };

  config = mkIf cfg.enable {
    services.opensnitch = {
      enable = true;
      settings = {
        DefaultAction = "deny";
        ProcMonitorMethod = "ebpf";
        Firewall = "nftables";
        LogLevel = 1;
      };
    };

    environment.systemPackages = with pkgs; [
      opensnitch-ui
    ];
  };
}
