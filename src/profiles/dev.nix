{...}: {
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
    imports = [
      inputs.self.homeModules.common
      inputs.self.homeModules.dev-lang-asm
      inputs.self.homeModules.dev-lang-c-based
      inputs.self.homeModules.dev-lang-go
      inputs.self.homeModules.dev-lang-hyprlang
      inputs.self.homeModules.dev-lang-iot
      inputs.self.homeModules.dev-lang-just
      inputs.self.homeModules.dev-lang-kotlin
      inputs.self.homeModules.dev-lang-markdown
      inputs.self.homeModules.dev-lang-nix
      inputs.self.homeModules.dev-lang-python
      inputs.self.homeModules.dev-lang-rust
      inputs.self.homeModules.dev-lang-shell
      inputs.self.homeModules.dev-lang-sql
      inputs.self.homeModules.dev-lang-toml
      inputs.self.homeModules.dev-lang-typst
      inputs.self.homeModules.dev-lang-web
      inputs.self.homeModules.dev-lang-yaml
    ];

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
      ++ (desktop.tools pkgs)
      ++ (dev.build pkgs)
      ++ (dev.ides pkgs);
  };
}
