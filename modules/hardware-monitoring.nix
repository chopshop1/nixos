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
      description = "Enable automatic fan control based on CPU temperature";
    };

    fanControl.minTemp = mkOption {
      type = types.int;
      default = 45;
      description = "Temperature (°C) below which fans run at minimum speed";
    };

    fanControl.maxTemp = mkOption {
      type = types.int;
      default = 75;
      description = "Temperature (°C) at which fans run at full speed";
    };

    fanControl.minPwm = mkOption {
      type = types.int;
      default = 80;
      description = "Minimum PWM value (0-255) — fans never go below this";
    };

    fanControl.interval = mkOption {
      type = types.int;
      default = 3;
      description = "Polling interval in seconds";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # --- Sensor monitoring (lm_sensors) ---
    (mkIf cfg.sensors.enable {
      # NCT6687D driver for MSI X870 boards (out-of-tree, writable PWM)
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

    # --- Automatic fan control via nct6687d PWM ---
    (mkIf cfg.fanControl.enable {
      systemd.services.fan-control = {
        description = "CPU temperature-based fan control via nct6687d";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-modules-load.service" ];
        serviceConfig = {
          Type = "simple";
          Restart = "on-failure";
          RestartSec = 5;
        };
        path = [ pkgs.coreutils ];
        script = let
          minTemp = cfg.fanControl.minTemp;
          maxTemp = cfg.fanControl.maxTemp;
          minPwm = cfg.fanControl.minPwm;
          interval = cfg.fanControl.interval;
        in ''
          # Find the nct6687 hwmon device (path-stable lookup by name)
          NCT_HWMON=""
          for h in /sys/class/hwmon/hwmon*; do
            if [ "$(cat "$h/name" 2>/dev/null)" = "nct6687" ]; then
              NCT_HWMON="$h"
              break
            fi
          done

          if [ -z "$NCT_HWMON" ]; then
            echo "ERROR: nct6687 hwmon device not found. Is the nct6687d module loaded?"
            exit 1
          fi

          echo "Using hwmon device: $NCT_HWMON"

          # Find available PWM channels and enable manual control
          PWMS=""
          for p in "$NCT_HWMON"/pwm[0-9]*; do
            [ -f "$p" ] || continue
            # Skip _enable/_mode/etc files
            case "$p" in *_*) continue ;; esac
            enable_file="''${p}_enable"
            if [ -f "$enable_file" ]; then
              echo 1 > "$enable_file" 2>/dev/null  # 1 = manual control
            fi
            PWMS="$PWMS $p"
          done

          echo "Controlling PWM channels:$PWMS"

          # Find k10temp for CPU temperature
          K10_HWMON=""
          for h in /sys/class/hwmon/hwmon*; do
            if [ "$(cat "$h/name" 2>/dev/null)" = "k10temp" ]; then
              K10_HWMON="$h"
              break
            fi
          done

          if [ -z "$K10_HWMON" ]; then
            echo "ERROR: k10temp hwmon device not found"
            exit 1
          fi

          echo "Reading CPU temp from: $K10_HWMON/temp1_input (Tctl)"

          cleanup() {
            echo "Restoring automatic fan control..."
            for p in $PWMS; do
              enable_file="''${p}_enable"
              [ -f "$enable_file" ] && echo 0 > "$enable_file" 2>/dev/null
            done
            exit 0
          }
          trap cleanup EXIT INT TERM

          MIN_TEMP=${toString minTemp}
          MAX_TEMP=${toString maxTemp}
          MIN_PWM=${toString minPwm}
          MAX_PWM=255
          RANGE_TEMP=$((MAX_TEMP - MIN_TEMP))
          RANGE_PWM=$((MAX_PWM - MIN_PWM))

          while true; do
            # Read Tctl (millidegrees)
            temp_raw=$(cat "$K10_HWMON/temp1_input" 2>/dev/null)
            temp=$((temp_raw / 1000))

            if [ "$temp" -le "$MIN_TEMP" ]; then
              pwm=$MIN_PWM
            elif [ "$temp" -ge "$MAX_TEMP" ]; then
              pwm=$MAX_PWM
            else
              pwm=$(( MIN_PWM + (temp - MIN_TEMP) * RANGE_PWM / RANGE_TEMP ))
            fi

            for p in $PWMS; do
              echo "$pwm" > "$p" 2>/dev/null
            done

            sleep ${toString interval}
          done
        '';
      };
    })
  ]);
}
