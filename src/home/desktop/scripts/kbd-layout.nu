#!/usr/bin/env nu
use _shared.nu *

# Keyboard Layout Manager
const KEYBOARD_NAME = "asus-keyboard"

def get_layout_info [full_name: string] {
    if ($full_name | str contains "English (US)") {
        { key: "US", language: "English" }
    } else if ($full_name | str contains "intl") {
        { key: "MX", language: "Spanish" }
    } else {
        { key: "?", language: "Unknown" }
    }
}

def main [
    --get    # Get current layout info for Waybar
    --change # Change to next layout
] {
    if $get {
        let full_name = (hyprctl devices -j | from json | get keyboards | where name == $KEYBOARD_NAME | get 0.active_keymap)
        waybar_json (get_layout_info $full_name)
    } else if $change {
        run_silent { hyprctl switchxkblayout $KEYBOARD_NAME next }
        sleep 100ms

        
        let full_name = (hyprctl devices -j | from json | get keyboards | where name == $KEYBOARD_NAME | get 0.active_keymap)
        let info = (get_layout_info $full_name)
        let msg = $"Language set to: \(($info.key)\) ($info.language)"
        
        log_success $msg
        notify "Keyboard Layout" $msg --icon "input-keyboard" --tag "keyboard_layout"
    }
}



