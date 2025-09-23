# Docker daemon, Docker Compose v2, and user access configuration.
{ pkgs, userSettings, ... }:
let username = userSettings.username or "devuser";
in {
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  users.groups.docker.members = [ username ];

  environment.systemPackages = [ pkgs.docker-compose ];
}
