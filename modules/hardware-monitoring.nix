{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.hardwareMonitoring;
in
{
  options.my.hardwareMonitoring = {
    enable = mkEnableOption "hardware monitoring, fan control, and RGB";

    sensors.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable lm_sensors for temperature/fan monitoring";
    };

    rgb.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable OpenRGB for RGB control (motherboard headers, RAM, etc.)";
    };

    rgb.disableOnBoot = mkOption {
      type = types.bool;
      default = false;
      description = "Turn off all RGB on boot via OpenRGB";
    };

    fanControl.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable fancontrol daemon (requires running pwmconfig first)";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # --- Sensor monitoring (lm_sensors) ---
    (mkIf cfg.sensors.enable {
      # NCT6687D driver for MSI X870 boards (out-of-tree kernel module)
      boot.extraModulePackages = with config.boot.kernelPackages; [
        nct6687d
      ];
      boot.kernelModules = [ "nct6687d" ];

      environment.systemPackages = with pkgs; [
        lm_sensors
        i2c-tools  # SMBus access for RAM sensors + RGB
      ];
    })

    # --- RGB control (OpenRGB) ---
    (mkIf cfg.rgb.enable {
      # OpenRGB udev rules + daemon
      services.hardware.openrgb = {
        enable = true;
        motherboard = "amd";
      };

      environment.systemPackages = with pkgs; [
        openrgb-with-all-plugins
      ];

      # I2C/SMBus access required for RAM RGB and some mobo controllers
      hardware.i2c.enable = true;

      # Add user to i2c group for non-root RGB control
      users.users.dev.extraGroups = [ "i2c" ];

      # Turn off all RGB at boot
      systemd.services.openrgb-off = mkIf cfg.rgb.disableOnBoot {
        description = "Turn off all RGB lighting";
        wantedBy = [ "multi-user.target" ];
        after = [ "openrgb.service" ];
        wants = [ "openrgb.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.openrgb-with-all-plugins}/bin/openrgb --mode off";
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";  # Wait for OpenRGB server to be ready
        };
      };
    })

    # --- Fan control daemon (optional, needs pwmconfig setup first) ---
    (mkIf cfg.fanControl.enable {
      hardware.fancontrol.enable = true;
      # After first boot with sensors enabled, run as root:
      #   sudo sensors-detect
      #   sudo pwmconfig
      # Then copy the generated config:
      #   hardware.fancontrol.config = builtins.readFile /etc/fancontrol;
    })
  ]);
}
