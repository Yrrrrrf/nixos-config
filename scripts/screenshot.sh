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
    # Use hyprshot to capture a region, save it, and copy it to the clipboard.
    if hyprshot -m region -o "$OUTPUT_DIR" --clipboard-only; then
      send_notification "Screenshot Captured" "Region copied and saved."
    else
      send_notification "Screenshot Cancelled" "Capture was cancelled."
    fi
    ;;

  --screen)
    # Use hyprshot to capture the current screen, save it, and copy it.
    if hyprshot -m output -o "$OUTPUT_DIR" --clipboard-only; then
      send_notification "Screenshot Captured" "Screen copied and saved."
    else
      send_notification "Screenshot Cancelled" "Capture was cancelled."
    fi
    ;;

  *)
    echo "Usage: $0 [--region | --screen]"
    exit 1
    ;;
esac
