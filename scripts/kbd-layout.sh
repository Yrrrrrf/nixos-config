#!/usr/bin/env bash
#
# A helper script to manage keyboard layout switching for Hyprland.
# It can change to the next layout and notify the user, or get the
# current layout for display in Waybar.

# --- CONFIGURATION ---
KEYBOARD_NAME="asus-keyboard"

# --- FUNCTION: Translates the long layout name to a short, clean one ---
get_short_name() {
    local full_name="$1"
    local short_name="?"

    # Check the full name and assign a clean, short name.
    # The "*intl*" pattern is a robust way to catch the international variant.
    case "$full_name" in
      "English (US)")
        short_name="US"
        ;;
      *intl*)
        short_name="MX"
        ;;
    esac

    echo "$short_name"
}

# --- FUNCTION: Get current layout for Waybar ---
get_layout_for_waybar() {
    local full_name
    full_name=$(hyprctl devices -j | jq -r ".keyboards[] | select(.name == \"$KEYBOARD_NAME\") | .active_keymap")

    # Get the clean name using our new function
    local short_name
    short_name=$(get_short_name "$full_name")

    # Print the JSON object for Waybar
    printf '{"text":"%s", "tooltip":"%s"}\n' "$short_name" "Layout: $full_name"
}

# --- FUNCTION: Change layout and send notification ---
change_layout_and_notify() {
    hyprctl switchxkblayout "$KEYBOARD_NAME" next
    sleep 0.1

    local new_full_name
    new_full_name=$(hyprctl devices -j | jq -r ".keyboards[] | select(.name == \"$KEYBOARD_NAME\") | .active_keymap")

    # Get the clean name using our new function
    local new_short_name
    new_short_name=$(get_short_name "$new_full_name")

    # Send a notification with the clean name
    notify-send -i input-keyboard "Keyboard Layout Changed" "Switched to: <b>${new_short_name}</b>"
}

# --- Main Logic ---
case "$1" in
  --get)
    get_layout_for_waybar
    ;;
  --change)
    change_layout_and_notify
    ;;
  *)
    echo "Usage: $0 [--get | --change]"
    exit 1
    ;;
esac