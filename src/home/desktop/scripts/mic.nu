#!/usr/bin/env nu
# mic.nu — Microphone mute toggle + waybar status.
use _shared.nu *

def muted []: nothing -> bool {
    capture { wpctl get-volume @DEFAULT_AUDIO_SOURCE@ } | str contains "MUTED"
}

def meta [is_muted: bool]: nothing -> record {
    if $is_muted {
        { icon: "󰍭", desc: "Microphone muted",  class: "muted" }
    } else {
        { icon: "󰍬", desc: "Microphone active", class: "active" }
    }
}

def main [--get-status --toggle] {
    if $toggle {
        run_silent { swayosd-client --input-volume mute-toggle }
        let m = (meta (muted))
        notify "Microphone" $m.desc
    } else {
        let m = (meta (muted))
        as_json {
            text:    $m.icon
            tooltip: $m.desc
            class:   $m.class
        }
    }
}
