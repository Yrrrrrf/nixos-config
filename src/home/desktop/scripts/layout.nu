#!/usr/bin/env nu
# layout.nu — Keyboard layout switcher (Hyprland).
use _shared.nu *

# Replace with your actual keyboard device name from:
#   hyprctl devices -j | from json | get keyboards | select name
const KEYBOARD_NAME = "asus-keyboard"

# Parse hyprland's active_keymap string into a compact display record.
#   "English (US)"                          → us
#   "English (US, intl., with dead keys)"   → us-intl
def get_layout_info [full_name: string] {
    let lower = ($full_name | str downcase)
    let lang = (
        $lower
        | parse -r '^(?P<v>[a-z]+)'
        | get v.0?
        | default ($lower | str substring 0..2)
    )
    let variant = (
        $lower
        | parse -r '\((?P<v>[^,)]+)'
        | get v.0?
        | default ""
        | str trim
    )
    let short = (if ($variant | is-empty) { $lang } else { $"($lang)-($variant)" })
    {
        text: $"⌨ ($short)"
        tooltip: $"Layout: ($full_name)"
        class: $short
    }
}

def current_layout [] {
    hyprctl devices -j
    | from json
    | get keyboards
    | where name == $KEYBOARD_NAME
    | get 0.active_keymap
}

def main [--get --change] {
    if $change {
        run_silent { hyprctl switchxkblayout $KEYBOARD_NAME next }
        log_success $"Layout: (current_layout)"
    } else {
        # default = --get
        as_json (get_layout_info (current_layout))
    }
}
