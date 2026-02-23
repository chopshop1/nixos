{ config, lib, pkgs, ... }:

with lib;

{
  # Enable Sunshine - X11 capture for Plasma X11 session
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;

    settings = {
      # X11 capture for Plasma X11 session
      capture = "x11";
      encoder = "vaapi";
      # Input settings
      key_repeat_delay = "500";
      key_repeat_frequency = "24";
      keyboard = "enabled";
      mouse = "enabled";
      gamepad = "enabled";
      # Force controller always connected - fixes reconnect issues
      controller = "1";
      # Use x360 emulation (most compatible)
      gamepad_type = "x360";
      min_log_level = "info";
    };
  };

  # Sunshine startup script for Plasma X11 session
  environment.etc."sunshine-start.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      sleep 3

      # Find the Plasma/SDDM X11 display dynamically
      # SDDM runs Xorg on a real seat; pick the display owned by root
      for sock in /tmp/.X11-unix/X*; do
        num="''${sock##*/tmp/.X11-unix/X}"
        owner=$(stat -c '%U' "$sock" 2>/dev/null)
        if [ "$owner" = "root" ]; then
          DISPLAY=":$num"
          break
        fi
      done
      export DISPLAY="''${DISPLAY:-:0}"

      export XDG_SESSION_TYPE="x11"
      # Unset Wayland vars
      unset WAYLAND_DISPLAY
      # VAAPI/AMD GPU acceleration
      export LIBVA_DRIVER_NAME="radeonsi"
      export RADV_PERFTEST="gpl"

      # XAUTHORITY is inherited from the user session (set by SDDM)
      echo "Sunshine starting on DISPLAY=$DISPLAY"
      exec /run/wrappers/bin/sunshine
    '';
  };

  # Sunshine service - use wrapper script
  systemd.user.services.sunshine = {
    after = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = mkForce "/etc/sunshine-start.sh";
      Restart = mkForce "always";
      RestartSec = mkForce "10s";
      # Protect from OOM killer (-900 to 1000, lower = less likely to be killed)
      OOMScoreAdjust = mkForce "-500";
      Nice = mkForce "-10";
    };
  };

  # Enable Flatpak
  services.flatpak.enable = true;

  # Open additional ports not covered by openFirewall
  networking.firewall = {
    allowedTCPPorts = [
      47984  # HTTPS/Web UI
      47989  # HTTP/Web UI
      47990  # Web UI
      48010  # RTSP
    ];
    allowedUDPPorts = [
      47998  # Video
      47999  # Control
      48000  # Audio
      48010  # RTSP
    ];
  };

  # Enable Avahi for network discovery (helps Moonlight find the host)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;  # Required for Sunshine user service
    };
  };

  # Ensure the dev user is in required groups for capture
  users.users.dev.extraGroups = [ "input" "video" "render" ];

  # Udev rules for Sunshine to access input devices
  services.udev.extraRules = ''
    # uinput for virtual input devices (mouse, keyboard, gamepad)
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0666", OPTIONS+="static_node=uinput", TAG+="uaccess"
    # uhid for DualSense (ds5) gamepad emulation
    KERNEL=="uhid", MODE="0666", OPTIONS+="static_node=uhid", TAG+="uaccess"
    # Allow access to event devices for input
    SUBSYSTEM=="input", MODE="0666", TAG+="uaccess"
    # hidraw for DualSense (ds5) gamepad emulation
    KERNEL=="hidraw*", MODE="0666", TAG+="uaccess"
  '';

  # Load kernel modules for virtual input devices
  boot.kernelModules = [ "uinput" "uhid" ];

  # Input tools for streaming (X11 session)
  environment.systemPackages = with pkgs; [
    xdotool
    xorg.xdpyinfo
  ];

  # Enable libinput for input device hotplugging
  services.libinput.enable = true;

}
