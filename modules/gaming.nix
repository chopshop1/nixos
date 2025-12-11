{ config, lib, pkgs, ... }:

{
  # Enable Steam with Proton support
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;  # Helps with game capture
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

  # Wine and Proton dependencies
  environment.systemPackages = with pkgs; [
    # Wine packages
    wineWowPackages.stagingFull  # 64-bit and 32-bit Wine with staging patches
    winetricks
    protontricks  # Proton-specific winetricks wrapper

    # Proton-GE (community Proton with extra patches)
    protonup-qt  # GUI for managing Proton versions

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
