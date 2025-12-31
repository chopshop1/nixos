{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/editor-declarative.nix
    ./modules/docker.nix
    ./modules/cli-tools.nix
    ./modules/desktop-apps.nix
    ./modules/system-base.nix
    ./modules/power-management.nix
    ./modules/nvidia.nix
    ./modules/gaming.nix
    ./modules/sunshine.nix
    ./modules/vibe-kanban.nix
    # ./modules/sway-headless.nix  # Disabled: wlroots capture doesn't work with NVIDIA
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Kernel parameters to prevent suspension
  boot.kernelParams = [
    "consoleblank=0"
    "noresume"
    "nohibernate"
  ];

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Development environment variables (Playwright, GTK/GDK for Rust/Tauri)
  environment.variables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    PKG_CONFIG_PATH = lib.makeSearchPath "lib/pkgconfig" [
      # GTK/WebKit
      pkgs.gtk3.dev
      pkgs.glib.dev
      pkgs.cairo.dev
      pkgs.pango.dev
      pkgs.gdk-pixbuf.dev
      pkgs.harfbuzz.dev
      pkgs.freetype.dev
      pkgs.fontconfig.dev
      pkgs.libsoup_3.dev
      pkgs.webkitgtk_4_1.dev
      pkgs.librsvg.dev
      pkgs.libpng.dev
      pkgs.pixman
      pkgs.fribidi.dev
      pkgs.libepoxy.dev

      # X11
      pkgs.xorg.libX11.dev
      pkgs.xorg.libXcursor.dev
      pkgs.xorg.libXrandr.dev
      pkgs.xorg.libXi.dev
      pkgs.xorg.libxcb.dev
      pkgs.xorg.libXext.dev
      pkgs.xorg.libXfixes.dev
      pkgs.xorg.libXcomposite
      pkgs.xorg.libXdamage
      pkgs.xorg.libXinerama

      # Wayland
      pkgs.wayland.dev
      pkgs.libxkbcommon.dev

      # Other
      pkgs.at-spi2-core.dev
      pkgs.dbus.dev
      pkgs.libayatana-appindicator.dev
      pkgs.openssl.dev
      pkgs.alsa-lib.dev
    ];
  };

  # Time zone and locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system
  services.xserver.enable = true;

  # Enable SDDM Display Manager with auto-login (works better with X11 + NVIDIA)
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;  # Force X11 for Sunshine compatibility
    theme = "breeze";  # Use Breeze theme (respects system dark mode)
  };
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "dev";
  services.displayManager.defaultSession = "plasmax11";  # Force Plasma X11 session for Sunshine

  # Enable KDE Plasma desktop (better X11 support than GNOME)
  services.desktopManager.plasma6.enable = true;

  # Force dark mode system-wide
  environment.sessionVariables = {
    # GTK dark theme
    GTK_THEME = "Breeze-Dark";
    # Qt/KDE dark theme
    QT_STYLE_OVERRIDE = "breeze-dark";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Enable sound with pipewire
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable polkit for authentication
  security.polkit.enable = true;

  # Enable passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Enable dbus for desktop integration
  services.dbus.enable = true;

  # Set zsh as the default shell system-wide
  users.defaultUserShell = pkgs.zsh;
  environment.shells = with pkgs; [ zsh bash ];

  # Define a user account (minimal, as Home Manager manages the environment)
  users.users.dev = {
    isNormalUser = true;
    description = "dev";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
    hashedPassword = ""; # No password for automatic login
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable flakes and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # XDG Desktop Portal configuration (KDE portal is auto-enabled with Plasma)

  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitUserEnvironment = true;
      AcceptEnv = "SHELL LANG LC_*";
      UsePAM = true;
    };
  };

  # Set default shell for SSH sessions
  programs.ssh.extraConfig = ''
    SetEnv SHELL=${pkgs.zsh}/bin/zsh
  '';

  # Enable Tailscale
  services.tailscale.enable = true;

  # System state version
  system.stateVersion = "25.05";

  # Enable nix-ld for running unpackaged binaries (including Playwright browsers)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Core
      glibc
      gcc.cc.lib
      zlib
      stdenv.cc.cc.lib

      # GTK/WebKit (Playwright browser deps)
      glib
      gtk3
      gtk4
      cairo
      pango
      gdk-pixbuf
      harfbuzz
      freetype
      fontconfig
      atk
      at-spi2-atk
      at-spi2-core

      # X11
      xorg.libX11
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXi
      xorg.libxcb
      xorg.libXext
      xorg.libXfixes
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXrender

      # Wayland
      wayland
      libxkbcommon

      # Networking/Security
      nss
      nspr
      openssl
      curl

      # Media
      alsa-lib
      libpulseaudio
      libdrm
      mesa.drivers
      libGL
      libva
      libvdpau

      # GStreamer
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base

      # Other
      cups
      dbus
      expat
      libpng
      libjpeg
      icu
      libxslt
      libxml2
    ];
  };
}