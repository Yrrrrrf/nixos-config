#!/usr/bin/env nu
# volume.nu — Audio sink control + waybar status.
use _shared.nu *

# wpctl prints: "Volume: 0.50" or "Volume: 0.50 [MUTED]"
def state []: nothing -> record {
    let raw = (capture { wpctl get-volume @DEFAULT_AUDIO_SINK@ })
    let muted = ($raw | str contains "MUTED")
    let pct = (
        $raw
        | parse -r 'Volume: (?P<v>[0-9.]+)'
        | get v.0
        | into float
        | $in * 100
        | math round
        | into int
    )
    { pct: $pct, muted: $muted }
}

# (pct, muted) → presentation. tooltip = action hint, not a number restated.
def meta [pct: int, muted: bool]: nothing -> record {
    if $muted {
        { icon: "󰝟", desc: "Muted — click to unmute", class: "muted" }
    } else {
        let icon = if $pct > 66 { "󰕾" } else if $pct > 33 { "󰖀" } else { "󰕿" }
        let class = if $pct > 66 { "high" } else if $pct > 33 { "medium" } else { "low" }
        { icon: $icon, desc: "Scroll to adjust, click to mute", class: $class }
    }
}

def get_waybar [] {
    let s = (state)
    let m = (meta $s.pct $s.muted)
    as_json {
        text:    $"($m.icon) ($s.pct)%"
        tooltip: $m.desc
        class:   $m.class
    }
}

def main [--get --up --down --mute --set: int] {
    if $up {
        run_silent { wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ }
        run_silent { swayosd-client --output-volume raise }
    } else if $down {
        run_silent { wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- }
        run_silent { swayosd-client --output-volume lower }
    } else if $mute {
        run_silent { wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle }
        run_silent { swayosd-client --output-volume mute-toggle }
    } else if $set != null {
        run_silent { wpctl set-volume @DEFAULT_AUDIO_SINK@ ($"($set)%") }
        run_silent { swayosd-client --output-volume ($set) }
    } else {
        get_waybar
    }
}
