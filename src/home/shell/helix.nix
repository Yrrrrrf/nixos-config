{...}: {
  flake.homeModules.helix = {pkgs, ...}: {
    programs.helix = {
      enable = true;
    };
    xdg.configFile."helix/config.toml".source = ./helix.toml;
  };
}
