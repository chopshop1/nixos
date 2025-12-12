{ config, lib, pkgs, ... }:

{
  # Install Sway and dependencies for headless streaming
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # Required packages for headless Sway streaming
  environment.systemPackages = with pkgs; [
    sway
    swaybg
    foot          # Terminal for sway
    wlr-randr     # Wayland randr for resolution control
    wl-clipboard  # Clipboard support
  ];

  # Create the Sway config directory and headless config
  environment.etc."sway-headless/config".text = ''
    # Headless Sway configuration for Sunshine streaming

    # Set default resolution (will be overridden by sunshine script)
    output HEADLESS-1 resolution 3840x2160@60Hz position 0,0

    # Allow tearing for lower latency gaming
    output * allow_tearing yes
    output * max_render_time off

    # Dark background
    output * bg #1a1a1a solid_color

    # Basic keybindings
    set $mod Mod4
    bindsym $mod+Return exec foot
    bindsym $mod+q kill
    bindsym $mod+Shift+e exit

    # Sunshine is started via systemd service that depends on this
  '';

  # Script to start Sunshine after Sway is ready
  environment.etc."sway-headless/start-sunshine.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      sleep 2
      exec /run/wrappers/bin/sunshine
    '';
  };

  # Resolution adjustment script for Sunshine
  environment.etc."sway-headless/set-resolution.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      # Called by Sunshine to match client resolution

      WIDTH="''${SUNSHINE_CLIENT_WIDTH:-3840}"
      HEIGHT="''${SUNSHINE_CLIENT_HEIGHT:-2160}"
      FPS="''${SUNSHINE_CLIENT_FPS:-60}"

      export SWAYSOCK=/run/user/1000/sway-headless.sock

      echo "Setting resolution to ''${WIDTH}x''${HEIGHT}@''${FPS}Hz"
      ${pkgs.sway}/bin/swaymsg -s $SWAYSOCK "output HEADLESS-1 mode ''${WIDTH}x''${HEIGHT}@''${FPS}Hz"
    '';
  };

  # Systemd user service for headless Sway
  systemd.user.services.sway-headless = {
    description = "Headless Sway session for Sunshine streaming";
    wantedBy = [ "default.target" ];

    environment = {
      # Use ONLY headless backend (no libinput - Sunshine handles input)
      WLR_BACKENDS = "headless";
      WLR_RENDERER = "vulkan";
      WLR_LIBINPUT_NO_DEVICES = "1";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "sway";
      XDG_SESSION_DESKTOP = "sway";
      # NVIDIA specific
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
      __GL_GSYNC_ALLOWED = "1";
      __GL_VRR_ALLOWED = "1";
      # Vulkan/EGL
      VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
      __EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json";
      # Bypass seat management for headless operation
      WLR_SESSION = "headless";
      LIBSEAT_BACKEND = "noop";
      # Shell for Sway exec commands
      SHELL = "/bin/sh";
    };

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.sway}/bin/sway --config /etc/sway-headless/config";
      ExecStopPost = "${pkgs.coreutils}/bin/rm -f /run/user/1000/sway-headless.sock";
      Restart = "on-failure";
      RestartSec = "5";
    };
  };

  # Allow Sunshine to connect to the headless Sway session
  # by creating a known socket path
  systemd.user.services.sway-headless-socket = {
    description = "Create Sway headless socket symlink";
    wantedBy = [ "sway-headless.service" ];
    after = [ "sway-headless.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 2 && ln -sf $XDG_RUNTIME_DIR/sway-ipc.*.sock /run/user/1000/sway-headless.sock || true'";
      ExecStop = "${pkgs.coreutils}/bin/rm -f /run/user/1000/sway-headless.sock";
    };
  };
}
