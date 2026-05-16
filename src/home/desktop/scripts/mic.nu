#!/usr/bin/env nu
# mic.nu — Microphone mute toggle + waybar status.
use _shared.nu *

# Read mic mute state from PipeWire/WirePlumber.
def read_muted [] {
    wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | str trim | str contains "MUTED"
}

def main [--get-status --toggle] {
    if $toggle {
        run_silent { swayosd-client --input-volume mute-toggle }
        let muted = (read_muted)
        log_success (if $muted { "Microphone muted" } else { "Microphone active" })
    } else {
        # default = --get-status
        let muted = (read_muted)
        let icon = (if $muted { "" } else { "" })
        let class = (if $muted { "muted" } else { "active" })
        let tooltip = (if $muted { "Mic: Muted" } else { "Mic: Active" })
        as_json { text: $icon, tooltip: $tooltip, class: $class }
    }
}
