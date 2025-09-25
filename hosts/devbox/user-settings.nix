{ config, lib, pkgs, ... }:

{
  users.users.dev = {
    isNormalUser = true;
    description = "Development User";
    extraGroups = [ "networkmanager" "wheel" "docker" "audio" "video" ];
    shell = pkgs.bash;
    packages = with pkgs; [
      thunderbird
      vscode
      docker-compose
      nodejs
      bun
      python3
      rustc
      cargo
      go
      _1password
      _1password-gui
    ];
  };

  programs.bash.enableCompletion = true;

  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  services.flatpak.enable = true;

  programs.steam = {
    enable = false;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
  };
}