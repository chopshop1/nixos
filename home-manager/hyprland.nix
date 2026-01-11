{ config, lib, pkgs, ... }:

{
  # Hyprland configuration via Home Manager
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # Monitor configuration (AMD RX 7900 XTX)
      monitor = [
        "HDMI-A-1,1920x1080@120,0x0,1"  # 1080p 120Hz
        ",preferred,auto,1"  # Fallback for any other monitors
      ];

      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgb(7aa2f7) rgb(bb9af7) 45deg";  # Tokyo Night blue/magenta
        "col.inactive_border" = "rgb(414868)";  # Tokyo Night gray
        layout = "dwindle";
        allow_tearing = true;  # For gaming/streaming
      };

      # Decoration (Tokyo Night aesthetic)
      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 8;
          passes = 2;
          new_optimizations = true;
        };
        shadow = {
          enabled = true;
          range = 15;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

      # Animations
      animations = {
        enabled = true;
        bezier = [
          "myBezier, 0.05, 0.9, 0.1, 1.05"
        ];
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # Input
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
      };

      # Dwindle layout
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # Misc
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        vfr = true;  # Variable framerate
      };

      # Environment
      env = [
        "XCURSOR_SIZE,24"
        "WLR_NO_HARDWARE_CURSORS,0"
      ];

      # Key bindings
      "$mod" = "SUPER";

      bind = [
        # Launch apps
        "$mod, Return, exec, kitty"
        "$mod, D, exec, wofi --show drun"
        "$mod, Space, exec, wofi --show drun"  # Alternative launcher shortcut
        "$mod, Q, killactive"
        "$mod SHIFT, E, exit"

        # Window management
        "$mod, V, togglefloating"
        "$mod, F, fullscreen"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"

        # Focus movement (vim-like)
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"

        # Move windows
        "$mod SHIFT, h, movewindow, l"
        "$mod SHIFT, l, movewindow, r"
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, j, movewindow, d"

        # Workspace switching
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # Scroll through workspaces
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

        # Screenshots
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        "SHIFT, Print, exec, grim - | wl-copy"
        "$mod, Print, exec, grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"

        # Clipboard history
        "$mod, C, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"
      ];

      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Super key alone opens launcher (on release)
      bindr = [
        "SUPER, SUPER_L, exec, pkill wofi || wofi --show drun"
      ];

      # Autostart
      exec-once = [
        "waybar"
        "mako"
        "hyprpaper"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
        # Start a minimal X11 app to trigger XWayland, then restart Sunshine for proper X11 capture
        "sleep 2 && ${pkgs.xorg.xeyes}/bin/xeyes & sleep 4 && systemctl --user restart sunshine"
      ];

      # Window rules for gaming/Sunshine compatibility
      windowrulev2 = [
        "immediate, class:^(steam_app).*"  # Allow tearing for Steam games
        "immediate, class:^(gamescope)$"   # Allow tearing for Gamescope

        # Hide xeyes (used to trigger XWayland for Sunshine)
        "float, class:^(xeyes)$"
        "size 1 1, class:^(xeyes)$"
        "move -100 -100, class:^(xeyes)$"
        "float, class:^(pavucontrol)$"     # Float audio control
        "float, class:^(nm-connection-editor)$"  # Float network manager
        "float, title:^(Picture-in-Picture)$"    # Float PiP windows

        # Steam window rules
        # minsize prevents Steam windows from being too small to interact with
        "minsize 1 1, title:^()$,class:^(steam)$"

        # Float Steam popup windows
        "float, class:^(steam)$,title:^(Friends List)$"
        "float, class:^(steam)$,title:^(Steam Settings)$"
        "float, class:^(steam)$,title:^(Steam - News)$"
        "float, class:^(steam)$,title:^(Screenshot Manager)$"
        "float, class:^(steam)$,title:^(Steam Guard)$"

        # Keep Steam main window
        "workspace 2 silent, class:^(steam)$,title:^(Steam)$"
      ];
    };
  };

  # Waybar configuration (Tokyo Night themed)
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;

        modules-left = ["hyprland/workspaces" "hyprland/window"];
        modules-center = ["clock"];
        modules-right = ["tray" "network" "pulseaudio" "cpu" "memory"];

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "0";
          };
          on-click = "activate";
        };

        "hyprland/window" = {
          max-length = 50;
        };

        clock = {
          format = "  {:%H:%M}";
          format-alt = "  {:%Y-%m-%d}";
          tooltip-format = "<tt>{calendar}</tt>";
        };

        cpu = {
          format = " {usage}%";
          interval = 2;
        };

        memory = {
          format = " {}%";
          interval = 2;
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = " Muted";
          format-icons = {
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
        };

        network = {
          format-wifi = " {signalStrength}%";
          format-ethernet = " {ipaddr}";
          format-disconnected = "󰖪 Disconnected";
          tooltip-format = "{ifname}: {ipaddr}";
        };

        tray = {
          spacing = 10;
        };
      };
    };

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: rgba(26, 27, 38, 0.9);
        color: #c0caf5;
        border-bottom: 2px solid #7aa2f7;
      }

      #workspaces {
        margin: 0 5px;
      }

      #workspaces button {
        padding: 0 8px;
        color: #565f89;
        background: transparent;
        border: none;
        border-radius: 0;
      }

      #workspaces button.active {
        color: #7aa2f7;
        border-bottom: 2px solid #bb9af7;
      }

      #workspaces button:hover {
        background: rgba(122, 162, 247, 0.2);
      }

      #window {
        padding: 0 10px;
        color: #a9b1d6;
      }

      #clock, #cpu, #memory, #network, #pulseaudio, #tray {
        padding: 0 10px;
        margin: 0 2px;
      }

      #clock {
        color: #bb9af7;
      }

      #cpu {
        color: #9ece6a;
      }

      #memory {
        color: #7dcfff;
      }

      #network {
        color: #7aa2f7;
      }

      #pulseaudio {
        color: #e0af68;
      }

      #tray {
        margin-right: 5px;
      }
    '';
  };

  # Hyprpaper (wallpaper) - default to solid Tokyo Night background
  home.file.".config/hypr/hyprpaper.conf".text = ''
    preload =
    wallpaper = ,#1a1b26
    splash = false
  '';

  # Mako notifications (Tokyo Night themed)
  services.mako = {
    enable = true;
    settings = {
      background-color = "#1a1b26";
      text-color = "#c0caf5";
      border-color = "#7aa2f7";
      border-radius = 10;
      border-size = 2;
      default-timeout = 5000;
      font = "JetBrainsMono Nerd Font 11";
    };
  };

  # Wofi launcher
  programs.wofi = {
    enable = true;
    settings = {
      show = "drun";
      width = 500;
      height = 400;
      always_parse_args = true;
      show_all = true;
      allow_images = true;
      image_size = 24;
      print_command = true;
      layer = "overlay";
      insensitive = true;
      prompt = "";
      # Vim-style keybindings
      key_down = "Ctrl-j";
      key_up = "Ctrl-k";
      key_pgdn = "Ctrl-d";
      key_pgup = "Ctrl-u";
      key_exit = "Escape";
    };
    style = ''
      window {
        background-color: #1a1b26;
        border: 2px solid #7aa2f7;
        border-radius: 10px;
      }

      #input {
        background-color: #24283b;
        color: #c0caf5;
        border: none;
        border-radius: 5px;
        padding: 10px;
        margin: 10px;
      }

      #inner-box {
        margin: 5px;
      }

      #outer-box {
        margin: 5px;
      }

      #scroll {
        margin: 5px;
      }

      #entry {
        padding: 10px;
        border-radius: 5px;
      }

      #entry:selected {
        background-color: #7aa2f7;
        color: #1a1b26;
      }

      #text {
        margin: 5px;
      }
    '';
  };

  # Cursor theme (Breeze for Plasma compatibility)
  # NOTE: gtk.enable disabled to avoid conflicts with Plasma's .gtkrc-2.0 management
  home.pointerCursor = {
    gtk.enable = false;  # Plasma manages this
    x11.enable = true;
    package = pkgs.kdePackages.breeze;
    name = "breeze_cursors";
    size = 24;
  };

  # GTK theme settings - DISABLED when using Plasma
  # Plasma manages .gtkrc-2.0 itself, so home-manager's GTK management conflicts
  # Only enable this for standalone Hyprland sessions (not Plasma)
  # gtk = {
  #   enable = true;
  #   theme = {
  #     name = "Breeze-Dark";
  #     package = pkgs.kdePackages.breeze-gtk;
  #   };
  #   iconTheme = {
  #     name = "breeze-dark";
  #     package = pkgs.kdePackages.breeze-icons;
  #   };
  #   cursorTheme = {
  #     name = "breeze_cursors";
  #     package = pkgs.kdePackages.breeze;
  #     size = 24;
  #   };
  #   gtk3.extraConfig = {
  #     gtk-application-prefer-dark-theme = true;
  #   };
  #   gtk4.extraConfig = {
  #     gtk-application-prefer-dark-theme = true;
  #   };
  # };

  # Qt theme - disabled for Plasma compatibility
  # When using Plasma, KDE handles Qt theming automatically
  # Only enable for Hyprland/Wayland sessions:
  # qt = {
  #   enable = true;
  #   platformTheme.name = "gtk";
  #   style.name = "adwaita-dark";
  # };

  # dconf settings for dark theme
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # Plasma/KDE config files - DISABLED when using Plasma desktop
  # Plasma manages these files itself, so home-manager management causes conflicts
  # Only enable these for standalone Hyprland sessions (not Plasma)
  #
  # home.file.".config/kdeglobals".text = ''
  #   [General]
  #   ColorScheme=BreezeDark
  #
  #   [KDE]
  #   LookAndFeelPackage=org.kde.breezedark.desktop
  #   widgetStyle=Breeze
  #
  #   [Colors:View]
  #   BackgroundNormal=35,38,52
  #   ForegroundNormal=192,202,245
  #
  #   [Icons]
  #   Theme=breeze-dark
  # '';
  #
  # home.file.".config/plasmarc".text = ''
  #   [Theme]
  #   name=breeze-dark
  # '';
  #
  # home.file.".config/kcminputrc".text = ''
  #   [Mouse]
  #   cursorTheme=breeze_cursors
  #   cursorSize=24
  # '';
  #
  # home.file.".config/kwinrc".text = ''
  #   [org.kde.kdecoration2]
  #   theme=Breeze
  # '';
  #
  # home.file.".config/kcolorschemerc".text = ''
  #   [General]
  #   Name=Breeze Dark
  # '';
  #
  # home.file.".config/plasmanotifyrc".text = ''
  #   [Notifications]
  #   LowPriorityHistory=true
  # '';
}
