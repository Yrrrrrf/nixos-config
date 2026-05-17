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
def country [name: string]: nothing -> string {
    if ($name | str contains "intl") {
        "MX"
    } else {
        "US"
    }
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
