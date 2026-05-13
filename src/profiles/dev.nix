{config, ...}: {
  flake.nixosModules.specialisations-dev = {inputs, ...}: {
    specialisation.dev.configuration = {
      system.nixos.tags = ["dev"];
    };
  };

  flake.homeModules.dev = {
    pkgs,
    lib,
    inputs,
    ...
  }: let
    cli = inputs.self.lib.pkgsets.cli;
    desktop = inputs.self.lib.pkgsets.desktop;
    libs = inputs.self.lib.libsets;
    dev = inputs.self.lib.pkgsets.dev;
  in {
    imports =
      [
        inputs.self.homeModules.common
      ]
      ++ (lib.attrValues (lib.filterAttrs (n: _: lib.hasPrefix "dev-lang-" n) inputs.self.homeModules));

    home.sessionVariables = {
      AQ_DRM_DEVICES = "/dev/dri/igpu:/dev/dri/dgpu";
      LD_LIBRARY_PATH = lib.makeLibraryPath (libs.build pkgs);
      PKG_CONFIG_PATH = lib.makeSearchPath "lib/pkgconfig" ((libs.build pkgs) ++ (dev.build pkgs));
    };

    home.packages =
      (libs.gui pkgs)
      ++ (cli.net pkgs)
      ++ (cli.archive pkgs)
      ++ (cli.bench pkgs)
      ++ (cli.rust-dev pkgs)
      ++ (cli.misc pkgs)
      ++ (desktop.apps pkgs)
      ++ (desktop.creative pkgs)
      ++ (desktop.office pkgs)
      ++ (dev.build pkgs)
      ++ (dev.ides pkgs);
  };
}
