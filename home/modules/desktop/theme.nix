# /etc/nixos/modules/desktop/theme.nix
#
# This file centralizes the Catppuccin Mocha color palette and style
# definitions for the entire desktop configuration.
{
  # ===================================================================
  # --- COLOR PALETTE (Catppuccin Mocha) ---
  # ===================================================================
  rosewater = "#f5e0dc";
  flamingo = "#f2cdcd";
  pink = "#f5c2e7";
  mauve = "#cba6f7";
  red = "#f38ba8";
  maroon = "#eba0ac";
  peach = "#fab387";
  yellow = "#f9e2af";
  green = "#a6e3a1";
  teal = "#94e2d5";
  sky = "#89dceb";
  sapphire = "#74c7ec";
  blue = "#89b4fa";
  lavender = "#b4befe";

  # Base Tones
  text = "#cdd6f4";
  subtext1 = "#bac2de";
  subtext0 = "#a6adc8";
  overlay2 = "#9399b2";
  overlay1 = "#7f849c";
  overlay0 = "#6c7086";
  surface2 = "#585b70";
  surface1 = "#45475a";
  surface0 = "#313244";
  base = "#1e1e2e";
  mantle = "#181825";
  crust = "#11111b";

  # ===================================================================
  # --- STYLE DEFINITIONS ---
  # These values define the shared geometry for UI elements.
  # ===================================================================
  style = {
    # The larger radius used for main containers like Waybar islands,
    # Rofi's window, and Dunst notifications.
    borderRadius.island = 12;

    # The smaller radius used for internal elements like Waybar pills
    # and Rofi's input bar and list items.
    borderRadius.pill = 10;

    # The consistent border width for all elements.
    borderWidth = 1;

    # A base unit for spacing and padding.
    spacing = 8;
  };
}
