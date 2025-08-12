# /etc/nixos/modules/system/fonts.nix
#
# This module handles the declarative management of system-wide fonts.
# Fonts installed here are available to all applications and users.

{ pkgs, ... }:

{
  # --- Font Configuration ---
  # The `fonts.packages` option is the standard NixOS way to install fonts.
  # We are including several "Nerd Fonts", which are patched with a large
  # number of glyphs and icons, ideal for custom status bars and prompts.
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # A popular programming font with patched icons.
    nerd-fonts.fira-code      # Another popular font with programming ligatures and icons.
    nerd-fonts.caskaydia-cove # Microsoft's Cascadia Code, patched with icons.
  ];
}