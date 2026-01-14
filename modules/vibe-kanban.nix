{ config, lib, pkgs, ... }:

{
  # Ensure bun and gh are available system-wide
  environment.systemPackages = with pkgs; [
    bun
    gh
  ];

  # Systemd service for vibe-kanban
  systemd.services.vibe-kanban = {
    description = "Vibe Kanban Server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    environment = {
      HOST = "0.0.0.0";
      PORT = "5115";
      HOME = "/home/dev";
    };

    path = with pkgs; [
      # Version control
      gh
      git

      # Node/JS
      bun
      nodejs

      # Rust
      cargo
      rustc

      # CLI tools
      coreutils
      bash
      gnused
      gnugrep
      findutils
      curl
      jq
      openssh
    ];

    serviceConfig = {
      Type = "simple";
      User = "dev";
      Group = "users";
      WorkingDirectory = "/home/dev/work";
      ExecStart = "${pkgs.bun}/bin/bunx vibe-kanban";
      Restart = "always";
      RestartSec = "5";
    };
  };

  # Open firewall port for vibe-kanban
  networking.firewall.allowedTCPPorts = [ 5115 ];
}
