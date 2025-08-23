#!/usr/bin/env bash
#
# A consolidated helper script to manage the microphone for Hyprland.
# It can get the current status for Waybar (with JSON) or toggle the mute state.

# --- FUNCTION: Get status for Waybar ---
get_status_for_waybar() {
    local MUTE_STATE
    MUTE_STATE=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | awk '{print $3}')

    local ICON="" # Default: Unmuted icon
    local CLASS=""
    local TOOLTIP="Microphone: Active"

    if [[ "$MUTE_STATE" == "[MUTED]" ]]; then
        ICON="" # Muted icon
        CLASS="muted"
        TOOLTIP="Microphone: Muted"
    fi

    # Print a JSON object for Waybar
    printf '{"text":"%s", "tooltip":"%s", "class":"%s"}\n' "$ICON" "$TOOLTIP" "$CLASS"
}

# --- FUNCTION: Toggle mute state and send notification ---
toggle_mic_and_notify() {
    # Toggle the mute state
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

    # Give the system a moment to update
    sleep 0.1

    local NEW_MUTE_STATE
    NEW_MUTE_STATE=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | awk '{print $3}')

    if [[ "$NEW_MUTE_STATE" == "[MUTED]" ]]; then
        notify-send -i "microphone-sensitivity-muted" -h string:x-dunst-stack-tag:mic_mute "Microphone Muted"
    else
        notify-send -i "audio-input-microphone" -h string:x-dunst-stack-tag:mic_mute "Microphone Unmuted"
    fi
}

# --- Main Logic ---
case "$1" in
  --get-status)
    get_status_for_waybar
    ;;
  --toggle)
    toggle_mic_and_notify
    ;;
  *)
    echo "Usage: $0 [--get-status | --toggle]"
    exit 1
    ;;
esac
