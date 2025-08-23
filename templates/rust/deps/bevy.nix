# /etc/nixos/templates/rust/deps/bevy.nix
{ pkgs }: with pkgs; [
  # Audio
  alsa-lib

  # Core Wayland and X11 libraries for windowing
  libxkbcommon
  wayland
  xorg.libX11
  xorg.libXcursor

  # For dynamic linking and build-time discovery
  pkg-config
  
  # For hot-reloading during development
  cargo-watch
]
