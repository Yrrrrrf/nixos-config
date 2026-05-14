#!/usr/bin/env nu
use _shared.nu *

# Volume Manager
def main [
    --get   # Get volume status for Waybar
    --up    # Increase volume
    --down  # Decrease volume
    --mute  # Toggle mute
] {
    if $get {
        let vol_raw = (wpctl get-volume @DEFAULT_AUDIO_SINK@ | str trim | split row " ")
        let volume = ($vol_raw | get 1 | into float | ($in * 100) | math round)
        let muted = (($vol_raw | length) > 2 and ($vol_raw | get 2) == "[MUTED]")

        
        let icon = if $muted { "󰖁" } else if $volume == 0 { "" } else if $volume < 50 { "" } else { "󰕾" }
        as_json { volume: $volume, muted: $muted, icon: $icon }


    } else if $up {
        run_silent { swayosd-client --output-volume raise }
        log_success "Volume increased"
    } else if $down {
        run_silent { swayosd-client --output-volume lower }
        log_success "Volume decreased"
    } else if $mute {
        run_silent { swayosd-client --output-volume mute-toggle }
        log_success "Volume mute toggled"
    }
}

