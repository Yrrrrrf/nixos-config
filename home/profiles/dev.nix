# /etc/nixos/home/profiles/dev.nix
# The "Full Dev" profile. Imports the default config and adds dev packages.

{ pkgs, config, lib, ... }:

let
  cliPkgs = import ../modules/packages/cli.nix { inherit pkgs; };
  desktopPkgs = import ../modules/packages/desktop.nix { inherit pkgs; };
  devPkgs = import ../modules/packages/development.nix { inherit pkgs; };
  commonLibs = import ../modules/packages/common.nix { inherit pkgs lib; };
in
{
  imports = [
    ./default.nix
  ]; # import shared config

  # --- Session Variables ---
  home.sessionVariables = {
    LD_LIBRARY_PATH = lib.makeLibraryPath (commonLibs.buildLibs);
    PKG_CONFIG_PATH = lib.makeSearchPath "lib/pkgconfig" (commonLibs.buildLibs);
  };

  # --- Final Package List ---
  home.packages =
    commonLibs.guiLibs ++

    cliPkgs.replacements ++
    cliPkgs.tools ++

    desktopPkgs.gui ++
    desktopPkgs.utils ++

    # Access the specific lists from your development.nix file
    devPkgs.buildTools ++
    devPkgs.ides ++

    # Flatten the 'lang' attribute set into a single list
    devPkgs.lang.kotlin ++
    devPkgs.lang.python ++
    devPkgs.lang.rust ++
    devPkgs.lang.go ++
    devPkgs.lang.web ++

    [ pkgs.ciscoPacketTracer8 ]
    ;
}
