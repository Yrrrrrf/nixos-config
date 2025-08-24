#!/usr/bin/env bash
#
# A helper script for taking screenshots with Flameshot on Hyprland.
# This script uses Flameshot's native GUI and clipboard functionality.

# --- FUNCTION: Send a notification ---
# We use a stack tag to replace the previous notification.
send_notification() {
  notify-send -i "flameshot" \
              -h string:x-dunst-stack-tag:screenshot_notification \
              "$1" "$2"
}

# --- Main Logic ---
case "$1" in
  --region)
    # Use 'flameshot gui -c' to capture a region and copy it to the clipboard.
    # The 'cliphist' daemon will automatically store it from the clipboard.
    if flameshot gui -c; then
      send_notification "Screenshot Copied" "Region added to clipboard and history."
    else
      send_notification "Screenshot Cancelled" "Capture was cancelled."
    fi
    ;;

  --screen)
    # Use 'flameshot full -c' to capture the entire desktop and copy it.
    if flameshot full -c; then
      send_notification "Screenshot Copied" "Full screen added to clipboard and history."
    else
      send_notification "Screenshot Cancelled" "Capture was cancelled."
    fi
    ;;

  *)
    echo "Usage: $0 [--region | --screen]"
    exit 1
    ;;
esac
