{ config, pkgs, lib, ... }:

{
  # mprocs configuration with vim keybindings
  home.file.".config/mprocs/mprocs.yaml".text = ''
    keymap:
      # Process list navigation (vim style)
      procs:
        "j": "next-proc"
        "k": "prev-proc"
        "J": "next-proc"
        "K": "prev-proc"
        "g": "select-first"
        "G": "select-last"
        "x": "kill-proc"
        "X": "hard-kill-proc"
        "a": "add-proc"
        "r": "rename-proc"
        "R": "restart-proc"
        "Enter": "toggle-focus"
        "l": "toggle-focus"
        "h": "toggle-focus"
        "q": "quit"
        "?": "show-keys"
        "/": "filter"
        "Escape": "reset-filter"
        "z": "zoom"

      # Terminal scrolling (vim style)
      term:
        "h": "toggle-focus"
        "Escape": "toggle-focus"
        "j": "scroll-down"
        "k": "scroll-up"
        "d": "scroll-half-page-down"
        "u": "scroll-half-page-up"
        "g": "scroll-to-top"
        "G": "scroll-to-bottom"
        "z": "zoom"

      # Copy mode
      copy:
        "Escape": "exit-copy"
        "Enter": "copy-selected"
        "j": "move-down"
        "k": "move-up"
        "h": "move-left"
        "l": "move-right"
        "v": "toggle-selection"
  '';
}
