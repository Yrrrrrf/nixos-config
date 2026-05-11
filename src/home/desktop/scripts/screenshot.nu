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

    if $region {
        if (do { hyprshot -m region -o $output_dir } | complete).exit_code == 0 {
            send_notification "Screenshot Captured" "Region copied and saved."
        } else {
            send_notification "Screenshot Cancelled" "Capture was cancelled."
        }
    } else if $screen {
        if (do { hyprshot -m output --current -o $output_dir } | complete).exit_code == 0 {
            send_notification "Screenshot Captured" "Screen copied and saved."
        }
    }
}
