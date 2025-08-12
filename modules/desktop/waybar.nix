# /etc/nixos/modules/home/desktop/waybar.nix
#
# This file declaratively manages the configuration for the Waybar status bar.
# It defines the layout and behavior of all modules, and also creates the
# associated power menu script required by the power button widget.

{ config, pkgs, ... }:

{
  # --- Waybar Program Configuration ---
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;

    # The 'settings' attribute set is a direct translation of Waybar's JSON config,
    # allowing for a fully declarative setup.
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 40;
        margin-top = 4;
        margin-left = 8;
        margin-right = 8;
        modules-left = [
          "custom/profile"
          "clock"
          "hyprland/workspaces"
        ];
        modules-center = [ "hyprland/window" ];
        modules-right = [
          "pulseaudio#mic"
          "pulseaudio"
          "cpu"
          "network"
          "bluetooth"
          "battery"
          "custom/asus-profile"
          "custom/power"
        ];

        # Profile picture module.
        # The actual image is set in waybar-style.css.
        "custom/profile" = {
          format = " "; # Content is just the CSS background image
          tooltip = true;
          "tooltip-format" = "yrrrrrf";
        };

        clock = {
          format = "{:%H:%M}";
          tooltip-format = "<big>{:%D}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "hyprland/workspaces" = {
          format = "{id}";
          "format-icons" = {
            active = "";
            default = "";
          };
          "on-click" = "activate"; # BINDING: Click to switch to that workspace.
        };

        "hyprland/window" = {
          format = "{title}";
          "max-length" = 50;
        };

        pulseaudio = {
          format = "{volume}% {icon}";
          "format-muted" = "";
          "format-icons" = { default = [ "" "" ]; };
          "on-click" = "pavucontrol"; # BINDING: Click to open PulseAudio Volume Control.
        };

        "pulseaudio#mic" = {
          format = "{format_source}";
          "format-source" = "";
          "format-source-muted" = "";
          "on-click" = "pavucontrol"; # BINDING: Click to open PulseAudio Volume Control.
        };

        cpu = {
          format = " {usage}%";
          "tooltip-format" = "CPU: {usage}%";
          "on-click" = "wezterm -e btop"; # BINDING: Click to open the btop process viewer.
        };

        network = {
          "format-wifi" = " {essid}";
          "format-ethernet" = "󰈀 Connected";
          "format-disconnected" = "󰖪 Disconnected";
          "tooltip-format-wifi" = "Signal: {signalStrength}% @ {frequency}GHz\nIP: {ipaddr}\nDown: {bandwidthDownBytes}\nUp: {bandwidthUpBytes}";
          "on-click" = "wezterm -e nmtui";
        };

        bluetooth = {
          format = " {status}";
          "format-off" = "";
          "format-disabled" = " Disabled";
          "format-connected" = " {device_alias}";
        };

        battery = {
          states = { warning = 30; critical = 15; };
          format = "{capacity}% {icon}";
          "format-charging" = "{capacity}% ";
          "format-plugged" = "{capacity}% 🔌";
          "format-icons" = [ "" "" "" "" "" ];
        };

        # --- ADDED: The full module definition for the ASUS profile helper ---
        "custom/asus-profile" = {
          format = " {} ";          # Display the "text" field from our JSON output (the icon)
          tooltip = true;         # Enable the tooltip from our JSON
          return-type = "json";   # Tell Waybar to expect JSON output from the script
          interval = 5;           # How often to run the script (in seconds)
          exec = "asus-helper --get"; # The command to get the status
          on-click = "asus-helper --change"; # The command to run on click
        };

        "custom/power" = {
          format = "";
          # BINDING: Click to open a power menu in Rofi.
          # This command calls the script we define below.
          "on-click" = "${pkgs.rofi-wayland}/bin/rofi -dmenu -p 'Power' -i <<< $'Logout\nSuspend\nReboot\nShutdown' | xargs -r ~/.local/bin/waybar-powermenu";
          tooltip = false;
        };
      };
    };

    # The style is read directly from the adjacent CSS file.
    # This keeps the styling separate from the functional configuration.
    style = builtins.readFile ./waybar-style.css;
  };

  # --- Power Menu Script ---
  # This Home Manager option creates an executable file in the user's home directory.
  # This script is called by the 'custom/power' module in Waybar.
  home.file.".local/bin/waybar-powermenu" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      case $1 in
          "Logout") hyprctl dispatch exit ;;
          "Suspend") systemctl suspend ;;
          "Reboot") systemctl reboot ;;
          "Shutdown") systemctl poweroff ;;
      esac
    '';
  };

  # --- Required Packages ---
  # These packages are dependencies for the 'on-click' actions in Waybar.
  # Including them here makes this module self-contained.
  home.packages = with pkgs; [
    pavucontrol
    rofi-wayland
  ];
}
