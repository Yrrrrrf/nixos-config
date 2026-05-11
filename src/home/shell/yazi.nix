{...}: {
  flake.homeModules.yazi = {pkgs, ...}: {
    xdg.configFile."yazi/yazi.toml".source = ./yazi.toml;
    programs.yazi.enable = true;
  };
}
