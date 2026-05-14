#!/usr/bin/env nu
use _shared.nu *

# Microphone Manager
def main [
    --get-status # Get status for Waybar
    --toggle     # Toggle mic using SwayOSD
] {
    if $get_status {
        let mute_state = (wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | split row " " | get 2? | default "")
        
        if $mute_state == "[MUTED]" {
            as_json { status: "Muted", icon: "" }
        } else {
            as_json { status: "Active", icon: "" }
        }
    } else if $toggle {
        swayosd-client --input-volume mute-toggle
        sleep 100ms
        
        let mute_state = (wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | split row " " | get 2? | default "")
        let status = if $mute_state == "[MUTED]" { "Muted" } else { "Active" }
        let msg = $"Microphone status set to: ($status)"
        log_success $msg
        notify "Microphone" $msg --icon "audio-input-microphone" --tag "mic_status"
    }

}


