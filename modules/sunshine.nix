{ config, lib, pkgs, ... }:

{
  # Enable Sunshine game streaming server (nixpkgs version with proper capabilities)
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;  # Required for KMS capture
    openFirewall = true;

    # Application profiles using virtual display (DP-1) for independent streaming
    # The virtual display is created via kernel parameter: video=DP-1:3840x2160@60e
    applications = {
      env = {
        PATH = "$(PATH)";
        DISPLAY = ":0";
      };
      apps = [
        {
          name = "Desktop (Virtual 4K)";
          prep-cmd = [
            {
              # Enable virtual display and set to 4K, disable physical display for streaming
              do = "${pkgs.xorg.xrandr}/bin/xrandr --output DP-1 --mode 3840x2160 --rate 60 --primary";
              # Re-enable physical display on disconnect
              undo = "${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-A-1 --primary";
            }
          ];
          exclude-global-prep-cmd = "false";
          auto-detach = "true";
        }
        {
          name = "Desktop (Virtual 1080p)";
          prep-cmd = [
            {
              do = "${pkgs.xorg.xrandr}/bin/xrandr --output DP-1 --mode 1920x1080 --rate 60 --primary";
              undo = "${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-A-1 --primary";
            }
          ];
          auto-detach = "true";
        }
        {
          name = "Desktop (Virtual 1440p)";
          prep-cmd = [
            {
              do = "${pkgs.xorg.xrandr}/bin/xrandr --output DP-1 --mode 2560x1440 --rate 60 --primary";
              undo = "${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-A-1 --primary";
            }
          ];
          auto-detach = "true";
        }
        {
          name = "Desktop (Physical Monitor)";
          # No prep-cmd - streams from your physical HDMI-A-1 display as-is
          auto-detach = "true";
        }
      ];
    };
  };

  # Also enable flatpak for other apps (Sunshine flatpak can be removed)
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
    };
  };

  # Ensure the dev user is in the input group for capture
  users.users.dev.extraGroups = [ "input" "video" ];

  # Udev rules for Sunshine to access input devices
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
  '';

  # Load uinput module for virtual input devices
  boot.kernelModules = [ "uinput" ];

}
