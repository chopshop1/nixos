# Core language runtimes and terminal tooling shared by all hosts.
{ pkgs, lib, ... }: {
  # Allow unfree packages globally (e.g., NVIDIA proprietary driver)
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    nodejs_22
    bun
    rustc
    cargo
    go
    python3
    git
    neovim
    tmux
    htop
    curl
    wget
    jq
    gcc
    gnupg
    unzip
    iproute2
    lsof
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.tmux.enable = true;

  nix = {
    package = pkgs.nix;
    extraOptions = "experimental-features = nix-command flakes";
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
  };
}
