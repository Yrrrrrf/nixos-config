#!/usr/bin/env nu

# A helper script to manage keyboard backlight for Hyprland in a NON-CYCLIC way.
# It checks the current state and will not wrap around from high to off or vice-versa.

const levels = ["Off", "Low", "Med", "High"]

def get_current_level [] {
    asusctl -k | lines | find "Current keyboard led brightness:" | first | ansi strip | split row ":" | last | str trim
}



def set_brightness [level: string] {
    let level_lower = ($level | str downcase)
    asusctl --kbd-bright $level_lower
}

def main [
    --up   # Increase brightness
    --down # Decrease brightness
    --get  # Get current level for Waybar
] {
    let current_level = (get_current_level)
    
    if $get {
        { level: $current_level, icon: "󰌌" } | to json --raw
        return
    }

    let current_index = ($levels | enumerate | where item == $current_level | get 0?.index | default (-1))

    if $current_index == -1 {
        print -e $"Error: Could not determine current backlight level. Got: ($current_level)"
        exit 1
    }

    if $up {
        if $current_index < (($levels | length) - 1) {
            let next = ($levels | get ($current_index + 1))
            set_brightness $next
            print $"Keyboard backlight increased to: ($next)"
        }
    } else if $down {
        if $current_index > 0 {
            let next = ($levels | get ($current_index - 1))
            set_brightness $next
            print $"Keyboard backlight decreased to: ($next)"
        }
    }
}

