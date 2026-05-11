#!/usr/bin/env nu

# A helper script to manage keyboard backlight for Hyprland in a NON-CYCLIC way.
# It checks the current state and will not wrap around from high to off or vice-versa.

const levels = ["Off", "Low", "Med", "High"]

def get_current_level [] {
    asusctl -k | lines | find "Current keyboard led brightness:" | split row ":" | last | str trim
}

def set_brightness [level: string] {
    let level_lower = ($level | str downcase)
    asusctl --kbd-bright $level_lower
}

def main [
    --up   # Increase brightness
    --down # Decrease brightness
] {
    let current_level = (get_current_level)
    let current_index = ($levels | enumerate | where item == $current_level | get 0?.index | default (-1))

    if $current_index == -1 {
        print -e $"Error: Could not determine current backlight level. Got: ($current_level)"
        exit 1
    }

    if $up {
        if $current_index < (($levels | length) - 1) {
            set_brightness ($levels | get ($current_index + 1))
        }
    } else if $down {
        if $current_index > 0 {
            set_brightness ($levels | get ($current_index - 1))
        }
    }
}
