{ config, lib, pkgs, ... }:

{
  # Enable Sunshine game streaming server (nixpkgs version with proper capabilities)
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;  # Required for KMS capture
    openFirewall = true;

    settings = {
      # wlroots capture for Hyprland (Wayland)
      capture = "wlr";
      adapter_name = "/dev/dri/card1";  # RX 7900 XTX (discrete GPU, card0 is iGPU)
      output_name = "0";  # Primary Wayland output (HDMI-A-1)

      # Use VA-API hardware encoding on AMD
      encoder = "vaapi";

      min_fps_factor = "1";

      # Video codec - HEVC/AV1 have better quality per bit than H.264
      hevc_mode = "2";         # 0=never, 1=prefer, 2=always
      av1_mode = "1";          # Enable AV1 when client supports it

      # Color accuracy settings
      colorspace = "rec709";   # rec709 for SDR, bt2020 for HDR
      colorrange = "full";     # Full RGB range (0-255) for better gradients

      # CRITICAL for text sharpness - 4:4:4 chroma (no subsampling)
      # 4:2:0 causes color bleed on text edges making it blurry
      encoder_csc = "1";       # 0 = 4:2:0, 1 = 4:4:4

      # Encoder quality - lower qp = higher quality (18-23 recommended)
      qp = "20";
      min_threads = "2";

      # AMD VA-API quality preference (0 = quality, higher = speed)
      vaapi_coder = "0";

      # Default to 2K 120Hz - order matters, first is default
      resolutions = ''
        [
          2560x1440,
          1920x1080,
          1280x720,
          3840x2160
        ]
      '';

      # Default to 120fps - order matters, first is default
      fps = ''
        [
          120,
          60,
          30
        ]
      '';
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
