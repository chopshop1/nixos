{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.desktop-apps;
in
{
  options.my.desktop-apps = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable desktop applications";
    };

    browsers = mkOption {
      type = types.bool;
      default = true;
      description = "Enable web browsers";
    };

    proton = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Proton suite applications";
    };

    onePassword = mkOption {
      type = types.bool;
      default = true;
      description = "Enable 1Password";
    };
  };

  config = mkIf cfg.enable {
    # Firefox is handled separately via programs.firefox
    programs.firefox.enable = cfg.browsers;

    environment.systemPackages = with pkgs; []
      ++ (if cfg.browsers then [ chromium brave ] else [])
      ++ (if cfg.proton then [
        protonmail-desktop
        protonmail-bridge
        protonmail-bridge-gui
        proton-pass
        protonvpn-gui
      ] else [])
      ++ (if cfg.onePassword then [
        _1password-cli
        _1password-gui
      ] else []);

    # Enable 1Password GUI if selected
    programs._1password-gui.enable = cfg.onePassword;
  };
}