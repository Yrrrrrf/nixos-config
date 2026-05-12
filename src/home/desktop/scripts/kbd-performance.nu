#!/usr/bin/env nu

# A consolidated helper script to manage ASUS performance profiles.
# It can get the current status for Waybar or change to the next profile.

def main [
    --get    # Get current status for Waybar
    --change # Change to the next profile
] {
    if $get {
        let profile = (asusctl profile -p | lines | find "Active profile is" | first | ansi strip | split row " " | last)
        
        let icon = match $profile {
            "Quiet" => "󰒑"
            "Balanced" => "󰾅"
            "Performance" => "󰓅"
            _ => ""
        }

        { profile: $profile, icon: $icon } | to json --raw
    } else if $change {
        asusctl profile -n
        let profile = (asusctl profile -p | lines | find "Active profile is" | first | ansi strip | split row " " | last)
        
        print $"Performance profile set to: ($profile)"
        notify-send -i "system-performance" -h string:x-dunst-stack-tag:performance_profile $"Performance Profile: ($profile)"
    }
}

