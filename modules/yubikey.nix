{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.yubikey;
in
{
  options.my.yubikey = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable YubiKey support";
    };

    enablePam = mkOption {
      type = types.bool;
      default = false;
      description = "Enable PAM authentication with YubiKey (sudo, login)";
    };
  };

  config = mkIf cfg.enable {
    # Smart card daemon for PIV/OpenPGP card support
    services.pcscd.enable = true;

    # U2F/FIDO2 is now natively supported by udev (no config needed)

    # YubiKey personalization tools and utilities
    environment.systemPackages = with pkgs; [
      yubikey-manager      # ykman CLI tool
      yubikey-personalization # ykpersonalize tool
      yubico-piv-tool      # PIV smart card management
      yubioath-flutter     # OATH (TOTP/HOTP) authenticator + YubiKey management GUI
      pam_u2f              # PAM module for U2F
      libfido2             # FIDO2 library and tools
      age-plugin-yubikey   # Age encryption with YubiKey
    ];

    # GPG with smart card support
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = false;  # Set to true if you want YubiKey-based SSH auth
      pinentryPackage = pkgs.pinentry-qt;  # Qt pinentry for KDE
    };

    # Udev rules for YubiKey access without root
    services.udev.packages = with pkgs; [
      yubikey-personalization
    ];

    # Lock screen when YubiKey is removed (optional, disabled by default)
    # services.udev.extraRules = ''
    #   ACTION=="remove", ENV{ID_VENDOR_ID}=="1050", RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
    # '';

    # PAM configuration for YubiKey authentication
    security.pam.u2f = mkIf cfg.enablePam {
      enable = true;
      cue = true;  # Show "Please touch your YubiKey" message
      authFile = "/etc/u2f_mappings";  # Central auth file
    };

    # Add u2f to sudo and login if PAM is enabled
    security.pam.services = mkIf cfg.enablePam {
      sudo.u2fAuth = true;
      login.u2fAuth = true;
      sddm.u2fAuth = true;
    };
  };
}
