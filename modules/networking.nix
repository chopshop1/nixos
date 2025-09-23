# Hostname, timezone, and networking defaults.
{ lib, userSettings, ... }: {
  networking.hostName = userSettings.hostname or "devbox";
  networking.networkmanager.enable = true;
  time.timeZone = userSettings.timezone or "UTC";
}
