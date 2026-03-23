# Lessons Learned

## Sunshine Black Screen: Display Mismatch (2026-02-22)

### What happened

Moonlight connected to Sunshine but showed a black screen. Plasma desktop was running fine locally.

### Root cause

Two X11 displays existed simultaneously:

- `:0` — Sway headless XWayland (dark background, nothing on it)
- `:1` — SDDM/Plasma X server (actual desktop)

`sunshine-start.sh` hardcoded `DISPLAY=:0`, so Sunshine captured the empty Sway session instead of Plasma.

The `sway-headless.nix` module started before SDDM and grabbed `:0` first. SDDM's Xorg then fell back to `:1`.

### Fix

1. Removed `sway-headless.nix` from imports (wasn't serving a purpose with Plasma active)
2. Replaced hardcoded `DISPLAY=:0` with dynamic detection — finds the root-owned X socket in `/tmp/.X11-unix/`

### Rules to prevent recurrence

- **Never hardcode DISPLAY numbers.** X display assignment depends on startup order and is not deterministic when multiple X servers exist.
- **Don't run multiple X/Wayland compositors unless each has an explicit purpose.** Two compositors = two displays = confusion about which one Sunshine captures.
- **When debugging Sunshine black screen:** check `journalctl --user -u sunshine` for the `Streaming display:` line. If it says `HEADLESS-1` instead of a real output like `HDMI-A-0`, Sunshine is on the wrong display.
- **Quick diagnostic commands:**
  ```bash
  # What X displays exist and who owns them
  ls -la /tmp/.X11-unix/

  # What display is Plasma/kwin actually using
  tr '\0' '\n' < /proc/$(pgrep kwin)/environ | grep DISPLAY

  # What display is Sunshine using
  journalctl --user -u sunshine | grep "Streaming display"
  ```
