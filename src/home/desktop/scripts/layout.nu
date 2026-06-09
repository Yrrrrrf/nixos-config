#!/usr/bin/env nu
# layout.nu — Keyboard layout switcher (Hyprland).
# Bar shows country code only; tooltip carries the full keymap name.
use _shared.nu *
# Get the main keyboard device name.
def keyboard_name []: nothing -> string {
    hyprctl devices -j | from json | get keyboards | where main == true | get 0?.name | default "asus-keyboard"
}
# Active keymap name from hyprctl.
def keymap []: nothing -> string {
    let name = (keyboard_name)
    hyprctl devices -j | from json | get keyboards | where name == $name | get 0?.active_keymap | default "Unknown"
}
# Reduce keymap names to country codes.
def country [name: string]: nothing -> string {
    if ($name | str contains "intl") or ($name | str contains "Spanish") {
        "MX"
    } else {
        "US"
    }
}
def main [--get, --change]: nothing -> nothing {
    let kb = (keyboard_name)
    if $change {
        run_silent { hyprctl switchxkblayout $kb next }
        let now = (keymap)
        let code = (country $now)
        osd $"Kbd set: ($code)" "input-keyboard"
    } else {
        let now = (keymap)
        let code = (country $now)
        status $"⌨ ($code)" $now ($code | str downcase)
    }
}
