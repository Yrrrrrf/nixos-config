#!/usr/bin/env nu

# A helper script for taking fast screenshots with hyprshot on Hyprland.
# It saves the image, copies it to the clipboard, and sends a notification.

def send_notification [title: string, message: string] {
    notify-send -i "camera-photo" -h string:x-dunst-stack-tag:screenshot_notification $title $message
}

def main [
    --region # Capture a region
    --screen # Capture the current monitor
] {
    let output_dir = ($env.HOME | path join "Pictures" "Screenshots")
    mkdir $output_dir
    let filename = (date now | format date "screenshot_%Y%m%d_%H%M%S.png")

    if $region {
        print "Select a region to capture..."
        ^hyprshot -s -m region -o $output_dir -f $filename
        print $"Screenshot stored on: ($output_dir | path join $filename)"
        send_notification "Screenshot Captured" "Region saved and copied."
    } else if $screen {
        ^hyprshot -s -m output -m active -o $output_dir -f $filename
        print $"Screenshot stored on: ($output_dir | path join $filename)"
        send_notification "Screenshot Captured" "Screen saved and copied."
    }
}



