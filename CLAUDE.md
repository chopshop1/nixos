# NixOS Configuration

## Important: secrets.nix

**NEVER commit `secrets.nix` to git.** This file contains sensitive information.

### Workflow

`secrets.nix` must be **staged** for Nix flake builds to work, but must **never be committed**.

- Keep it staged: `git add -f secrets.nix`
- When committing, stage files individually (`git add <file>`) instead of `git add .` or `git add -A`
- If you accidentally unstage it, re-stage with: `git add -f secrets.nix`

The file will appear in `git status` as staged - this is expected. Just don't include it in commits.
