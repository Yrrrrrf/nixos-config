{...}: {
  flake.nixosModules.specialisations-minimal = {
    inputs,
    lib,
    ...
  }: let
    user = inputs.self.lib.users.yrrrrrf;
  in {
    specialisation.minimal.configuration = {
      system.nixos.tags = ["minimal"];
      home-manager.users.${user.username} = lib.mkForce inputs.self.homeModules.minimal;
    };
  };

  flake.homeModules.minimal = {
    pkgs,
    inputs,
    ...
  }: let
    desktop = inputs.self.lib.pkgsets.desktop;
  in {
    imports = [inputs.self.homeModules.common];

    home.packages = desktop.apps pkgs;
  };
}
