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

      # Listen on all interfaces (useful for remote access)
      host = "0.0.0.0";
      port = 11434;
    };

    # Open firewall for Ollama API
    networking.firewall.allowedTCPPorts = [ 11434 ];

    # CLI tool
    environment.systemPackages = [ config.services.ollama.package ];
  };
}
