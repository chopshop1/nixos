{ pkgs ? import <nixpkgs> {} }:

let
  lib = pkgs.lib;

  # PKG_CONFIG_PATH for all dev libraries (from configuration-cleaned.nix)
  pkgConfigPath = lib.concatStringsSep ":" [
    "${pkgs.gtk3.dev}/lib/pkgconfig"
    "${pkgs.pango.dev}/lib/pkgconfig"
    "${pkgs.glib.dev}/lib/pkgconfig"
    "${pkgs.cairo.dev}/lib/pkgconfig"
    "${pkgs.harfbuzz.dev}/lib/pkgconfig"
    "${pkgs.gdk-pixbuf.dev}/lib/pkgconfig"
    "${pkgs.at-spi2-core.dev}/lib/pkgconfig"
    "${pkgs.fontconfig.dev}/lib/pkgconfig"
    "${pkgs.freetype.dev}/lib/pkgconfig"
    "${pkgs.libpng.dev}/lib/pkgconfig"
    "${pkgs.pixman}/lib/pkgconfig"
    "${pkgs.libxkbcommon.dev}/lib/pkgconfig"
    "${pkgs.libepoxy.dev}/lib/pkgconfig"
    "${pkgs.fribidi.dev}/lib/pkgconfig"
    "${pkgs.graphite2.dev}/lib/pkgconfig"
    "${pkgs.libsoup_3.dev}/lib/pkgconfig"
    "${pkgs.webkitgtk_4_1.dev}/lib/pkgconfig"
    "${pkgs.openssl.dev}/lib/pkgconfig"
    "${pkgs.alsa-lib.dev}/lib/pkgconfig"
    "${pkgs.dbus.dev}/lib/pkgconfig"
    "${pkgs.zlib.dev}/lib/pkgconfig"
    "${pkgs.libayatana-appindicator.dev}/lib/pkgconfig"
    "${pkgs.libayatana-indicator}/lib/pkgconfig"
    "${pkgs.libdbusmenu-gtk3}/lib/pkgconfig"
    "${pkgs.ayatana-ido}/lib/pkgconfig"
    "${pkgs.gobject-introspection.dev}/lib/pkgconfig"
  ];

  # LIBRARY_PATH for linker (from configuration-cleaned.nix)
  libraryPath = lib.concatStringsSep ":" [
    "${pkgs.zlib}/lib"
    "${pkgs.openssl.out}/lib"
    "${pkgs.glib.out}/lib"
    "${pkgs.gtk3}/lib"
    "${pkgs.cairo}/lib"
    "${pkgs.pango.out}/lib"
    "${pkgs.gdk-pixbuf}/lib"
    "${pkgs.harfbuzz}/lib"
    "${pkgs.atk}/lib"
    "${pkgs.webkitgtk_4_1}/lib"
    "${pkgs.libsoup_3}/lib"
    "${pkgs.alsa-lib}/lib"
    "${pkgs.libayatana-appindicator}/lib"
    "${pkgs.xdotool}/lib"
  ];

  # LD_LIBRARY_PATH for runtime (from configuration-cleaned.nix)
  ldLibraryPath = lib.concatStringsSep ":" [
    "${pkgs.libayatana-appindicator}/lib"
    "${pkgs.gtk3}/lib"
    "${pkgs.webkitgtk_4_1}/lib"
    "${pkgs.glib.out}/lib"
  ];

  # CPATH for C compiler includes (from configuration-cleaned.nix)
  cpath = lib.concatStringsSep ":" [
    "${pkgs.openssl.dev}/include"
    "${pkgs.glib.dev}/include"
    "${pkgs.gtk3.dev}/include"
    "${pkgs.zlib.dev}/include"
  ];

in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # ── Core utilities (system-base.nix) ──
    vim
    wget
    curl
    git
    htop
    tree
    unzip
    zip

    # ── Network tools (system-base.nix) ──
    nmap
    nettools
    dig
    traceroute

    # ── System monitoring (system-base.nix) ──
    lsof
    iotop
    ncdu

    # ── Shell (cli-tools.nix) ──
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    starship

    # ── AI coding agents ──
    opencode

    # ── Modern CLI tools (cli-tools.nix) ──
    fzf
    bat
    eza
    ripgrep
    fd
    delta
    duf
    dust
    procs
    sd
    tokei
    hyperfine
    tealdeer
    gh
    jq

    # ── Process management (home-manager/packages.nix) ──
    mprocs

    # ── Terminal multiplexer ──
    tmux

    # ── Editor (editor-declarative.nix, home-manager/neovim.nix) ──
    neovim

    # ── Language runtimes (cli-tools.nix, home-manager/packages.nix) ──
    bun
    nodejs
    python312
    cargo
    rustc
    rustup

    # ── Language servers (editor-declarative.nix) ──
    lua-language-server
    nil
    nodePackages.typescript-language-server
    pyright
    rust-analyzer
    gopls

    # ── Formatters & linters (editor-declarative.nix) ──
    nixpkgs-fmt
    black
    nodePackages.prettier
    rustfmt
    gofumpt

    # ── Build tools (cli-tools.nix, editor-declarative.nix) ──
    pkg-config
    cmake
    gnumake
    gcc

    # ── Docker tools (docker.nix) ──
    docker
    docker-compose

    # ── Dev libraries: OpenSSL, zlib, LLVM (cli-tools.nix) ──
    openssl
    openssl.dev
    zlib
    zlib.dev
    llvmPackages.libclang
    llvmPackages.clang
    clang

    # ── GTK / WebKit core (cli-tools.nix) ──
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

    # ── HTTP library (cli-tools.nix) ──
    libsoup_3
    libsoup_3.dev

    # ── System tray support (cli-tools.nix) ──
    libayatana-appindicator
    libayatana-appindicator.dev

    # ── X11 dependencies (cli-tools.nix) ──
    libx11
    libxcursor
    libxrandr
    libxi
    libxcb
    libxext
    libxfixes
    libxcomposite
    libxdamage
    libxinerama
    libxtst
    libxrender
    xorg.xorgserver

    # ── Wayland (cli-tools.nix) ──
    wayland
    libxkbcommon

    # ── GTK accessibility & integration (cli-tools.nix) ──
    at-spi2-core
    at-spi2-atk
    atk
    atkmm
    dbus
    fribidi

    # ── Automation / misc libs (cli-tools.nix) ──
    xdotool
    libepoxy
    libpng
    pixman

    # ── Playwright browser dependencies (cli-tools.nix) ──
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

    # ── GStreamer (cli-tools.nix) ──
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav

    # ── Audio (cli-tools.nix) ──
    alsa-lib

    # ── SVG support (cli-tools.nix) ──
    librsvg
    librsvg.dev

    # ── Tauri build tools (cli-tools.nix) ──
    file
    patchelf
    squashfsTools
    dpkg
    rpm
    flatpak-builder

    # ── Notification support (cli-tools.nix) ──
    libnotify

    # ── Fonts for rendering (cli-tools.nix) ──
    noto-fonts
    noto-fonts-color-emoji
    liberation_ttf
    freefont_ttf
    wqy_zenhei

    # ── Nerd Fonts (cli-tools.nix) ──
    nerd-fonts._0xproto
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.meslo-lg
    nerd-fonts.caskaydia-cove
    nerd-fonts.iosevka
    nerd-fonts.sauce-code-pro
  ];

  shellHook = ''
    # LIBCLANG path for Rust bindgen
    export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib"

    # PKG_CONFIG_PATH for all dev libraries
    export PKG_CONFIG_PATH="${pkgConfigPath}''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

    # Library path for linker
    export LIBRARY_PATH="${libraryPath}''${LIBRARY_PATH:+:$LIBRARY_PATH}"

    # Runtime library path
    export LD_LIBRARY_PATH="${ldLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    # C compiler include paths for native builds
    export CPATH="${cpath}''${CPATH:+:$CPATH}"

    # Shell
    export SHELL="${pkgs.zsh}/bin/zsh"

    # PATH additions
    export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"

    # Playwright configuration — nix-ld patches downloaded browser binaries automatically
    export PLAYWRIGHT_BROWSERS_PATH="$HOME/.cache/ms-playwright"
    export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS="true"

    # Auto-install Playwright browsers if the project needs them
    if [ -f "node_modules/playwright-core/browsers.json" ]; then
      EXPECTED_REV=$(${pkgs.jq}/bin/jq -r '.browsers[] | select(.name == "chromium") | .revision' node_modules/playwright-core/browsers.json 2>/dev/null)
      if [ -n "$EXPECTED_REV" ] && [ ! -f "$PLAYWRIGHT_BROWSERS_PATH/chromium-$EXPECTED_REV/INSTALLATION_COMPLETE" ]; then
        echo "Playwright chromium-$EXPECTED_REV missing — installing browsers..."
        npx playwright install
      fi
    fi

    # Docker BuildKit
    export DOCKER_BUILDKIT="1"
    export COMPOSE_DOCKER_CLI_BUILD="1"

    # Source container config files if they exist
    [ -f "$HOME/.config/container/env" ] && source "$HOME/.config/container/env"
    [ -f "$HOME/.config/container/rc" ] && source "$HOME/.config/container/rc"
  '';
}
