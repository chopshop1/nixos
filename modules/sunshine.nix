{ config, lib, pkgs, ... }:

{
  # Enable Sunshine game streaming server (nixpkgs version with proper capabilities)
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;  # Required for KMS capture
    openFirewall = true;

    settings = {
      # Use KMS capture for GNOME Wayland (wlroots doesn't work with NVIDIA headless)
      capture = "kms";
      adapter_name = "/dev/dri/card1";
      output_name = "0";
      min_fps_factor = "1";

      # Resolution list (limited to display's native resolution without dummy plug)
      resolutions = ''
        [
          1280x720,
          1920x1080
        ]
      '';
    };

    # Application profiles for streaming
    applications = {
      apps = [
        {
          name = "Desktop";
          auto-detach = "true";
          # Set resolution to match client before starting
          prep-cmd = [
            {
              do = "/etc/sway-headless/set-resolution.sh";
              undo = "true";
            }
          ];
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

  # Note: For 4K streaming without a 4K monitor, you need a hardware HDMI dummy plug
  # The headless Sway + wlroots approach doesn't work with NVIDIA GPUs

}
