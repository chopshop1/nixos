{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      customRC = ''
        set number
        set relativenumber
        set autoindent
        set tabstop=2
        set shiftwidth=2
        set smarttab
        set softtabstop=2
        set expandtab
        set mouse=a
        set clipboard=unnamedplus
        set cursorline
        set ttyfast
        set encoding=UTF-8
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    vscode
    sublime4
    emacs
    helix
  ];
}