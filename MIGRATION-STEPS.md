# Migration Steps

## Prerequisites

Your system needs flakes support enabled to use the new configuration.

## Step-by-Step Migration

### 1. Enable Flakes (Required First)

```bash
# This will enable flakes support in your current configuration
./enable-flakes.sh
```

This rebuilds your system with flakes enabled. This is required before you can use the new modular configuration.

### 2. Run Migration Script

After flakes are enabled, run:

```bash
./migrate.sh
```

This will:
- Create a full backup
- Test the new configuration
- Apply changes if you approve

### 3. Alternative Manual Steps

If you prefer to migrate manually:

```bash
# 1. Backup current configuration
cp -r /home/dev/nixos /home/dev/nixos-backup

# 2. Enable flakes first
sudo nixos-rebuild switch

# 3. Replace configuration files
cp flake-improved.nix flake.nix
cp configuration-cleaned.nix configuration.nix

# 4. Rebuild with new configuration
sudo nixos-rebuild switch --flake .#nixos
```

## Troubleshooting

### If "experimental features" error appears:
Run `./enable-flakes.sh` first to enable flakes support.

### If build fails:
1. Check the error message for missing dependencies
2. Review the backup at `/home/dev/nixos-backup-*`
3. You can rollback: `sudo nixos-rebuild switch --rollback`

### If Home Manager has issues:
The user configuration might need adjustment. Check `home-manager/dev.nix`

## Verification

After successful migration:
```bash
# Check flakes are working
nix flake show

# Check Docker
docker ps

# Check Neovim
nvim --version

# Check shell
echo $SHELL
```

## Files Changed

- `configuration.nix` → Cleaned and modularized
- `flake.nix` → New modular flake structure
- `home.nix` → Moved to `home-manager/dev.nix`
- Added 6 new modules in `modules/` directory

## Rollback

If needed, your backup is saved with timestamp. To rollback:
```bash
sudo nixos-rebuild switch --rollback
```

Or restore from backup:
```bash
cp -r /home/dev/nixos-backup-[timestamp]/* /home/dev/nixos/
sudo nixos-rebuild switch
```