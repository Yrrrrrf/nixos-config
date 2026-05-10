# /etc/nixos/home/profiles/dev.nix
# The "Full Dev" profile. Imports the default config and adds dev packages.
{ pkgs, lib, ... }:
let
  cli     = import ../modules/packages/cli.nix     { inherit pkgs; };
  desktop = import ../modules/packages/desktop.nix { inherit pkgs; };
  libs    = import ../modules/packages/libs.nix    { inherit pkgs lib; };
  dev     = import ../modules/packages/dev/packages.nix { inherit pkgs; };
in {
  imports = [
    ./default.nix
    ../modules/packages/default.nix
  ];

  home.sessionVariables = {
    AQ_DRM_DEVICES  = "/dev/dri/igpu:/dev/dri/dgpu";
    LD_LIBRARY_PATH = lib.makeLibraryPath libs.build;
    PKG_CONFIG_PATH = lib.makeSearchPath "lib/pkgconfig" (libs.build ++ dev.build);
  };

  home.packages =
       libs.gui
    ++ cli.nav ++ cli.view ++ cli.text ++ cli.git ++ cli.system
    ++ cli.net ++ cli.archive ++ cli.bench ++ cli.shell
    ++ cli.rust-dev ++ cli.misc
    ++ desktop.apps ++ desktop.creative ++ desktop.office ++ desktop.tools
    ++ dev.build ++ dev.ides;
}
