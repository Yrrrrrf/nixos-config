#!/usr/bin/env nu
# kbd-backlight.nu — ASUS keyboard backlight cycling (G14-specific).
use _shared.nu *

const LEVELS = ["off" "low" "med" "high"]

# asusctl -k prints: "Current keyboard led brightness: Med"
def current_level [] {
    asusctl -k | str trim | split row " " | last | str downcase
}

def next_level [direction: string] {
    let now = (current_level)
    let idx = (
        $LEVELS
        | enumerate
        | where item == $now
        | get 0.index?
        | default 1
    )
    let next_idx = (match $direction {
        "up"   => (($idx + 1) | math min (($LEVELS | length) - 1))
        "down" => (($idx - 1) | math max 0)
        _      => $idx
    })
    $LEVELS | get $next_idx
}

def main [--get --up --down] {
    if $up {
        let next = (next_level "up")
        run_silent { asusctl --kbd-bright $next }
        log_success $"Keyboard backlight: ($next)"
    } else if $down {
        let next = (next_level "down")
        run_silent { asusctl --kbd-bright $next }
        log_success $"Keyboard backlight: ($next)"
    } else {
        # default = --get
        let level = (current_level)
        as_json {
            text: $"󰌌 ($level)"
            tooltip: $"Keyboard backlight: ($level)"
            class: $level
        }
    }
}
