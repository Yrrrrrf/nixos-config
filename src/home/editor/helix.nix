{...}: {
  flake.homeModules.helix = {pkgs, ...}: {
    programs.helix.enable = true;
    programs.helix.settings = {};
  };
}
