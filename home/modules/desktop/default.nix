# /etc/nixos/home/modules/desktop/default.nix
# This module acts as a master switch for the entire graphical desktop environment.
{pkgs, ...}: {
  # This should ONLY import other configuration modules for the desktop.
  imports = [
    # --- Core Desktop Components ---
    ./dunst.nix
    ./hypr/hypridle.nix
    ./hypr/hyprland.nix
    ./hypr/hyprlock.nix
    ./rofi.nix
    ./waybar.nix
    ./wezterm.nix
    ./swayosd.nix
  ];

  # The package lists have been correctly removed from here.
  # The profile is now responsible for handling them.

  # Enable core graphical services needed for everything to work.
  services.dunst.enable = true;
  programs.rofi.enable = true;
}
