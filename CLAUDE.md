# NixOS Configuration

## Git User Configuration

Git user name and email are configured via environment variables at activation time.

### First-time setup

1. Copy `.env.example` to `.env` and fill in your values
2. Run:

```bash
source .env && sudo -E nixos-rebuild switch --flake .#nixos-amd
```

### Subsequent rebuilds

Once set, your git config is preserved in `~/.config/git/local`. You can rebuild normally:

```bash
sudo nixos-rebuild switch --flake .#nixos-amd
```

### Updating git config

To change your git user info, either:
- Pass new environment variables to nixos-rebuild (as shown above)
- Edit `~/.config/git/local` directly
