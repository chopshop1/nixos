# NixOS Container Module - Declarative dev environment via systemd-nspawn
#
# This creates a lightweight NixOS container with all dev tools.
# It shares the host nix store (no duplication) and bind-mounts your workspace.
#
# Usage:
#   sudo nixos-container start devbox
#   sudo nixos-container root-login devbox
#   # Then: su - dev
#
# Or from host directly:
#   sudo nixos-container run devbox -- su - dev -c 'cd /workspace && nix develop'
#
# Import this module in your NixOS flake to enable.
{ config, pkgs, lib, ... }:

let
  cfg = config.my.devContainer;

  # Reuse the package list from shell.nix as system packages
  devPackages = with pkgs; [
    # ── Core utilities ──
    vim wget curl git htop tree unzip zip

    # ── Network tools ──
    nmap nettools dig traceroute

    # ── System monitoring ──
    lsof ncdu

    # ── Shell ──
    zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions starship

    # ── AI coding agents ──
    opencode

    # ── Modern CLI tools ──
    fzf bat eza ripgrep fd delta duf dust procs sd tokei hyperfine tealdeer gh jq

    # ── Process management ──
    mprocs

    # ── Terminal multiplexer ──
    tmux
    tmuxPlugins.sensible
    tmuxPlugins.yank
    tmuxPlugins.prefix-highlight
    tmuxPlugins.cpu
    tmuxPlugins.resurrect
    tmuxPlugins.continuum

    # ── Editor ──
    neovim

    # ── Language runtimes ──
    bun nodejs python312 cargo rustc

    # ── Language servers ──
    lua-language-server nil nodePackages.typescript-language-server
    pyright rust-analyzer gopls

    # ── Formatters & linters ──
    nixpkgs-fmt black nodePackages.prettier rustfmt gofumpt

    # ── Build tools ──
    pkg-config cmake gnumake gcc

    # ── Dev libraries ──
    openssl openssl.dev zlib zlib.dev
    llvmPackages.libclang llvmPackages.clang clang

    # ── GTK / WebKit ──
    webkitgtk_4_1 webkitgtk_4_1.dev
    gtk3 gtk3.dev glib glib.dev
    gobject-introspection gobject-introspection.dev
    cairo cairo.dev pango pango.dev
    gdk-pixbuf gdk-pixbuf.dev
    harfbuzz harfbuzz.dev graphite2 graphite2.dev
    freetype freetype.dev fontconfig fontconfig.dev

    # ── HTTP / System tray ──
    libsoup_3 libsoup_3.dev
    libayatana-appindicator libayatana-appindicator.dev

    # ── X11 ──
    libx11 libxcursor libxrandr libxi libxcb libxext
    libxfixes libxcomposite libxdamage libxinerama libxtst libxrender

    # ── Wayland ──
    wayland libxkbcommon

    # ── GTK accessibility ──
    at-spi2-core at-spi2-atk atk atkmm dbus fribidi

    # ── Misc libs ──
    xdotool libepoxy libpng pixman

    # ── Playwright browser deps ──
    cups libdrm mesa nspr nss gtk4 icu enchant libevent flite
    libjpeg lcms2 libmanette libopus libsecret libvpx libwebp
    woff2 libxml2 libxslt x264 libavif

    # ── GStreamer ──
    gst_all_1.gstreamer gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav

    # ── Audio / SVG ──
    alsa-lib librsvg librsvg.dev

    # ── Tauri build tools ──
    file patchelf squashfsTools dpkg rpm flatpak-builder

    # ── Misc ──
    libnotify

    # ── Fonts ──
    noto-fonts noto-fonts-color-emoji liberation_ttf freefont_ttf wqy_zenhei
    nerd-fonts._0xproto nerd-fonts.jetbrains-mono nerd-fonts.fira-code
    nerd-fonts.hack nerd-fonts.meslo-lg nerd-fonts.caskaydia-cove
    nerd-fonts.iosevka nerd-fonts.sauce-code-pro
  ];

  # Environment variables for dev builds
  devEnvironment = {
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    LIBRARY_PATH = lib.concatStringsSep ":" [
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
    PKG_CONFIG_PATH = lib.concatStringsSep ":" [
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
      "${pkgs.gobject-introspection.dev}/lib/pkgconfig"
    ];
    LD_LIBRARY_PATH = lib.concatStringsSep ":" [
      "${pkgs.libayatana-appindicator}/lib"
      "${pkgs.gtk3}/lib"
      "${pkgs.webkitgtk_4_1}/lib"
      "${pkgs.glib.out}/lib"
    ];
    CPATH = lib.concatStringsSep ":" [
      "${pkgs.openssl.dev}/include"
      "${pkgs.glib.dev}/include"
      "${pkgs.gtk3.dev}/include"
      "${pkgs.zlib.dev}/include"
    ];
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
    PLAYWRIGHT_BROWSERS_PATH = "/home/dev/.cache/ms-playwright";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };

in {
  options.my.devContainer = {
    enable = lib.mkEnableOption "NixOS dev container (systemd-nspawn)";

    workspacePath = lib.mkOption {
      type = lib.types.str;
      default = "/home/dev/work";
      description = "Host path to bind-mount as /workspace in the container";
    };

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Start the container automatically at boot";
    };

    privateNetwork = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Isolate container network (false = share host network)";
    };
  };

  config = lib.mkIf cfg.enable {
    containers.devbox = {
      autoStart = cfg.autoStart;
      ephemeral = false;
      privateNetwork = cfg.privateNetwork;

      # Share host nix store - no 11GB duplication
      bindMounts = {
        "/workspace" = {
          hostPath = cfg.workspacePath;
          isReadOnly = false;
        };
        "/home/dev/.ssh-host" = {
          hostPath = "/home/dev/.ssh";
          isReadOnly = true;
        };
      };

      config = { config, pkgs, ... }: {
        system.stateVersion = "25.05";

        # All dev packages available system-wide
        environment.systemPackages = devPackages;

        # Dev environment variables
        environment.variables = devEnvironment;

        # Enable flakes inside container
        nix.settings.experimental-features = [ "nix-command" "flakes" ];

        # Default shell: zsh
        programs.zsh.enable = true;

        # Dev user
        users.users.dev = {
          isNormalUser = true;
          home = "/home/dev";
          shell = pkgs.zsh;
          extraGroups = [ "wheel" ];
          initialPassword = "dev";
        };

        # Root shell: zsh
        users.users.root.shell = pkgs.zsh;

        # Passwordless sudo
        security.sudo.extraRules = [{
          users = [ "dev" ];
          commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
        }];

        # Tmux config (inline with Nix plugin paths, mirrors home-manager/tmux.nix)
        environment.etc."skel/.tmux.conf".text = ''
          # Default shell
          set-option -g default-shell /run/current-system/sw/bin/zsh

          # Source main config from dotfiles (shared with macOS)
          source-file ~/.config/tmux/dotfiles/tmux.conf

          # Plugins via Nix store (mirrors home-manager plugin loading)
          run-shell ${pkgs.tmuxPlugins.sensible.rtp}
          run-shell ${pkgs.tmuxPlugins.yank.rtp}
          run-shell ${pkgs.tmuxPlugins.prefix-highlight.rtp}
          run-shell ${pkgs.tmuxPlugins.cpu.rtp}

          # Resurrect (options must precede run-shell)
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-nvim 'session'
          run-shell ${pkgs.tmuxPlugins.resurrect.rtp}

          # Continuum (options must precede run-shell)
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
          run-shell ${pkgs.tmuxPlugins.continuum.rtp}
        '';

        # Clone nvim config repo after boot (runs as dev user with SSH keys)
        systemd.services.dev-nvim-clone = {
          description = "Clone nvim config for dev user";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = "dev";
            Group = "users";
            Environment = "GIT_SSH_COMMAND=${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new";
          };
          path = [ pkgs.git pkgs.openssh ];
          script = ''
            NVIM_DIR="/home/dev/.local/share/nvim-config"
            mkdir -p /home/dev/.local/share

            if [ ! -d "$NVIM_DIR/.git" ]; then
              git clone git@github.com:chopshop1/.nvim.git "$NVIM_DIR"
            else
              git -C "$NVIM_DIR" pull --ff-only 2>/dev/null || true
            fi
          '';
        };

        # Deploy config files to dev user home on activation
        system.activationScripts.devUserConfig.deps = [ "etc" ];
        system.activationScripts.devUserConfig.text = ''
          # Copy SSH keys from host bind-mount with correct ownership
          if [ -d /home/dev/.ssh-host ]; then
            mkdir -p /home/dev/.ssh
            cp -a /home/dev/.ssh-host/* /home/dev/.ssh/ 2>/dev/null || true
            chown -R dev:users /home/dev/.ssh
            chmod 700 /home/dev/.ssh
            chmod 600 /home/dev/.ssh/git /home/dev/.ssh/known_hosts 2>/dev/null || true
          fi

          DOTFILES_DIR="/workspace/dotfiles"
          NVIM_DIR="/home/dev/.local/share/nvim-config"

          if [ -d /home/dev ]; then
            # Tmux (Nix-generated with plugin paths — must be copied, not symlinked)
            cp -Lf /etc/skel/.tmux.conf /home/dev/.tmux.conf 2>/dev/null && chown dev:users /home/dev/.tmux.conf

            # Symlink configs from dotfiles bind-mount
            if [ -d "$DOTFILES_DIR" ]; then
              # Zsh
              ln -sf "$DOTFILES_DIR/zsh/zshrc" /home/dev/.zshrc

              # Starship
              mkdir -p /home/dev/.config
              ln -sf "$DOTFILES_DIR/starship/starship.toml" /home/dev/.config/starship.toml

              # Git
              mkdir -p /home/dev/.config/git
              ln -sf "$DOTFILES_DIR/git/gitconfig" /home/dev/.config/git/config

              # Mprocs
              mkdir -p /home/dev/.config/mprocs
              ln -sf "$DOTFILES_DIR/mprocs/mprocs.yaml" /home/dev/.config/mprocs/mprocs.yaml

              # Tmux dotfiles (shared config sourced by Nix-generated .tmux.conf)
              mkdir -p /home/dev/.config/tmux/dotfiles
              ln -sf "$DOTFILES_DIR/tmux/tmux.conf" /home/dev/.config/tmux/dotfiles/tmux.conf
              ln -sf "$DOTFILES_DIR/tmux/platform-nixos.conf" /home/dev/.config/tmux/platform-nixos.conf
              ln -sf "$DOTFILES_DIR/tmux/platform-macos.conf" /home/dev/.config/tmux/platform-macos.conf
              mkdir -p /home/dev/.local/bin
              for script in tmux-session-picker tmux-continuum-save tmux-cloudflare-deploy tmux-url-handler; do
                [ -f "$DOTFILES_DIR/tmux/$script" ] && ln -sf "$DOTFILES_DIR/tmux/$script" /home/dev/.local/bin/$script
              done

              # Claude config
              CLAUDE_DIR="/home/dev/.claude"
              mkdir -p "$CLAUDE_DIR"
              [ -f "$DOTFILES_DIR/claude/settings.json" ] && ln -sf "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json"
              [ -d "$DOTFILES_DIR/claude/hooks" ] && ln -sfn "$DOTFILES_DIR/claude/hooks" "$CLAUDE_DIR/hooks"
              [ -d "$DOTFILES_DIR/claude/commands" ] && ln -sfn "$DOTFILES_DIR/claude/commands" "$CLAUDE_DIR/commands"
              [ -f "$DOTFILES_DIR/claude/shared-CLAUDE.md" ] && ln -sf "$DOTFILES_DIR/claude/shared-CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
              [ -f "$DOTFILES_DIR/claude/statusline.sh" ] && ln -sf "$DOTFILES_DIR/claude/statusline.sh" "$CLAUDE_DIR/statusline.sh"
              [ -f "$DOTFILES_DIR/claude/statusline-parser.py" ] && ln -sf "$DOTFILES_DIR/claude/statusline-parser.py" "$CLAUDE_DIR/statusline-parser.py"
            fi

            # Nvim config symlink (mirrors home-manager/neovim.nix:36)
            ln -sfn "$NVIM_DIR" /home/dev/.config/nvim

            # Ensure proper ownership
            chown -R dev:users /home/dev/.config /home/dev/.local /home/dev/.claude 2>/dev/null || true
          fi

          # Deploy same configs to root
          if [ -d "$DOTFILES_DIR" ]; then
            ln -sf "$DOTFILES_DIR/zsh/zshrc" /root/.zshrc
            mkdir -p /root/.config
            ln -sf "$DOTFILES_DIR/starship/starship.toml" /root/.config/starship.toml
            mkdir -p /root/.config/tmux/dotfiles
            ln -sf "$DOTFILES_DIR/tmux/tmux.conf" /root/.config/tmux/dotfiles/tmux.conf
            ln -sf "$DOTFILES_DIR/tmux/platform-nixos.conf" /root/.config/tmux/platform-nixos.conf
            ln -sf "$DOTFILES_DIR/tmux/platform-macos.conf" /root/.config/tmux/platform-macos.conf
            mkdir -p /root/.local/bin
            for script in tmux-session-picker tmux-continuum-save tmux-cloudflare-deploy tmux-url-handler; do
              [ -f "$DOTFILES_DIR/tmux/$script" ] && ln -sf "$DOTFILES_DIR/tmux/$script" /root/.local/bin/$script
            done
          fi
          cp -Lf /etc/skel/.tmux.conf /root/.tmux.conf 2>/dev/null
          ln -sfn "$NVIM_DIR" /root/.config/nvim
        '';

        # Networking: use host DNS
        networking.useHostResolvConf = true;

        # Minimal services
        services.openssh.enable = false;
        documentation.enable = false;
      };
    };
  };
}
