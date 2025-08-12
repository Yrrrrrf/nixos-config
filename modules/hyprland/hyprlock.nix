# /etc/nixos/modules/home/hyprland/hyprlock.nix
#
# This module declaratively manages the hyprlock screen locker via Home Manager.
# It enables the program and links it to its separate configuration file.

{ pkgs, ... }:

{
  programs.hyprlock = {
    enable = true;

    # This option loads the hyprlock theme and settings from an external file.
    # This keeps the Nix file clean and allows you to use the native
    # hyprlock configuration syntax. The path is relative to this .nix file.
    extraConfig = builtins.readFile ./hyprlock.conf;
  };
}