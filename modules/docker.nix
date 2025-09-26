{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.docker;
in
{
  options.my.docker = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Docker containerization platform";
    };

    users = mkOption {
      type = types.listOf types.str;
      default = [ "dev" ];
      description = "Users to add to the docker group";
    };

    enableCompose = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Docker Compose";
    };

    enableBuildkit = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Docker BuildKit by default";
    };

    storageDriver = mkOption {
      type = types.str;
      default = "overlay2";
      description = "Docker storage driver to use";
    };

    enablePrune = mkOption {
      type = types.bool;
      default = true;
      description = "Enable automatic Docker pruning";
    };
  };

  config = mkIf cfg.enable {
    # Enable Docker service
    virtualisation.docker = {
      enable = true;
      storageDriver = cfg.storageDriver;

      # Enable BuildKit by default
      daemon.settings = mkIf cfg.enableBuildkit {
        features = {
          buildkit = true;
        };
      };

      # Auto-prune Docker resources weekly
      autoPrune = mkIf cfg.enablePrune {
        enable = true;
        dates = "weekly";
        flags = [
          "--all"
          "--volumes"
        ];
      };
    };

    # Add users to docker group
    users.extraGroups.docker.members = cfg.users;

    # Install Docker-related packages
    environment.systemPackages = with pkgs; [
      docker
    ] ++ (if cfg.enableCompose then [ docker-compose ] else []);

    # Environment variables for Docker
    environment.variables = mkIf cfg.enableBuildkit {
      DOCKER_BUILDKIT = "1";
      COMPOSE_DOCKER_CLI_BUILD = "1";
    };
  };
}