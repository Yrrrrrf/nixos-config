#!/usr/bin/env nu

# A consolidated helper script to manage ASUS performance profiles.
# It can get the current status for Waybar or change to the next profile.

def main [
    --get    # Get current status for Waybar
    --change # Change to the next profile
] {
    if $get {
        let profile = (asusctl profile -p | lines | find "Active profile is" | split row " " | last)
        
        let info = match $profile {
            "Quiet" => { icon: "󰒑", class: "quiet" }
            "Balanced" => { icon: "󰾅", class: "balanced" }
            "Performance" => { icon: "󰓅", class: "performance" }
            _ => { icon: "", class: "unknown" }
        }

        {
            text: $info.icon,
            tooltip: $"Profile: ($profile)",
            class: $info.class
        } | to json --raw
    } else if $change {
        asusctl profile -n
        let profile = (asusctl profile -p | lines | find "Active profile is" | split row " " | last)
        
        notify-send -i "system-performance" -h string:x-dunst-stack-tag:performance_profile $"Performance Profile: ($profile)"
    }
}
