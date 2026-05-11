{...}: {
  flake.homeModules.fastfetch = {pkgs, ...}: {
    xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch.jsonc;
  };
}
