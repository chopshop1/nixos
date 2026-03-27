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

      # Enable Wake-on-LAN and tune ethernet NICs (disable EEE + offloads for r8169 stability)
      systemd.services.wake-on-lan = {
        description = "Enable Wake-on-LAN and tune ethernet NICs";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "enable-wol" ''
            for iface in $(ls /sys/class/net | grep -E "^(en|eth)"); do
              ${pkgs.ethtool}/bin/ethtool -s "$iface" wol g 2>/dev/null || true
              ${pkgs.ethtool}/bin/ethtool --set-eee "$iface" eee off 2>/dev/null || true
              ${pkgs.ethtool}/bin/ethtool -K "$iface" tso off gso off gro off 2>/dev/null || true
            done
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

      environment.systemPackages = [ pkgs.iw ];

      # Disable WiFi power save at driver level (NM settings alone aren't enough)
      systemd.services.wifi-power-save-off = {
        description = "Disable WiFi power save at driver level";
        wantedBy = [ "multi-user.target" ];
        after = [ "NetworkManager-wait-online.target" ];
        wants = [ "NetworkManager-wait-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "wifi-power-save-off" ''
            for iface in $(${pkgs.iw}/bin/iw dev | ${pkgs.gawk}/bin/awk '/Interface/{print $2}'); do
              ${pkgs.iw}/bin/iw dev "$iface" set power_save off 2>/dev/null || true
            done
          '';
        };
      };
    })

    (mkIf cfg.preferEthernet {
      # Disable WiFi when ethernet is connected (and re-enable when unplugged)
      # Two interfaces on the same subnet + Docker's ip_forward=1 causes
      # routing confusion and 85-100% packet loss
      networking.networkmanager.dispatcherScripts = [
        {
          type = "basic";
          source = pkgs.writeShellScript "wifi-toggle-on-ethernet" ''
            IFACE="$1"
            ACTION="$2"

            # Only act on ethernet events
            case "$IFACE" in
              en*|eth*) ;;
              *) exit 0 ;;
            esac

            case "$ACTION" in
              up)
                ${pkgs.networkmanager}/bin/nmcli radio wifi off
                logger "nm-dispatcher: ethernet $IFACE up, WiFi disabled"
                ;;
              down)
                ${pkgs.networkmanager}/bin/nmcli radio wifi on
                logger "nm-dispatcher: ethernet $IFACE down, WiFi re-enabled"
                ;;
            esac
          '';
        }
      ];
    })
  ];
}