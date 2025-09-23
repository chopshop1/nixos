# User account, shell defaults, and npm prefix setup.
{ config, pkgs, lib, userSettings, ... }:
let
  username = userSettings.username or "devuser";
  sshKey = userSettings.sshAuthorizedKey or null;
  hasKey = sshKey != null && sshKey != "";
in {
  users.defaultUserShell = pkgs.zsh;
  environment.shells = [ pkgs.zsh ];

  users.users.${username} = {
    isNormalUser = true;
    description = "Primary development user";
    home = "/home/${username}";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "docker" "networkmanager" ];
  } // lib.optionalAttrs hasKey { openssh.authorizedKeys.keys = [ sshKey ]; }
    // lib.optionalAttrs (!hasKey) { initialPassword = "changeme"; };

  system.activationScripts."reset-${username}-password" = lib.mkIf (!hasKey) {
    text = ''
      if [ -x ${pkgs.shadow}/bin/chage ]; then
        ${pkgs.shadow}/bin/chage -d 0 ${username} || true
      fi
    '';
    deps = [ "users" ];
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "sudo" "docker" ];
    };
    shellInit = ''
      export NPM_CONFIG_PREFIX="$HOME/.npm-global"
      export PATH="$HOME/.npm-global/bin:$PATH"
    '';
  };
}
