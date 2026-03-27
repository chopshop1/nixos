# Dev Container

Portable development environment powered by Nix. Get the same tools everywhere -
Docker, NixOS, macOS, or any system with Nix installed.

## Quick Start (Docker)

```bash
# 1. Set up environment variables
cp .env.example .env
# Edit .env with your git name/email

# 2. Build and run
docker-compose up -d
docker-compose exec dev zsh
```

## Manual Docker Build

```bash
docker build -t dev-container .
docker run -it --rm \
  -v "$(pwd)/../:/workspace" \
  -v "$HOME/.ssh:/home/dev/.ssh:ro" \
  -e GIT_USER_NAME="Your Name" \
  -e GIT_USER_EMAIL="you@example.com" \
  --network host \
  dev-container
```

## Without Docker (nix develop)

If you have Nix installed with flakes enabled, skip Docker entirely:

```bash
# Enter the dev shell directly
cd devContainer
nix develop

# Or from the repo root
nix develop ./devContainer
```

This works on NixOS, macOS (with Nix), and any Linux distro with Nix installed.

## What's Included

| Category     | Tools                                              |
| ------------ | -------------------------------------------------- |
| Shell        | zsh, starship prompt, fzf, zsh-autosuggestions     |
| Editor       | neovim with LSP support                            |
| Multiplexer  | tmux (with resurrect/continuum), mprocs            |
| Languages    | Node.js, Bun, Python 3.12, Rust, Go               |
| CLI          | ripgrep, fd, bat, eza, delta, jq, gh               |
| Build        | gcc, cmake, pkg-config, cargo, rustc               |
| Containers   | docker, docker-compose                             |
| Network      | curl, wget, nmap, dig                              |

## Customization

### Add packages

Edit `shell.nix` and add packages to the `buildInputs` list:

```nix
buildInputs = with pkgs; [
  # ... existing packages ...
  your-new-package
];
```

Then rebuild the container or re-enter `nix develop`.

### Change shell configs

Edit files in `config/`:

- `config/zshrc` - Shell aliases, functions, key bindings
- `config/starship.toml` - Prompt theme
- `config/tmux.conf` - Tmux settings and plugins
- `config/gitconfig` - Git configuration
- `config/mprocs.yaml` - Process manager keybindings

Changes take effect on next container start (configs are symlinked).

## Environment Variables

Create a `.env` file (see `.env.example`):

```
GIT_USER_NAME=Your Name
GIT_USER_EMAIL=you@example.com
```

These are injected into the container and applied by `setup.sh` on startup.

## Architecture

```
devContainer/
├── flake.nix          # Nix flake (pins nixpkgs, defines dev shell + OCI image)
├── shell.nix          # All packages and environment variables
├── config/            # Dotfiles (symlinked into ~ at runtime)
├── Dockerfile         # Multi-stage build using nixos/nix base
├── docker-compose.yml # Volume mounts, env vars, networking
├── setup.sh           # Entrypoint: symlinks configs, sets git user, enters nix shell
└── .dockerignore      # Excludes .git and non-flake lockfiles
```

## Nix OCI Image (Alternative)

The flake also defines a pure Nix-built OCI image (no Dockerfile needed):

```bash
nix build .#container
docker load < result
docker run -it dev-container:latest
```

This produces a smaller, reproducible image but takes longer to build.
