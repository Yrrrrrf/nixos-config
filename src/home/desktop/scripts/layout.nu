#!/usr/bin/env nu
# layout.nu — Keyboard layout switcher (Hyprland).
# Bar shows country code only; tooltip carries the full keymap name.
use _shared.nu *

const KEYBOARD_NAME = "asus-keyboard"

# Active keymap name from hyprctl.
def keymap []: nothing -> string {
    hyprctl devices -j
    | from json
    | get keyboards
    | where name == $KEYBOARD_NAME
    | get 0?.active_keymap
    | default "Unknown"
}

# Reduce keymap names to country codes.
# Fast path: 2 uppercase letters right after first "(", e.g. "(US".
# Fallback: known country names mapped to ISO-ish codes.
# Add new entries here as new layouts join the rotation.
def country [name: string]: nothing -> string {
    let direct = ($name | parse -r '\((?P<c>[A-Z]{2})' | get c.0?)
    if $direct != null { return $direct }

    let inside = ($name | parse -r '\((?P<v>[^,)]+)' | get v.0? | default "" | str trim)
    {
        "Mexico":          "MX"
        "Latin American":  "LA"
        "United Kingdom":  "UK"
    } | get -o $inside | default "??"
}

def main [--get --change] {
    if $change {
        run_silent { hyprctl switchxkblayout $KEYBOARD_NAME next }
        let now = (keymap)
        notify "Keyboard Layout" (country $now)
    } else {
        let now = (keymap)
        let code = (country $now)
        as_json {
            text:    $"⌨ ($code)"
            tooltip: $now
            class:   ($code | str downcase)
        }
    }
}
