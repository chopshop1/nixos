{ config, pkgs, lib, ... }:

let
  # Ensures Playwright browsers are installed in the writable cache.
  # Nix-ld patches the downloaded binaries automatically.
  playwright-ensure-browsers = pkgs.writeShellScriptBin "playwright-ensure-browsers" ''
    BROWSERS_DIR="''${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}"

    # Find the expected browser revision from the project's installed playwright-core
    BROWSERS_JSON=$(find . -path "*/playwright-core/browsers.json" -not -path "*/worktrees/*" 2>/dev/null | head -1)
    if [ -z "$BROWSERS_JSON" ]; then
      echo "No playwright-core found in current project — skipping browser install"
      exit 0
    fi

    EXPECTED_REVISION=$(${pkgs.jq}/bin/jq -r '.browsers[] | select(.name == "chromium") | .revision' "$BROWSERS_JSON")
    if [ -z "$EXPECTED_REVISION" ]; then
      echo "Could not determine expected chromium revision"
      exit 1
    fi

    if [ -d "$BROWSERS_DIR/chromium-$EXPECTED_REVISION" ] && [ -f "$BROWSERS_DIR/chromium-$EXPECTED_REVISION/INSTALLATION_COMPLETE" ]; then
      exit 0
    fi

    echo "Installing Playwright browsers (need chromium-$EXPECTED_REVISION)..."
    npx playwright install
  '';
in
{
  # User-specific packages
  home.packages = with pkgs; [
    playwright-ensure-browsers
    # Browsers
    google-chrome  # Required for Claude Code browser integration

    # Development tools
    bun
    nodejs
    cargo
    rustc
    rust-analyzer

    # CLI tools
    fzf
    bat
    eza
    ripgrep
    fd
    mprocs

    # Desktop applications
    firefox
    thunderbird
    kitty
    obsidian

    # 1Password
    _1password-cli
    _1password-gui

    # Proton applications
    protonmail-desktop
    protonmail-bridge
    protonmail-bridge-gui
    proton-pass
    protonvpn-gui
    libsecret
    gnome-keyring

    # Development
    vscode
  ];
}
