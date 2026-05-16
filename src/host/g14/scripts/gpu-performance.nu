#!/usr/bin/env nu
# gpu-performance.nu — ASUS power profile control (G14-specific).
# Imports _shared.nu — both files land in ~/.local/bin/ at runtime.
use _shared.nu *

# Read current profile. asusctl output ends with the profile name
# regardless of phrasing across versions, so we take the last token.
def current_profile [] {
    asusctl profile -p | str trim | split row " " | last
}

def pick_meta [profile: string] {
    match $profile {
        "Quiet"       => { icon: "󰒑", class: "quiet" }
        "Balanced"    => { icon: "󰾅", class: "balanced" }
        "Performance" => { icon: "󰓅", class: "performance" }
        _             => { icon: "", class: "unknown" }
    }
}

def main [--get --change] {
    if $change {
        run_silent { asusctl profile -n }
        log_success $"Profile: (current_profile)"
    } else {
        # default = --get
        let p = (current_profile)
        let m = (pick_meta $p)
        as_json {
            text: $"($m.icon) ($p)"
            tooltip: $"Power profile: ($p)"
            class: $m.class
        }
    }
}
