{ config, lib, pkgs, ... }:

{
  # Enable Steam with Proton support
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;  # Helps with game capture

    # Force Steam to use XWayland (fixes window closing issues on Wayland)
    package = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        # X11 libraries
        xorg.libXcursor
        xorg.libXi
        xorg.libXinerama
        xorg.libXScrnSaver
        xorg.libXrandr
        xorg.libXrender
        xorg.libXfixes
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXtst

        # CEF/Chromium dependencies (required for Store/Library)
        nss
        nspr
        cups
        at-spi2-atk
        at-spi2-core
        libdrm
        mesa
        libxkbcommon
        pango
        cairo
        glib
        gdk-pixbuf
        gtk3
        dbus

        # Audio/media
        libpng
        libpulseaudio
        libvorbis
        alsa-lib

        # General dependencies
        stdenv.cc.cc.lib
        libkrb5
        keyutils
        openssl
        freetype
        harfbuzz
        fontconfig
        libudev-zero

        # Additional dependencies for games like Arc Raiders
        SDL2
        SDL2_image
        SDL2_mixer
        SDL2_ttf
        curl
        zlib
        libidn2
        icu
        bzip2
        xz
        libgcrypt
      ];
      extraEnv = {
        # Note: Removed SDL_VIDEODRIVER=x11 as it breaks EAC games like Arc Raiders
        # Games can override this individually if needed
        GDK_BACKEND = "x11";
        # Fix Steam CEF browser issues on Wayland
        STEAM_ENABLE_WAYLAND = "0";
      };
    };

    # Extra compatibility packages for Steam runtime
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  # Environment variables for Steam
  environment.sessionVariables = {
    # Force Steam to use X11/XWayland (no scaling since display is at native 2K)
    STEAM_FORCE_DESKTOPUI_SCALING = "1";
    # Disable GPU compositor in CEF to fix blank Store/Library
    STEAM_DISABLE_BROWSER_SANDBOX = "1";
  };

  # Enable Gamescope compositor (useful for game streaming)
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # Enable GameMode for optimized gaming performance
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
      };
    };
  };

  # Wine, Proton dependencies, and gaming utilities
  environment.systemPackages = with pkgs; [
    # Steam through gamescope (for big picture mode)
    (writeShellScriptBin "steam-gamescope" ''
      exec ${pkgs.gamescope}/bin/gamescope -W 2560 -H 1440 -r 120 --expose-wayland -- steam -tenfoot "$@"
    '')
    # Wine packages
    wineWowPackages.stagingFull  # 64-bit and 32-bit Wine with staging patches
    winetricks
    protontricks  # Proton-specific winetricks wrapper

    # Proton-GE (community Proton with extra patches)
    protonup-qt  # GUI for managing Proton versions

    # Wine prefix managers
    bottles  # Modern wineprefix manager with GUI

    # UMU - Unified launcher for running Windows games outside Steam
    umu-launcher  # Run games with Proton outside of Steam
    faugus-launcher  # Simple GUI for UMU-Launcher

    # Game utilities
    lutris  # Game launcher with Wine/Proton integration
    heroic  # Epic/GOG launcher with Proton support
    mangohud  # FPS overlay and performance monitoring
    gamemode  # Feral GameMode

    # Dependencies often needed by Windows games
    dxvk  # DirectX to Vulkan translation
    vkd3d-proton  # DirectX 12 to Vulkan

    # Capture and streaming helpers
    obs-studio  # For testing capture
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-vaapi
  ];

  # Enable 32-bit support for Wine
  hardware.graphics.enable32Bit = true;

  # Add user to gamemode group
  users.users.dev.extraGroups = [ "gamemode" ];
}
