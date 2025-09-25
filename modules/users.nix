{ config, lib, pkgs, ... }:

{
  users.defaultUserShell = pkgs.bash;

  users.users.dev = {
    isNormalUser = true;
    description = "Development User";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "dialout" "plugdev" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
    ];
  };

  users.mutableUsers = true;

  programs.zsh.enable = true;
  programs.fish.enable = true;

  environment.shells = with pkgs; [
    bash
    zsh
    fish
  ];
}