#!/usr/bin/env nu

# Microphone Manager
# --get-status: Used by Waybar (JSON output)
# --toggle:     Used by Keybinds (Triggers SwayOSD)

def main [
    --get-status # Get status for Waybar
    --toggle     # Toggle mic using SwayOSD
] {
    if $get_status {
        let mute_state = (wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | split row " " | get 2? | default "")
        
        let info = if $mute_state == "[MUTED]" {
            { icon: "", class: "muted", tooltip: "Microphone: Muted" }
        } else {
            { icon: "", class: "", tooltip: "Microphone: Active" }
        }

        {
            text: $info.icon,
            tooltip: $info.tooltip,
            class: $info.class
        } | to json --raw
    } else if $toggle {
        swayosd-client --input-volume mute-toggle
    }
}
