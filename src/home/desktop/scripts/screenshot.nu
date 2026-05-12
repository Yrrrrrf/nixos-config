#!/usr/bin/env nu
use _shared.nu *

# Screenshot Utility
def main [
    --region # Capture a region
    --screen # Capture the current monitor
] {
    let output_dir = ($env.HOME | path join "Pictures" "Screenshots")
    mkdir $output_dir
    let filename = (date now | format date "screenshot_%Y%m%d_%H%M%S.png")
    let full_path = ($output_dir | path join $filename)

    if $region {
        log_success "Select a region to capture..."
        ^hyprshot -s -m region -o $output_dir -f $filename
        log_success $"Screenshot stored on: ($full_path)"
        notify "Screenshot Captured" "Region saved and copied." --icon "camera-photo" --tag "screenshot_notification"
    } else if $screen {
        ^hyprshot -s -m output -m active -o $output_dir -f $filename
        log_success $"Screenshot stored on: ($full_path)"
        notify "Screenshot Captured" "Screen saved and copied." --icon "camera-photo" --tag "screenshot_notification"
    }
}




