# /etc/nixos/home/profiles/minimal.nix
# The "Minimal" profile. Imports the default config and adds only essential packages.
{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: let
  cli = inputs.self.lib.pkgsets.cli;
  desktop = inputs.self.lib.pkgsets.desktop;
in {
  imports = [./default.nix];

  home.packages =
    (cli.nav pkgs)
    ++ (cli.view pkgs)
    ++ (cli.text pkgs)
    ++ (cli.git pkgs)
    ++ (cli.system pkgs)
    ++ (cli.shell pkgs)
    ++ (desktop.apps pkgs);
}
