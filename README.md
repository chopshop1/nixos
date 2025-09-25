# nixos devbox

Terminal-only, reproducible NixOS environment preloaded with development tooling, Neovim (NvChad), Docker, and CLI AI assistants.

## Quick start (fresh machine)

1. **Install NixOS base system**
   - Boot the latest minimal NixOS ISO.
   - Partition/disks as desired, mount the target root filesystem at `/mnt`.
   - Run `nixos-generate-config --root /mnt` to create an initial hardware profile.
   - Copy `hardware-configuration.nix` from `/mnt/etc/nixos/` into `hosts/devbox/hardware-configuration.nix` in this repository, committing the host-specific version.

2. **Configure host specifics**
   - Edit `hosts/devbox/user-settings.nix` to set your hostname, username, timezone, and **SSH public key**. Providing a key disables password login; if left `null`, the user password defaults to `changeme` and is forced to reset on first login.
   - Update the `root`/`boot` blocks in the same file with the device paths, labels, or UUIDs for your disks. Leave `boot.device = null` when you do not mount a separate EFI system partition.
   - Adjust the `bootLoader` block: leave `type = null` to supply your own bootloader, set `type = "systemd-boot"` when you mount an EFI partition, or set `type = "grub"` and `device` to the target disk (e.g. `/dev/nvme0n1`) for BIOS installs.
   - Flip `virtualization.enableKVM` to `true` only if SVM/virtualization is enabled in firmware; otherwise leave it `false` to avoid loading `kvm-amd`.
   - Optionally adjust modules or add overlays under `modules/` for custom needs.

3. **Install using flakes**
   - From the repo root (copied into the installer environment), run:
     ```bash
     sudo nixos-install --flake .#devbox
     ```
   - After the install completes, reboot into the new system.

4. **First login & provisioning**
   - Log in as the configured `${username}` (default `devuser`).
   - Run the AI tooling bootstrap:
     ```bash
     ./scripts/provision-ai-cli.sh
     ```
   - Export your API keys (e.g., in `~/.zshrc`):
     ```bash
     export ANTHROPIC_API_KEY=...
     export OPENAI_API_KEY=...
     ```
   - Launch `nvim` to allow NvChad to perform its initial sync (headless check runs automatically in `verify.sh`).

5. **Verify definition of done**
   - From the repo root as `${username}`:
     ```bash
     ./scripts/verify.sh --host devbox
     ```
   - The script validates SSH hardening, shells, language runtimes, Docker, AI CLIs, and idempotency.

### Legacy (non-flake) install

If flakes are unavailable, copy `legacy/configuration.nix` and its companion modules into `/etc/nixos/` and run `sudo nixos-rebuild switch`. Update `legacy/configuration.nix` with the same `hosts/devbox/user-settings.nix` values and replace the placeholder hashes before use.

## Repository layout

- `flake.nix / flake.lock` – primary NixOS entrypoint.
- `modules/*.nix` – composable NixOS modules (base tooling, SSH, Docker, users, networking, editor, security).
- `modules/hardware-*.nix` – hardware defaults (storage mapping, AMD tuning) referenced by host definitions.
- `hosts/devbox/` – host configuration, hardware stub, and overridable user settings.
- `scripts/` – operational helpers (AI CLI provisioning, NvChad fallback installer, updates, verification).
- `legacy/` – single-file configuration fallback plus hardware stub.

## Updating, switching, and rollback

- Rebuild with current repo state:
  ```bash
  sudo nixos-rebuild switch --flake .#devbox
  ```
- Pull upstream nixpkgs/home-manager updates and apply:
  ```bash
  ./scripts/update.sh devbox
  ```
- Roll back to the previous generation if something breaks:
  ```bash
  sudo nixos-rebuild switch --rollback
  ```

## AI CLI provisioning details

`scripts/provision-ai-cli.sh` installs the latest published versions of:

- `@anthropic-ai/claude-code` (warns if unavailable and points to Anthropic guidance)
- `@openai/codex` **or** the official `openai` CLI when Codex is not published

The script creates/uses `~/.npm-global`, ensures the PATH adjustments live in `~/.zshrc`, and is safe to re-run (idempotent). When `@openai/codex` is missing, the script automatically installs the OpenAI CLI (`openai`) and prints usage hints; reruns simply update to the latest versions.

## NvChad management

Neovim is installed system-wide via Nix. NvChad is deployed declaratively through Home Manager. If you prefer a manual fallback, run `scripts/nvchad-install.sh` to clone/update NvChad into `~/.config/nvim` (the script refuses to overwrite non-git directories).

## Troubleshooting

- **SSH key missing during first build** – password authentication is enabled with password `changeme`, and the password is expired on first login (`chage -d 0`). Update `hosts/devbox/user-settings.nix` with an SSH key and rebuild to disable password login permanently.
- **Docker group membership** – after the first rebuild or user creation, log out/in so the `docker` group applies. `./scripts/verify.sh` confirms membership.
- **Docker hello-world pull failures** – re-run with network access or `./scripts/verify.sh --skip-docker-run` if offline (other checks still run).
- **NvChad sync issues** – run `nvim --headless "+Lazy sync" +qa` or `scripts/nvchad-install.sh` to force an update.
- **AI CLI auth errors** – ensure `ANTHROPIC_API_KEY` and `OPENAI_API_KEY` are exported in your shell or managed via a secrets store.
- **Virtualisation disabled in firmware** – leave `virtualization.enableKVM = false`; enabling it without SVM/AMD-V causes the kernel to log repeated `kvm_amd: SVM not supported` messages.

### Hardware/graphics configuration (hardware-agnostic defaults and AMD black screen)

- The config now separates hardware concerns:
  - `modules/hardware-cpu.nix` – generic firmware and microcode for both AMD/Intel; optional KVM module based on `virtualization.kvmVendor`.
  - `modules/kernel.nix` – kernel params, console log level, text-mode fallback.
  - `modules/graphics.nix` – OpenGL, optional video driver pinning, optional `amdgpu` in initrd, and Plymouth toggle.

- If you see a black screen with a blinking cursor on an AMD GPU after install:
  1. In `hosts/devbox/user-settings.nix`, set a minimal AMD-oriented graphics stanza:
     ```nix
     graphics = {
       enableOpenGL = true;
       driver = "amdgpu";        # Pin driver
       plymouthEnable = false;    # Keep splash disabled initially
       initrd = { amdgpu = true; }; # Enable early KMS if using encrypted root or if blank screen persists
     };
     ```
  2. Optionally add kernel params for visibility while debugging:
     ```nix
     kernel = {
       consoleLogLevel = 7;       # verbose boot
       initrdVerbose = true;
       params = [ "amd_pstate=active" ];
       # As a last resort only:
       # forceTextMode = true;    # adds nomodeset (disables KMS)
     };
     ```
  3. Rebuild and reboot:
     ```bash
     sudo nixos-rebuild switch --flake .#devbox
     sudo reboot
     ```
  4. Once stable, you can relax `consoleLogLevel` back to `4` and disable `initrdVerbose`.

- For virtualization on AMD, enable KVM only if SVM is enabled in firmware:
  ```nix
  virtualization = {
    enableKVM = true;
    kvmVendor = "amd"; # or "intel" on Intel machines
  };
  ```

## Development & contributions

- Format Nix files with `nix fmt` (formatter attr exported by the flake).
- Keep hardware-specific changes inside each host's `hardware-configuration.nix`.
- Avoid storing secrets; inject them at runtime via environment variables or secrets tooling.

## Example verify output

```
$ ./scripts/verify.sh --host devbox
[OK]    sshd service active
[OK]    SSH listening on 22/tcp
...
[OK]    codex -h
[OK]    nixos-rebuild dry-run clean
[OK]    provision-ai-cli idempotent

All checks passed.
```

## Docker smoke test

Build and load a privileged Docker image (for quick userland checks only):

```bash
./scripts/build-docker-image.sh
docker run --rm -it --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro devbox:latest
```

The script builds the `devbox-container` flake target via `nixos-generators`. The container runs systemd; SSH and Docker daemon are disabled, but language runtimes, zsh/Oh My Zsh, and NvChad match the bare-metal configuration. Run the container with `--privileged` so systemd can boot.

## Release notes

- Home Manager drives per-user configuration; NvChad is pinned through flake inputs for reproducibility.
- AI CLI tools are installed via npm into a user-local prefix; if `@openai/codex` is missing the official `openai` CLI is installed automatically instead.
- Password authentication is only enabled when no SSH key is supplied; the password expires immediately to enforce a change.
