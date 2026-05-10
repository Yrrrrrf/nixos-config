{lib, ...}: {
  options.flake.lib.pkgsets.desktop = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };
  config.flake.lib.pkgsets.desktop = {
    apps = pkgs:
      with pkgs; [
        spotify
        brave
        firefox
        obsidian
        discord
        rnote
      ];
    creative = pkgs:
      with pkgs; [
        gimp3
        inkscape
        obs-studio
      ];
    office = pkgs:
      with pkgs; [
        libreoffice-qt6-fresh
        thunderbird
        mendeley
      ];
    tools = pkgs:
      with pkgs; [
        wezterm
        swww
        hyprlock
        hypridle
        xfce.thunar
        dunst
        libnotify
        hyprshot
        cliphist
        wl-clipboard
        cheese
        brightnessctl
        yt-dlp
      ];
  };
}
