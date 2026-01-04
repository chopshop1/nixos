{ config, lib, pkgs, ... }:

{
  # Enable Sunshine - let it auto-detect capture method
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;

    settings = {
      # X11 capture for XFCE desktop
      capture = "x11";
      encoder = "vaapi";
      adapter_name = "/dev/dri/renderD128";
      # Capture HDMI-1 dummy plug (id: 3 from Sunshine's display detection)
      output_name = "3";
      # Input settings
      key_repeat_delay = "500";
      key_repeat_frequency = "24";
      # Debug logging
      min_log_level = "debug";
    };
  };

  # X11 environment for XFCE session
  systemd.user.services.sunshine = {
    environment = {
      DISPLAY = ":0";
      XDG_RUNTIME_DIR = "/run/user/1001";
      XAUTHORITY = "/home/dev/.Xauthority";
      # Add libXtst to library path for XTEST input injection
      LD_LIBRARY_PATH = "${pkgs.xorg.libXtst}/lib";
    };
    # Disable X11 access control before starting Sunshine (allows local connections)
    serviceConfig = {
      ExecStartPre = "${pkgs.xorg.xhost}/bin/xhost +local:";
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
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput", TAG+="uaccess"
  '';

  # Load uinput module for virtual input devices
  boot.kernelModules = [ "uinput" ];

  # X11 input tools (xdotool uses XTEST for input injection)
  environment.systemPackages = with pkgs; [
    xdotool
    xorg.xdpyinfo
  ];

  # Disable DPMS and screensaver for headless streaming (dummy plug)
  # Without this, the monitor turns off and Sunshine shows black screen
  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xset}/bin/xset -dpms
    ${pkgs.xorg.xset}/bin/xset s off
    ${pkgs.xorg.xset}/bin/xset s noblank
  '';

  # Enable libinput for X11 input device hotplugging (required for Sunshine virtual devices)
  services.libinput.enable = true;

}
