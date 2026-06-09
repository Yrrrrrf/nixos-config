#!/usr/bin/env nu
# brightness.nu — Screen backlight control + waybar status.
# brightnessctl for state, swayosd-client for OSD.
use _shared.nu *
def percent []: nothing -> int {
    let cur = (capture { brightnessctl get } | into int)
    let max = (capture { brightnessctl max } | into int)
    (($cur * 100) / $max | math round | into int)
}
def meta [pct: int]: nothing -> record {
    level3 $pct "󰃠" "󰃟" "󰃞" | merge {desc: "Scroll to adjust"}
}
def get_waybar [] {
    let p = (percent)
    let m = (meta $p)
    status $"($m.icon) ($p)%" $m.desc $m.class
}
def main [
    --get
    --up
    --down
    --set: int
]: nothing -> nothing {
    if $up {
        run_silent { swayosd-client --brightness raise }
    } else if $down {
        run_silent { swayosd-client --brightness lower }
    } else if $set != null {
        run_silent { brightnessctl set ($"($set)%") }
        run_silent { swayosd-client --brightness ($set) }
    } else {
        get_waybar
    }
}
