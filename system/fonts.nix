# /etc/nixos/modules/system/fonts.nix
#
# This module handles the declarative management of system-wide fonts.
# Fonts installed here are available to all applications and users.
{pkgs, ...}: {
  # --- Font Configuration ---
  # The `fonts.packages` option is the standard NixOS way to install fonts.
  # We are including several "Nerd Fonts", which are patched with a large
  # number of glyphs and icons, ideal for custom status bars and prompts.
  fonts.packages = with pkgs; [
    # code
    nerd-fonts.symbols-only # Set of symbols
    nerd-fonts.jetbrains-mono # A popular programming font with patched icons.
    nerd-fonts.fira-code # Another popular font with programming ligatures and icons.

    # formal
    nerd-fonts.lilex # slim one
    nerd-fonts.iosevka # tall font hahaha

    # cool ones!
    nerd-fonts.hurmit # Cool curved font
    nerd-fonts.heavy-data # Retro Tek

    # terminal looking
    nerd-fonts.terminess-ttf
  ];
}
