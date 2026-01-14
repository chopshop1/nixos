{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.plasma;
in
{
  options.my.plasma = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable KDE Plasma desktop environment";
    };
  };

  config = mkIf cfg.enable {
    # Enable X11
    services.xserver.enable = true;

    # Enable SDDM display manager (X11 mode for Sunshine compatibility)
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = false;
      theme = "breeze";
      settings = {
        General.DefaultSession = "plasmax11.desktop";
        Autologin.Session = "plasmax11.desktop";
        Theme = {
          Current = "breeze";
          CursorTheme = "breeze_cursors";
        };
      };
    };

    # Enable KDE Plasma 6
    services.desktopManager.plasma6.enable = true;

    # Auto-login to Plasma X11 session
    services.displayManager.autoLogin = {
      enable = true;
      user = "dev";
    };
    services.displayManager.defaultSession = "plasmax11";

    # XDG Portal for Plasma - use KDE portal backend
    xdg.portal = {
      extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
      config.KDE.default = [ "kde" ];
    };

    # KDE/Qt environment - X11 mode with dark theme
    environment.sessionVariables = {
      # Portal detection
      XDG_CURRENT_DESKTOP = "KDE";
      XDG_SESSION_DESKTOP = "KDE";
      # Qt settings
      QT_QPA_PLATFORM = "xcb";
      # Force dark color scheme for Qt/KDE apps
      QT_QPA_PLATFORMTHEME = "kde";
      # GTK dark theme preference
      GTK_THEME = "Breeze-Dark";
    };

    # Qt styling
    qt = {
      enable = true;
      platformTheme = "kde";
      style = "breeze";
    };

    # GTK dark theme configuration
    programs.dconf = {
      enable = true;
      profiles.user.databases = [{
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "Breeze-Dark";
          };
        };
      }];
    };

    # KDE packages
    environment.systemPackages = with pkgs; [
      # KDE essentials
      kdePackages.konsole
      kdePackages.dolphin
      kdePackages.ark
      kdePackages.spectacle
      kdePackages.gwenview
      kdePackages.kate
      kdePackages.kcalc
      kdePackages.kdeconnect-kde

      # System tools
      kdePackages.ksystemlog
      kdePackages.filelight
      kdePackages.partitionmanager

      # Plasma integration
      kdePackages.plasma-browser-integration
      kdePackages.kdeplasma-addons

      # Theming - Dark mode
      kdePackages.breeze
      kdePackages.breeze-gtk
      kdePackages.breeze-icons
      kdePackages.kde-gtk-config
    ];

    # GTK 3 dark theme settings
    environment.etc."gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=true
      gtk-theme-name=Breeze-Dark
      gtk-icon-theme-name=breeze-dark
      gtk-cursor-theme-name=breeze_cursors
    '';

    # GTK 4 dark theme settings
    environment.etc."gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=true
      gtk-theme-name=Breeze-Dark
      gtk-icon-theme-name=breeze-dark
      gtk-cursor-theme-name=breeze_cursors
    '';

    # KDE Connect firewall
    programs.kdeconnect.enable = true;
  };
}
