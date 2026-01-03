{ config, lib, pkgs, ... }:

{
  # Enable Sunshine game streaming server (nixpkgs version with proper capabilities)
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;  # Required for KMS capture
    openFirewall = true;

    settings = {
      # X11 capture for XFCE/X11 desktop
      # Use "wlr" for Hyprland/Wayland, "x11" for X11 desktops
      capture = "x11";
      adapter_name = "/dev/dri/card1";  # RX 7900 XTX (discrete GPU, card0 is iGPU)
      output_name = "0";  # Primary output

      # Use VA-API hardware encoding on AMD
      encoder = "vaapi";

      # Video codec - prefer HEVC but allow fallback to H.264
      hevc_mode = "1";         # 0=never, 1=prefer, 2=always
      av1_mode = "1";          # Enable AV1 when client supports it

      # Encoder quality
      qp = "20";
      min_threads = "2";
    };

    # Application profiles for streaming
    applications = {
      apps = [
        {
          name = "Desktop";
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

  # Ensure the dev user is in required groups for capture
  users.users.dev.extraGroups = [ "input" "video" "render" ];

  # Udev rules for Sunshine to access input devices
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
  '';

  # Load uinput module for virtual input devices
  boot.kernelModules = [ "uinput" ];

  # Note: For 4K streaming without a 4K monitor, you may need a hardware HDMI dummy plug
  # Hyprland with wlroots capture works natively for streaming

}
