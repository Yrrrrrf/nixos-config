#!/usr/bin/env bash
#
# A consolidated helper script to manage ASUS performance profiles.
# It can get the current status for Waybar or change to the next profile.

# Gets current profile and prints a JSON object for Waybar.
get_profile_for_waybar() {
    local PROFILE
    PROFILE=$(asusctl profile -p | grep "Active profile is" | cut -d' ' -f4)

    local ICON=""
    local CLASS="unknown"

    case "$PROFILE" in
      Quiet)
        ICON="󰒑"
        CLASS="quiet"
        ;;
      Balanced)
        ICON="󰾅"
        CLASS="balanced"
        ;;
      Performance)
        ICON="󰓅"
        CLASS="performance"
        ;;
    esac

    printf '{"text":"%s", "tooltip":"Profile: %s", "class":"%s"}\n' "$ICON" "$PROFILE" "$CLASS"
}

# Changes to the next profile and sends a single, updating notification.
change_profile_and_notify() {
    # 1. Change to the next performance profile.
    asusctl profile -n

    # 2. Get the name of the new active profile.
    local PROFILE_NAME
    PROFILE_NAME=$(asusctl profile -p | grep "Active profile is" | cut -d' ' -f4)

    # 3. Send the notification with a stack tag.
    #    This ensures that this new notification will replace any
    #    previous notification that had the same "performance_profile" tag.
    notify-send -i "system-performance" \
                -h string:x-dunst-stack-tag:performance_profile \
                "Performance Profile: ${PROFILE_NAME}"
}


# Main logic: Check the first argument to decide which function to run.
case "$1" in
  --get)
    get_profile_for_waybar
    ;;
  --change)
    change_profile_and_notify
    ;;
  *)
    echo "Usage: $0 [--get | --change]"
    exit 1
    ;;
esac
