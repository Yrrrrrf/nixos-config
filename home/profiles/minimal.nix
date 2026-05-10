# /etc/nixos/home/profiles/minimal.nix
# The "Minimal" profile. Imports the default config and adds only essential packages.
{
  pkgs,
  config,
  lib,
  ...
}: let
  cliPkgs = import ../modules/packages/cli.nix {inherit pkgs;};
  desktopPkgs = import ../modules/packages/desktop.nix {inherit pkgs;};
in {
  imports = [./default.nix]; # <-- Import the shared config

  # --- Final Package List ---
  home.packages = cliPkgs.replacements ++ cliPkgs.tools ++ desktopPkgs.gui ++ desktopPkgs.utils;
}
