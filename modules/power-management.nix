{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.powerManagement;
in
{
  options.my.powerManagement = {
    preventSuspend = mkOption {
      type = types.bool;
      default = true;
      description = "Prevent system from suspending (useful for SSH availability)";
    };

    enableWakeOnLan = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Wake-on-LAN for ethernet interfaces";
    };

    keepWifiAlive = mkOption {
      type = types.bool;
      default = true;
      description = "Keep WiFi connection alive and prevent power saving";
    };

    preferEthernet = mkOption {
      type = types.bool;
      default = true;
      description = "Prioritize ethernet connections over WiFi";
    };
  };

  config = mkMerge [
    (mkIf cfg.preventSuspend {
      # Prevent system from sleeping to maintain SSH availability
      services.logind.settings = {
        Login = {
          HandleSuspendKey = "ignore";
          HandleHibernateKey = "ignore";
          HandleLidSwitch = "ignore";
          HandleLidSwitchDocked = "ignore";
          HandleLidSwitchExternalPower = "ignore";
          IdleAction = "ignore";
          IdleActionSec = "0";
          UserStopDelaySec = "0";
        };
      };

      # Disable automatic suspend completely
      systemd.targets.sleep.enable = false;
      systemd.targets.suspend.enable = false;
      systemd.targets.hibernate.enable = false;
      systemd.targets.hybrid-sleep.enable = false;

      # Mask suspend/sleep services
      systemd.services."systemd-suspend".enable = false;
      systemd.services."systemd-hibernate".enable = false;
      systemd.services."systemd-hybrid-sleep".enable = false;

      # Completely disable power management
      powerManagement.enable = false;
    })

    (mkIf cfg.enableWakeOnLan {
      environment.systemPackages = [ pkgs.ethtool ];

      # Enable Wake-on-LAN for ethernet interfaces
      systemd.services.wake-on-lan = {
        description = "Enable Wake-on-LAN for ethernet interfaces";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = ''
            ${pkgs.bash}/bin/bash -c '
              for iface in $(ls /sys/class/net | grep -E "^(en|eth)"); do
                ${pkgs.ethtool}/bin/ethtool -s $iface wol g 2>/dev/null || true
              done
            '
          '';
        };
      };

      # Re-enable Wake-on-LAN after suspend/resume
      powerManagement.powerUpCommands = ''
        for iface in $(ls /sys/class/net | grep -E "^(en|eth)"); do
          ${pkgs.ethtool}/bin/ethtool -s $iface wol g 2>/dev/null || true
        done
      '';
    })

    (mkIf cfg.keepWifiAlive {
      # Keep WiFi connection alive
      networking.networkmanager.wifi.powersave = false;

      # Ensure NetworkManager doesn't put WiFi to sleep
      networking.networkmanager.settings = {
        connection = {
          "wifi.powersave" = 2;
        };
        device = {
          "wifi.scan-rand-mac-address" = "no";
        };
      };
    })

    (mkIf cfg.preferEthernet {
      # Prioritize ethernet over WiFi by setting route metrics
      # Lower metric = higher priority (ethernet: 100, WiFi: 600)
      networking.networkmanager.settings = {
        "connection-ethernet" = {
          "match-device" = "type:ethernet";
          "ipv4.route-metric" = 100;
          "ipv6.route-metric" = 100;
        };
        "connection-wifi" = {
          "match-device" = "type:wifi";
          "ipv4.route-metric" = 600;
          "ipv6.route-metric" = 600;
        };
      };
    })
  ];
}