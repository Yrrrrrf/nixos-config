#!/usr/bin/env nu
use _asus.nu *

# Performance Profile Manager
def main [
    --get    # Get current status for Waybar
    --change # Change to the next profile
] {
    if $get {
        let profile = (parse_asus (asusctl profile -p) "Active profile is")
        
        let icon = match $profile {
            "Quiet" => "󰒑"
            "Balanced" => "󰾅"
            "Performance" => "󰓅"
            _ => ""
        }

        as_json { profile: $profile, icon: $icon }
    } else if $change {
        run_silent { asusctl profile -n }

        let profile = (parse_asus (asusctl profile -p) "Active profile is")

        let msg = $"GPU profile set to: ($profile)"
        log_success $msg
        notify "Performance Profile" $msg --icon "system-performance" --tag "performance_profile"
    }
}


