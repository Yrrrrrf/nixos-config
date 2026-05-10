{
  pkgs,
  lib,
  ...
}: {
  gui = with pkgs; [
    wayland
    libxkbcommon
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    xorg.libXinerama
    libglvnd
    libGL
    alsa-lib
    glib
    SDL2
    SDL2_ttf
    SDL2_image
    SDL2_mixer
    SDL2_gfx
  ];
  build = with pkgs; [
    systemd.dev
    pkg-config
    alsa-lib.dev
    wayland.dev
    xorg.libxcb
    fontconfig
    freetype
    qt6.qtbase
    qt6.qtwayland
    libjpeg
    libpng
    giflib
  ];
}
