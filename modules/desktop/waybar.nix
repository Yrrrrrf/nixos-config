{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;
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
          "custom/mic"
          "pulseaudio"
          "cpu"
          "network"
          "bluetooth"
          "battery"
          "custom/asus-profile"
          "custom/keyboard-layout"
          "custom/power"
        ];

        # --- Left & Center Modules ---
        "custom/profile" = { format = " "; tooltip = true; "tooltip-format" = "yrrrrrf"; };
        clock = { format = "{:%H:%M}"; tooltip-format = "<big>{:%D}</big>\n<tt><small>{calendar}</small></tt>"; };
        "hyprland/workspaces" = { format = "{id}"; "format-icons" = { active = ""; default = ""; }; "on-click" = "activate"; };
        # "hyprland/workspaces" = {
        #   # Display the workspace name (一, 二, etc.)
        #   format = "{name}";
        #   "on-click" = "activate";
        # };

        "hyprland/window" = { format = "{title}"; "max-length" = 50; };
        
        # --- Right Side Modules ---
        cpu = { format = " {usage}%"; "tooltip-format" = "CPU: {usage}%"; "on-click" = "wezterm -e btop"; };
        network = { "format-wifi" = " {essid}"; "format-ethernet" = "󰈀 Connected"; "format-disconnected" = "󰖪 Disconnected"; "tooltip-format-wifi" = "Signal: {signalStrength}% @ {frequency}GHz\nIP: {ipaddr}\nDown: {bandwidthDownBytes}\nUp: {bandwidthUpBytes}"; "on-click" = "wezterm -e nmtui"; };
        bluetooth = { format = " {status}"; "format-off" = ""; "format-disabled" = " Disabled"; "format-connected" = " {device_alias}"; };
        battery = { states = { warning = 30; critical = 15; }; format = "{capacity}% {icon}"; "format-charging" = "{capacity}% "; "format-plugged" = "{capacity}% 🔌"; "format-icons" = [ "" "" "" "" "" ]; };
        "custom/asus-profile" = { format = "{}"; tooltip = true; return-type = "json"; interval = 5; exec = "asus-helper --get"; on-click = "asus-helper --change"; };
        "custom/keyboard-layout" = { format = "{}"; tooltip = true; return-type = "json"; interval = 1; exec = "keyboard-helper --get"; on-click = "keyboard-helper --change"; };
        "custom/power" = { format = ""; "on-click" = "${pkgs.rofi-wayland}/bin/rofi -dmenu -p 'Power' -i <<< $'Logout\nSuspend\nReboot\nShutdown' | xargs -r ~/.local/bin/waybar-powermenu"; tooltip = false; };

        # === The standard pulseaudio module, now ONLY for speakers ===
        # pulseaudio = {
        #   format = "{volume}% {icon}";
        #   "format-muted" = "";
        #   "format-icons" = { default = [ "" "" ]; };
        #   "on-click" = "pavucontrol";
        # };

        # === The standard pulseaudio module, now with classic speaker icons ===
        pulseaudio = {
          format = "{volume}% {icon}";
          "format-muted" = "{volume}% 󰖁"; # The new "speaker with X" icon
          "on-click" = "pavucontrol";
          "format-icons" = {
            headphone = "";
            # Classic low and high volume icons
            default = [ "" "󰕾" ""];
          };
        };



        # === The completely independent custom mic module ===
        "custom/mic" = {
          format = "{}";
          interval = 1;
          return-type = "json";
          exec = "mic-helper --get-status";
          on-click = "mic-helper --toggle";
        };
      };
    };

    style = builtins.readFile ./waybar-style.css;
  };

  # --- Power Menu Script & Dependencies ---
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
  home.packages = with pkgs; [
    pavucontrol
    rofi-wayland
  ];
}
