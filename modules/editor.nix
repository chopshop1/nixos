# Neovim configured with NvChad via Home Manager.
{ lib, userSettings, nvchadSrc, ... }:
let username = userSettings.username or "devuser";
in {
  home-manager.users.${username} = { pkgs, ... }: {
    home.stateVersion = lib.mkDefault "24.05";

    home.sessionVariables.EDITOR = "nvim";

    xdg.enable = true;
    xdg.configFile."nvim" = {
      source = nvchadSrc;
      recursive = true;
    };

    programs.home-manager.enable = true;
  };
}
