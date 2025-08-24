#!/usr/bin/env bash
#
# A helper script for taking fast screenshots with hyprshot on Hyprland.
# It saves the image, copies it to the clipboard, and sends a notification.

# --- FUNCTION: Send a notification ---
# We use a stack tag to replace the previous notification.
send_notification() {
  notify-send -i "camera-photo" \
              -h string:x-dunst-stack-tag:screenshot_notification \
              "$1" "$2"
}

# --- Main Logic ---
# The output directory for all screenshots.
OUTPUT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$OUTPUT_DIR"

case "$1" in
  --region)
    # Capture a region. By default, hyprshot saves to the specified directory
    # AND copies to the clipboard. The conflicting --clipboard-only flag is removed.
    if hyprshot -m region -o "$OUTPUT_DIR"; then
      send_notification "Screenshot Captured" "Region copied and saved."
    else
      send_notification "Screenshot Cancelled" "Capture was cancelled."
    fi
    ;;

  --screen)
    # Capture the current monitor without requiring a click by using the --current flag.
    # It saves the file to the directory and copies it to the clipboard.
    if hyprshot -m output --current -o "$OUTPUT_DIR"; then
      send_notification "Screenshot Captured" "Screen copied and saved."
    # else
    #   send_notification "Screenshot Cancelled" "Capture was cancelled."
    fi
    ;;

  *)
    echo "Usage: $0 [--region | --screen]"
    exit 1
    ;;
esac
