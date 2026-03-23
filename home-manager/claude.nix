{ config, pkgs, lib, ... }:

{
  # Claude Code configuration

  # Claude Code configuration - symlink to agents repo
  home.file.".config/claude".source = config.lib.file.mkOutOfStoreSymlink "/home/dev/work/agents";

  # Dotfiles repo - symlink individual claude config files (not the whole directory)
  # This preserves session data (history, projects, credentials) while syncing settings
  home.file.".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "/home/dev/work/dotfiles/claude/settings.json";
  home.file.".claude/hooks".source = config.lib.file.mkOutOfStoreSymlink "/home/dev/work/dotfiles/claude/hooks";
}
