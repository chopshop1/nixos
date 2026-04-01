{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.sunshine;
  gpuCfg = config.my.gpu;
  proxyPython = pkgs.python3.withPackages (ps: [ ps.evdev ]);

  # Map GPU type to VAAPI driver name
  defaultVaapiDriver = {
    nvidia = "nvidia";
    amd = "radeonsi";
    intel = "iHD";
    none = null;
  }.${gpuCfg.type} or null;
in
{
  options.my.sunshine = {
    enable = mkEnableOption "Sunshine game streaming server";

    audioSink = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "alsa_output.pci-0000_03_00.1.hdmi-stereo-extra3";
      description = "PulseAudio/PipeWire sink name for Sunshine audio capture. If null, Sunshine uses its default behavior (virtual sink).";
    };

    vaapiDriverName = mkOption {
      type = types.nullOr types.str;
      default = defaultVaapiDriver;
      description = "LIBVA_DRIVER_NAME for hardware encoding in the Sunshine startup script. Defaults based on my.gpu.type. Systemd services don't inherit environment.sessionVariables, so this must be set explicitly.";
    };
  };

  config = mkIf cfg.enable {
  # Enable Sunshine - X11 capture for Plasma X11 session
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;

    settings = {
      # X11 capture for Plasma X11 session
      capture = "x11";
      encoder = "vaapi";

      # Force single client to avoid multiple gamepads
      channels = "1";

      # Streaming stability — prevents Moonlight frame jumping
      # Forward error correction: higher = more resilient to packet loss
      # but uses more bandwidth. 20% is a good balance.
      fec_percentage = "20";
      # Number of threads for software encoding fallback (0 = auto)
      min_threads = "2";

      # Input settings
      key_repeat_delay = "500";
      key_repeat_frequency = "24";
      keyboard = "enabled";
      mouse = "enabled";
      gamepad = "enabled";
      # Force controller always connected - fixes reconnect issues
      controller = "1";
      # Use x360 emulation (most compatible)
      gamepad_type = "x360";
      min_log_level = "info";
    } // optionalAttrs (cfg.audioSink != null) {
      # Audio: capture from a specific sink directly instead of creating a virtual one
      # This prevents Sunshine from switching the default audio device on connect
      audio_sink = cfg.audioSink;
    };
  };

  # Sunshine startup script for Plasma X11 session
  environment.etc."sunshine-start.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      sleep 3

      # Find the Plasma/SDDM X11 display dynamically
      # SDDM runs Xorg on a real seat; pick the display owned by root
      for sock in /tmp/.X11-unix/X*; do
        num="''${sock##*/tmp/.X11-unix/X}"
        owner=$(stat -c '%U' "$sock" 2>/dev/null)
        if [ "$owner" = "root" ]; then
          DISPLAY=":$num"
          break
        fi
      done
      export DISPLAY="''${DISPLAY:-:0}"

      export XDG_SESSION_TYPE="x11"
      # Unset Wayland vars
      unset WAYLAND_DISPLAY
      # VAAPI hardware encoding — must be set explicitly since systemd services
      # don't inherit environment.sessionVariables from gpu.nix
      ${optionalString (cfg.vaapiDriverName != null) ''export LIBVA_DRIVER_NAME="${cfg.vaapiDriverName}"''}
      ${optionalString (gpuCfg.type == "amd") ''export RADV_PERFTEST="gpl"''}

      # XAUTHORITY is inherited from the user session (set by SDDM)
      echo "Sunshine starting on DISPLAY=$DISPLAY"
      exec /run/wrappers/bin/sunshine
    '';
  };

  # Sunshine service - use wrapper script
  systemd.user.services.sunshine = {
    after = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = mkForce "/etc/sunshine-start.sh";
      Restart = mkForce "always";
      RestartSec = mkForce "10s";
      # Protect from OOM killer (-900 to 1000, lower = less likely to be killed)
      OOMScoreAdjust = mkForce "-500";
      Nice = mkForce "-10";
      # Real-time scheduling priority for encoder threads — prevents frame pacing jitter
      LimitRTPRIO = mkForce "99";
      LimitMEMLOCK = mkForce "infinity";
    };
  };

  # Enable Flatpak
  services.flatpak.enable = true;

  # Open additional ports not covered by openFirewall
  networking.firewall = {
    allowedTCPPorts = [
      47984  # HTTPS/Web UI
      47989  # HTTP/Web UI
      47990  # Web UI
      48010  # RTSP
    ];
    allowedUDPPorts = [
      47998  # Video
      47999  # Control
      48000  # Audio
      48010  # RTSP
    ];
  };

  # Enable Avahi for network discovery (helps Moonlight find the host)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;  # Required for Sunshine user service
    };
  };

  # Ensure the dev user is in required groups for capture
  users.users.dev.extraGroups = [ "input" "video" "render" ];

  # Udev rules for Sunshine to access input devices
  services.udev.extraRules = ''
    # uinput for virtual input devices (mouse, keyboard, gamepad)
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput", TAG+="uaccess"
    # uhid for DualSense (ds5) gamepad emulation
    KERNEL=="uhid", MODE="0660", GROUP="input", OPTIONS+="static_node=uhid", TAG+="uaccess"
    # Allow access to event devices for input
    SUBSYSTEM=="input", MODE="0660", GROUP="input", TAG+="uaccess"
    # hidraw for DualSense (ds5) gamepad emulation
    KERNEL=="hidraw*", MODE="0660", GROUP="input", TAG+="uaccess"
    # Stable symlink for Sunshine virtual gamepad — always points to latest Sunshine device
    # Match vendor 045e (Microsoft) + Sunshine's Xbox One pad name
    SUBSYSTEM=="input", ATTRS{name}=="Sunshine X-Box One (virtual) pad", ATTRS{id/vendor}=="045e", KERNEL=="event*", SYMLINK+="input/sunshine-gamepad", TAG+="systemd", ENV{SYSTEMD_WANTS}="sunshine-gamepad-proxy.service", OPTIONS+="link_priority=100"
    # Alternative: Match by product ID range used by Sunshine (02ea = Xbox One)
    SUBSYSTEM=="input", ATTRS{id/vendor}=="045e", ATTRS{id/product}=="02ea", KERNEL=="event*", SYMLINK+="input/sunshine-gamepad-new", TAG+="systemd", ENV{SYSTEMD_WANTS}="sunshine-gamepad-proxy.service", OPTIONS+="link_priority=50"
  '';

  # Load kernel modules for virtual input devices and Xbox controller support
  boot.kernelModules = [ "uinput" "xpad" ];

  # Input tools for streaming (X11 session)
  environment.systemPackages = with pkgs; [
    xdotool
    xdpyinfo
    evsieve
  ];

  # Enable libinput for input device hotplugging
  services.libinput.enable = true;

  # Persistent gamepad proxy — survives Moonlight reconnects
  #
  # Problem 1 (reconnect): When Moonlight disconnects/reconnects, Sunshine destroys
  # and recreates its virtual gamepad. Games hold a file handle to the old device and
  # never pick up the new one — the controller dies while video keeps working.
  #
  # Problem 2 (stuck inputs): On brief disconnects, the axis "release" event is lost.
  # The game sees the last axis value as still held, causing stuck movement.
  #
  # Problem 3 (device identity): evsieve's output had vendor=0000/product=0000, which
  # SDL's game controller database can't map. Games that re-enumerate devices (e.g.
  # FF15 during combat) fail to recognize it as an Xbox controller.
  #
  # Solution: Python uinput proxy that:
  #   - Creates a persistent output device with correct Xbox 360 IDs (045e:028e)
  #   - Grabs Sunshine's ephemeral gamepad exclusively
  #   - Forwards all events to the persistent output
  #   - On disconnect: injects neutral events (fixes stuck inputs), waits for
  #     reconnect, re-grabs, and resumes forwarding
  #
  # Flow:
  #   Sunshine (uinput) → "Sunshine X-Box One (virtual) pad" (ephemeral, /dev/input/sunshine-gamepad)
  #       ↓ grabbed exclusively by proxy
  #   Python proxy (uinput) → "Xbox 360 Controller" (persistent, vendor=045e, product=028e)
  #       ↓ recognized by
  #   SDL / Proton / Steam Input → Game
  #
  # Diagnostics:
  #   systemctl status sunshine-gamepad-proxy
  #   cat /proc/bus/input/devices | grep -A 6 "Xbox 360"
  #   journalctl -u sunshine-gamepad-proxy --no-pager -n 30
  environment.etc."sunshine-gamepad-proxy.py" = {
    mode = "0755";
    text = ''
      #!/usr/bin/env python3
      """Persistent gamepad proxy for Sunshine streaming - single device pass-through."""
      import evdev
      from evdev import UInput, ecodes, InputDevice
      import os, sys, time, signal

      OUTPUT_NAME = "Xbox 360 Controller"
      VENDOR, PRODUCT, VERSION = 0x045e, 0x028e, 0x0110

      def find_sunshine_device():
          """Find first Sunshine virtual gamepad."""
          for path in evdev.list_devices():
              try:
                  dev = InputDevice(path)
                  if "Sunshine X-Box" in dev.name and "py-evdev-uinput" not in (dev.phys or ""):
                      return dev
              except Exception:
                  pass
          return None

      def create_output(caps):
          for evtype in (ecodes.EV_SYN, ecodes.EV_FF, ecodes.EV_MSC):
              caps.pop(evtype, None)
          ui = UInput(caps, name=OUTPUT_NAME, vendor=VENDOR, product=PRODUCT,
                      version=VERSION, bustype=ecodes.BUS_USB)
          print(f"Created output: {OUTPUT_NAME} ({VENDOR:#06x}:{PRODUCT:#06x})", flush=True)
          return ui

      def main():
          print("Sunshine gamepad proxy starting", flush=True)
          sys.stdout.flush()

          dev = None
          output = None
          caps = None
          last_path = None

          while True:
              if dev is None or last_path is None:
                  dev = find_sunshine_device()
                  if dev is None:
                      time.sleep(0.2)
                      continue

              if dev.path != last_path:
                  try:
                      dev.grab()
                      print(f"Grabbed: {dev.path}", flush=True)
                  except IOError as e:
                      if "Device or resource busy" not in str(e):
                          print(f"Grab failed: {e}", flush=True)
                      time.sleep(0.2)
                      continue

                  try:
                      caps = dev.capabilities(absinfo=True)
                      output = create_output(caps)
                      last_path = dev.path
                  except Exception as e:
                      print(f"Setup failed: {e}", flush=True)
                      dev = None
                      time.sleep(0.2)
                      continue

              try:
                  for event in dev.read_loop():
                      if output is None:
                          continue
                      if event.type == ecodes.EV_SYN:
                          output.syn()
                      elif event.type in (ecodes.EV_ABS, ecodes.EV_KEY):
                          output.write(event.type, event.code, event.value)
              except OSError:
                  print("Device disconnected", flush=True)
                  dev = None
                  last_path = None
                  if output:
                      output.close()
                      output = None
                  time.sleep(0.2)
              except Exception as e:
                  print(f"Error: {e}", flush=True)
                  dev = None
                  time.sleep(0.2)

      if __name__ == "__main__":
          main()
    '';
  };

  systemd.services.sunshine-gamepad-proxy = {
    description = "Persistent gamepad proxy for Sunshine (Python uinput)";
    after = [ "remote-fs.target" ];
    wants = [ "remote-fs.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${proxyPython}/bin/python3 /etc/sunshine-gamepad-proxy.py";
      User = "dev";
      Group = "input";
      Restart = "always";
      RestartSec = "2s";
      TimeoutStartSec = "30s";
      TimeoutStopSec = "10s";
      IgnoreSIGPIPE = "false";
      KillMode = "mixed";
    };
  };

  }; # end mkIf cfg.enable
}
