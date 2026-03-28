{ config, pkgs, lib, ... }:

# Watchdog that detects a stuck HDA codec (common after GPU crashes/resets on AMD)
# and auto-recovers by reloading the snd_hda_intel kernel module.
#
# Detection: any ALSA PCM in RUNNING state with hw_ptr=0 and appl_ptr>0 means
# the hardware stopped consuming audio data while PipeWire is still writing.
{
  systemd.services.audio-recovery = {
    description = "HDMI audio codec crash recovery watchdog";
    after = [ "sound.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = let
        script = pkgs.writeShellScript "audio-recovery" ''
          set -euo pipefail
          STUCK=0
          for status in /proc/asound/card0/pcm*/sub0/status; do
            [ -f "$status" ] || continue
            STATE=$(${pkgs.gawk}/bin/awk '/^state:/ {print $2}' "$status")
            [ "$STATE" = "RUNNING" ] || continue
            HW_PTR=$(${pkgs.gawk}/bin/awk '/^hw_ptr/ {print $3}' "$status")
            APPL_PTR=$(${pkgs.gawk}/bin/awk '/^appl_ptr/ {print $3}' "$status")
            if [ "$HW_PTR" = "0" ] && [ "$APPL_PTR" != "0" ]; then
              STUCK=1
              break
            fi
          done

          [ "$STUCK" = "1" ] || exit 0

          echo "audio-recovery: stuck HDA codec detected (hw_ptr=0), recovering..."

          # Stop user PipeWire to release the ALSA device
          RUNTIME_DIR="/run/user/1001"
          ${pkgs.sudo}/bin/sudo -u dev XDG_RUNTIME_DIR=$RUNTIME_DIR \
            ${pkgs.systemd}/bin/systemctl --user stop \
              pipewire.socket pipewire-pulse.socket pipewire pipewire-pulse wireplumber \
            || true

          sleep 1

          # Reload the kernel driver
          ${pkgs.kmod}/bin/modprobe -r snd_hda_intel
          sleep 2
          ${pkgs.kmod}/bin/modprobe snd_hda_intel

          sleep 2

          # Restart PipeWire
          ${pkgs.sudo}/bin/sudo -u dev XDG_RUNTIME_DIR=$RUNTIME_DIR \
            ${pkgs.systemd}/bin/systemctl --user start \
              pipewire.socket pipewire-pulse.socket wireplumber

          echo "audio-recovery: codec recovered successfully"
        '';
      in "${script}";
    };
  };

  systemd.timers.audio-recovery = {
    description = "Check for stuck HDMI audio codec every 10s";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "10s";
      AccuracySec = "5s";
    };
  };
}
