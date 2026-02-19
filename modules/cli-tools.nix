{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.cli-tools;
in
{
  options.my.cli-tools = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable enhanced CLI tools";
    };

    modern = mkOption {
      type = types.bool;
      default = true;
      description = "Enable modern CLI tool replacements (eza, bat, etc.)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Shell enhancements
      zsh-autosuggestions
      zsh-syntax-highlighting
      zsh-completions
      starship

      # Tauri v2 / Playwright development dependencies
      pkg-config
      rustup

      # Development libraries (libssl-dev, libclang-dev equivalents)
      openssl.dev
      llvmPackages.libclang
      llvmPackages.clang
      clang
      cmake
      zlib
      zlib.dev

      # GTK/WebKit core (including dev outputs for Rust builds)
      webkitgtk_4_1
      webkitgtk_4_1.dev
      gtk3
      gtk3.dev
      glib
      glib.dev
      gobject-introspection
      gobject-introspection.dev
      cairo
      cairo.dev
      pango
      pango.dev
      gdk-pixbuf
      gdk-pixbuf.dev
      harfbuzz
      harfbuzz.dev
      graphite2
      graphite2.dev
      freetype
      freetype.dev
      fontconfig
      fontconfig.dev

      # HTTP library for WebKit
      libsoup_3
      libsoup_3.dev

      # System tray support
      libayatana-appindicator
      libayatana-appindicator.dev

      # X11 dependencies
      xorg.libX11
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXi
      xorg.libxcb
      xorg.libXext
      xorg.libXfixes
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXinerama
      xorg.libXtst
      xorg.libXrender
      xorg.xorgserver  # for xvfb

      # Wayland
      wayland
      libxkbcommon

      # Other GTK dependencies
      at-spi2-core
      at-spi2-atk
      atk
      atkmm  # Accessibility for Tauri
      dbus
      fribidi

      # Automation (libxdo for Tauri)
      xdotool
      libepoxy
      libpng
      pixman

      # Playwright browser dependencies
      cups
      libdrm
      mesa
      nspr
      nss
      gtk4
      icu
      enchant
      libevent
      flite
      libjpeg
      lcms2
      libmanette
      libopus
      libsecret
      libvpx
      libwebp
      woff2
      libxml2
      libxslt
      x264
      libavif

      # GStreamer (for video/audio in Playwright)
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-libav

      # Fonts for browser rendering
      noto-fonts
      noto-fonts-color-emoji
      liberation_ttf
      freefont_ttf
      wqy_zenhei

      # Note: Nerd Fonts moved to fonts.packages below

      # Audio (for cpal - microphone capture)
      alsa-lib

      # OpenSSL (for reqwest/downloads)
      openssl

      # SVG icon support for Tauri
      librsvg
      librsvg.dev

      # Tauri build tools
      file           # file type detection
      patchelf       # binary patching
      squashfsTools  # AppImage builds
      dpkg           # .deb package builds
      rpm            # .rpm package builds
      flatpak-builder # Flatpak builds

      # Node/Bun/Python
      bun
      nodejs
      python312

      # Notification support (for Claude Code hooks, etc.)
      libnotify  # notify-send command

      # AI coding agents
      opencode   # Terminal-based AI coding agent

      # JSON/data processing
      jq         # Command-line JSON processor

      # Modern CLI tools
    ] ++ (if cfg.modern then with pkgs; [
      fzf       # Fuzzy finder
      bat       # Better cat
      eza       # Better ls
      ripgrep   # Better grep
      fd        # Better find
      delta     # Better diff
      duf       # Better df
      dust      # Better du
      procs     # Better ps
      sd        # Better sed
      tokei     # Code statistics
      hyperfine # Command-line benchmarking
      tealdeer  # Better tldr
      gh        # GitHub CLI
    ] else []);

    # LD_LIBRARY_PATH for Tauri appindicator (system tray)
    environment.sessionVariables = {
      LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.libayatana-appindicator ];
    };

    # Nerd Fonts for terminal/coding (must be in fonts.packages, not systemPackages)
    fonts.packages = with pkgs; [
      nerd-fonts._0xproto        # 0xProto
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.meslo-lg
      nerd-fonts.caskaydia-cove  # Cascadia Code
      nerd-fonts.iosevka
      nerd-fonts.sauce-code-pro  # Source Code Pro
    ];
  };
}