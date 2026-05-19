# No Helix language entry — packages only. Loader should treat missing
# `helix` as `{ language = []; language-server = {}; }`.
{...}: {
  config.flake.lib.dev.langs.iot = {
    extraPackages = pkgs: [pkgs.platformio];
  };
}
