# Dev Container Flake
#
# Usage:
#   nix develop          - Enter local dev shell with all tools
#   nix build .#container - Build OCI container image (load with: docker load < result)
{
  description = "Dev Container - portable development environment";

  inputs = {
    # Pin to same nixpkgs as host system for maximum store cache hits
    nixpkgs.url = "github:NixOS/nixpkgs/addf7cf5f383a3101ecfba091b98d0a1263dc9b8";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    devShell = import ./shell.nix { inherit pkgs; };
    shellPkgs = (devShell.buildInputs or []) ++ (devShell.nativeBuildInputs or []);
  in {
    devShells.${system}.default = devShell;

    packages.${system}.container = pkgs.dockerTools.buildLayeredImage {
      name = "dev-container";
      tag = "latest";

      contents = shellPkgs ++ [
        pkgs.bashInteractive
        pkgs.coreutils
        pkgs.cacert
      ];

      extraCommands = ''
        # Create basic filesystem structure
        mkdir -p tmp home/dev etc
        chmod 1777 tmp

        # Copy config files if they exist
        ${pkgs.lib.optionalString (builtins.pathExists ./config) ''
          cp -r ${./config}/* home/dev/ 2>/dev/null || true
        ''}
      '';

      config = {
        Env = [
          "HOME=/home/dev"
          "USER=dev"
          "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          "TERM=xterm-256color"
        ];
        WorkingDir = "/home/dev";
        Entrypoint = [ "${pkgs.zsh}/bin/zsh" ];
      };
    };
  };
}
