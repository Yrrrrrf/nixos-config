{lib, ...}: {
  options.flake.lib.libsets = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };
  config.flake.lib.libsets = {
    gui = pkgs:
      with pkgs; [
        wayland
        libxkbcommon
        libglvnd
        libGL
        alsa-lib
        glib
      ];
    build = pkgs:
      with pkgs; [
        systemd.dev
        pkg-config
        alsa-lib.dev
        wayland.dev
        fontconfig
      ];
  };
}
