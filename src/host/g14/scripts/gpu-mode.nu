#!/usr/bin/env nu
# gpu-performance.nu — ASUS power profile (G14).
# Reads asusctl's "Active profile is X" line, ignoring stderr spam.
use _shared.nu *

# asusctl profile -p outputs (after stderr filter):
#   Active profile is Performance
#   Profile on AC is Performance
#   Profile on Battery is Quiet
# Only the first line carries the active profile.
def current []: nothing -> string {
    capture { asusctl profile get }
    | lines
    | where {|l| $l | str starts-with "Active profile:"}
    | get 0?
    | default ""
    | parse "Active profile: {p}"
    | get p.0?
    | default "Unknown"
}

# Single source of truth: profile name → presentation record.
# tooltip carries the *description*, not a restatement of `text`.
def meta [profile: string]: nothing -> record {
    match $profile {
        "Quiet"       => { icon: "󰒲", desc: "Silent — fans off, battery priority" }
        "Balanced"    => { icon: "󰓅", desc: "Default — adaptive performance" }
        "Performance" => { icon: "󱐌", desc: "Maximum — fans engaged, plugged in recommended" }
        _             => { icon: "󰋖", desc: "Unknown profile state" }
    }
}

def main [--get --change] {
    if $change {
        run_silent { asusctl profile next }
        let now = (current)
        let m = (meta $now)
        run_silent { swayosd-client --custom-message $"GPU Mode: ($m.icon)" --custom-icon $m.icon }
    } else {
        let now = (current)
        let m = (meta $now)
        as_json {
            text:    $"($m.icon) ($now)"
            tooltip: $m.desc
            class:   ($now | str downcase)
        }
    }
}
