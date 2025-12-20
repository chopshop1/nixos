{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.cli-tools;
in
{
  options.my.cli-tools = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable enhanced CLI tools";
    };

    modern = mkOption {
      type = types.bool;
      default = true;
      description = "Enable modern CLI tool replacements (eza, bat, etc.)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Shell enhancements
      zsh-autosuggestions
      zsh-syntax-highlighting
      zsh-completions
      starship

      # Modern CLI tools
    ] ++ (if cfg.modern then with pkgs; [
      fzf       # Fuzzy finder
      bat       # Better cat
      eza       # Better ls
      ripgrep   # Better grep
      fd        # Better find
      delta     # Better diff
      duf       # Better df
      dust      # Better du
      procs     # Better ps
      sd        # Better sed
      tokei     # Code statistics
      hyperfine # Command-line benchmarking
      tealdeer  # Better tldr
      gh        # GitHub CLI
    ] else []);
  };
}