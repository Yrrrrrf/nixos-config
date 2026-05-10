# /etc/nixos/home/profiles/minimal.nix
# The "Minimal" profile. Imports the default config and adds only essential packages.
{ pkgs, config, lib, ... }:
let
  cli     = import ../modules/packages/cli.nix     { inherit pkgs; };
  desktop = import ../modules/packages/desktop.nix { inherit pkgs; };
in {
  imports = [ ./default.nix ];

  home.packages =
       cli.nav ++ cli.view ++ cli.text ++ cli.git ++ cli.system ++ cli.shell
    ++ desktop.apps;
}
