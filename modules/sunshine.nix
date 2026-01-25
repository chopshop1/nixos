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
      # X11 capture for X11 session
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

  # Sunshine config file
  environment.etc."sunshine/sunshine.conf" = {
    mode = "0644";
    text = ''
      capture = x11
      encoder = vaapi
      keyboard = enabled
      mouse = enabled
      gamepad = enabled
      controller = 1
      gamepad_type = x360
      min_log_level = info
      key_repeat_delay = 500
      key_repeat_frequency = 24
    '';
  };

  # Sunshine startup script that finds XAUTHORITY from running KDE session
  environment.etc."sunshine-start.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      sleep 3
      # Find XAUTHORITY from kwin_x11 process
      KWIN_PID=$(${pkgs.procps}/bin/pgrep -f kwin_x11 | head -1)
      if [ -n "$KWIN_PID" ] && [ -r "/proc/$KWIN_PID/environ" ]; then
        export XAUTHORITY=$(cat /proc/$KWIN_PID/environ | tr '\0' '\n' | grep ^XAUTHORITY= | cut -d= -f2)
      fi
      export DISPLAY=:0
      # Unset Wayland vars to ensure X11 capture
      unset WAYLAND_DISPLAY
      unset XDG_SESSION_TYPE
      exec /run/wrappers/bin/sunshine /etc/sunshine/sunshine.conf
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

  # Input tools for streaming
  environment.systemPackages = with pkgs; [
    xdotool
    xorg.xdpyinfo
    wl-clipboard  # Wayland clipboard
    ydotool       # Wayland input automation
  ];

  # Enable libinput for input device hotplugging
  services.libinput.enable = true;

}
