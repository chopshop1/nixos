{ config, pkgs, lib, ... }:

{
  # Environment variables
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    SHELL = "${pkgs.zsh}/bin/zsh";
    # Playwright configuration for NixOS
    # Let Playwright download to writable cache, nix-ld patches binaries automatically
    PLAYWRIGHT_BROWSERS_PATH = "${config.home.homeDirectory}/.cache/ms-playwright";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };
}
