# /etc/nixos/home/modules/packages/desktop.nix
{ pkgs, ... }: {
  # This file now just returns an attribute set.
  # The 'gui' attribute holds our list of packages.
  gui = with pkgs; [
    spotify obsidian steam firefox brave thunderbird gimp3 inkscape
    obs-studio mendeley libreoffice-qt6-fresh discord
  ];

  # The desktop utilities can be a separate list.
  utils = with pkgs; [
    wezterm
    swww
    hyprlock
    hypridle
    yazi
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
}
