{ config, lib, pkgs, ... }:

# Lightweight resource monitor for crash diagnostics.
# Logs system stats every 5 minutes to journald so we can see
# what was happening before a silent lockup.
# Check with: journalctl -u crash-monitor --since "1 hour ago"

let
  monitorScript = pkgs.writeShellScript "crash-monitor" ''
    echo "=== System Resource Snapshot ==="
    echo "MEMORY:"
    ${pkgs.procps}/bin/free -h
    echo ""
    echo "SWAP/ZRAM:"
    ${pkgs.coreutils}/bin/cat /proc/swaps
    echo ""
    echo "LOAD:"
    ${pkgs.coreutils}/bin/cat /proc/loadavg
    echo ""
    echo "TOP MEMORY CONSUMERS:"
    ${pkgs.procps}/bin/ps aux --sort=-%mem | head -6
    echo ""
    echo "DOCKER:"
    ${pkgs.docker}/bin/docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "docker unavailable"
    echo ""
    echo "TEMPERATURES:"
    ${pkgs.lm_sensors}/bin/sensors 2>/dev/null || echo "sensors unavailable"
  '';
in {
  systemd.services.crash-monitor = {
    description = "Periodic system resource snapshot for crash diagnostics";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = monitorScript;
    };
  };

  systemd.timers.crash-monitor = {
    description = "Run crash-monitor every 5 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
      AccuracySec = "30s";
    };
  };
}
