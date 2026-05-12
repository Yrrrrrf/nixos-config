#!/usr/bin/env nu

# A helper script to manage keyboard layout switching for Hyprland.
# It can change to the next layout and notify the user, or get the
# current layout for display in Waybar.

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
        get_layout_info $full_name | to json --raw
    } else if $change {
        hyprctl switchxkblayout $KEYBOARD_NAME next
        sleep 100ms
        
        let full_name = (hyprctl devices -j | from json | get keyboards | where name == $KEYBOARD_NAME | get 0.active_keymap)
        let info = (get_layout_info $full_name)
        let msg = $"Language set to: \(($info.key)\) ($info.language)"
        
        print $msg
        notify-send -i "input-keyboard" -h string:x-dunst-stack-tag:keyboard_layout $msg
    }
}


