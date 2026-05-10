{pkgs, ...}: {
  apps = with pkgs; [spotify brave firefox obsidian discord rnote];
  creative = with pkgs; [gimp3 inkscape obs-studio];
  office = with pkgs; [libreoffice-qt6-fresh thunderbird mendeley];
  tools = with pkgs; [wezterm swww hyprlock hypridle xfce.thunar dunst libnotify hyprshot cliphist wl-clipboard cheese brightnessctl yt-dlp];
}
