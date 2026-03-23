{ config, pkgs, lib, ... }:

{
  # Kitty terminal configuration with Tokyo Night theme
  programs.kitty = {
    enable = true;
    settings = {
      shell = "${pkgs.zsh}/bin/zsh";
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      window_padding_width = 10;

      # Tokyo Night Storm colorscheme
      background = "#1a1b26";
      foreground = "#c0caf5";
      selection_background = "#283457";
      selection_foreground = "#c0caf5";
      url_color = "#73daca";
      cursor = "#c0caf5";
      cursor_text_color = "#1a1b26";

      # Tabs
      active_tab_background = "#7aa2f7";
      active_tab_foreground = "#1f2335";
      inactive_tab_background = "#292e42";
      inactive_tab_foreground = "#545c7e";

      # Normal colors
      color0 = "#15161e";
      color1 = "#f7768e";
      color2 = "#9ece6a";
      color3 = "#e0af68";
      color4 = "#7aa2f7";
      color5 = "#bb9af7";
      color6 = "#7dcfff";
      color7 = "#a9b1d6";

      # Bright colors
      color8 = "#414868";
      color9 = "#f7768e";
      color10 = "#9ece6a";
      color11 = "#e0af68";
      color12 = "#7aa2f7";
      color13 = "#bb9af7";
      color14 = "#7dcfff";
      color15 = "#c0caf5";
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
  };

  # GTK/Qt theme configuration is in hyprland.nix

  # Konsole (KDE Terminal) Tokyo Night theme
  home.file.".local/share/konsole/TokyoNight.colorscheme".text = ''
    [Background]
    Color=26,27,38

    [BackgroundFaint]
    Color=26,27,38

    [BackgroundIntense]
    Color=36,40,59

    [Color0]
    Color=21,22,30

    [Color0Faint]
    Color=21,22,30

    [Color0Intense]
    Color=65,72,104

    [Color1]
    Color=247,118,142

    [Color1Faint]
    Color=247,118,142

    [Color1Intense]
    Color=247,118,142

    [Color2]
    Color=158,206,106

    [Color2Faint]
    Color=158,206,106

    [Color2Intense]
    Color=158,206,106

    [Color3]
    Color=224,175,104

    [Color3Faint]
    Color=224,175,104

    [Color3Intense]
    Color=224,175,104

    [Color4]
    Color=122,162,247

    [Color4Faint]
    Color=122,162,247

    [Color4Intense]
    Color=122,162,247

    [Color5]
    Color=187,154,247

    [Color5Faint]
    Color=187,154,247

    [Color5Intense]
    Color=187,154,247

    [Color6]
    Color=125,207,255

    [Color6Faint]
    Color=125,207,255

    [Color6Intense]
    Color=125,207,255

    [Color7]
    Color=169,177,214

    [Color7Faint]
    Color=169,177,214

    [Color7Intense]
    Color=192,202,245

    [Foreground]
    Color=192,202,245

    [ForegroundFaint]
    Color=169,177,214

    [ForegroundIntense]
    Color=192,202,245

    [General]
    Anchor=0.5,0.5
    Blur=false
    ColorRandomization=false
    Description=Tokyo Night
    FillStyle=Tile
    Opacity=1
    Wallpaper=
    WallpaperFlipType=NoFlip
    WallpaperOpacity=1
  '';

  home.file.".local/share/konsole/TokyoNight.profile".text = ''
    [Appearance]
    ColorScheme=TokyoNight
    Font=JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1

    [Cursor Options]
    CursorShape=1

    [General]
    Command=/run/current-system/sw/bin/zsh
    Name=Tokyo Night
    Parent=FALLBACK/

    [Scrolling]
    HistoryMode=2
    ScrollBarPosition=2

    [Terminal Features]
    BlinkingCursorEnabled=true
  '';

  # Set Konsole to use Tokyo Night profile by default
  home.file.".config/konsolerc".text = ''
    [Desktop Entry]
    DefaultProfile=TokyoNight.profile

    [General]
    ConfigVersion=1

    [MainWindow]
    MenuBar=Disabled
    ToolBarsMovable=Disabled

    [TabBar]
    TabBarVisibility=ShowTabBarWhenNeeded
  '';
}
