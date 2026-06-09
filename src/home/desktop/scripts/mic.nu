#!/usr/bin/env nu
# mic.nu — Microphone mute toggle + waybar status.
use _shared.nu *
def muted []: nothing -> bool {
    capture { wpctl get-volume @DEFAULT_AUDIO_SOURCE@ } | str contains "MUTED"
}
def meta [is_muted: bool]: nothing -> record {
    if $is_muted {
        {icon: "󰍭", desc: "Microphone muted", class: "muted"}
    } else {
        {icon: "󰍬", desc: "Microphone active", class: "active"}
    }
}
def main [--get, --toggle]: nothing -> nothing {
    if $toggle {
        run_silent { wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle }
        run_silent { swayosd-client --input-volume mute-toggle }
        let m = (meta (muted))
        notify "Microphone" $m.desc
    } else {
        let m = (meta (muted))
        status $m.icon $m.desc $m.class
    }
}
