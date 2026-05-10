# /etc/nixos/modules/home/desktop/dunst.nix
#
# Declarative theming and configuration for the Dunst notification daemon.
# This theme matches the Catppuccin Mocha "floating island" style, consistent
# with the Rofi and Waybar configurations.
{pkgs, ...}: {
  services.dunst = {
    enable = true;
    # Dunst settings are configured declaratively here.
    settings = let
      # Define Catppuccin Mocha colors for consistency.
      # NOTE: These will also be moved to a central 'theme.nix' file.
      rosewater = "#f5e0dc";
      mauve = "#cba6f7";
      red = "#f38ba8";
      green = "#a6e3a1";
      yellow = "#f9e2af";
      text = "#cdd6f4";
      surface1 = "#45475a";
      base = "#1e1e2e";
    in {
      # --- Global Settings ---
      # These settings apply to all notifications unless overridden by an urgency level.
      global = {
        monitor = 0; # primary monitor

        # --- Appearance ---
        font = "JetBrainsMono Nerd Font 10";
        format = "<b>%s</b>\\n%b"; # Summary in bold, then body

        newest_on_top = true;

        # --- Geometry ---
        # Sizing and positioning of the notification window.
        width = 350;
        height = 100;
        origin = "top-right";
        offset = "20x50"; # 20px from right edge, 50px from top

        # --- Theming (Floating Island Style) ---
        frame_width = 1;
        frame_color = surface1;
        separator_color = surface1;
        border_radius = 12; # Matches Hyprland and Rofi rounding
        padding = 12;
        horizontal_padding = 16;
      };

      # --- Urgency Levels ---
      # Define specific styles and behaviors for different notification priorities.

      # Low urgency notifications (e.g., volume changes, brightness changes).
      urgency_low = {
        background = base;
        foreground = text;
        timeout = 5;
      };

      # Normal notifications (most application messages).
      urgency_normal = {
        background = base;
        foreground = text;
        timeout = 10;
      };

      # Critical notifications (e.g., low battery, important system alerts).
      urgency_critical = {
        background = base;
        foreground = text;
        frame_color = red; # A red frame to draw attention.
        timeout = 20;
      };
    };
  };
}
