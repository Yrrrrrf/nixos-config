{...}: {
  flake.nixosModules.specialisations-minimal = {inputs, ...}: let
    user = inputs.self.lib.users.yrrrrrf;
  in {
    specialisation.minimal.configuration = {
      system.nixos.tags = ["minimal"];
      home-manager.users.${user.username} = inputs.self.homeModules.minimal;
    };
  };

  flake.homeModules.minimal = {
    pkgs,
    config,
    lib,
    inputs,
    ...
  }: let
    cli = inputs.self.lib.pkgsets.cli;
    desktop = inputs.self.lib.pkgsets.desktop;
  in {
    imports = [inputs.self.homeModules.default];

    home.packages =
      (cli.nav pkgs)
      ++ (cli.view pkgs)
      ++ (cli.text pkgs)
      ++ (cli.git pkgs)
      ++ (cli.system pkgs)
      ++ (cli.shell pkgs)
      ++ (desktop.apps pkgs);
  };
}
