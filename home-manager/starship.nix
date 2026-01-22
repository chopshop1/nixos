{ config, pkgs, lib, ... }:

{
  # Starship prompt - Tokyo Night theme (2025 trendy build)
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      # Code Editor Color Principles:
      # Purple (#8031f7): Keywords, functions → session icon, time
      # Pink (#d23d91): Strings, special → git branch
      # Cyan (#76e3ea): Types, constants, success → directory, staged, clean
      # Coral (#fc704f): Numbers, operators → modified
      # Red (#ff4445): Errors, deletions → errors, deleted
      # Light Purple (#b780ff): Comments → untracked, secondary info

      format = "[░▒▓](#5b8af7)[  ](bg:#5b8af7 fg:#1a1a2e)$os$directory[](fg:#5b8af7 bg:#3a3a5c)$git_branch$git_status$git_state[](fg:#3a3a5c bg:#2a2a4a)$c$rust$golang$nodejs$php$java$kotlin$haskell$python$bun[](fg:#2a2a4a bg:#1d1d3a)$docker_context$conda$aws[](fg:#1d1d3a bg:#1a1a2e)$time[ ](fg:#1a1a2e)$line_break$character";

      palette = "code_editor";

      os = {
        disabled = false;
        style = "bg:#5b8af7 fg:#1a1a2e";
        symbols = {
          Windows = "󰍲";
          Ubuntu = "󰕈";
          SUSE = "";
          Raspbian = "󰐿";
          Mint = "󰣭";
          Macos = "";
          Manjaro = "";
          Linux = "󰌽";
          Gentoo = "󰣨";
          Fedora = "󰣛";
          Alpine = "";
          Amazon = "";
          Android = "";
          Arch = "󰣇";
          Artix = "󰣇";
          CentOS = "";
          Debian = "󰣚";
          Redhat = "󱄛";
          RedHatEnterprise = "󱄛";
          NixOS = "";
        };
      };

      directory = {
        style = "fg:#ffffff bg:#5b8af7";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          Documents = "󰈙 ";
          Downloads = " ";
          Music = "󰝚 ";
          Pictures = " ";
          Developer = "󰲋 ";
          work = " ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:#3a3a5c";
        format = "[[ $symbol $branch ](fg:#DA7756 bg:#3a3a5c)]($style)";
      };

      git_status = {
        style = "bg:#3a3a5c";
        conflicted = "[!\${count}](bg:#3a3a5c fg:#ff4445) ";
        ahead = "[⇡\${count}](bg:#3a3a5c fg:#d23d91) ";
        behind = "[⇣\${count}](bg:#3a3a5c fg:#d23d91) ";
        diverged = "[⇕\${ahead_count}⇣\${behind_count}](bg:#3a3a5c fg:#fc704f) ";
        up_to_date = "[✓](bg:#3a3a5c fg:#3a3a5c)";
        untracked = "[?\${count}](bg:#3a3a5c fg:#8031f7) ";
        stashed = "[$\${count}](bg:#3a3a5c fg:#d23d91) ";
        modified = "[●\${count}](bg:#3a3a5c fg:#DA7756) ";
        staged = "[+\${count}](bg:#3a3a5c fg:#d23d91) ";
        renamed = "[»\${count}](bg:#3a3a5c fg:#d23d91) ";
        deleted = "[✘\${count}](bg:#3a3a5c fg:#ff4445) ";
        format = "[[($all_status$ahead_behind )](fg:#d23d91 bg:#3a3a5c)]($style)";
      };

      git_state = {
        style = "bg:#3a3a5c fg:#fc704f";
        format = "[[ $state($progress_current/$progress_total) ](bg:#3a3a5c fg:#fc704f)]($style)";
        rebase = "REBASING";
        merge = "MERGING";
        revert = "REVERTING";
        cherry_pick = "CHERRY-PICKING";
        bisect = "BISECTING";
        am = "AM";
        am_or_rebase = "AM/REBASE";
      };

      c = {
        symbol = " ";
        style = "bg:#2a2a4a";
        format = "[[ $symbol($version) ](fg:#b780ff bg:#2a2a4a)]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:#2a2a4a";
        format = "[[ $symbol($version) ](fg:#b780ff bg:#2a2a4a)]($style)";
      };

      golang = {
        symbol = "";
        style = "bg:#2a2a4a";
        format = "[[ $symbol($version) ](fg:#b780ff bg:#2a2a4a)]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:#2a2a4a";
        format = "[[ $symbol($version) ](fg:#b780ff bg:#2a2a4a)]($style)";
      };

      php = {
        symbol = "";
        style = "bg:#2a2a4a";
        format = "[[ $symbol($version) ](fg:#b780ff bg:#2a2a4a)]($style)";
      };

      java = {
        symbol = " ";
        style = "bg:#2a2a4a";
        format = "[[ $symbol($version) ](fg:#b780ff bg:#2a2a4a)]($style)";
      };

      kotlin = {
        symbol = "";
        style = "bg:#2a2a4a";
        format = "[[ $symbol($version) ](fg:#b780ff bg:#2a2a4a)]($style)";
      };

      haskell = {
        symbol = "";
        style = "bg:#2a2a4a";
        format = "[[ $symbol($version) ](fg:#b780ff bg:#2a2a4a)]($style)";
      };

      python = {
        symbol = "";
        style = "bg:#2a2a4a";
        format = "[[ $symbol($version)(($virtualenv)) ](fg:#b780ff bg:#2a2a4a)]($style)";
      };

      bun = {
        symbol = "󰛦 ";
        style = "bg:#2a2a4a";
        format = "[[ $symbol($version) ](fg:#b780ff bg:#2a2a4a)]($style)";
      };

      docker_context = {
        symbol = "";
        style = "bg:#1d1d3a";
        format = "[[ $symbol($context) ](fg:#76e3ea bg:#1d1d3a)]($style)";
      };

      conda = {
        symbol = " ";
        style = "bg:#1d1d3a";
        format = "[[ $symbol$environment ](fg:#76e3ea bg:#1d1d3a)]($style)";
        ignore_base = false;
      };

      aws = {
        symbol = " ";
        style = "bg:#1d1d3a";
        format = "[[ $symbol($profile)(\\($region\\)) ](fg:#fc704f bg:#1d1d3a)]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:#1a1a2e";
        format = "[[  $time ](fg:#76e3ea bg:#1a1a2e)]($style)";
      };

      line_break = {
        disabled = false;
      };

      character = {
        disabled = false;
        success_symbol = "[❯](bold fg:#76e3ea)";
        error_symbol = "[❯](bold fg:#ff4445)";
        vimcmd_symbol = "[❮](bold fg:#76e3ea)";
        vimcmd_replace_one_symbol = "[❮](bold fg:#8031f7)";
        vimcmd_replace_symbol = "[❮](bold fg:#8031f7)";
        vimcmd_visual_symbol = "[❮](bold fg:#fc704f)";
      };

      cmd_duration = {
        show_milliseconds = false;
        format = "took [$duration](bold fg:#fc704f) ";
        disabled = false;
        min_time = 2000;
        show_notifications = true;
        min_time_to_notify = 45000;
      };

      palettes.code_editor = {
        # Code Editor Color Palette
        # Semantic color mapping for terminal prompts
        bg = "#1a1a2e";
        bg_dark = "#16162a";
        bg_highlight = "#2a2a4a";
        terminal_black = "#3a3a5c";
        fg = "#e6ccff";
        fg_dark = "#b780ff";
        fg_gutter = "#3a3a5c";

        # Primary colors
        purple = "#8031f7";      # Keywords, functions
        pink = "#d23d91";        # Strings, special
        cyan = "#76e3ea";        # Types, constants, success
        coral = "#fc704f";       # Numbers, operators
        red = "#ff4445";         # Errors, deletions
        light_purple = "#b780ff"; # Comments, secondary

        # Extended palette
        magenta = "#d23d91";
        green = "#76e3ea";
        yellow = "#fc704f";
        blue = "#8031f7";
        orange = "#fc704f";
        teal = "#76e3ea";
      };
    };
  };
}
