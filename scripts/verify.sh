#!/usr/bin/env bash
set -euo pipefail

HOST="devbox"
USER_NAME="devuser"
EXPECT_PASSWORD_AUTH=0
SKIP_DOCKER_RUN=0

usage() {
  cat <<USAGE
Usage: ${0##*/} [--host HOSTNAME] [--user USERNAME] [--expect-password-auth] [--skip-docker-run]

Run post-install validation checks for the devbox configuration.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST="$2"
      shift 2
      ;;
    --user)
      USER_NAME="$2"
      shift 2
      ;;
    --expect-password-auth)
      EXPECT_PASSWORD_AUTH=1
      shift
      ;;
    --skip-docker-run)
      SKIP_DOCKER_RUN=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

failures=()

run_check() {
  local desc="$1"
  local cmd="$2"
  if bash -o pipefail -c "$cmd" >/dev/null 2>&1; then
    printf "[OK]    %s\n" "$desc"
  else
    printf "[FAIL]  %s\n" "$desc" >&2
    failures+=("$desc")
  fi
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_check "AI CLI provisioning" "\"$REPO_ROOT/scripts/provision-ai-cli.sh\""
run_check "AI CLI provisioning idempotent" "\"$REPO_ROOT/scripts/provision-ai-cli.sh\""

run_check "sshd service active" "systemctl is-active --quiet sshd"
run_check "SSH listening on 22/tcp" "ss -lnpt | grep -q ':22 '"
run_check "SSH root login disabled" "sudo sshd -T | grep -qi 'permitrootlogin no'"

if [[ $EXPECT_PASSWORD_AUTH -eq 1 ]]; then
  run_check "Password authentication enabled" "sudo sshd -T | grep -qi 'passwordauthentication yes'"
else
  run_check "Password authentication disabled" "sudo sshd -T | grep -qi 'passwordauthentication no'"
fi

run_check "Default shell is zsh" "getent passwd '$USER_NAME' | cut -d: -f7 | grep -q 'zsh'"
run_check "Oh My Zsh initialized" "zsh -ic 'echo $ZSH' | grep -q 'oh-my-zsh'"
run_check "npm prefix exported" "zsh -ic 'npm config get prefix' | grep -q \"$HOME/.npm-global\""
run_check "npm bin on PATH" "zsh -ic 'echo $PATH' | tr ':' '\n' | grep -q \"$HOME/.npm-global/bin\""

run_check "node available" "node -v"
run_check "npm available" "npm -v"
run_check "bun available" "bun --version"
run_check "rustc available" "rustc --version"
run_check "cargo available" "cargo --version"
run_check "go available" "go version"
run_check "python3 available" "python3 --version"

run_check "Neovim available" "nvim --version"
run_check "NvChad init.lua present" "test -f $HOME/.config/nvim/init.lua"
run_check "Neovim headless check" "nvim --headless '+qall'"

run_check "User in docker group" "getent group docker | grep -q '$USER_NAME'"
run_check "docker info" "docker info"

if [[ $SKIP_DOCKER_RUN -eq 0 ]]; then
  run_check "docker hello-world" "docker run --rm hello-world"
fi

run_check "docker compose version" "docker compose version || docker-compose version"

run_check "claude CLI" "command -v claude"
run_check "claude --help" "claude --help"
run_check "codex CLI or replacement" "command -v codex || command -v openai"
run_check "codex/help output" "(codex -h || openai -h)"

flake_arg=$(printf '%q' "${REPO_ROOT}#${HOST}")
run_check "nixos-rebuild dry-run clean" "sudo nixos-rebuild dry-run --flake ${flake_arg} 2>&1 | tee >(grep -q '0 to rebuild' >/dev/null) >/dev/null"

if [[ ${#failures[@]} -gt 0 ]]; then
  printf '\nFailures (%d):\n' "${#failures[@]}" >&2
  for f in "${failures[@]}"; do
    printf ' - %s\n' "$f" >&2
  done
  exit 1
fi

printf '\nAll checks passed.\n'
