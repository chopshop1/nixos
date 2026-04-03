{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.ollama;
in
{
  options.my.ollama = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Ollama local LLM server";
    };

    package = mkOption {
      type = types.enum [ "default" "rocm" "cuda" "vulkan" "cpu" ];
      default = "default";
      description = "Ollama package variant (rocm for AMD, cuda for NVIDIA)";
    };
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;

      # Select package based on GPU type
      package = {
        "default" = pkgs.ollama;
        "rocm" = pkgs.ollama-rocm;
        "cuda" = pkgs.ollama-cuda;
        "vulkan" = pkgs.ollama-vulkan;
        "cpu" = pkgs.ollama-cpu;
      }.${cfg.package};

      # Bind to localhost only -- previously 0.0.0.0 with an open firewall port,
      # which exposed the unauthenticated API to the entire LAN.
      # For remote access, use Tailscale: `tailscale funnel 11434` or SSH tunnel.
      host = "127.0.0.1";
      port = 11434;
    };

    # CLI tool
    environment.systemPackages = [ config.services.ollama.package ];
  };
}
