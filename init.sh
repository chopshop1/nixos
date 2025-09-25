nix-shell -p git

git pull

sudo nixos-rebuild switch --flake .#devbox