# /etc/nixos/home/modules/packages/common.nix
#
# This is now a pure "data" module. It exports attribute sets
# containing lists of packages, but sets no options itself.
{
  pkgs,
  lib,
  ...
}: let
  # Libraries needed for running most GUI applications
  guiLibs = with pkgs; [
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

  # A broader set of libraries for compiling software
  buildLibs = with pkgs; [
    systemd.dev
    pkg-config
    alsa-lib.dev
    glib
    libglvnd
    libxkbcommon
    SDL2
    SDL2_gfx
    SDL2_image
    SDL2_mixer
    SDL2_ttf
    wayland
    wayland.dev
    xorg.libX11
    xorg.libxcb
    xorg.libXcursor
    xorg.libXi
    xorg.libXinerama
    xorg.libXrandr
    fontconfig
    freetype
    qt6.qtbase
    qt6.qtwayland
    libjpeg
    libpng
    giflib
  ];

  vulkanLibs = with pkgs; [
    xorg.libXi
    vulkan-tools
    vulkan-headers
    vulkan-loader
    vulkan-validation-layers
  ];
in {
  # We now return the lists under named attributes.
  # The profile will decide what to do with them.
  inherit guiLibs buildLibs vulkanLibs;
}
