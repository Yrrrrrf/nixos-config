# /etc/nixos/modules/home/desktop/rofi.nix
#
# Declarative configuration for the Rofi application launcher.
# This module uses native Home Manager options to generate the Rofi theme,
# ensuring a robust and reproducible setup. The theme is a "Floating Island"
# style using Catppuccin colors to match the overall desktop aesthetic.

{ config, pkgs, ... }:

let
  # This helper function from the NixOS library is used to tell the Rofi
  # module to treat a string as a literal value rather than a string in quotes.
  # It's necessary for setting Rasi properties correctly.
  inherit (config.lib.formats.rasi) mkLiteral;

  # --- Catppuccin Mocha Palette ---
  # NOTE: In a future step, we can centralize these colors in a single 'theme.nix'
  # file to share them across all applications (Rofi, Dunst, Waybar, etc.).
  mauve = "#cba6f7";
  text = "#cdd6f4";
  overlay0 = "#6c7086";
  surface1 = "#45475a";
  surface0 = "#313244";
  base = "#1e1e2e";
  crust = "#11111b";
in
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland; # Specify the Wayland-compatible version of Rofi.
    theme = {
      "*" = {
        /* General settings and variable definitions */
        font = "JetBrainsMono Nerd Font 12";
        
        background-color = mkLiteral base;
        foreground-color = mkLiteral text;
        border-color = mkLiteral surface1;

        /* Define a solid background and a high-contrast foreground for selection */
        selected-background = mkLiteral mauve;
        selected-foreground = mkLiteral crust; # Dark text for readability on the mauve bg
      };

      "window" = {
        /* The main window is the "island" itself */
        background-color = mkLiteral "@background-color";
        border = mkLiteral "1px";
        border-color = mkLiteral "@border-color";
        border-radius = 12; /* Matches Waybar and Hyprland rounding */
        padding = "1.5em";
        width = "55%";
      };

      "mainbox" = {
        border = 0;
        padding = 0;
      };

      "inputbar" = {
        children = map mkLiteral [ "prompt" "textbox-prompt-colon" "entry" ];
        background-color = mkLiteral surface0;
        text-color = mkLiteral text;
        padding = "0.75em";
        border-radius = 8;
        margin = "0 0 1.5em 0"; /* Space between input and results */
      };
      
      "prompt" = {
        enabled = true;
        background-color = mkLiteral "inherit";
        text-color = mkLiteral mauve;
      };

      "textbox-prompt-colon" = {
        expand = false;
        str = ""; /* Nerd Font search icon */
        background-color = mkLiteral "inherit";
        text-color = mkLiteral "inherit";
        padding = mkLiteral "0 1em 0 0.25em";
      };

      "entry" = {
        background-color = mkLiteral "inherit";
        text-color = mkLiteral "inherit";
        placeholder = "Search Applications...";
        placeholder-color = mkLiteral overlay0;
      };

      "listview" = {
        lines = 8;
        columns = 1;
        spacing = "0.5em"; /* Space between rows */
        scrollbar = false;
        padding = 0;
        border = 0;
      };

      "element" = {
        border = 0;
        padding = "0.75em";
        border-radius = 8;
      };

      "element-text" = {
        background-color = mkLiteral "inherit";
        text-color = mkLiteral "inherit";
        vertical-align = mkLiteral "0.5";
      };
      
      "element-icon" = {
        size = 24;
        border = mkLiteral "0px 1em 0px 0px";
        background-color = mkLiteral "inherit";
      };

      "element.normal.normal" = {
        background-color = mkLiteral surface0;
        text-color = mkLiteral "@foreground-color";
      };

      "element.selected.normal" = {
        /* Apply the solid background and high-contrast text color on selection */
        background-color = mkLiteral "@selected-background";
        text-color = mkLiteral "@selected-foreground";
      };
    };
  };
}