{ config, pkgs, lib, ... }:

{
  # Plasma dark theme configuration
  # Uses activation script to set theme without conflicting with Plasma's config management
  #
  # This script runs after each home-manager switch and applies the Breeze Dark theme
  # if it's not already set. It uses Plasma's own tools to set the theme properly.

  home.activation.setPlasmaTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Only run if we're in a KDE/Plasma session or if Plasma tools are available
    if command -v ${pkgs.kdePackages.plasma-workspace}/bin/lookandfeeltool &> /dev/null; then

      # Check current theme setting in kdeglobals
      KDEGLOBALS="$HOME/.config/kdeglobals"
      CURRENT_THEME=""

      if [ -f "$KDEGLOBALS" ]; then
        CURRENT_THEME=$(grep -E "^LookAndFeelPackage=" "$KDEGLOBALS" 2>/dev/null | cut -d= -f2 || true)
      fi

      # If not already using breezedark, apply it
      if [ "$CURRENT_THEME" != "org.kde.breezedark.desktop" ]; then
        echo "Setting Plasma to Breeze Dark theme..."
        ${pkgs.kdePackages.plasma-workspace}/bin/lookandfeeltool -a org.kde.breezedark.desktop 2>/dev/null || true

        # Also ensure color scheme is set in kdeglobals if the file exists
        if [ -f "$KDEGLOBALS" ]; then
          # Use kwriteconfig6 if available for proper config updates
          if command -v ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 &> /dev/null; then
            ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group General --key ColorScheme BreezeDark
            ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group Icons --key Theme breeze-dark
          fi
        fi
      fi
    fi
  '';

  # KWin compositor settings for gaming performance
  # Suspend compositing when fullscreen windows are detected (e.g. Wine/Proton games).
  # Without this, KWin composites game frames through the desktop compositor,
  # adding latency and causing irregular frame pacing.
  home.activation.setKwinCompositorSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 &> /dev/null; then
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kwinrc --group Compositing --key WindowsBlockCompositing true
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kwinrc --group Compositing --key AllowTearing true
    fi
  '';
}
