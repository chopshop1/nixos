{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.streaming;
in {
  options.my.streaming = {
    enable = mkEnableOption "streaming optimizations for Moonlight/Sunshine";

    interface = mkOption {
      type = types.str;
      default = "enp13s0";
      description = "Primary ethernet interface for streaming";
    };

    # Bitrate in Mbps
    maxBitrate = mkOption {
      type = types.int;
      default = 100;
      description = "Maximum bitrate for streaming in Mbps (50-150 recommended for 1080p120)";
    };
  };

  config = mkIf cfg.enable {
    # ===========================================
    # KERNEL NETWORK OPTIMIZATIONS
    # ===========================================
    boot.kernel.sysctl = {
      # Increase UDP buffer sizes (critical for video streaming)
      "net.core.rmem_max" = 67108864;          # 64MB max receive buffer
      "net.core.wmem_max" = 67108864;          # 64MB max send buffer
      "net.core.rmem_default" = 16777216;      # 16MB default receive
      "net.core.wmem_default" = 16777216;      # 16MB default send

      # UDP-specific buffers
      "net.ipv4.udp_rmem_min" = 16384;
      "net.ipv4.udp_wmem_min" = 16384;

      # TCP buffers (for control channel)
      "net.ipv4.tcp_rmem" = "4096 87380 67108864";
      "net.ipv4.tcp_wmem" = "4096 65536 67108864";

      # Increase network queue depth
      "net.core.netdev_max_backlog" = 30000;
      "net.core.netdev_budget" = 600;
      "net.core.netdev_budget_usecs" = 6000;

      # Reduce latency - disable delayed ACKs for faster response
      "net.ipv4.tcp_low_latency" = 1;

      # Enable TCP BBR congestion control (better for streaming)
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";

      # Fast TCP connection reuse
      "net.ipv4.tcp_tw_reuse" = 1;
      "net.ipv4.tcp_fin_timeout" = 15;

      # Increase connection tracking for multiple streams
      "net.netfilter.nf_conntrack_max" = 262144;

      # Disable TCP slow start after idle (maintains speed)
      "net.ipv4.tcp_slow_start_after_idle" = 0;

      # Increase somaxconn for more pending connections
      "net.core.somaxconn" = 8192;

      # Enable TCP fast open for lower latency
      "net.ipv4.tcp_fastopen" = 3;
    };

    # Load BBR module
    boot.kernelModules = [ "tcp_bbr" ];

    # ===========================================
    # NETWORK INTERFACE TUNING
    # ===========================================
    # Tune ethernet interface for low latency on boot
    systemd.services.streaming-network-tuning = {
      description = "Tune network interface for low-latency streaming";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "tune-streaming-network" ''
          IFACE="${cfg.interface}"

          # Check if interface exists
          if [ ! -d "/sys/class/net/$IFACE" ]; then
            echo "Interface $IFACE not found, skipping tuning"
            exit 0
          fi

          # Increase ring buffer sizes if supported
          ${pkgs.ethtool}/bin/ethtool -G "$IFACE" rx 4096 tx 4096 2>/dev/null || true

          # Disable generic receive offload for lower latency
          # (GRO can batch packets causing micro-stutters)
          ${pkgs.ethtool}/bin/ethtool -K "$IFACE" gro off 2>/dev/null || true

          # Keep TSO/GSO on for better throughput on send side
          ${pkgs.ethtool}/bin/ethtool -K "$IFACE" tso on gso on 2>/dev/null || true

          # Set interrupt coalescing for lower latency (if supported)
          ${pkgs.ethtool}/bin/ethtool -C "$IFACE" rx-usecs 10 tx-usecs 10 2>/dev/null || true

          # Increase txqueuelen for better buffering
          ${pkgs.iproute2}/bin/ip link set "$IFACE" txqueuelen 10000 2>/dev/null || true

          echo "Streaming network tuning applied to $IFACE"
        '';
      };
    };

    # ===========================================
    # SUNSHINE - NO ENCODER OVERRIDES
    # ===========================================
    # Let Sunshine use defaults, control quality via Moonlight client
    # Encoder settings removed to avoid pixelation issues

    # ===========================================
    # CPU GOVERNOR FOR CONSISTENT PERFORMANCE
    # ===========================================
    powerManagement.cpuFreqGovernor = mkDefault "performance";

    # ===========================================
    # QOS - PRIORITIZE STREAMING TRAFFIC
    # ===========================================
    # Use traffic control to prioritize Sunshine ports
    systemd.services.streaming-qos = {
      description = "Set up QoS for streaming traffic";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "setup-streaming-qos" ''
          IFACE="${cfg.interface}"

          if [ ! -d "/sys/class/net/$IFACE" ]; then
            exit 0
          fi

          # Remove existing qdisc
          ${pkgs.iproute2}/bin/tc qdisc del dev "$IFACE" root 2>/dev/null || true

          # Set up fq_codel with flow queuing (good for mixed traffic)
          ${pkgs.iproute2}/bin/tc qdisc add dev "$IFACE" root fq_codel target 5ms interval 100ms quantum 1514 limit 10240 flows 1024

          echo "QoS configured for streaming on $IFACE"
        '';
      };
    };

    # ===========================================
    # ADDITIONAL PACKAGES
    # ===========================================
    environment.systemPackages = with pkgs; [
      ethtool      # Network interface tuning
      iperf3       # Network performance testing
      nethogs      # Per-process network monitoring
      bandwhich    # Bandwidth utilization tool
    ];
  };
}
