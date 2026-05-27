#!/usr/bin/env nu
# kbd-backlight.nu — ASUS keyboard backlight cycling (G14).
# Reads kernel sysfs; writes via asusctl daemon path.
use _shared.nu *
const SYS_PATH = "/sys/class/leds/asus::kbd_backlight/brightness"
const LEVELS = ["off", "low", "med", "high"]
# Current level as integer 0..3. sysfs is single source of truth.
def current []: nothing -> int {
    try {
        open $SYS_PATH | str trim | into int
    } catch { 0 }
}
# Compute next level name (clamped, no wrap).
def step [direction: string]: nothing -> string {
    let now = (current)
    let next_idx = (match $direction {
        "up" => {
            if $now < 3 { $now + 1 } else { 3 }
        }
        "down" => {
            if $now > 0 { $now - 1 } else { 0 }
        }
        _ => $now
    })
    $LEVELS | get $next_idx
}
# Level int → presentation record. Different icons per level so the
# bar visually reflects state, not a static glyph.
def meta [level: int]: nothing -> record { match $level {
    0 => {icon: "󰌌", desc: "Backlight off"}
    1 => {icon: "󱨇", desc: "Backlight low"}
    2 => {icon: "󱨈", desc: "Backlight medium"}
    3 => {icon: "󱨉", desc: "Backlight high"}
    _ => {icon: "󰋖", desc: "Backlight unknown"}
} }
def main [--get, --up, --down] {
    let dir = if $up { "up" } else if $down { "down" } else { null }
    if $dir != null {
        let cmd = if $dir == "up" { "next" } else { "prev" }
        run_silent { asusctl leds ($cmd) }
        let now = (current)
        let m = (meta $now)
        let pct = ($now / 3.0)
        run_silent { swayosd-client --custom-message $"($m.icon) Keyboard: ($LEVELS | get $now | str capitalize)" --custom-icon $m.icon --custom-progress $pct }
    } else {
        let lvl = (current)
        let m = (meta $lvl)
        as_json {
            text:    $m.icon
            tooltip: $m.desc
            class:   ($LEVELS | get $lvl)
        }
    }
}
