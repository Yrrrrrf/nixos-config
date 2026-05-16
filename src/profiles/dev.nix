{...}: {
  flake.nixosModules.specialisations-dev = {...}: {
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
    langs = builtins.attrValues inputs.self.lib.dev.langs;
  in {
    imports =
      [
        inputs.self.homeModules.common
      ]
      ++ (lib.attrValues (lib.filterAttrs (n: _: lib.hasPrefix "dev-lang-" n) inputs.self.homeModules));

    programs.helix.languages = {
      language = lib.concatMap (l: l.helix.language or []) langs;
      language-server = lib.foldl' (a: l: a // (l.helix.language-server or {})) {} langs;
    };

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
      ++ (dev.ides pkgs)
      ++ (lib.concatMap (l: (l.extraPackages or (_: [])) pkgs) langs);
  };
}
