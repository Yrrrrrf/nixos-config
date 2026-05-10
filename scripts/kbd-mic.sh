#!/usr/bin/env bash
#
# Microphone Manager
# --get-status: Used by Waybar (JSON output)
# --toggle:     Used by Keybinds (Triggers SwayOSD)

# --- FUNCTION: Get status for Waybar ---
get_status_for_waybar() {
    # We use wpctl to READ the status because SwayOSD doesn't output JSON for Waybar
    local MUTE_STATE
    MUTE_STATE=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | awk '{print $3}')

    local ICON="" # Unmuted
    local CLASS=""
    local TOOLTIP="Microphone: Active"

    if [[ "$MUTE_STATE" == "[MUTED]" ]]; then
        ICON="" # Muted
        CLASS="muted"
        TOOLTIP="Microphone: Muted"
    fi

    # Print JSON for Waybar
    printf '{"text":"%s", "tooltip":"%s", "class":"%s"}\n' "$ICON" "$TOOLTIP" "$CLASS"
}

# --- FUNCTION: Toggle using SwayOSD ---
toggle_mic() {
    # SwayOSD handles the actual muting AND the notification popup
    swayosd-client --input-volume mute-toggle
}

# --- Main Logic ---
case "$1" in
  --get-status)
    get_status_for_waybar
    ;;
  --toggle)
    toggle_mic
    ;;
  *)
    echo "Usage: $0 [--get-status | --toggle]"
    exit 1
    ;;
esac
