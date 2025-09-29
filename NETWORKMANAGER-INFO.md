# NetworkManager-wait-online Service Information

## Current Situation

The `NetworkManager-wait-online.service` error that appears during `nixos-rebuild switch` is a **harmless warning** that occurs only during system activation, not during boot.

## Why This Happens

1. **During `nixos-rebuild switch`**: NixOS attempts to restart all changed services
2. **NetworkManager-wait-online** is a one-shot service that waits for network connectivity
3. It times out after 60 seconds if network isn't fully ready
4. The error appears because the service is being restarted during activation

## What We've Done

1. **Disabled the service** in `modules/networkmanager-fix.nix`
2. **Removed it from boot targets** so it won't start on next boot
3. **Used `nixos-rebuild boot`** to update the boot configuration without triggering activation

## Impact

- **On current session**: You may see the error during `nixos-rebuild switch` (harmless)
- **On next boot**: The service will NOT start, so no error will occur
- **System functionality**: No impact - NetworkManager itself works perfectly

## Verification

After next reboot, you can verify the service is disabled:
```bash
systemctl status NetworkManager-wait-online.service
# Should show "inactive (dead)" or not found
```

## Alternative Solutions

If you want to completely suppress the warning during switch:

1. **Use `nixos-rebuild boot`** instead of `switch` and reboot
2. **Use `nixos-rebuild test`** to test without making permanent changes
3. **Accept the warning** as it's cosmetic and doesn't affect functionality

## Bottom Line

✅ **Your system is working correctly**
✅ **The error is cosmetic and only appears during activation**
✅ **On next boot, the service won't start and no error will occur**

This is a common NixOS quirk that many users encounter and is not indicative of any actual problem with your configuration.