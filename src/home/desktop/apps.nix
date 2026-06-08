{lib, ...}: {
  options.flake.lib.pkgsets.desktop = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };

  config.flake.lib.pkgsets.desktop = {
    apps = pkgs:
      with pkgs; [
        brave
        firefox
        obsidian
        discord
        rnote
        cheese
        steam
      ];
    creative = pkgs:
      with pkgs; [
        gimp3
        inkscape
        obs-studio
      ];
    office = pkgs:
      with pkgs; [
        thunderbird
        mendeley
      ];
  };
}
