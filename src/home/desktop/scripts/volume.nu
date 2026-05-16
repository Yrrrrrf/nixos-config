#!/usr/bin/env nu
# volume.nu — Audio sink control + waybar status.
# Mutating actions delegate to swayosd-client so the OSD renders;
# --get reads state directly from wpctl for waybar polling.
use _shared.nu *

# Read current volume (0-100, integer) and mute state.
# wpctl prints: "Volume: 0.50" or "Volume: 0.50 [MUTED]"
def read_state [] {
    let raw = (wpctl get-volume @DEFAULT_AUDIO_SINK@ | str trim)
    let muted = ($raw | str contains "MUTED")
    let parts = ($raw | split row " ")
    let volume = (($parts | get 1 | into float) * 100 | math round | into int)
    { volume: $volume, muted: $muted }
}

def pick_icon [volume: int, muted: bool] {
    if $muted        { "󰖁" }
    else if $volume == 0 { "" }
    else if $volume < 50 { "" }
    else                 { "󰕾" }
}

def pick_class [volume: int, muted: bool] {
    if $muted        { "muted" }
    else if $volume > 66 { "high" }
    else if $volume > 33 { "medium" }
    else                 { "low" }
}

def main [--get --up --down --mute] {
    if $up {
        run_silent { swayosd-client --output-volume raise }
    } else if $down {
        run_silent { swayosd-client --output-volume lower }
    } else if $mute {
        run_silent { swayosd-client --output-volume mute-toggle }
    } else {
        # default = --get
        let s = (read_state)
        let icon = (pick_icon $s.volume $s.muted)
        let class = (pick_class $s.volume $s.muted)
        let text = $"($icon) ($s.volume)%"
        let tooltip = (if $s.muted { "Volume: Muted" } else { $"Volume: ($s.volume)%" })
        as_json { text: $text, tooltip: $tooltip, class: $class }
    }
}
