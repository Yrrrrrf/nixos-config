#!/usr/bin/env nu
# brightness.nu — Screen backlight control + waybar status.
# Vendor-agnostic: brightnessctl for state, swayosd-client for OSD.
# Lives in desktop/ (not host/g14/) because neither tool is asus-specific.
use _shared.nu *

def read_percent [] {
    let current = (brightnessctl get | into int)
    let max = (brightnessctl max | into int)
    (($current * 100) / $max | math round | into int)
}

def pick_icon [pct: int] {
    if $pct > 66      { "󰃠" }
    else if $pct > 33 { "󰃟" }
    else              { "󰃞" }
}

def pick_class [pct: int] {
    if $pct > 66      { "high" }
    else if $pct > 33 { "medium" }
    else              { "low" }
}

def main [--get --up --down] {
    if $up {
        run_silent { swayosd-client --brightness raise }
    } else if $down {
        run_silent { swayosd-client --brightness lower }
    } else {
        # default = --get
        let pct = (read_percent)
        let icon = (pick_icon $pct)
        as_json {
            text: $"($icon) ($pct)%"
            tooltip: $"Brightness: ($pct)%"
            class: (pick_class $pct)
        }
    }
}
